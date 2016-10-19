Why Puppet and Arista
=====================

.. contents:: :local:

Your business is changing.  Can your network keep up?
-----------------------------------------------------

* Automatically test changes with Puppet and vEOS.

  Ensure the changes to your network are tested. vEOS is Arista EOS that will run on your favorite hypervisor enabling you to build a virtual test lab for your network. This allows your Continuous Integration (CI) tools to automatically test network configrations, defined in Puppet, on EOS before deploying those into production. `Download vEOS-lab <https://www.arista.com/en/support/software-download>`_ for free by registering at Arista.com.  For instructions on using vEOS in your hypervisor, search `EOS Central <https://eos.arista.com/>`_.

* Continually audit for compliance

  Puppet can monitor your network for compliance with the central configuration.  With all changes going through a revision control system, such as git, changes are clearly tracked showing who requested what change. Then Puppet logs exactly what was changed on every node.  If anyone makes changes directly on a device, Puppet will flag that in an audit run or automatically correct the device when in enforcing mode. This quickly assures you, your team, and auditors that you have the controls in place to know the state of every device on your network, properly manage change and ensure no unauthorized configurations exist.

* Data driven network definitions simplify configuration management

  Puppet, Hiera, and configuration templates make it easy to define your network settings in a YAML data file. This means adding things like a new VLAN or changing the syslog server across your entire environent is simply a one-line change to a data file instead of touching Puppet code or, owrse, manually configuring each device.  This reduces the risk of a configuration change and saves time, getting your team on to more important tasks quickly.

* Delegate routine server-port provisioning to the server team

  Puppet can be the self-service catalog for other teams within your business, increasing your ability to rapidly deliver business value. Does the server team use Puppet?  Do they have to open a network request every time they rack a new server? With a simple Puppet class provided by the network team, server admins can safely be allowed to self-provision standard host ports with internal checks to limit access to core network services such as uplink ports, BGP configurations, etc.

  Example::

      esx_server_port {'row3-rack2-server38':
        description => 'ESXi host 38, vmnic0',
        switchport  => '24',
      }

How do I take advantage of these capabilities?
----------------------------------------------

Contact Arista EOS+ Consulting Services `eosplus-dev@arista.com <eosplus-dev@arista.com>`_ formore information, a demo, or to let us jumpstart your Puppet environent.

