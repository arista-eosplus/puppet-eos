# Change Log

## [1.5.0](https://github.com/arista-eosplus/puppet-eos/tree/1.5.0) (2016-12-09)
[Full Changelog](https://github.com/arista-eosplus/puppet-eos/compare/v1.4.0...1.5.0)

**Implemented enhancements:**

- Cleanup style and ignore unnecessary files in release pkg [\#114](https://github.com/arista-eosplus/puppet-eos/pull/114) ([jerearista](https://github.com/jerearista))
- Add CI build badges to README.md [\#73](https://github.com/arista-eosplus/puppet-eos/pull/73) ([jerearista](https://github.com/jerearista))

**Fixed bugs:**

- Limit rubocop version when running ruby 1.9 [\#81](https://github.com/arista-eosplus/puppet-eos/pull/81) ([jerearista](https://github.com/jerearista))
- Update docs WRT puppet 2015.x agents [\#76](https://github.com/arista-eosplus/puppet-eos/pull/76) ([jerearista](https://github.com/jerearista))

**Closed issues:**

- Gems not Ruby 1.9.3 compatible [\#95](https://github.com/arista-eosplus/puppet-eos/issues/95)
- Wrong datatype ine trunk\_groups [\#79](https://github.com/arista-eosplus/puppet-eos/issues/79)

**Merged pull requests:**

- Style updates [\#113](https://github.com/arista-eosplus/puppet-eos/pull/113) ([jerearista](https://github.com/jerearista))
- Switchconfig type & provider [\#112](https://github.com/arista-eosplus/puppet-eos/pull/112) ([jerearista](https://github.com/jerearista))
- add 25gfull and 50gfull for the allowed ethernet speeds [\#110](https://github.com/arista-eosplus/puppet-eos/pull/110) ([mmailand](https://github.com/mmailand))
- add support for subinterfaces/loadinterval [\#109](https://github.com/arista-eosplus/puppet-eos/pull/109) ([mmailand](https://github.com/mmailand))
- Added eos\_alias type [\#108](https://github.com/arista-eosplus/puppet-eos/pull/108) ([mmailand](https://github.com/mmailand))
- added support for setting the crypto in managementdefaults [\#107](https://github.com/arista-eosplus/puppet-eos/pull/107) ([mmailand](https://github.com/mmailand))
- added support for autostate [\#106](https://github.com/arista-eosplus/puppet-eos/pull/106) ([mmailand](https://github.com/mmailand))
- Add TestKitchen framework [\#105](https://github.com/arista-eosplus/puppet-eos/pull/105) ([jerearista](https://github.com/jerearista))
- modify munge not to rely on netaddr gem [\#102](https://github.com/arista-eosplus/puppet-eos/pull/102) ([mrvinti](https://github.com/mrvinti))
- fix require statements to workaround autoload issues with puppet [\#100](https://github.com/arista-eosplus/puppet-eos/pull/100) ([rknaus](https://github.com/rknaus))
- add prefixlist type and provider + spec tests [\#99](https://github.com/arista-eosplus/puppet-eos/pull/99) ([mrvinti](https://github.com/mrvinti))
- add logging host type and provider [\#98](https://github.com/arista-eosplus/puppet-eos/pull/98) ([rknaus](https://github.com/rknaus))
- add ospf types and providers [\#97](https://github.com/arista-eosplus/puppet-eos/pull/97) ([rknaus](https://github.com/rknaus))
- Limit version of json and listen gems when Ruby \< 2.0 [\#96](https://github.com/arista-eosplus/puppet-eos/pull/96) ([jerearista](https://github.com/jerearista))
- add mst instance type and provider [\#94](https://github.com/arista-eosplus/puppet-eos/pull/94) ([rknaus](https://github.com/rknaus))
- add switchport trunk allowed vlan list capability [\#92](https://github.com/arista-eosplus/puppet-eos/pull/92) ([rknaus](https://github.com/rknaus))
- add ethernet speed and lacp port priority support [\#91](https://github.com/arista-eosplus/puppet-eos/pull/91) ([rknaus](https://github.com/rknaus))
- Fix password change issue for md5 and sha512 passwords [\#87](https://github.com/arista-eosplus/puppet-eos/pull/87) ([mmailand](https://github.com/mmailand))
- portchannel\_convergence needs two puppet runs [\#85](https://github.com/arista-eosplus/puppet-eos/pull/85) ([mmailand](https://github.com/mmailand))
- implemented trunk group support for the eos\_switchport provider [\#83](https://github.com/arista-eosplus/puppet-eos/pull/83) ([mmailand](https://github.com/mmailand))
- Fix issue with autoload of helper [\#82](https://github.com/arista-eosplus/puppet-eos/pull/82) ([rknaus](https://github.com/rknaus))
- Back out change from PR 78 - use set\_trunk\_groups. [\#80](https://github.com/arista-eosplus/puppet-eos/pull/80) ([devrobo](https://github.com/devrobo))
- Fixed Typo in the vlan provider in the trunk\_groups function. [\#78](https://github.com/arista-eosplus/puppet-eos/pull/78) ([mmailand](https://github.com/mmailand))
- Merge Release 1.4.0 back to develop [\#72](https://github.com/arista-eosplus/puppet-eos/pull/72) ([jerearista](https://github.com/jerearista))

## [v1.4.0](https://github.com/arista-eosplus/puppet-eos/tree/v1.4.0) (2016-01-13)
[Full Changelog](https://github.com/arista-eosplus/puppet-eos/compare/v1.3.0...v1.4.0)

**Implemented enhancements:**

- Update metadata to include requirements section [\#66](https://github.com/arista-eosplus/puppet-eos/issues/66)
- eos\_stp\_interface provider unit test is incomplete. [\#51](https://github.com/arista-eosplus/puppet-eos/issues/51)
- Add requirements section to metadata [\#67](https://github.com/arista-eosplus/puppet-eos/pull/67) ([jerearista](https://github.com/jerearista))

**Fixed bugs:**

- eos\_portchannel members not idempotent when interface order is not the same [\#46](https://github.com/arista-eosplus/puppet-eos/issues/46)
- eos\_vlan provider does not properly set trunk\_groups [\#38](https://github.com/arista-eosplus/puppet-eos/issues/38)
- Ensure order of array does not affect idempotency [\#70](https://github.com/arista-eosplus/puppet-eos/pull/70) ([websitescenes](https://github.com/websitescenes))
- Fixed trunk groups call in provider. [\#68](https://github.com/arista-eosplus/puppet-eos/pull/68) ([devrobo](https://github.com/devrobo))

**Closed issues:**

- Providers only actually work in tests [\#60](https://github.com/arista-eosplus/puppet-eos/issues/60)
- All providers should have a description [\#55](https://github.com/arista-eosplus/puppet-eos/issues/55)
- Cleanup documentation [\#19](https://github.com/arista-eosplus/puppet-eos/issues/19)

**Merged pull requests:**

- Release 1.4.0 [\#71](https://github.com/arista-eosplus/puppet-eos/pull/71) ([jerearista](https://github.com/jerearista))
- Add test cases for provider methods. [\#69](https://github.com/arista-eosplus/puppet-eos/pull/69) ([devrobo](https://github.com/devrobo))
- Add / enhance descriptions with examples [\#64](https://github.com/arista-eosplus/puppet-eos/pull/64) ([jerearista](https://github.com/jerearista))

## [v1.3.0](https://github.com/arista-eosplus/puppet-eos/tree/v1.3.0) (2015-11-21)
[Full Changelog](https://github.com/arista-eosplus/puppet-eos/compare/v1.2.0...v1.3.0)

**Implemented enhancements:**

- Confine types to only run on AristaEOS [\#36](https://github.com/arista-eosplus/puppet-eos/issues/36)
- Confine providers to only run on AristaEOS and when rbeapi \>= 0.3.0 is present [\#48](https://github.com/arista-eosplus/puppet-eos/pull/48) ([jerearista](https://github.com/jerearista))
- Feature bgp update [\#41](https://github.com/arista-eosplus/puppet-eos/pull/41) ([websitescenes](https://github.com/websitescenes))

**Merged pull requests:**

- Merge develop with master for Release 1.3.0 [\#63](https://github.com/arista-eosplus/puppet-eos/pull/63) ([jerearista](https://github.com/jerearista))
- Release 1.3.0 [\#62](https://github.com/arista-eosplus/puppet-eos/pull/62) ([jerearista](https://github.com/jerearista))
- Confinement update [\#61](https://github.com/arista-eosplus/puppet-eos/pull/61) ([jerearista](https://github.com/jerearista))
- Adjustments for idempotency in staticroute [\#59](https://github.com/arista-eosplus/puppet-eos/pull/59) ([websitescenes](https://github.com/websitescenes))
- Feature system update [\#58](https://github.com/arista-eosplus/puppet-eos/pull/58) ([websitescenes](https://github.com/websitescenes))
- Feature confine rbeapi [\#57](https://github.com/arista-eosplus/puppet-eos/pull/57) ([jerearista](https://github.com/jerearista))
- Netaddr inconsistencies. [\#56](https://github.com/arista-eosplus/puppet-eos/pull/56) ([websitescenes](https://github.com/websitescenes))
- Created eos\_vrrp type [\#53](https://github.com/arista-eosplus/puppet-eos/pull/53) ([devrobo](https://github.com/devrobo))
- Adding routemap functionality [\#52](https://github.com/arista-eosplus/puppet-eos/pull/52) ([websitescenes](https://github.com/websitescenes))
- Add eos\_config resource. [\#50](https://github.com/arista-eosplus/puppet-eos/pull/50) ([devrobo](https://github.com/devrobo))
- Addressed Rubocop issues [\#49](https://github.com/arista-eosplus/puppet-eos/pull/49) ([devrobo](https://github.com/devrobo))
- eos varp and varp interface functionality. [\#47](https://github.com/arista-eosplus/puppet-eos/pull/47) ([websitescenes](https://github.com/websitescenes))
- Fixed version typo from 4.15.5 --\> 4.14.5 [\#45](https://github.com/arista-eosplus/puppet-eos/pull/45) ([jerearista](https://github.com/jerearista))
- Fixes [\#44](https://github.com/arista-eosplus/puppet-eos/pull/44) ([devrobo](https://github.com/devrobo))
- Remove unneeded information from bgp flush [\#43](https://github.com/arista-eosplus/puppet-eos/pull/43) ([websitescenes](https://github.com/websitescenes))
- Adding feature eos user type and provider. [\#42](https://github.com/arista-eosplus/puppet-eos/pull/42) ([websitescenes](https://github.com/websitescenes))
- Convert bgp flush [\#40](https://github.com/arista-eosplus/puppet-eos/pull/40) ([devrobo](https://github.com/devrobo))
- Add 4.15 to the list of supported versions [\#39](https://github.com/arista-eosplus/puppet-eos/pull/39) ([jerearista](https://github.com/jerearista))

## [v1.2.0](https://github.com/arista-eosplus/puppet-eos/tree/v1.2.0) (2015-08-26)
[Full Changelog](https://github.com/arista-eosplus/puppet-eos/compare/v1.1.0...v1.2.0)

**Implemented enhancements:**

- Release 1.2.0 [\#34](https://github.com/arista-eosplus/puppet-eos/pull/34) ([jerearista](https://github.com/jerearista))
- Pass in boolean value for enable option. [\#33](https://github.com/arista-eosplus/puppet-eos/pull/33) ([devrobo](https://github.com/devrobo))
- BGP type and provider bug fix, enhancement, and updated tests [\#32](https://github.com/arista-eosplus/puppet-eos/pull/32) ([devrobo](https://github.com/devrobo))
- Feature eos\_staticroute [\#31](https://github.com/arista-eosplus/puppet-eos/pull/31) ([jerearista](https://github.com/jerearista))
- Rubocop cleanup. [\#30](https://github.com/arista-eosplus/puppet-eos/pull/30) ([devrobo](https://github.com/devrobo))
- Add unit test cases for yes/no and other boolean values. [\#28](https://github.com/arista-eosplus/puppet-eos/pull/28) ([devrobo](https://github.com/devrobo))
- Added support for BGP types and providers along with unit tests. [\#25](https://github.com/arista-eosplus/puppet-eos/pull/25) ([devrobo](https://github.com/devrobo))

**Fixed bugs:**

- mock not intercepting acl.getall call [\#14](https://github.com/arista-eosplus/puppet-eos/issues/14)
- BGP type and provider bug fix, enhancement, and updated tests [\#32](https://github.com/arista-eosplus/puppet-eos/pull/32) ([devrobo](https://github.com/devrobo))

**Closed issues:**

- eos\_bgp\_neighbor not configuring [\#27](https://github.com/arista-eosplus/puppet-eos/issues/27)
- eos\_interface not controlling shutdown/enable status properly [\#26](https://github.com/arista-eosplus/puppet-eos/issues/26)

**Merged pull requests:**

- Release 1.2.0 [\#37](https://github.com/arista-eosplus/puppet-eos/pull/37) ([jerearista](https://github.com/jerearista))
- Verify results from get/getall call is not nil. [\#35](https://github.com/arista-eosplus/puppet-eos/pull/35) ([devrobo](https://github.com/devrobo))
- Include release notes for the 1.1.0 release [\#24](https://github.com/arista-eosplus/puppet-eos/pull/24) ([jerearista](https://github.com/jerearista))

## [v1.1.0](https://github.com/arista-eosplus/puppet-eos/tree/v1.1.0) (2015-07-07)
[Full Changelog](https://github.com/arista-eosplus/puppet-eos/compare/v1.0.0...v1.1.0)

**Implemented enhancements:**

- Add tag metadata to enhance search-ability on Forge [\#11](https://github.com/arista-eosplus/puppet-eos/issues/11)
- Update metadata tags and operatingsystem\_support [\#12](https://github.com/arista-eosplus/puppet-eos/pull/12) ([jerearista](https://github.com/jerearista))

**Merged pull requests:**

- Include release notes for the 1.1.0 release [\#23](https://github.com/arista-eosplus/puppet-eos/pull/23) ([jerearista](https://github.com/jerearista))
- Release 1.1.0 [\#22](https://github.com/arista-eosplus/puppet-eos/pull/22) ([jerearista](https://github.com/jerearista))
- Prune unready types before release [\#21](https://github.com/arista-eosplus/puppet-eos/pull/21) ([jerearista](https://github.com/jerearista))
- Merge 1.1.0 updates to develop [\#20](https://github.com/arista-eosplus/puppet-eos/pull/20) ([jerearista](https://github.com/jerearista))
- Ci mods [\#18](https://github.com/arista-eosplus/puppet-eos/pull/18) ([devrobo](https://github.com/devrobo))
- Added eos\_command type, provider, and type unit test.  [\#16](https://github.com/arista-eosplus/puppet-eos/pull/16) ([devrobo](https://github.com/devrobo))
- Rubocop cleanup [\#13](https://github.com/arista-eosplus/puppet-eos/pull/13) ([devrobo](https://github.com/devrobo))
- Added support for eos\_stp\_interface type and provider along with unit… [\#10](https://github.com/arista-eosplus/puppet-eos/pull/10) ([devrobo](https://github.com/devrobo))
- Cleanup doc-related warnings and URLs [\#9](https://github.com/arista-eosplus/puppet-eos/pull/9) ([jerearista](https://github.com/jerearista))
- Fixup release 1.0.0 merges [\#8](https://github.com/arista-eosplus/puppet-eos/pull/8) ([jerearista](https://github.com/jerearista))

## [v1.0.0](https://github.com/arista-eosplus/puppet-eos/tree/v1.0.0) (2015-05-06)
**Closed issues:**

- warning: already initialized constant IPADDR\_REGEXP in mlag and ipinterface types [\#2](https://github.com/arista-eosplus/puppet-eos/issues/2)

**Merged pull requests:**

- Update guide/conf.py to get version from new metadata.json file [\#6](https://github.com/arista-eosplus/puppet-eos/pull/6) ([jerearista](https://github.com/jerearista))
- Docs [\#5](https://github.com/arista-eosplus/puppet-eos/pull/5) ([jerearista](https://github.com/jerearista))
- Release 1.0.0 [\#4](https://github.com/arista-eosplus/puppet-eos/pull/4) ([devrobo](https://github.com/devrobo))
- Release prep [\#3](https://github.com/arista-eosplus/puppet-eos/pull/3) ([jerearista](https://github.com/jerearista))
- adds type and provider support for vxlan vtep flood addresses [\#1](https://github.com/arista-eosplus/puppet-eos/pull/1) ([devrobo](https://github.com/devrobo))



\* *This Change Log was automatically generated by [github_changelog_generator](https://github.com/skywinder/Github-Changelog-Generator)*