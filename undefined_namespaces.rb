#!/usr/bin/env ruby

require 'bundler/setup'
require 'openid_connect'
require 'kubeclient'
require 'open-uri'
require 'aws-sdk-s3'
require 'json'
require 'pp'
require 'pry-byebug'

ENV_REPO = 'cloud-platform-environments'
ENV_REPO_NAMESPACE_PATH = "https://api.github.com/repos/ministryofjustice/#{ENV_REPO}/contents/namespaces/#{ENV.fetch('PIPELINE_CLUSTER')}"

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

def main
  namespaces_with_tfstate = namespace_names_with_tfstate

  namespace_names_with_no_source_code.each do |name|
    puts "Namespace #{name} exists in the cluster but is not defined in the #{ENV_REPO} repository"

    # If there is no terraform state associated with this namespace, then there
    # are no AWS resources to clean up
    # if namespaces_with_tfstate.include?(name)
    #   puts "AWS Resources:"
    #   aws_resources(name).each do |type, primary_id|
    #     puts "  #{type}: #{primary_id}"
    #   end
    # end
  end
end

def namespace_names_with_no_source_code
  namespace_names_in_k8s_cluster - K8S_DEFAULT_NAMESPACES \
    - namespace_names_defined_in_git_repository
end

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

  tf_objects.contents.map do |obj|
    regexp = %r[#{ENV_REPO}/#{ENV.fetch('PIPELINE_CLUSTER')}/(.*)/terraform.tfstate]
    if regexp.match(obj.key)
      $1
    end
  end.compact
end

main
