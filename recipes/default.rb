#
# Cookbook Name:: mongodb-opsworks
# Recipe:: default
#
# Copyright 2014, Appriss, Inc.
#
# All rights reserved - Do Not Redistribute
#

node['opsworks']['instance']['layers'].each do |layer|
	Chef::Log.info("Processing layer #{layer}.")
	layer_name = node['opsworks']['layers'][layer]['name']
	if Regexp.new(node['mongodb-opsworks']['replset_layer_pattern']).match(layer_name)
		node.normal['mongodb']['shard_name'] = $1
		if node['mongodb-opsworks']['sharded']
			set_name = $1
			node.normal['mongodb']['config']['replSet'] = "rs_#{set_name}"
		else
			node.normal['mongodb']['config']['replSet'] = $1
		end
	end
end

def init_item(instance_name,instance_config)
	json = JSON.parse(node.to_json)
	json['name'] = instance_name
	instance_item = Chef::Node.json_create(json)
	instance_item.automatic['recipes'] = ['opsworks_ganglia::configure-client','ssh_users','mysql::client','agent_version',
		'opsworks_stack_state_sync','mongodb-opsworks::default','test_suite','opsworks_cleanup']
	overrides = node['mongodb-opsworks']['instance_overrides'][instance_name]
	if overrides
		Chef::Log.info("Overriding attrs for instance #{instance_name}")
		instance_item.normal_attrs = Chef::Mixin::DeepMerge.merge(instance_item.normal_attrs,overrides)
	end
	return instance_item
end

def save_item(layer,item)
	instance_root_node = node['opsworks']['layers'][layer]['instances'][item.name]
	item.automatic['hostname'] = item.name
	Chef::Log.warn("Object dump: #{item.to_json}") if node['mongodb-opsworks']['debug_objects']
	item.automatic['fqdn'] = item.name + ".localdomain"
	item.automatic['ipaddress'] = instance_root_node['private_ip']
	#Don't duplicate the current node.
	unless node['hostname'] == item.name
		Chef::Log.info("Saving Node: \"#{item.name}\"")
		item.save 
	end
end

node['opsworks']['layers'].each do |layer,config|
	layer_name = node['opsworks']['layers'][layer]['name']
	case 
	when Regexp.new(node['mongodb-opsworks']['replset_layer_pattern']).match(layer_name)
		shard_or_replset_name = $1
		node['opsworks']['layers'][layer]['instances'].each do |instance,config|
			item = init_item(instance,node['opsworks']['layers'][layer]['instances'][instance])
			item.normal['mongodb']['is_replicaset'] = true
			if node['mongodb-opsworks']['sharded']
				item.normal['mongodb']['is_shard'] = true
				item.normal['mongodb']['shard_name'] = shard_or_replset_name
				item.normal['mongodb']['config']['replSet'] = "rs_#{shard_or_replset_name}"
				item.automatic['recipes'] << 'mongodb::shard'
				item.automatic['recipes'] << 'mongodb::replicaset'
			else
				item.normal['mongodb']['config']['replSet'] = shard_or_replset_name
				item.automatic['recipes'] << 'mongodb::replicaset'
			end
			save_item(layer,item)
		end
		
	when layer_name == node['mongodb-opsworks']['configsvr_layer']
		node['opsworks']['layers'][layer]['instances'].each do |instance,config|
			item = init_item(instance,node['opsworks']['layers'][layer]['instances'][instance])
			item.normal['mongodb']['is_configserver'] = true
			item.automatic['recipes'] << 'mongodb::configserver'
			save_item(layer,item)
		end
	when layer_name == node['mongodb-opsworks']['mongos_layer']
		node['opsworks']['layers'][layer]['instances'].each do |instance,config|
			item = init_item(instance,node['opsworks']['layers'][layer]['instances'][instance])
			item.normal['mongodb']['is_mongos'] = true
			item.normal['mongodb']['config']['instance_name'] = "mongos"
			item.automatic['recipes'] << 'mongodb::mongos'
			save_item(layer,item)
		end
	end
end

#If our node is in a sharded + replicaset config, we need to prime the attributes.
if node['mongodb-opsworks']['sharded'] 
	node['opsworks']['instance']['layers'].each do |layer|
		if Regexp.new(node['mongodb-opsworks']['replset_layer_pattern']).match(node['opsworks']['layers'][layer]['name'])
			node.normal['mongodb']['is_replicaset'] = true
			node.normal['mongodb']['is_shard'] = true
		end
	end
end

#If we are a mongos, need to zap a couple of attributes to ensure that the stuff actually works.
node['opsworks']['instance']['layers'].each do |layer|
	Chef::Log.info("DEB: Layer name #{layer}")
	Chef::Log.info("DEB: Layer desc #{node['opsworks']['layers'][layer]['name']}")
	Chef::Log.info("DEB: Desired layer #{node['mongodb-opsworks']['mongos_layer']}")
	if node['opsworks']['layers'][layer]['name'] == node['mongodb-opsworks']['mongos_layer']
		Chef::Log.info("DEB: deleting the nojournal option.")
		['nojournal','rest','smallfiles'].each do |option|
			node.default['mongodb']['config'].delete(option) rescue nil
		end
	end
end 


# nodes = search(
#       :node,
#       "mongodb_cluster_name:#{node['mongodb']['cluster_name']} AND \
#        mongodb_is_replicaset:true AND \
#        mongodb_shard_name:#{node['mongodb']['shard_name']} AND \
#        chef_environment:_default"
#     )
nodes = search(
      node[:mongodb][:collection_name],
      "mongodb_cluster_name:#{node[:mongodb][:cluster_name]} AND \
       mongodb_is_shard:true AND \
       chef_environment:#{node.chef_environment}"
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
		node.normal_attrs = Chef::Mixin::DeepMerge.merge(node.normal_attrs,node_overrides)
end

Chef::Log.info("After Node Overrides: #{node.to_json}")




