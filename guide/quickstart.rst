Quick Start
===========

.. contents:: :local:

Bootstrapping a switch
----------------------

There are a number of ways to bootstrap the necessary components on to a switch, and automatically load the minimal, initial configuration.  We strongly suggest `ZTP Server`_ to automate the steps from initial power-on to contacting the Puppet master.

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

From EOS 4.14.5 and up, it is recommended configure EOS to use unix-sockets for eAPI:

.. code-block:: console

  management api http-commands
     no protocol https
     protocol unix-socket
     no shutdown
  !

In EOS versions below 4.14.5, it is recommended to configure EOS to use https for eAPI.  This also requires the creation of a ``flash:eapi.conf`` in which to store user credentials to login to eAPI:

.. code-block:: console

  username eapi privilege 15 secret icanttellyou
  !
  management api http-commands
     no shutdown
  !

If you configured eAPI (``management api http-commands``) for anything other than
``unix-socket``, then an ``flash:eapi.conf`` is also required.  Ensure that the connection is ``localhost`` and enter the transport, port, username, and password required for the puppet module to connect to eAPI.  See more about configuring `eapi.conf`_.

Example ``flash:eapi.conf``:

.. code-block:: console

  [connection:localhost]
  transport: https
  port: 1234
  username: eapi
  password: password
  enablepwd: itsasecret

Install the puppet agent from `PuppetLabs`_ (`previous releases`_):

Puppet 3.x::

  Arista#copy http://myserver/puppet-enterprise-3.8.2-eos-4-i386.swix extensions:
  Arista#extension puppet-enterprise-3.8.2-eos-4-i386.swix

Puppet All-In-One agent (2015.x)::

  Arista#copy http://myserver/puppet-agent-1.3.5-1.eos4.i386.swix extensions:
  Arista#extension puppet-agent-1.3.5-1.eos4.i386.swix

Additionally, Puppet 2015.x and up should be configured to run as root in the puppet.conf file::

  Arista#bash sudo /opt/puppetlabs/bin/puppet config set user root

Install the `rbeapi extension`_:

.. note::
  The rbeapi rubygem and its requirements MAY be installed using Puppet instead of by SWIX on the CLI.  Care should be taken to ensure that the rubygems are installed in a manner that will be restored upon switch reload.  This is automatic with the SWIX package but, otherwise, will be re-initiated by the next Puppet agent run following a reload.

Puppet 3.x::

  Arista#copy http://myserver/rbeapi-puppet3-0.5.1.swix extensions:
  Arista#extension rbeapi-puppet3-0.5.1.swix

Puppet All-In-One agent (2015.x)::

  Arista#copy http://myserver/rbeapi-puppet-aio-0.5.1.swix extensions:
  Arista#extension rbeapi-puppet-aio-0.5.1.swix

Save the installed extensions::

  Arista#copy installed-extensions boot-extensions

EOS Command Aliases
^^^^^^^^^^^^^^^^^^^

If working with puppet manually from the CLI, it may be convenient to add CLI aliases to your systems.  Some examples follow.

.. code-block:: console

  alias pa bash sudo puppet agent --environment demo --waitforcert 30 --onetime true
  alias puppet bash sudo /opt/puppetlabs/bin/puppet
  alias puppet2015 bash sudo /opt/puppetlabs/bin/puppet
  alias puppet3 bash sudo puppet
  alias puppet-vrf bash sudo ip netns exec <MGMT-VRF> /opt/puppetlabs/bin/puppet

With the above aliases, repetitive typing can be reduced to, for example:

.. code-block:: console

  Arista#pa --test
  Arista#puppet resource eos_vlan
  Arista#puppet describe eos_vlan

Configuring the Puppet Master
-----------------------------

Follow the standard instructions for `installing either a Puppet Enterprise or Puppet Open-source master <https://docs.puppetlabs.com/>`_ server and setup your environment(s). (Standalone Puppet, also known as headless or masterless puppet, is covered in a separate section.) As the paths to various items and specifics may vary from system to system, you may need to make minor adjustments to the ommands, below, to conform to your particular system.  Use ``puppet config print`` to locate the correct paths.

On the master, install the `Forge: eos`_ module (Source: `GitHub: puppet-eos`_). This module is self-contained including the types and providers specific to EOS.

.. note::
  There is also a `netdev_stdlib <https://forge.puppetlabs.com/netdevops/netdev_stdlib>`_ module in which PuppetLabs maintains a cross-platform set of Types in netdev_stdlib and the EOS-specific providers are in `netdev_stdlib_eos <https://forge.puppetlabs.com/aristanetworks/netdev_stdlib_eos>`_.

It is NOT necessary to install the rbeapi rubygem on the server, beginning with module version 1.3.0.

Add the aristanetworks-eos module to your server's modulepath:

Puppet installer::

  $ sudo puppet module install aristanetworks-eos [--environment production ] [--modulepath $basemodulepath ]

Install from source::

  $ sudo git clone https://github.com/arista-eosplus/puppet-eos.git <environment>/modules/eos
  $ cd <environment>/modules/eos/
  $ sudo git checkout <version or branch>

Link using Git submodules::

  $ cd $moduledir
  $ git submodule add https://github.com/arista-eosplus/puppet-eos.git eos
  $ git submodule status
  $ git submodule init
  $ git status

Verifying the agent on EOS
--------------------------

Run the puppet agent on EOS.  This performs several key tasks:

* Generate a keypair and request a certificate from the master
* Retrieve the CA and Master certificates
* Run pluginsync (enabled by default) to download the types and providers
* Run the defined manifests, if configured

.. note::
  Prior to the first full agent run, there may not be a link in the default PATH requiring you to fully qualify the path to puppet. Starting with Puppet 2015.x, the puppet binary is installed in /opt/puppetlabs/bin/.  After the first puppet agent run, a link will be created in /usr/bin/ which is in the default PATH.

.. code-block:: console

  Arista#bash sudo /opt/puppetlabs/bin/puppet agent [--environment <env_name>] --test --onetime --no-daemonize --waitforcert 30

On the Master, sign the node's certificate request:

.. code-block:: console

  $sudo puppet cert list
  $sudo puppet cert sign <certname>

If you did not include ``waitforcert``, above, then re-run the puppet agent command to install the signed certificate from the server:

.. code-block:: console

  Arista#bash sudo puppet agent [--environment <env_name>] --test --onetime --waitforcert 30

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
.. _`Forge: eos`: https://forge.puppetlabs.com/aristanetworks/eos
.. _`Github: puppet-eos`: https://github.com/arista-eosplus/puppet-eos
.. _`ZTP Server`: https://github.com/arista-eosplus/ztpserver
.. _`PuppetLabs`: https://puppetlabs.com/download-puppet-enterprise-all#eos
.. _`previous releases`: https://puppetlabs.com/misc/pe-files/previous-releases
.. _`rbeapi extension`: https://github.com/arista-eosplus/rbeapi/releases

