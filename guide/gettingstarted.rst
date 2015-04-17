Getting Started
===============

.. contents:: :local:

Configuring the Puppet Master
-----------------------------

Follow the standard practices for installing either Puppet Enterprise or Puppet Open-source master servers and your environment(s). As the paths to various items and specifics may vary from system to system, you might need to make minor adjustments to the instructions, below, to conform to your particular system.  The command ``puppet confing print`` can assist you in locating the right directories.

On the master, install the `Forge: puppet-eos`_ module (Source: `GitHub: puppet-eos`_). This module is self-contained including the types and providers specific to EOS.  There is also a `netdev_stdlib <https://forge.puppetlabs.com/netdevops/netdev_stdlib>`_ module in which PuppetLabs maintains a common set of Types in netdev_stdlib and the EOS providers are in `netdev_stdlib_eos <https://forge.puppetlabs.com/aristanetworks/netdev_stdlib_eos>`_.

Add the puppet-eos module to your server's modulepath:

Puppet installer::

  $ puppet module install puppet-eos [--environment production ] [--modulepath $basemodulepath ]

Install from source::

  $ git clone https://github.com/arista-eosplus/puppet-eos.git modulepath/eos
  $ git checkout <version or branch>

Link using Git submodules::

  $ git submodule add https://github.com/arista-eosplus/puppet-eos.git modulepath/eos

Bootstrapping EOS switches
--------------------------

There are a number of ways to bootstrap the necessary components on to a switch, and automatically load the minimal, initial configuration.  We strongly suggest _`ZTP Server` to automate the steps from initial power-on to contacting the Puppet master.

Sample minimal configuration on a switch includes basic IP connectivity, hostname and domain-name which are used to generate the switch's SSL certificate, a name-server or host entry for "puppet", the default master name unless otherwise specified, and enabling eAPI (management api http-commands):

.. code-block:: console

  !
  hostname my-switch
  ip name-server vrf default 8.8.8.8
  ip domain-name example.com
  ip host puppet 192.2.2.5
  !
  interface Management1
     ip address 192.2.2.101/24
     no shutdown
  !
  ip route 0.0.0.0/0 192.2.2.1
  !

  If EOS version is 4.14.5 or later
  !
  management api http-commands
     no protocol https
     protocol unix-socket
     no shutdown
  !

  If EOS version is below 4.14.5
  username eapi privilege 15 secret icanttellyou
  !
  management api http-commands
     no shutdown
  !

Install the puppet agent from `PuppetLabs`_::

  Arista#copy http://myserver/puppet-enterprise-3.7.2-eos-4-i386.swix extensions:
  Arista#extension puppet-enterprise-3.7.2-eos-4-i386.swix
  Arista#copy installed-extensions boot-extensions

Install the rbeapi extension::

  Arista#copy http://myserver/rbeapi-0.1.0.swix extensions:
  Arista#extension rbeapi-0.1.0.swix
  Arista#copy installed-extensions boot-extensions

Additional Puppet Master configuration
--------------------------------------

Configuring rbeapi
^^^^^^^^^^^^^^^^^^

Rbeapi, in many cases, requires a configuration file describing its connection method and credentials to eAPI on the switch. Available transports include https, http, http-local, and unix socket (EOS 4.14.5).  Unix socket is recommended if available in the running version of EOS due to ease of configuration and security posture.  
The /mnt/flash/eapi.conf file (also flash:eapi.conf) can be installed at bootstrap time or by puppet afterward. To do so with puppet, modify the sample files, below, to meet your needs.

Create the module skeleton on the Puppet master::

  cd <modulepath>
  puppet module generate <username-modulename>
  mkdir <username-modulename>/templates/

Create an eapi.conf template in <modulepath>/<username-modulename>/templates/eapi.conf.erb

.. code-block:: erb

  <%# rbeapi/templates/eapi.conf.erb %>
  # Managed by Class['rbeapi']
  [connection:localhost]
  <% if @host -%>
  host: <%= @host %>
  <% end -%>
  <% if @_transport != "http" -%>
  transport: <%= @_transport %>
  <% end -%>
  <% if @_username != "admin" -%>
  username: <%= @_username %>
  <% end -%>
  <% if @_password != "" -%>
  password: <%= @_password %>
  <% end -%>
  <% if @port -%>
  port: <%= @port %>
  <% end -%>

Create a class that can be applied to nodes in <modulepath>/<username-modulename>/manifests/init.pp

.. code-block:: ruby

  # modules/rbeapi/manifests/init.pp
  # Example to configure eAPI for use with rbeapi
  #   class { rbeapi:
  #    username => eapi,
  #    password => icanttellyou,
  #  }
  class rbeapi ($host = "localhost",
                $transport = https,
                $username = admin,
                $password = "") {

    package { 'rbeapi':
      ensure => installed,
      provider => 'gem',
    }

    # Check the EOS version (split in to major.minor.patch)
    $section = split($::operatingsystemrelease, '\.')
    $major = $section[0]
    $minor = $section[1]
    if $section[2] =~ /^(\d+)/ {
      $patch = $1
    } else {
      $patch = 0
    }

    # eapi.conf can use "socket" starting with EOS 4.14.5
    if $major >= 4 and $minor >= 14 and $patch >= 5 {
      $_transport = socket
      # The following defaults cause the template to skip
      #   user/pass sections
      $_username = admin
      $_password = ""
    } else {
      # Just pass through values we received
      $_transport = $transport
      $_username = $username
      $_password = $password
    }

    # Populate the eapi.conf file
    file { 'eapi.conf':
      path => '/mnt/flash/eapi.conf',
      ensure => file,
      content => template("rbeapi/eapi.conf.erb"),
      require => Package['rbeapi'],
    }
  }

.. target-notes::

.. _`Forge: puppet-eos`: https://forge.puppetlabs.com/aristanetworks/puppet-eos
.. _`Github: puppet-eos`: https://github.com/arista-eosplus/puppet-eos
.. _`ZTP Server`: https://github.com/arista-eosplus/ztpserver
.. _`PuppetLabs`: https://puppetlabs.com/download-puppet-enterprise-all#eos

