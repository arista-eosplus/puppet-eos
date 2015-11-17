Release 1.3 - November 2015
=========================

.. contents:: :local:

New Resource Types
------------------

* 'eos_vrrp' (`53 <https://github.com/arista-eosplus/puppet-eos/pull/53>`_) [`devrobo <https://github.com/devrobo>`_]
    .. comment
* 'eos_routemap' (`52 <https://github.com/arista-eosplus/puppet-eos/pull/52>`_) [`websitescenes <https://github.com/websitescenes>`_]
    .. comment
* 'eos_config' (`50 <https://github.com/arista-eosplus/puppet-eos/pull/50>`_) [`devrobo <https://github.com/devrobo>`_]
    .. comment
* 'eos_varp and eos_varp_interface' (`47 <https://github.com/arista-eosplus/puppet-eos/pull/47>`_) [`websitescenes <https://github.com/websitescenes>`_]
    .. comment
* 'eos_user' (`42 <https://github.com/arista-eosplus/puppet-eos/pull/42>`_) [`websitescenes <https://github.com/websitescenes>`_]
    .. comment

Enhancements
------------

* 'Confine providers to only run on AristaEOS and when rbeapi >= 0.3.0 is present' (`48 <https://github.com/arista-eosplus/puppet-eos/pull/48>`_) [`jerearista <https://github.com/jerearista>`_]
    Implements puppet feature :rbeapi.   Example use: ``confine :feature => :rbeapi``
* 'Feature bgp update' (`41 <https://github.com/arista-eosplus/puppet-eos/pull/41>`_) [`websitescenes <https://github.com/websitescenes>`_]
    .. comment

Fixed
-----

* 'Unittests: mock not intercepting acl.getall call' (`14 <https://github.com/arista-eosplus/puppet-eos/issues/14>`_)
    .. comment

Known Caveats
-------------

* 'eos_portchannel members not idempotent when interface order is not the same' (`46 <https://github.com/arista-eosplus/puppet-eos/issues/46>`_)
    .. comment
* 'eos_vlan provider does not properly set trunk_groups' (`38 <https://github.com/arista-eosplus/puppet-eos/issues/38>`_)
    .. comment
* 'Feature system update' (`58 <https://github.com/arista-eosplus/puppet-eos/pull/58>`_)
    .. comment
* 'All providers should have a description' (`55 <https://github.com/arista-eosplus/puppet-eos/issues/55>`_)
    .. comment
* 'eos_stp_interface provider unit test is incomplete.' (`51 <https://github.com/arista-eosplus/puppet-eos/issues/51>`_)
    .. comment
* 'Cleanup documentation' (`19 <https://github.com/arista-eosplus/puppet-eos/issues/19>`_)
    .. comment

