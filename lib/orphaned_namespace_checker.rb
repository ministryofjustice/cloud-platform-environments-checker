require 'bundler/setup'
require 'openid_connect'
require 'kubeclient'
require 'open-uri'
require 'aws-sdk-s3'
require 'json'

require './lib/orphaned_namespace_checker/cloud_platform_orphaned_namespaces'
require './lib/orphaned_namespace_checker/github_namespace_lister'
require './lib/orphaned_namespace_checker/tf_state_namespace_lister'
require './lib/orphaned_namespace_checker/cluster_namespace_lister'

require 'pp'
