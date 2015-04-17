Cookbook
============

.. contents:: :local:

Creating a Node Profile Manifest
--------------------------------

A common pattern is to use node profile manifests to define reusable blocks that get applied to individual nodes, as needed. Node profile manifests define contain classes which define the desired state for one or more settings. These profile classes are, then, assigned to nodes based on the node classification. Profile classes may use parameters (specified in a resource definition or Hiera) to allow customization per node.

Recipe 1: Masterless / Headless
-------------------------------

Puppet may be run in a masterless / headless manner.  This method is useful for testing as well as full deployments. When running headless, modules, manifests, etc are made available to each node (NFS, wget, git, subversion) then are applied at the node with the ``puppet apply <manifest>`` command.

Recipe 2: MLAG
--------------

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

