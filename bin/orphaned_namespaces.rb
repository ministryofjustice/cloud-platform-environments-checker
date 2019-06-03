#!/usr/bin/env ruby

require "#{File.dirname(__FILE__)}/../lib/orphaned_namespace_checker"

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

  # How to retrieve the terraform state, so we can query it to look
  # for AWS resource definitions
  tfstate = {
    s3client: Aws::S3::Client.new(
      region: env('TFSTATE_AWS_REGION'),
      credentials: Aws::Credentials.new(env('TFSTATE_AWS_ACCESS_KEY_ID'), env('TFSTATE_AWS_SECRET_ACCESS_KEY')),
    ),
    bucket: env('PIPELINE_STATE_BUCKET'),
    bucket_prefix: env('TFSTATE_BUCKET_PREFIX'),
  }

  result = CloudPlatformOrphanNamespaces.new(
    cluster_name: env('PIPELINE_CLUSTER'),
    kubeconfig: kubeconfig,
    tfstate:    tfstate,
  ).report

  # Concourse will create the 'output' directory during the
  # 'check-environments' pipeline task. It will do so as root,
  # so this script also needs to run as root, or it will not
  # be able to write to a file in that directory.
  # Concourse seems to have a baked-in assumption that it, and
  # any containers it runs, will run as root.
  File.open('./output/check.txt', 'w') { |f| f.puts(result) }
end

def check_prerequisites
  %w(
    KUBECONFIG_AWS_REGION
    KUBECONFIG_AWS_ACCESS_KEY_ID
    KUBECONFIG_AWS_SECRET_ACCESS_KEY
    KUBECONFIG_S3_BUCKET
    KUBECONFIG_S3_KEY
    KUBE_CONFIG
    KUBE_CTX
    TFSTATE_AWS_REGION
    TFSTATE_AWS_ACCESS_KEY_ID
    TFSTATE_AWS_SECRET_ACCESS_KEY
    PIPELINE_CLUSTER
    PIPELINE_STATE_BUCKET
    BUCKET_PREFIX
  ).each do |var|
    env(var)
  end
end

def env(var)
  ENV.fetch(var)
end

main
