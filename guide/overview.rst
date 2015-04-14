Overview
========

.. contents:: :local:

Where do I start?
-----------------

When first considering getting started with puppet, unless you have previous experience with the tools required, we suggest a gradual approach.   Start by automating portions of the configuration that are outside the data-plane; auxiliary services such as NTP, for example. It is a core service that well understood and should be consistently implemented across most environments. As you become more comfortable with automation, add other management-plane sections of the config: domain-name, DNS servers, syslog, login credentials or AAA configuration.   Its very easy to bite off a manageable piece at a time. After sufficient experience with automating the management plane, then work the automation in to the data-plane.

Once you are comfortable with the level of automation and have full buy-in, consider letting Puppet purge resources which it does not manage.  For example, initially, you might ensure that all devices have the same NTP or syslog servers.  At some point, you could tell Puppet to purge all others to ensure that there are no old or rogue syslog servers remaining configured on devices, too.  Doing so can enhance the security and audit posture of an environment, even further.

Terminology
-----------

There are some important terms to understand when working with Puppet.  Type is something that Puppet knows how to manage; a hostname, VLAN, layer-2 interface, etc.   A Provider is the implementation-specific code that evaluates and effects change to the respective Type. There can be multiple Providers for a Type; for example: VLAN configuration may have a different provider for each OS vendor that it supports.  A Module consists of one or more Types and/or Providers packaged together or, it could be a grouping of related manifest classes, files, and templates.

Puppet works by having an agent running on each node which polls the master for a catalog that describes the desired state of resources on the node.   The agent, then resolves any discrepancies.  On each future run, the agent will verify the state of the resources and only make changes in the event of a discrepancy.

Prerequisites
-------------

`PuppetLabs <http://puppetlabs.com/>`_ provides an EOS extension (SWIX file) for Arista switches that contains Ruby, the Puppet Enterprise agent and a number of dependencies for use with either Puppet Enterprise or Open Source Puppet masters.

On EOS, `eAPI <https://eos.arista.com/arista-eapi-101/>`_ must be initially enabled and the `rbeapi <https://github.com/arista-eosplus/rbeapi>`_ rubygem extension installed.  These 2 components are used by the puppet modules to review the current state of resources and to bring them into compliance with the desired state.

On-switch Requirements:

* Puppet agent

  * Ruby, etc.

* rbeapi rubygem
* eAPI enabled

