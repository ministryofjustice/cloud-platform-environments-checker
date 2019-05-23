#!/usr/bin/env ruby

require 'bundler/setup'
require 'openid_connect'
require 'kubeclient'
require 'open-uri'
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

undefined_namespaces = namespace_names_in_k8s_cluster \
  - namespace_names_defined_in_git_repository \
  - K8S_DEFAULT_NAMESPACES

pp undefined_namespaces

