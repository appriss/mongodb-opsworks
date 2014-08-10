#
# Cookbook Name:: mongodb-opsworks
# Recipe:: default
#
# Copyright 2014, Appriss, Inc.
#
# All rights reserved - Do Not Redistribute
#

node['opsworks']['instance']['layers'].each do |layer|
	if Regexp.new(node['opsworks-mongodb']['replset_layer_pattern']).match(layer)
		node.normal['mongodb']['shard_name'] = $1
		node.normal['mongodb']['config']['replSet'] = $1
	end
end

node_overrides = node['opsworks-mongodb']['instance_overrides'][node['opsworks']['instance']['hostname']]


total = Array.new
node['mongodb'].each_attribute do |k,v|
	line = "k: #{k}, v:#{v}"
	total.push line
end

execute "Output node list" do
	command "echo #{total} >>/tmp/total.out"
end


if node_overrides
	node_overrides.each_attribute do |key, val|
		node.override['mongodb'][key] = val
	end
end