#!/usr/bin/env ruby

require "#{File.dirname(__FILE__)}/../lib/orphaned_namespace_checker"

# This is the 'empty' main.tf file that we add, by default, to any namespaces users create
CANONICAL_MAIN_TF_URL = 'https://raw.githubusercontent.com/ministryofjustice/cloud-platform-environments/master/namespace-resources/resources-main-tf'

ENVIRONMENTS_GITHUB_REPO = 'cloud-platform-environments'

def main(namespace)
  check_prerequisites(namespace)

  puts
  puts "About to delete AWS resources for namespace: #{namespace}"
  puts

  tf_executable = "#{ENV.fetch('TERRAFORM_PATH')}/terraform"

  system("rm -rf .terraform main.tf") # clean up any leftover artefacts from prior invocations
  add_main_tf
  tf_init(tf_executable, namespace)
  system('terraform plan')
end

def check_prerequisites(namespace)
  raise "Please supply namespace as the first command-line argument" if namespace.to_s.empty?

  # Ensure we have AWS credentials
  ENV.fetch('TFSTATE_AWS_ACCESS_KEY_ID')
  ENV.fetch('TFSTATE_AWS_SECRET_ACCESS_KEY')

  raise "Namespace #{namespace} exists in the environments github repo\nAborting." if namespace_defined_in_code?(namespace)
end

def namespace_defined_in_code?(namespace)
  GithubNamespaceLister.new(
    env_repo: ENVIRONMENTS_GITHUB_REPO,
    cluster_name: ENV.fetch('PIPELINE_CLUSTER')
  ).namespace_exists?(namespace)
end

def add_main_tf
  content = open(CANONICAL_MAIN_TF_URL).read
  raise "Couldn't retrieve main.tf from #{CANONICAL_MAIN_TF_URL}" if content.to_s.empty?
  File.open('main.tf', 'w') {|f| f.puts content}
end

def tf_init(tf_executable, namespace)
  # Get AWS credentials from the environment, via bash, so that we don't
  # accidentally log them in cleartext, if all commands are logged.
  cmd = <<~EOF
  #{tf_executable} init \
    -backend-config="access_key=${TFSTATE_AWS_ACCESS_KEY_ID}" \
    -backend-config="secret_key=${TFSTATE_AWS_SECRET_ACCESS_KEY}" \
    -backend-config="bucket=#{ENV.fetch('PIPELINE_STATE_BUCKET')}" \
    -backend-config="key=#{ENV.fetch('PIPELINE_CLUSTER')}/#{namespace}/terraform.tfstate" \
    -backend-config="region=#{ENV.fetch('TFSTATE_AWS_REGION')}"
  EOF
  system cmd
end

main ARGV.shift
