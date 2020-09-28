#!/usr/bin/env ruby

require "#{File.dirname(__FILE__)}/../lib/cp_hosted_namespaces.rb"

ANNOTATION_PREFIX = "cloud-platform.justice.gov.uk"

def main
  check_prerequisites

  namespaces = lister.namespaces

  namespace_details = {}

  namespaces.each { |ns| namespace_details[ns[:name]] = namespace_hash(ns) }

  ingresses = lister.get_ingresses

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

def lister
  @lister ||= ClusterNamespaceLister.new(
    config_file: env('KUBE_CONFIG'),
    context: env('KUBE_CTX'),
  )
end

def namespace_hash(ns)
  {
    namespace: ns[:name],
    application: annotation(ns, "application"),
    business_unit: annotation(ns, "business_unit"),
    team_name: annotation(ns, "team_name"),
    team_slack_channel: annotation(ns, "slack-channel"),
    github_url: annotation(ns, "source-code"),
    deployment_type: annotation(ns, "environment-name"),
    domain_names: [],
  }
end

def annotation(ns, annot)
  ns.dig(:annotations, :"#{ANNOTATION_PREFIX}/#{annot}")
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
