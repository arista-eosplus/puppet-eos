Quick Start
===========

.. contents:: :local:

Bootstrapping a switch
----------------------

There are a number of ways to bootstrap the necessary components on to a switch, and automatically load the minimal, initial configuration.  We strongly suggest _`ZTP Server` to automate the steps from initial power-on to contacting the Puppet master.

Sample minimal configuration on a switch includes basic IP connectivity, hostname and domain-name which are used to generate the switch's SSL certificate, a name-server or host entry for "puppet", the default master name unless otherwise specified, and enabling eAPI (management api http-commands):

.. code-block:: console

  !
  hostname my-switch
  ip domain-name example.com
  !
  ip name-server vrf default 8.8.8.8
  ! OR
  ip host puppet 192.2.2.5
  !
  interface Management1
     ip address 192.2.2.101/24
     no shutdown
  !
  ip route 0.0.0.0/0 192.2.2.1
  !

  ! If EOS version is 4.14.5 or higher, use unix-sockets
  !
  management api http-commands
     no protocol https
     protocol unix-socket
     no shutdown
  !

  ! If EOS version is below 4.14.5
  username eapi privilege 15 secret icanttellyou
  !
  management api http-commands
     no shutdown
  !

If you configured eAPI (``management api http-commands``) for anything other than
``unix-socket``, then ``flash:eapi.conf`` is also required.  Ensure that the connection is ``localhost`` and enter the transport, port, username, and password required for the puppet module to connect to eAPI.  See more about configuring `eapi.conf`_.

Example ``flash:eapi.conf``:

.. code-block:: console

  [connection:localhost]
  transport: https
  port: 1234
  username: eapi
  password: password
  enablepwd: itsasecret

Install the puppet agent from `PuppetLabs`_::

  Arista#copy http://myserver/puppet-enterprise-3.7.2-eos-4-i386.swix extensions:
  Arista#extension puppet-enterprise-3.7.2-eos-4-i386.swix

Install the rbeapi extension::

  Arista#copy http://myserver/rbeapi-0.1.0.swix extensions:
  Arista#extension rbeapi-0.1.0.swix

Save the installed extensions::

  Arista#copy installed-extensions boot-extensions

EOS Command Aliases
^^^^^^^^^^^^^^^^^^^

If working with puppet manually from the CLI, it may be convenient to add the following aliases to your systems

.. code-block:: console

  alias pa bash sudo puppet agent --environment demo --waitforcert 30 --onetime true
  alias puppet bash sudo puppet

With the above aliases, repetitive typing can be reduced to, for example:

.. code-block:: console

  Arista#pa --test
  Arista#puppet resource eos_vlan
  Arista#puppet describe eos_vlan

Configuring the Puppet Master
-----------------------------

Follow the standard instructions for installing either a Puppet Enterprise or Puppet Open-source master server and setup your environment(s). As the paths to various items and specifics may vary from system to system, you may need to make minor adjustments to the ommands, below, to conform to your particular system.  Use ``puppet config print`` to locate the correct paths.

On the master, install the `Forge: puppet-eos`_ module (Source: `GitHub: puppet-eos`_). This module is self-contained including the types and providers specific to EOS.

.. note::
  There is also a `netdev_stdlib <https://forge.puppetlabs.com/netdevops/netdev_stdlib>`_ module in which PuppetLabs maintains a cross-platform set of Types in netdev_stdlib and the EOS-specific providers are in `netdev_stdlib_eos <https://forge.puppetlabs.com/aristanetworks/netdev_stdlib_eos>`_.

Add the puppet-eos module to your server's modulepath:

Puppet installer::

  $ puppet module install puppet-eos [--environment production ] [--modulepath $basemodulepath ]

Install from source::

  $ git clone https://github.com/arista-eosplus/puppet-eos.git modulepath/eos
  $ git checkout <version or branch>

Link using Git submodules::

  $ cd $moduledir
  $ git submodule add https://github.com/arista-eosplus/puppet-eos.git eos
  $ git submodule status
  $ git submodule init
  $ git status

Ensure plugins are available on the master
^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^

After adding new modules containing libraries to the server, these must be synced into the libdir to be shared with agents:

.. code-block:: console

  $ puppet plugin download

Verifying the agent on EOS
--------------------------

Run the puppet agent on EOS.  This performs several key tasks:
* Generate a keypair and request a certificate from the master
* Retrieve the CA and Master certificates
* Run pluginsync (enabled by default) to download the types and providers
* Run the defined manifests, if configured

.. code-block:: console

  Arista#bash sudo puppet agent --test --onetime true --waitforcert 30

On the Master, sign the node's certificate request:

.. code-block:: console

  $puppet cert list
  $puppet cert sign <certname>

If you did not include ``waitforcert``, above, then re-run the puppet agent command to install the signed certificate from the server:

.. code-block:: console

  Arista#bash sudo puppet agent --test --onetime true --waitforcert 30

Verify that the ``eos_*`` types are available on the switch:

.. code-block:: console

  Arista#bash sudo puppet resource --types [| grep eos]

View the current state of a type:

.. code-block:: console

  Arista#bash sudo puppet resource eos_vlan
  eos_vlan { '1':
    ensure    => 'present',
    enable    => 'true',
    vlan_name => 'default',
  }

View the description for a type:

.. code-block:: console

  Arista#bash sudo puppet describe eos_vlan

If the steps, above, were not successful, proceed to the :ref:`troubleshooting` chapter.

.. target-notes::

.. _`eapi.conf`: https://github.com/arista-eosplus/rbeapi#example-eapiconf-file
.. _`Forge: puppet-eos`: https://forge.puppetlabs.com/aristanetworks/puppet-eos
.. _`Github: puppet-eos`: https://github.com/arista-eosplus/puppet-eos
.. _`ZTP Server`: https://github.com/arista-eosplus/ztpserver
.. _`PuppetLabs`: https://puppetlabs.com/download-puppet-enterprise-all#eos

