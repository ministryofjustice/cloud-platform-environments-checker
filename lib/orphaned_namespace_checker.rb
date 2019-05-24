require 'bundler/setup'
require 'openid_connect'
require 'kubeclient'
require 'open-uri'
require 'aws-sdk-s3'
require 'json'

require './lib/cloud_platform_orphaned_namespaces'
require './lib/github_namespace_lister'
require './lib/tf_state_namespace_lister'

require 'pp'
