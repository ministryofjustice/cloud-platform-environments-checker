#!/usr/bin/env ruby

require "#{File.dirname(__FILE__)}/../lib/orphaned_namespace_checker"

# This is the 'empty' main.tf file that we add, by default, to any namespaces users create
CANONICAL_MAIN_TF_URL = 'https://raw.githubusercontent.com/ministryofjustice/cloud-platform-environments/master/namespace-resources/resources-main-tf'

ENVIRONMENTS_GITHUB_REPO = 'cloud-platform-environments'

# TODO: get from env. vars.
PIPELINE_STATE_BUCKET = 'moj-cp-k8s-investigation-environments-terraform'
PIPELINE_STATE_REGION = 'eu-west-1'
PIPELINE_CLUSTER = 'cloud-platform-live-0.k8s.integration.dsd.io'

def main(namespace)
  check_prerequisites(namespace)

  puts
  puts "About to delete AWS resources for namespace: #{namespace}"
  puts

  system("rm -rf .terraform main.tf") # clean up any leftover artefacts from prior invocations
  add_main_tf
  tf_init namespace
  system('terraform plan')
end

def check_prerequisites(namespace)
  raise "Namespace #{namespace} exists in the environments github repo\nAborting." if namespace_defined_in_code?(namespace)

  # Ensure we have AWS credentials
  ENV.fetch('TFSTATE_AWS_ACCESS_KEY_ID')
  ENV.fetch('TFSTATE_AWS_SECRET_ACCESS_KEY')
end

def namespace_defined_in_code?(namespace)
  GithubNamespaceLister.new(
    env_repo: ENVIRONMENTS_GITHUB_REPO,
    cluster_name: ENV.fetch('PIPELINE_CLUSTER')
  ).namespace_exists?(namespace)
end

def add_main_tf
  content = open(CANONICAL_MAIN_TF_URL).read
  raise "Couldn't retrieve main.tf from #{CANONICAL_MAIN_TF_URL}" if content.empty?
  File.open('main.tf', 'w') {|f| f.puts content}
end

def tf_init(namespace)
  cmd = <<~EOF
  terraform init \
    -backend-config="access_key=${TFSTATE_AWS_ACCESS_KEY_ID}" \
    -backend-config="secret_key=${TFSTATE_AWS_SECRET_ACCESS_KEY}" \
    -backend-config="bucket=#{PIPELINE_STATE_BUCKET}" \
    -backend-config="key=#{PIPELINE_CLUSTER}/#{namespace}/terraform.tfstate" \
    -backend-config="region=#{PIPELINE_STATE_REGION}"
  EOF
  system cmd
end

main ARGV.shift
