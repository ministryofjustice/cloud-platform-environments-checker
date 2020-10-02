#!/usr/bin/env ruby

require "#{File.dirname(__FILE__)}/../lib/orphaned_namespace_checker"

ANNOTATION_PREFIX = "cloud-platform.justice.gov.uk"

def main
  check_prerequisites

  hash = lister.namespaces.each_with_object({}) { |ns, acc|
    acc[ns.metadata.name] = namespace_hash(ns)
  }

  lister.ingresses.map { |ingress| add_ingress(hash, ingress) }

  rtn = {
    updated_at: Time.now,
    namespace_details: hash.values,
  }

  puts rtn.to_json
end

def lister
  @lister ||= ClusterNamespaceLister.new(
    config_file: env("KUBE_CONFIG"),
    context: env("KUBE_CTX"),
  )
end

def namespace_hash(ns)
  {
    namespace: ns.metadata.name,
    application: annotation(ns, "application"),
    business_unit: annotation(ns, "business-unit"),
    team_name: annotation(ns, "team-name").to_s,
    team_slack_channel: annotation(ns, "slack-channel"),
    github_url: annotation(ns, "source-code"),
    deployment_type: ns.dig("metadata", "labels", "#{ANNOTATION_PREFIX}/environment-name"),
    domain_names: [],
  }
end

def annotation(ns, annot)
    if defined?(ns.metadata.annotations) 
      ns.metadata.annotations["#{ANNOTATION_PREFIX}/#{annot}"]
    end
end

def add_ingress(hash, ingress)
  namespace = ingress.dig("metadata", "namespace")
  hash[namespace][:domain_names] = hosts_from_ingress(ingress)
end

def hosts_from_ingress(ingress)
  ingress.dig("spec", "rules").map { |h| h["host"] }
end

def check_prerequisites
  %w[
    KUBE_CONFIG
    KUBE_CTX
  ].each do |var|
    env(var)
  end
end

def env(var)
  ENV.fetch(var)
end

main
