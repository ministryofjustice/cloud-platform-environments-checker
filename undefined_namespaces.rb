#!/usr/bin/env ruby

require 'bundler/setup'
require 'openid_connect'
require 'kubeclient'
require 'open-uri'
require 'aws-sdk-s3'
require 'json'
require 'pp'
require 'pry-byebug'

ENV_REPO_NAMESPACE_PATH = "https://api.github.com/repos/ministryofjustice/cloud-platform-environments/contents/namespaces/#{ENV.fetch('PIPELINE_CLUSTER')}"

K8S_DEFAULT_NAMESPACES = %w(
  cert-manager
  default
  ingress-controllers
  kiam
  kube-public
  kube-system
  kuberos
  opa
)

def namespace_names_defined_in_git_repository
  content = open(ENV_REPO_NAMESPACE_PATH).read
  JSON.parse(content).map { |hash| hash.fetch('name') }
end

def namespace_names_in_k8s_cluster
  # TODO: fix this - we won't have current context in the pipeline
  config = Kubeclient::Config.read(ENV.fetch('KUBECONFIG'))
  context = config.context

  client = Kubeclient::Client.new(
    context.api_endpoint,
    'v1',
    ssl_options: context.ssl_options,
    auth_options: context.auth_options
  )

  pods = client.get_pods
  client.get_namespaces.map { |n| n.metadata.name }
end

# If a namespace is defined in the terraform state for the cluster
# it means there are AWS resources associated with it.
def namespace_names_with_tfstate
  s3 = Aws::S3::Client.new
  tf_objects = s3.list_objects(bucket: ENV.fetch('PIPELINE_STATE_BUCKET'))

  tf_objects.contents.each do |obj|
    regexp = %r[#{ENV.fetch('PIPELINE_STATE_KEY_PREFIX')}#{ENV.fetch('PIPELINE_CLUSTER')}/(.*)/terraform.tfstate]
    if regexp.match(obj.key)
      puts $1
    end
  end
end

namespace_names_with_tfstate

# undefined_namespaces = namespace_names_in_k8s_cluster \
#   - namespace_names_defined_in_git_repository \
#   - K8S_DEFAULT_NAMESPACES

