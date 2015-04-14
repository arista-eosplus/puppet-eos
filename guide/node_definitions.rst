Node Definitions
================

.. contents:: :local:

Getting to know the Types
-------------------------

There are a number of ways to browse the available EOS types::

  $ puppet resource --types | grep eos
  $ puppet describe eos_vlan

Display the current state of a type:

.. code-block:: puppet

  Arista#bash sudo puppet resource eos_vlan
  eos_vlan { '1':
    ensure    => 'present',
    enable    => 'true',
    vlan_name => 'default',
  }
  eos_vlan { '123':
    ensure    => 'present',
    enable    => 'true',
    vlan_name => 'VLAN0123',
  }
  eos_vlan { '300':
    ensure    => 'present',
    enable    => 'true',
    vlan_name => 'ztp_bootstrap',
  }


Creating a Node Profile Manifest
--------------------------------

Below are two sample manifests (classes) that can be applied to nodes to configure MLAG between a spine and ToR switch.
This is a very basic example to illustrate the use of the eos types.  A more useful class would accept variables or read data from hiera 
to use for interface IDs, VLAN IDs, peer-addresses, etc.

Spine1 Sample
^^^^^^^^^^^^^

.. code-block:: puppet

  # Configure peer link and MLAG peer.
  eos_vlan { "4094":
    trunk_groups => ["mlagpeer"],
  }
  eos_interface { "Port-Channel10":
    description => "MLAG Peer link",
    ensure => present,
  }
  eos_portchannel { "Port-Channel10":
    lacp_mode => active,
    members => ["Ethernet1", "Ethernet2"],
  }
  eos_switchport { "Port-Channel10":
    ensure => present,
    mode => trunk,
    # trunk_group => "mlagpeer",
  }
  eos_stp_config { "4094":
    mode => "none",
  }
  eos_ipinterface { "Vlan4094":
    address => "10.0.0.1/30",
  }
  eos_mlag { "Rack2":
    local_interface => "Vlan4094",
    peer_address => "10.0.0.2",
    peer_link => "Port-Channel10",
    domain_id => "mlag1",
    enable => true,
  }

  # Configure downstream links
  eos_portchannel { "Port-Channel3":
    lacp_mode => active,
    members => ["Ethernet2/4"],
  }
  eos_mlag_interface { "Port-Channel3":
    mlag_id => 3,
    ensure => present,
  }
  eos_switchport { "Port-Channel3":
    ensure => present,
    mode => trunk,
    trunk_native_vlan => 300,
    trunk_allowed_vlans => [301, 302, 303, 305, 306, 307],
  }

  # Create vlans
  eos_vlan { "300":
    vlan_name => "ztp_bootstrap",
    ensure => present,
  }

  $vlans = ["301", "302", "303", "305", "306", "307"]
  each($vlans) |$value| { eos_vlan { $value: ensure => present, } }


ToR Sample
^^^^^^^^^^

.. code-block:: puppet

  eos_interface { "Port-Channel3":
  ensure => present,
  description => "MLAG uplink to spine" 
  }
  eos_switchport {'Ethernet1':
    ensure => present,
  }
  eos_switchport {'Ethernet2':
    ensure => present,
  }
  eos_portchannel { "Port-Channel3":
    lacp_mode => active,
    members => ["Ethernet1", "Ethernet2"],
  }
  eos_switchport { "Port-Channel3":
    ensure => present,
    mode => trunk,
    trunk_native_vlan => 300,
    trunk_allowed_vlans => [301, 302, 303, 305, 306, 307],
  }

  eos_switchport {'Ethernet3':
    access_vlan => 302,
    mode => access,
    ensure => present,
  }
  eos_switchport {'Ethernet4':
    access_vlan => 301,
    mode => access,
    ensure => present,
  }

  $vlans = ["301", "302", "303", "305", "306", "307"]

  # In Puppet 3.7 with "parser = future" 
  #each($vlans) |$value| { eos_vlan { $value: ensure => present } }

  # Existing syntax
  define newvlan {
    eos_vlan { $name: 
      ensure => present 
    }
  }
  newvlan { $vlans :
  }

