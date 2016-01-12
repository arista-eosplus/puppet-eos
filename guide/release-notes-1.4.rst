Release 1.4.0 - January 2016
============================

.. contents:: :local:

Enhancements
------------

* Add requirements section to metadata (`67 <https://github.com/arista-eosplus/puppet-eos/pull/67>`_) [`jerearista <https://github.com/jerearista>`_]
    .. comment
* Add additional examples in docstrings (`64 <https://github.com/arista-eosplus/puppet-eos/pull/64>`_) [`jerearista <https://github.com/jerearista>`_]
    .. comment

Fixed
-----

* Ensure order of array does not affect idempotency (`70 <https://github.com/arista-eosplus/puppet-eos/pull/70>`_)
    This resolves several potential, but rare, issues.  In the event that a
    port-channel is in a state where some members were up and others not,
    Puppet could receive the list of members out of order, and believe that
    one or more members were not properly configured, reapplying their config.
    (`4    6 <https://github.com/arista-eosplus/puppet-eos/issues/46>`_)
* eos_vlan provider does not properly set trunk_groups (`38 <https://github.com/arista-eosplus/puppet-eos/issues/38>`_)
    The eos_vlan provider now properly sets the trunk_groups:

        eos_vlan { '4094':
          trunk_groups => ['mlag_peer'],
        }

* mock not intercepting acl.getall call (`14 <https://github.com/arista-eosplus/puppet-eos/issues/14>`_)
    .. comment

