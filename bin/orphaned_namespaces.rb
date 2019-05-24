#!/usr/bin/env ruby

require './lib/orphaned_namespace_checker'

CloudPlatformOrphanNamespaces.new.report
