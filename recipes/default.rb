#
# Cookbook Name:: mongodb-opsworks
# Recipe:: default
#
# Copyright 2014, Appriss, Inc.
#
# All rights reserved - Do Not Redistribute
#

node['opsworks']['instance']['layers'].each do |layer|
	Chef::Log.info("processing layer #{layer}.")
	Chef::Log.info("Layer's name is #{layer['name']}.")
	if Regexp.new(node['opsworks-mongodb']['replset_layer_pattern']).match(layer['name'])
		Chef::Log.info("Setting Shard values to #{$1}")
		node.normal['mongodb']['shard_name'] = $1
		node.normal['mongodb']['config']['replSet'] = $1
	end
end

node_overrides = node['opsworks-mongodb']['instance_overrides'][node['opsworks']['instance']['hostname']]


total = Array.new
node.each_attribute do |k,v|
	line = "k: #{k}, v:#{v}"
	total.push line
end

file "/tmp/total.out" do
	content total.to_s
end


if node_overrides
	node_overrides.each_attribute do |key, val|
		node.override['mongodb'][key] = val
	end
end