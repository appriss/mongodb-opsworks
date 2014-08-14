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
	json = JSON.parse(node.to_json)
	json['name'] = instance_name
	instance_item = Chef::Node.json_create(json)
	Chef::Log.warn("Object type is #{instance_item.class}")
	overrides = node['opsworks-mongodb']['instance_overrides'][instance_name]
	if overrides
		Chef::Mixin::DeepMerge(instance_item,overrides)
	end
	Chef::Log.info("Item is #{instance_item}")
	Chef::Log.info("JSON is #{instance_item.to_json}")
	return instance_item
end

def save_item(layer,item)
	Chef::Log.info("Layer name is #{layer}")
	Chef::Log.info("Instance name is #{item.name}")
	instance_root_node = node['opsworks']['layers'][layer]['instances'][item.name]
	item.automatic['hostname'] = item.name
	Chef::Log.info("Instance hostname is #{item['hostname']}")
	Chef::Log.warn("Object dump: #{item.to_json}")
	item.automatic['fqdn'] = item.name + ".localdomain"
	item.automatic['ipaddress'] = instance_root_node['private_ip']
	#Don't duplicate the current node.
	Chef::Log.warn("Current node Name: \"#{node['hostname']}\"")
	Chef::Log.warn("Item node Name: \"#{item.name}\"")
	item.save unless node['hostname'] == item.name
	
end

node['opsworks']['layers'].each do |layer,config|
	layer_name = node['opsworks']['layers'][layer]['name']
	case 
	when Regexp.new(node['opsworks-mongodb']['replset_layer_pattern']).match(layer_name)
		shard_or_replset_name = $1
		node['opsworks']['layers'][layer]['instances'].each do |instance,config|
			item = init_item(instance,node['opsworks']['layers'][layer]['instances'][instance])
			item.normal['mongodb']['is_replicaset'] = true
			if node['opsworks-mongodb']['sharded']
				item.normal['mongodb']['is_shard'] = true
				item.normal['mongodb']['shard_name'] = shard_or_replset_name
			else
				item.normal['mongodb']['config']['replSet'] = shard_or_replset_name
			end
			save_item(layer,item)
		end
		
	when layer_name == node['opsworks-mongodb']['configsvr_layer']
		node['opsworks']['layers'][layer]['instances'].each_attribute do |instance,config|
			item = init_item(instance,node['opsworks']['layers'][layer]['instances'][instance])
			item.normal['mongodb']['is_configserver'] = true
			save_item(layer,item)
		end
	when layer_name == node['opsworks-mongodb']['mongos_layer']
		node['opsworks']['layers'][layer]['instances'].each_attribute do |instance,config|
			item = init_item(instance,node['opsworks']['layers'][layer]['instances'][instance])
			item.normal['mongodb']['is_mongos'] = true
			item.normal['mongodb']['config']['instance_name'] = "mongos"
			save_item(layer,item)
		end
	end
end

nodes = search(
      :node,
      "mongodb_cluster_name:#{node['mongodb']['cluster_name']} AND \
       mongodb_is_replicaset:true AND \
       mongodb_shard_name:#{node['mongodb']['shard_name']} AND \
       chef_environment:_default"
    )

nodes.each_index do |n|
Chef::Log.info("Node is #{n}")
Chef::Log.info("Node attr JSON is #{nodes[n].attributes.to_hash.to_json}")
end

Chef::Log.warn("We should have logged stuff before this")


allnodes = search(:node, "*:*")
Chef::Log.info("Big node list is #{allnodes}")

Chef::Log.info("Attributes available to be overridden: #{node['mongodb-opsworks']['instance_overrides']}")
Chef::Log.info("Node to be overridden: #{node['opsworks']['instance']['hostname']}")
node_overrides = node['mongodb-opsworks']['instance_overrides'][node['opsworks']['instance']['hostname']]
Chef::Log.info("Decision point!: #{node_overrides}")

if node_overrides
		Chef::Log.info("Merging node bases!")
		Chef::Mixin::DeepMerge(node,node_overrides)
end

Chef::Log.info("After Node Overrides: #{node.to_json}")




