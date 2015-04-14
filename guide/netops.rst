NetOps = DevOps + Networks
==========================

.. contents:: :local:

What is NetOps
--------------

DevOps has been defined by many people but to summarize, it is the practice of bringing Development and Operations closer together to operate is a more consistent manner.   There are many resources discussing the benefits of this methodology from reducing the delta between development, QA, stage and prod systems to speeding roll-out of security patches and new features, alike.  It does not mean that all Operations personnel must become developers, but everyone can benefit from using the same build, deployment, and monitoring tools tools consistently.   Managing hundreds or thousands of individual systems, whether physical or virtual is not realistic when there are so many tools available to ensure consistent, repeatable, deployments.  In conjunction with DevOps is the Infrastructure as Code principal in which automation and orchestration tools are used to perform the final installation and configuration work based on a definition of desired end-system state which can easily be version-controlled, tested, peer-reviewed, executed, and rolled back.  

Some of the business benefits of DevOps and Infrastructure as Code include better QA due to consistency across environments, easy integration with Change Management systems for reqire and approval, repeatability, reduced downtime due to manual configuration issues, and compliance auditing. All of this enables faster, consistent expansion when expanding an environment.  When the change being reviewed is tested in one environment, then can be deployed with no interpretation to the next environment, across as many systems as desired, misconfigurations are significantly reduced.    Further, when an issue is found, the same automation can quickly roll the environment back to the previous state.

Networks have the same challenges as systems; multiple devices which need to be configured similarly and consistently in order to work together as a system.  These could be anything from a redundant set devices for availability, to multiple building or floor switches to hundreds of identical racks in multiple datacenters.

NetOps is DevOps for networking. Utilizing similar automation, orchestration, and monitoring systems as in the server world with network devices, further enhances stability, reliability, and scalability. How?  What are these tools?  Below are just a few examples:

+--------------------------+------------------+-----------------+
|                          | Servers          | Network devices |
+--------------------------+------------------+-----------------+
| Bootstrap                | DHCP + PXE       | DHCP + ZTP      |
+--------------------------+------------------+-----------------+
| Configuration Management | Puppet, Ansible, | Puppet, Ansible |
|                          | Chef, SaltStack  |                 |
+--------------------------+------------------+-----------------+
| Monitoring               | Splunk,          | Splunk,         |
|                          | LogInsight,      | LogInsight,     |
|                          | LogStash         | LogStash        |
+--------------------------+------------------+-----------------+

