# Puppet EOS Module

#### Table of Contents

1. [Overview](#overview)
2. [Module Description](#module-description)
3. [Setup](#setup)
    * [What Puppet EOS affects](#what-puppet-eos-affects)
    * [Setup requirements](#setup-requirements)
    * [Beginning with NetDev EOS Providers](#beginning-eos)
4. [Usage - Configuration options and additional functionality](#usage)
5. [Reference - An under-the-hood peek at what the module is doing and how](#reference)
6. [Limitations - OS compatibility, etc.](#limitations)
7. [Development - Guide for getting started developing the module](#development)
8. [Contributing - Contributing to this project](#contributing)
9. [License](#license)
10. [Release Notes](#release-notes)


## Build status

[![Start Build Status](https://revproxy.arista.com/eosplus/ci/buildStatus/icon?job=puppet-eos_start&style=plastic)](https://revproxy.arista.com/eosplus/ci/job/puppet-eos_start)
System tests [![Spec Build Status](https://revproxy.arista.com/eosplus/ci/buildStatus/icon?job=puppet-eos_spec&style=plastic)](https://revproxy.arista.com/eosplus/ci/job/puppet-eos_spec)

## Overview

The Arista EOS module for Puppet provides a set of types and providers for
automating Arista EOS node configuraitons.  The module allows for configuration
of EOS nodes using the Puppet agent running native in EOS.

The Puppet EOS modules are freely provided to the open source community for
automating Arista EOS node configurations using Puppet.  Support for the
modules is provided on a best effort basis by the Arista EOS+ community.
Please file any bugs, questions or enhancement requests using [Github
Issues](http://github.com/arista-eosplus/puppet-eos/issues)

## Module Description

This module provides network abstractions for configuring network services on
Arista EOS nodes.  The module provides a set of types and providers to serve as
building blocks for automating the configuration of Arista EOS nodes.  This
module extends Puppet's capability to configure network devices including node
system services, access services and trunk side services of EOS nodes running
EOS 4.13 or later with the Puppet agent installed.  The Puppet agent running on
the node will use pluginsync to download the types and providers from the Puppet
master and uses the Ruby Client for eAPI (rbeapi) to interface with the nodes
configuration.

## Setup

### What Puppet EOS affects

The types and providers in this module provide native abstractions for
configuring Arista EOS nodes.

### Setup Requirements

This module requires pluginsync in order to synchronize the types and providers
to the node.  This module also requires the [Ruby Client for eAPI](rbeapi) to
be installed on the master and nodes.

### Beginning with eos

 1. Install the module on the Puppet master
 2. Install the rbeapi gem on the Puppet master [See Ruby Client for eAPI](rbeapi)
 3. Install the rbeapi gem on the switch [See Ruby Client for eAPI](rbeapi)
 4. Run the puppet agent on the switch to synchronize the types and providers
 5. List the types by running `bash sudo puppet resource --types | grep eos`
    from the EOS CLI enable mode
 6. Verify the providrs by running `bash sudo puppet resource <resource>` from 
    the EOS CLI enable mode

```
Arista$ bash sudo puppet resource eos_vlan
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

## Usage

See the [Documentation](http://puppet-eos.readthedocs.org/en/master/)

## Reference

See the [Type reference](http://puppet-eos.readthedocs.org/en/master/types.html) in the documentation

## Limitations
* Puppet 3.6 or later
* Ruby 1.9.3 or later
* [Arista EOS 4.13.7M or later](arista)
* [Ruby Client for eAPI 0.3.0 or later](rbeapi)

## Development

This module can be configured to run directly from source and configured to do
local development, sending the commands to the node over HTTP.  The following
instructions explain how to configure your local development environment.

This module requires one dependency that must be checked out as a Git working
copy in the context of ongoing development in addition to running Puppet from
source.

 * [rbeapi][rbeapi]

The dependency is managed via the bundler Gemfile and the environment needs to
be configured to use local Git copies:

    cd /workspace
    git clone https://github.com/arista-eosplus/rbeapi
    export GEM_RBEAPI_VERSION=file:///workspace/rbeapi

Once the dependencies are installed and the environment configured, then
install all of the dependencies:

    git clone https://github.com/arista-eosplus/puppet-eos
    cd puppet-eos
    bundle install --path .bundle/gems

Once everything is installed, run the spec tests to make sure everything is
working properly:

    bundle exec rspec spec

Finally, configure the eapi.conf file for rbeapi [See rbeapi for
details][rbeapi] and set the connection enviroment variable to run sanity tests
using `puppet resource`:

    export RBEAPI_CONNECTION=veos01

## Contributing

Contributions to this project are gladly welcomed in the form of issues (bugs,
questions, enhancement proposals) and pull requests.  All pull requests must be
accompanied by spec unit tests and up-to-date doc-strings, otherwise the pull
request will be rejected.

## License
Copyright (c) 2014-2015, Arista Networks EOS+
All rights reserved.

Redistribution and use in source and binary forms, with or without
modification, are permitted provided that the following conditions are met:

* Redistributions of source code must retain the above copyright notice, this
  list of conditions and the following disclaimer.

* Redistributions in binary form must reproduce the above copyright notice,
  this list of conditions and the following disclaimer in the documentation
  and/or other materials provided with the distribution.

* Neither the name of Arista Networks nor the names of its
  contributors may be used to endorse or promote products derived from
  this software without specific prior written permission.

THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS"
AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE
IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE
DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT HOLDER OR CONTRIBUTORS BE LIABLE
FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL
DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR
SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER
CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY,
OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE
OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.

## Release Notes

See the [Release Notes](http://puppet-eos.readthedocs.org/en/master/release-notes.html)
in the official documentation.


[rbeapi]: https://github.com/arista-eosplus/rbeapi
[arista]: http://www.arista.com


