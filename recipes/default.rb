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
	layer_name = node['opsworks']['layers'][layer]['name']
	Chef::Log.info("Layer's name is #{layer_name}.")
	if Regexp.new(node['opsworks-mongodb']['replset_layer_pattern']).match(layer_name)
		Chef::Log.info("Setting Shard values to #{$1}")
		node.normal['mongodb']['shard_name'] = $1
		node.normal['mongodb']['config']['replSet'] = $1
	end
end

def init_item(instance_name,instance_config)
	#Deep copy node set
	instance_item = Marshal.load(Marshal.dump(instance_config))
	instance_item['id'] = instance_name
	overrides = node['opsworks-mongodb']['instance_overrides'][instance_name]
	if overrides
		Chef::Mixin::DeepMerge(instance_item,overrides)
	end
	return instance_item
end

def save_item(item)
	db_item = Chef::DataBagItem.new
	db_item.data_bag = "cluster_config"
	db_item.raw_data = item.to_json
	db_item.save
end

cluster_config = Chef::DataBag.new
cluster_config.name("cluster_config")
node['opsworks']['layers'].each_attribute do |layer,config|
	layer_name = layer['name']
	case 
	when Regexp.new(node['opsworks-mongodb']['replset_layer_pattern']).match(layer_name)
		shard_or_replset_name = $1
		node['opsworks']['layers'][layer]['instances'].each do |instance|
			item = init_item(instance,node['opsworks']['layers'][layer]['instances'][instance])
			item['mongodb']['is_replicaset'] = true
			if node['opsworks-mongodb']['sharded']
				item['mongodb']['is_shard'] = true
				item['mongodb']['shard_name'] = shard_or_replset_name
			else
				item['mongodb']['config']['replSet'] = shard_or_replset_name
			end
		end
		save_item(item)
	when layer_name == node['opsworks-mongodb']['configsvr_layer']
		node['opsworks']['layers'][layer]['instances'].each_attribute do |instance|
			item = init_item(instance,node['opsworks']['layers'][layer]['instances'][instance])
			item['mongodb']['is_configserver'] = true
			save_item
		end
	when layer_name == node['opsworks-mongodb']['mongos_layer']
		node['opsworks']['layers'][layer]['instances'].each_attribute do |instance|
			item = init_item(instance,node['opsworks']['layers'][layer]['instances'][instance])
			item['mongodb']['is_mongos'] = true
			item['mongodb']['config']['instance_name'] = "mongos"
		end
	end
end

Chef::Log.info('Databag: #{cluster_config}')



node_overrides = node['opsworks-mongodb']['instance_overrides'][node['opsworks']['instance']['hostname']]

if node_overrides
	node_overrides.each_attribute do |key, val|
		Chef::Mixin::DeepMerge(instance_item,overrides)
	end
end