Why Puppet and Arista
=====================

.. contents:: :local:

Your business is changing.  Can your network keep up?
-----------------------------------------------------

Businesses need to adapt quickly. New ideas don't generate revenue or provide
value until they reach customers. In addition to application development, that
often requires scaling or modifying infrastructure from storage to physical
servers to the network. Puppet and Arista enable your network team to be more
responsive to their internal customers. This enables new servers to come online
faster, IP storage to be connected to those servers, and the various components
of your application to communicate and reach the customer.

* Automatically test changes with Puppet and vEOS.
    Ensure the changes to your network are tested. vEOS is Arista EOS that will
    run on your favorite hypervisor enabling you to build a virtual test lab
    for your network. This allows your Continuous Integration (CI) tools to
    automatically test network configrations, defined in Puppet, on EOS before
    deploying those into production.

    `Download vEOS-lab
    <https://www.arista.com/en/support/software-download>`_ for free by
    registering at Arista.com.  For instructions on using vEOS in your
    hypervisor, search `EOS Central <https://eos.arista.com/>`_.
* Continually audit for compliance
    Puppet can monitor your network for compliance with the central
    configuration.  With all changes going through a revision control system,
    such as git, changes are clearly tracked including who requested what change.
    Then Puppet logs exactly what was changed on every node.  If anyone makes
    changes directly on a device, Puppet will report that in an audit run or
    automatically correct the device when in enforcing mode. This quickly
    assures you, your team, and auditors that you have the controls in place to
    know the state of every device on your network, properly manage change and
    ensure no unauthorized configurations exist.
* Data driven network definitions simplify configuration management
    Puppet, Hiera, and configuration templates make it easy to define your
    network settings in a YAML data file. This means adding things like a new
    VLAN or changing the syslog server across your entire environent is simply
    a one-line change to a data file instead of touching Puppet code or, owrse,
    manually configuring each device.  This reduces the risk of a configuration
    change and saves time, getting your team on to more important tasks
    quickly.

    Hiera data::

        ---
        ntp::source_interface: 'Management1'
        ntp::servers:
          - 192.0.2.251

        eos_config::snmp::contact: 'NetOps'

        eos_config::name_servers::name_servers:
          - 192.0.2.250
          - 192.0.2.252

        vlans:
          1: { vlan_name: default }
          2: { vlan_name: TestVlan_2 }
          9: { vlan_name: Demo_vlan }
          100: { vlan_name: TestVlan_100, enable: false }
          101: { vlan_name: TEST_VLAN_101 }

* Delegate routine server-port provisioning to the server team
    Puppet can be the self-service catalog for other teams within your
    business, increasing your ability to rapidly deliver business value. Does
    the server team use Puppet?  Do they have to open a network request every
    time they rack a new server? With a simple Puppet class provided by the
    network team, server admins can safely be allowed to self-provision
    standard host ports with internal checks to limit access to core network
    services such as uplink ports, BGP configurations, etc.

    Example::

        esx_server_port {'row3-rack2-server38':
          description => 'ESXi host 38, vmnic0',
          switchport  => '24',
        }

* Work the way you work best
    We proide multiple ways to manage your network configuration with Puppet:
    Templates or discrete resources. If you are new to Puppet or prefer to
    think of your network configs like files, *eos_switchconfig* may be right
    for you.  This allows you to use a configuration template (or combine
    reusable configuration snippets) as the basis for your running-config.  If
    want to take advantage of the full power of Puppet, you may prefer to
    represent your configuration with the *discrete resource* model. This allos
    you to gradually, selectively move your network configuration under Puppet
    control and easily group and abstract complex portions of the config in to
    easy to use resources.

    Switchconfig with templates::

        eos_switchconfig {'running-config':
          content => template('network_configs/spine'),
        }

    Discrete resources::

        eos_ntp_server { '174.127.117.113':
          ensure => present,
        }

        eos_acl_entry{ 'test1:10':
          ensure       => present,
          acltype      => standard,
          action       => permit,
          srcaddr      => '192.168.1.0',
          srcprefixlen => 8,
          log          => true,
        }

        eos_bgp_neighbor { '192.0.2.1':
          ensure     => present,
          enable     => true,
          peer_group => 'Edge',
          remote_as  => 65004
        }


How do I take advantage of these capabilities?
----------------------------------------------

Contact Arista EOS+ Consulting Services `eosplus-dev@arista.com <eosplus-dev@arista.com>`_ formore information, a demo, or to let us jumpstart your Puppet environent.

