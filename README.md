# Puppet EOS Modules

## Overview

This module provides native Puppet modules for automating Arista EOS node
configurations.  This module allows for the configuration of EOS nodes using
the Puppet agent running natively in EOS

## Requirements
* Puppet 3.6 or later
* Ruby 1.9.3 or later
* Arista EOS 4.13.7 or later
* Ruby Client for eAPI 0.1.0 or later

## Local Development

This module can be configured to run directly from source and configured to do
local development, sending the commands to the node over HTTP.  The following
instructions explain how to configure your local development environment.

This module requires one dependency that must be checked out as Git working
copy in the context of ongoing development.  

* [rbeapi][rbeapi]

The dependency is managed via the bundler Gemfile and the environment needs to
be configured ot use lcoal Git copies:

    cd /workspace
    git clone https://github.com/arista-eosplus/rbeapi
    export GEM_RBEAPI_VERSION=file:///workspace/rbeapi

Once the dependencies are installed and the environment configured, then
install all of the dependencies:

    git clone https://github.com/puppet-eos
    cd puppet-eos
    bundle install --path .bundle/gems

Once everything is installed, run the spec tests to make sure everything is
working properly:

    bundle exec rspec spec

Finally, configure the eapi.conf file for rbeapi [See rbeapi for
details][rbeap] and set the connection enviroment variable to run sanity tests
using `puppet resource`:

    export RBEAPI_CONNECTION=veos01

```
$ bundle exec puppet resource eos_vlan
eos_vlan { '1':
  ensure    => 'present',
  enable    => 'true',
  vlan_name => 'default',
}
eos_vlan { '100':
  ensure    => 'present',
  enable    => 'true',
  vlan_name => 'TEST_VLAN_100',
}
```


## License

BSD-3 (see LICENSE)




