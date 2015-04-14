Getting Started
===============

.. contents:: :local:

Configuring the Puppet Master
-----------------------------

Follow the standard practices for installing either Puppet Enterprise or Puppet Open-source master servers and your environment(s). As the paths to various items and specifics may vary from system to system, you might need to make minor adjustments to the instructions, below, to conform to your particular system.  The command ``puppet confing print`` can assist you in locating the right directories.

On the master, install the `Forge: puppet-eos`_ module (Source: `GitHub: puppet-eos`_). This module is self-contained including the types and providers specific to EOS.  Compare this to the netdev_stdlib module in which PuppetLabs maintains a common set of Types in netdev_stdlib and the EOS providers are in puppet-netdev.

Add the puppet-eos module to your server's modulepath.

Puppet installer::

  $ puppet module install puppet-eos [--environment production ] [--modulepath $basemodulepath ]

Install from source::

  $ git clone https://github.com/arista-eosplus/puppet-eos.git modulepath/eos
  $ git checkout <version or branch>

Git submodules::

  $ git submodule add https://github.com/arista-eosplus/puppet-eos.git modulepath/eos

Bootstrapping EOS switches
--------------------------

There are a number of ways to bootstrap these on to a node.  We strongly suggest `ZTP Server`_ to take a node, fresh out of the box, and automatically load the minimak initial configuration and package instalation.


Sample minimal configuration on a switch

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

  copy http://myserver/puppet-enterprise-3.7.2-eos-4-i386.swix extensions:
  extension puppet-enterprise-3.7.2-eos-4-i386.swix
  copy installed-extensions boot-extensions

Install the rbeapi extension::

  copy http://myserver/rbeapi-0.1.0.swix extensions:
  extension rbeapi-0.1.0.swix
  copy installed-extensions boot-extensions

Additional Puppet Master configuration
--------------------------------------

Configuring rbeapi
^^^^^^^^^^^^^^^^^^

Rbeapi, in many cases, requires a configuration file describing its connection method and credentials to eAPI on the switch. Transports include https, http, http-local, and unix socket (EOS 4.14.5).  Unix socket is recommended if available in the running version of EOS due to ease of configuration and security posture.  
The /mnt/flash/eapi.conf (also flash:eapi.conf) can be installed at bootstrap time or by a simple puppet module.   To do so with puppet, modify the sample files, below to meet your needs.

Create the module skeleton on the Puppet master::

  mkdir -p <modulepath>/rbeapi/manifests/
  mkdir -p <modulepath>/rbeapi/templates/

Create an eapi.conf template in <modulepath>/rbeapi/templates/eapi.conf.erb

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

Create a class that can be referenced by nodes in <modulepath>/rbeapi/manifests/init.pp

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

    # Check the EOS version
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

