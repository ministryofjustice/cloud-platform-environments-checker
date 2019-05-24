#!/usr/bin/env ruby

require './lib/orphaned_namespace_checker'

puts CloudPlatformOrphanNamespaces.new.report
