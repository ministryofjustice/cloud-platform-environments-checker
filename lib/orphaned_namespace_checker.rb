require 'bundler/setup'
require 'openid_connect'
require 'kubeclient'
require 'open-uri'
require 'aws-sdk-s3'
require 'json'

require "#{File.dirname(__FILE__)}/orphaned_namespace_checker/cloud_platform_orphaned_namespaces"
require "#{File.dirname(__FILE__)}/orphaned_namespace_checker/kubeconfig"
require "#{File.dirname(__FILE__)}/orphaned_namespace_checker/github_namespace_lister"
require "#{File.dirname(__FILE__)}/orphaned_namespace_checker/tf_state_namespace_lister"
require "#{File.dirname(__FILE__)}/orphaned_namespace_checker/cluster_namespace_lister"
