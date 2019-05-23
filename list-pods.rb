#!/usr/bin/env ruby

require 'bundler/setup'
require 'openid_connect'
require 'kubeclient'
require 'open-uri'
require 'json'
require 'pp'
require 'pry-byebug'

URL = 'https://api.github.com/repos/ministryofjustice/cloud-platform-environments/contents/namespaces/live-1.cloud-platform.service.justice.gov.uk'

content = open(URL).read
git_namespaces = JSON.parse(content).map {|hash| hash.fetch('name')}
pp git_namespaces
exit

config = Kubeclient::Config.read(ENV.fetch('KUBECONFIG'))
context = config.context

client = Kubeclient::Client.new(
  context.api_endpoint,
  'v1',
  ssl_options: context.ssl_options,
  auth_options: context.auth_options
)

pods = client.get_pods
namespaces = client.get_namespaces

pry

1;

