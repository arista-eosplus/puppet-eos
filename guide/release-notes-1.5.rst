Release 1.5
-----------

New Modules
^^^^^^^^^^^

* Created eos_vrrp type (`53 <https://github.com/arista-eosplus/puppet-eos/pull/53>`_) [`devrobo <https://github.com/devrobo>`_]
    .. comment
* Adding routemap functionality (`52 <https://github.com/arista-eosplus/puppet-eos/pull/52>`_) [`websitescenes <https://github.com/websitescenes>`_]
    .. comment
* Add eos_config resource. (`50 <https://github.com/arista-eosplus/puppet-eos/pull/50>`_) [`devrobo <https://github.com/devrobo>`_]
    .. comment
* eos varp and varp interface functionality. (`47 <https://github.com/arista-eosplus/puppet-eos/pull/47>`_) [`websitescenes <https://github.com/websitescenes>`_]
    .. comment
* Adding feature eos user type and provider. (`42 <https://github.com/arista-eosplus/puppet-eos/pull/42>`_) [`websitescenes <https://github.com/websitescenes>`_]
    .. comment

Enhancements
^^^^^^^^^^^^

* Cleanup style and ignore unnecessary files in release pkg (`114 <https://github.com/arista-eosplus/puppet-eos/pull/114>`_) [`jerearista <https://github.com/jerearista>`_]
    .. comment
* Add CI build badges to README.md (`73 <https://github.com/arista-eosplus/puppet-eos/pull/73>`_) [`jerearista <https://github.com/jerearista>`_]
    .. comment
* Add requirements section to metadata (`67 <https://github.com/arista-eosplus/puppet-eos/pull/67>`_) [`jerearista <https://github.com/jerearista>`_]
    .. comment
* Confine providers to only run on AristaEOS and when rbeapi >= 0.3.0 is present (`48 <https://github.com/arista-eosplus/puppet-eos/pull/48>`_) [`jerearista <https://github.com/jerearista>`_]
    .. comment
* Feature bgp update (`41 <https://github.com/arista-eosplus/puppet-eos/pull/41>`_) [`websitescenes <https://github.com/websitescenes>`_]
    .. comment
* Release 1.2.0 (`34 <https://github.com/arista-eosplus/puppet-eos/pull/34>`_) [`jerearista <https://github.com/jerearista>`_]
    .. comment
* Pass in boolean value for enable option. (`33 <https://github.com/arista-eosplus/puppet-eos/pull/33>`_) [`devrobo <https://github.com/devrobo>`_]
    .. comment
* BGP type and provider bug fix, enhancement, and updated tests (`32 <https://github.com/arista-eosplus/puppet-eos/pull/32>`_) [`devrobo <https://github.com/devrobo>`_]
    .. comment
* Feature eos_staticroute (`31 <https://github.com/arista-eosplus/puppet-eos/pull/31>`_) [`jerearista <https://github.com/jerearista>`_]
    .. comment
* Rubocop cleanup. (`30 <https://github.com/arista-eosplus/puppet-eos/pull/30>`_) [`devrobo <https://github.com/devrobo>`_]
    .. comment
* Add unit test cases for yes/no and other boolean values. (`28 <https://github.com/arista-eosplus/puppet-eos/pull/28>`_) [`devrobo <https://github.com/devrobo>`_]
    .. comment
* Added support for BGP types and providers along with unit tests. (`25 <https://github.com/arista-eosplus/puppet-eos/pull/25>`_) [`devrobo <https://github.com/devrobo>`_]
    .. comment

Fixed
^^^^^

* Limit rubocop version when running ruby 1.9 (`81 <https://github.com/arista-eosplus/puppet-eos/pull/81>`_) [`jerearista <https://github.com/jerearista>`_]
    .. comment
* Manifest correctly applied but error returned (`77 <https://github.com/arista-eosplus/puppet-eos/issues/77>`_) [`GGabriele <https://github.com/GGabriele>`_]
    .. comment
* Update docs WRT puppet 2015.x agents (`76 <https://github.com/arista-eosplus/puppet-eos/pull/76>`_) [`jerearista <https://github.com/jerearista>`_]
    .. comment
* Ensure order of array does not affect idempotency (`70 <https://github.com/arista-eosplus/puppet-eos/pull/70>`_) [`websitescenes <https://github.com/websitescenes>`_]
    .. comment
* Fixed trunk groups call in provider. (`68 <https://github.com/arista-eosplus/puppet-eos/pull/68>`_) [`devrobo <https://github.com/devrobo>`_]
    .. comment
* eos_portchannel members not idempotent when interface order is not the same (`46 <https://github.com/arista-eosplus/puppet-eos/issues/46>`_) [`jerearista <https://github.com/jerearista>`_]
    .. comment
* eos_vlan provider does not properly set trunk_groups (`38 <https://github.com/arista-eosplus/puppet-eos/issues/38>`_) [`jerearista <https://github.com/jerearista>`_]
    .. comment

Known Caveats
^^^^^^^^^^^^^

* autoload issue with netaddr gem in eos_varp type (`101 <https://github.com/arista-eosplus/puppet-eos/issues/101>`_)
    .. comment
* Confirm support for the complete list of speeds (`93 <https://github.com/arista-eosplus/puppet-eos/issues/93>`_)
    .. comment
* Fix eos_user provider test to catch encryption attribute not being supported in the provider (`88 <https://github.com/arista-eosplus/puppet-eos/issues/88>`_)
    .. comment
* It is not possible to change a user password if they are encryptet in md5 or sha512 (`86 <https://github.com/arista-eosplus/puppet-eos/issues/86>`_)
    .. comment
* portchannel_convergence needs two puppet runs (`84 <https://github.com/arista-eosplus/puppet-eos/issues/84>`_)
    .. comment
* Clean up boolean properties and parameters in types (`75 <https://github.com/arista-eosplus/puppet-eos/issues/75>`_)
    .. comment
* Add refreshonly parameter to eos_command (`65 <https://github.com/arista-eosplus/puppet-eos/issues/65>`_)
    .. comment

