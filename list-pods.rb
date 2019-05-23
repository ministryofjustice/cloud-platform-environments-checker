#!/usr/bin/env ruby

require 'bundler/setup'
require 'openid_connect'
require 'kubeclient'
require 'pp'
require 'pry-byebug'

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

