.. _troubleshooting:

Troubleshooting
===============

.. contents:: :local:

Server: Error: ... cannot load such file -- rbeapi/client
---------------------------------------------------------

If you see the following error on the master::

  Server: Error: Could not autoload puppet/provider/eos_vlan/default: cannot load such file -- rbeapi/client

Install the rbeapi rubygem on the server::

  sudo gem install rbeapi

Server: Error: ... provider 'eos': undefined method `api' for nil:NilClass`
---------------------------------------------------------------------------

If you try to apply a class or nmanifest and receive the following error::

  Server: Error: Could not prefetch eos_vlan provider 'eos': undefined method `api' for nil:NilClass`

The eos provider requires a connection to an EOS device and cannot be applied on an OS that does not support Arista eAPI except in development mode.

Either ensure this manifest/class only gets applied to EOS devices or redirect eAPI communications on this system to a real or virtual EOS device::

  export RBEAPI_CONF=/path/to/my/.eapi.conf
  export RBEAPI_CONNECTION=<connection-name>

