Overview
========

.. contents:: :local:

Introduction
------------

Puppet is a configuration management platform which operates by way of the user defining the desired state for a resource, puppet comparing that to the current state, then resolving any differences.  By having an agent running on each node, puppet can not only be operated from a master, but can also be used in a standalone (masterless, headless) configuration.

This Type / Provider module enables Types specific for managing Arista EOS device configuration from Puppet.  By defining profile classes around these types, network device management can be refocused to managing network applications such as ntp, stp, ospf, vxlan, or even abstracted away from a network-centric perspective in to higher level business goals such as deploying a new application service or site.

Puppet masters can be deployed in Enterprise or Open Source varieties providing various levels of tools and support, including dashboards and reporting. Such additional toolsets provide simplified configuration and rich analysis and auditing of an environment.

Terminology
-----------

When working with Puppet there is some basic terminology which is helpful to understand.  A Type is resource that Puppet knows how to manage; a hostname, VLAN, layer-2 interface, etc.   A Provider is the implementation-specific code that evaluates and effects change to the respective Type. There can be multiple Providers for a Type; for example: VLAN configuration may have a different provider for each OS vendor that it supports.  A Module can consist of one or more Types and/or Providers packaged together or, it could be a grouping of related manifest classes, files, and templates.

Prerequisites
-------------

`Puppet <http://puppet.com/>`_ provides an EOS extension (SWIX file) for Arista switches that contains Ruby, the Puppet Enterprise agent and a number of dependencies for use with either Puppet Enterprise or Open Source Puppet masters.

On EOS, `eAPI <https://eos.arista.com/arista-eapi-101/>`_ must be initially enabled and the `rbeapi <https://github.com/arista-eosplus/rbeapi>`_ rubygem extension installed.  These 2 components are used by the puppet modules to review the current state of resources and to bring them into compliance with the desired state.

On-switch Requirements:

* Puppet agent

  * Ruby, etc.

* rbeapi rubygem
* eAPI enabled

