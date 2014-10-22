# Puppet EOS Modules

## Overview

This repository contains the Arista developed modules for automating EOS nodes using Puppet.  The modules in this repository are freely developed and distributed by the Arista EOS+ community.

## eAPI Configure

Early releases require eAPI to be configured.  eAPI configuration should be store in /mnt/flash/eapi.conf.   This is only temporary and a final solution will be developed prior to full release.

The eapi.conf file is a stand YAML file with the following configuration options:

```
---
:username: <eapi username>
:password: <eapi password>
:use_ssl: [true, false]
:port: <eapi port>
:hostname: <hostname> # should use default of localhost
```


## Requirements

* Arista EOS 4.13 or later
* EOS Command API enabled

## License

BSD-3 (see LICENSE)

## Author Information

Arista EOS+ (eosplus-dev@arista.com)



