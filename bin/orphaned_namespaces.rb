#!/usr/bin/env ruby

require './lib/orphaned_namespace_checker'

# Concourse will create the 'output' directory during the
# 'check-environments' pipeline task. It will do so as root,
# so this script also needs to run as root, or it will not
# be able to write to a file in that directory.
# Concourse seems to have a baked-in assumption that it, and
# any containers it runs, will run as root.
File.open('./output/check.txt', 'w') do |f|
  f.puts CloudPlatformOrphanNamespaces.new.report
end
