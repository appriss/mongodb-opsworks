mongodb-opsworks Cookbook
=========================


mongodb-opsworks is a cookbook that is designed to take the mongodb cookbook and allow it to run successfully in AWS OpsWorks. The mongodb cookbook relies heavily on having a Chef server in place, which we know OpsWorks does not provide. However, now that OpsWorks uses chef-zero, we can successfully emulate the Chef server environment.

Attributes
----------

### mongodb-opsworks::default

* `node['mongodb-opsworks']['replset_layer_pattern']` - This pattern identifies a layer as a replicaset/shard. The match grouped into parantheses will be used as the shard name. **Default:** `^mongo-replicaset-(\S+)$`
* `node['mongodb-opsworks']['configsvr_layer']` - The name of the layer that holds the Config Servers. **Default:** `mongo-configsvr`
* `node['mongodb-opsworks']['mongos_layer']` = The name of the layer that holds the mongos frontends. **Default:** `mongo-mongos`
* `node['mongodb-opsworks']['sharded']` = Set this to `true` if your Mongo cluster will be sharded. **Default:** `false`
* `node['mongodb-opsworks']['debug_objects']` = Set this to `true` if you want the node objects that will be emulated to be dumped to the log file. Used for additional debugging (since these objects are big, this is disabled by default to spare your log file.). **Default:** `false`
* `node['mongodb-opsworks']['instance_overrides']` - Special: Used for overriding individual node attributes.

Usage
-----

### Using mongodb-opsworks to build a simple replicaset

1. Build a new OpsWorks stack.
  * Ensure that the Chef version is 11.10 or higher. Chef 11.10 is required for chef-zero support.
  * Ensure that mongodb and mongodb-opsworks are in your custom cookbook archive, or in your Berksfile.
  * Set the cluster name in the custom stack JSON as per normal [mongodb setup](https://github.com/edelight/chef-mongodb).
2. Create a new replicaset layer, mongo-replicaset-sampleset.
  * In this example, the replicaset name will be called "sampleset".
3. Set the following custom recipes in the layer:
  * In Setup stage: `mongodb::mongodb_org_repo`
  * In Configure stage: `mongodb-opsworks::default` `mongodb::replicaset`
    * Make _sure_ that `mongodb-opsworks::default` is before `mongodb::replicaset`!
4. Add instances and start it up!

### Using mongodb-opsworks to build a sharded cluster

#### Build the stack

1. Build the stack for the sharded cluster.
2. Ensure that the Chef version is 11.10 or higher. Chef 11.10 is required for chef-zero support.
3. Ensure that mongodb and mongodb-opsworks are in your custom cookbook archive, or in your Berksfile.
4. Set the cluster name in the custom stack JSON as per normal [mongodb setup](https://github.com/edelight/chef-mongodb).
5. Set the `['mongodb-opsworks']['sharded']` node to `true`
6. Set the `['mongodb']['sharded_collections']` as per normal [mongodb setup](https://github.com/edelight/chef-mongodb).

At the end, your custom stack JSON should look something like this:
```json
{ "mongodb": {
    "cluster_name" : "samplecluster",
    "sharded_collections": {
       "sampledb.items": "name"
    }
  },  
  "mongodb-opsworks" : {
    "sharded" : true,
  } 
}
```

#### Build the replicaset layers.

For each sharded replicaset you need, do the following:

1. Create a new replicaset layer, mongo-replicaset-replicaset*n*. 
  * Remember, your shard name will be based on name past "mongo-replicaset-".
2. Set the custom recipes in the layer:
  * In Setup stage: `mongodb::mongodb_org_repo`
  * In Configure stage: `mongodb-opsworks::default` `mongodb::shard` `mongodb::replicaset`
    * Order matters!
3. Add instances and startup.

Repeat for each shard that you want.

#### Build the config server layer.

1. Create a new layer called "mongo-configsvr".
2. Set the custom recipes in the layer:
  * In Setup stage: `mongodb::mongodb_org_repo`
  * In Configure stage: `mongodb-opsworks::default` `mongodb::configserver`
    * Again, order matters!
3. Add instances (remember, 1 or 3!) and start.

#### Build the mongos layer.

1. Create a new layer called "mongo-mongos".
2. Set the custom recipes in the layer:
  * In Setup stage: `mongodb::mongodb_org_repo`
  * In Configure stage: `mongodb-opsworks::default` `mongodb::mongos`
    * You should know by now...
3. Add instance and startup. 

Your cluster should now be operational!

### Using the instance_overrides attribute.

There is a special attribute that you can use to customize individual node that you nromally couldn't use in OpsWorks to set settings on an instance-by-instance basis. The best way to show how to use this attribute is by example. Let's say that in our simple setup, we wanted to run the replicaset real cheap and so only wanted 2 real replicaset members, but we still need an arbiter to break election ties. To do that, we would build the following custom stack JSON:

```json
{ "mongodb": {
    "cluster_name" : "samplecluster"
  },  
  "mongodb-opsworks" : {
    "instance_overrides" : {
      "sampleset3" : {
        "mongodb" : {
          "replica_arbiter_only" : true
        }
      }
    }
  } 
}
```

This sets the instance sampleset3 so that it is only an arbiter. You can use method to override any attribute on a specific instance, and would be the most useful for tuning in a sharded cluster where you want the tune of one shard to be different than another layer.

Contributing
------------

Pull requests are gladly accepted! Use the following process to get changes in. 

1. Fork the repository on Github
2. Create a named feature branch (like `add_component_x`)
3. Make the change
4. If you think you can make self-contained tests, do so.
5. Make sure to test your change using OpsWorks
6. Submit a Pull Request using Github

License and Authors
-------------------

License: Apache 2.0

Authors: Donavan Pantke (dpantke (at) appriss.com)
