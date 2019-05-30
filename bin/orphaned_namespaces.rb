#!/usr/bin/env ruby

require "#{File.dirname(__FILE__)}/../lib/orphaned_namespace_checker"

def env(var)
  ENV.fetch(var)
end

# How to fetch the kubeconfig file, so we can talk to the cluster
kubeconfig = {
  local_target:          env('KUBECONFIG'),
  region:                env('KUBECONFIG_AWS_REGION'),
  bucket:                env('KUBECONFIG_S3_BUCKET'),
  key:                   env('KUBECONFIG_S3_KEY'),
  aws_access_key_id:     env('KUBECONFIG_AWS_ACCESS_KEY_ID'),
  aws_secret_access_key: env('KUBECONFIG_AWS_SECRET_ACCESS_KEY'),
}

# How to retrieve the terraform state, so we can query it to look
# for AWS resource definitions
tfstate = {
  s3client: Aws::S3::Client.new(
    region: env('TFSTATE_AWS_REGION'),
    credentials: Aws::Credentials.new(env('TFSTATE_AWS_ACCESS_KEY_ID'), env('TFSTATE_AWS_SECRET_ACCESS_KEY'))
  ),
  bucket: env('PIPELINE_STATE_BUCKET'),
  bucket_prefix: env('BUCKET_PREFIX')
}

# Concourse will create the 'output' directory during the
# 'check-environments' pipeline task. It will do so as root,
# so this script also needs to run as root, or it will not
# be able to write to a file in that directory.
# Concourse seems to have a baked-in assumption that it, and
# any containers it runs, will run as root.
File.open('./output/check.txt', 'w') do |f|
  f.puts CloudPlatformOrphanNamespaces.new(
    kubeconfig: kubeconfig,
    tfstate:    tfstate
  ).report
end
