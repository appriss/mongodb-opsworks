default['mongodb-opsworks']['replset_layer_pattern'] = '^mongo-replicaset-(\S+)$'
default['mongodb-opsworks']['configsvr_layer'] = 'mongo-configsvr'
default['mongodb-opsworks']['mongos_layer'] = 'mongo-mongos'
default['mongodb-opsworks']['sharded'] = false
default['mongodb-opsworks']['debug_objects'] = false
# Start with an empty node override section, this allows the user to use the stack JSON to override attributes (such as node priority) on an individual instance.
default['mongodb-opsworks']['instance_overrides'] = ""
