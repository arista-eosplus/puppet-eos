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

What is NetOps
--------------

NetOps = DevOps for Networks

DevOps has been defined by many people but to summarize, it is the practice of bringing Development and Operations closer together to operate is a more consistent manner.   There are many resources discussing the benefits of this methodology from reducing the delta between development, QA, stage and prod systems to speeding roll-out of security patches and new features, alike.  It does not mean that all Operations personnel must become developers, but everyone can benefit from using the same build, deployment, and monitoring tools tools consistently.   Managing hundreds or thousands of individual systems, whether physical or virtual is not realistic when there are so many tools available to ensure consistent, repeatable, deployments.  In conjunction with DevOps is the Infrastructure as Code principal in which automation and orchestration tools are used to perform the final installation and configuration work based on a definition of desired end-system state which can easily be version-controlled, tested, peer-reviewed, executed, and rolled back.  

Some of the business benefits of DevOps and Infrastructure as Code include better QA due to consistency across environments, easy integration with Change Management systems for reqire and approval, repeatability, reduced downtime due to manual configuration issues, and compliance auditing. All of this enables faster, consistent expansion when expanding an environment.  When the change being reviewed is tested in one environment, then can be deployed with no interpretation to the next environment, across as many systems as desired, misconfigurations are significantly reduced.    Further, when an issue is found, the same automation can quickly roll the environment back to the previous state.

Networks have the same challenges as systems; multiple devices which need to be configured similarly and consistently in order to work together as a system.  These could be anything from a redundant set devices for availability, to multiple building or floor switches to hundreds of identical racks in multiple datacenters.

NetOps is DevOps for networking. Utilizing similar automation, orchestration, and monitoring systems as in the server world with network devices, further enhances stability, reliability, and scalability. How?  What are these tools?  Below are just a few examples:

+--------------------------+------------------+-----------------+
|                          | Servers          | Network devices |
+==========================+==================+=================+
| Bootstrap                | DHCP + PXE       | DHCP + ZTP      |
+--------------------------+------------------+-----------------+
| Configuration Management | Puppet, Ansible, | Puppet, Ansible |
|                          | Chef, SaltStack  |                 |
+--------------------------+------------------+-----------------+
| Monitoring               | Splunk,          | Splunk,         |
|                          | LogInsight,      | LogInsight,     |
|                          | LogStash         | LogStash        |
+--------------------------+------------------+-----------------+

