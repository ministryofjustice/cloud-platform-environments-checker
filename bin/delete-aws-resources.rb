#!/usr/bin/env ruby

require "#{File.dirname(__FILE__)}/../lib/orphaned_namespace_checker"

ENVIRONMENTS_GITHUB_REPO = 'cloud-platform-environments'

def main(namespace, destroy)
  check_prerequisites(namespace)

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
  Kubeconfig.new(kubeconfig).fetch_and_store

  puts
  puts "About to delete AWS resources for namespace: #{namespace}"
  puts

  tf_executable = "#{env('TERRAFORM_PATH')}/terraform"

  system("rm -rf .terraform") # clean up any leftover state from prior invocations
  tf_init(tf_executable, namespace)

  # KUBE_CONFIG & KUBE_CTX env. vars must be in scope, or tf_plan will not work
  # see: https://www.terraform.io/docs/providers/kubernetes/index.html#argument-reference

  destroy ? tf_apply(tf_executable) : tf_plan(tf_executable)
end

def check_prerequisites(namespace)
  raise "Please supply namespace as the first command-line argument" if namespace.to_s.empty?

  %w(
    TFSTATE_AWS_ACCESS_KEY_ID
    TFSTATE_AWS_SECRET_ACCESS_KEY
    TFSTATE_AWS_REGION
    TERRAFORM_PATH
    PIPELINE_STATE_BUCKET
    PIPELINE_CLUSTER
  ).each do |var|
    env(var)
  end

  raise "Namespace #{namespace} exists in the environments github repo\nAborting." if namespace_defined_in_code?(namespace)
end

def namespace_defined_in_code?(namespace)
  GithubNamespaceLister.new(
    env_repo: ENVIRONMENTS_GITHUB_REPO,
    cluster_name: env('PIPELINE_CLUSTER')
  ).namespace_exists?(namespace)
end

def tf_init(tf_executable, namespace)
  # Get AWS credentials from the environment, via bash, so that we don't
  # accidentally log them in cleartext, if all commands are logged.
  cmd = <<~EOF
  #{tf_executable} init \
    -backend-config="access_key=${TFSTATE_AWS_ACCESS_KEY_ID}" \
    -backend-config="secret_key=${TFSTATE_AWS_SECRET_ACCESS_KEY}" \
    -backend-config="bucket=#{env('PIPELINE_STATE_BUCKET')}" \
    -backend-config="key=#{env('PIPELINE_CLUSTER')}/#{namespace}/terraform.tfstate" \
    -backend-config="region=#{env('TFSTATE_AWS_REGION')}"
  EOF
  system cmd
end

def tf_plan(tf_executable)
  # Terraform plan will only use AWS credentials from these, specific
  # variable names.
  cmd = <<~EOF
    AWS_ACCESS_KEY_ID=${TFSTATE_AWS_ACCESS_KEY_ID} \
    AWS_SECRET_ACCESS_KEY=${TFSTATE_AWS_SECRET_ACCESS_KEY} \
    #{tf_executable} plan
  EOF
  system cmd
end

# Apply the terraform plan, with no confirmation step.
# This will actually delete AWS resources, so use with care.
def tf_apply(tf_executable)
  cmd = <<~EOF
    AWS_ACCESS_KEY_ID=${TFSTATE_AWS_ACCESS_KEY_ID} \
    AWS_SECRET_ACCESS_KEY=${TFSTATE_AWS_SECRET_ACCESS_KEY} \
    #{tf_executable} apply --auto-approve
  EOF
  system cmd
end

def env(var)
  ENV.fetch(var)
end

namespace = ARGV.shift
destroy = (ARGV.shift == 'destroy')

main(namespace, destroy)
