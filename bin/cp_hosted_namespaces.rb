#!/usr/bin/env ruby

require "#{File.dirname(__FILE__)}/../lib/cp_hosted_namespaces.rb"

def main
  check_prerequisites

  # How to fetch the kubeconfig file, so we can talk to the cluster
  kubeconfig = {
    s3client: Aws::S3::Client.new(
      region: env('KUBECONFIG_AWS_REGION'),
      credentials: Aws::Credentials.new(env('KUBECONFIG_AWS_ACCESS_KEY_ID'), env('KUBECONFIG_AWS_SECRET_ACCESS_KEY'))
    ),
    bucket:                env('KUBECONFIG_S3_BUCKET'),
    key:                   env('KUBECONFIG_S3_KEY'),
    local_target:          env('KUBE_CONFIG'),
    context:               env('KUBE_CTX'),
  }

  namespaces = ClusterNamespaceLister.new(
    config_file: env('KUBE_CONFIG'),
    context: env('KUBE_CTX'),
  ).namespaces

  namespace_details = {}

  namespaces.each do |namespace|
    namespace_details[namespace[:name]] = {
      namespace: namespace[:name],
      application: namespace.dig(:annotations, :'cloud-platform.justice.gov.uk/application'),
      business_unit: namespace.dig(:annotations, :'cloud-platform.justice.gov.uk/business-unit'),
      team_name: namespace.dig(:annotations, :'cloud-platform.justice.gov.uk/team-name'),
      team_slack_channel: namespace.dig(:annotations, :'cloud-platform.justice.gov.uk/slack-channel'),
      github_url: namespace.dig(:annotations, :'cloud-platform.justice.gov.uk/source-code'),
      deployment_type: namespace.dig(:labels, :'cloud-platform.justice.gov.uk/environment-name'),
      domain_names: []
    }
  end

  ingresses = ClusterNamespaceLister.new(
    config_file: env('KUBE_CONFIG'),
    context: env('KUBE_CTX'),
  ).get_ingresses



  ingresses
    .reject { |ingress| ClusterNamespaceLister::K8S_DEFAULT_NAMESPACES.include?(ingress.dig("metadata","namespace"))  }
    .map { |ingress|
      namespace = ingress.dig("metadata","namespace")
      namespace_details[namespace][:domain_names] = hosts_from_ingress(ingress)
    }

  namespace_details = namespace_details.map { |key,value| value }


  rtn = {
    updated_at: Time.now,
    namespace_details: namespace_details,
  }

  puts rtn.to_json

end

def hosts_from_ingress(ingress)
  ingress.dig("spec","rules").map { |h| h["host"] }
end

def check_prerequisites
  %w(
    KUBECONFIG_AWS_ACCESS_KEY_ID
    KUBECONFIG_AWS_REGION
    KUBECONFIG_AWS_SECRET_ACCESS_KEY
    KUBECONFIG_S3_BUCKET
    KUBECONFIG_S3_KEY
    KUBERNETES_CLUSTER
    KUBE_CONFIG
    KUBE_CTX
  ).each do |var|
    env(var)
  end
end

def env(var)
  ENV.fetch(var)
end

main
