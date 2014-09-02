name             'mongodb-opsworks'
maintainer       'Donavan Pantke'
maintainer_email 'dpantke@appriss.com'
license          'Apache 2.0'
description      'Prepares an OpsWorks stack to run the chef-mongodb recipe'
long_description IO.read(File.join(File.dirname(__FILE__), 'README.md'))
version          '1.0.0'

depends 'mongodb'
