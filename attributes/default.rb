default['opsworks-mongodb']['replset_layer_pattern'] = '^mongo-replset-(\S+)$'
default['opsworks-mongodb']['configsvr_layer'] = 'mongo-configsvr'
default['opsworks-mongodb']['mongos_layer'] = 'mongo-mongos'
# Start with an empty node override section, this allows the user to use the stack JSON to override attributes (such as node priority) on an individual instance.
default['opsworks-mongodb']['instance_overrides'] = ""
