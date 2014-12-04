#
# Copyright (c) 2014, Arista Networks, Inc.
# All rights reserved.
#
# Redistribution and use in source and binary forms, with or without
# modification, are permitted provided that the following conditions are
# met:
#
#  Redistributions of source code must retain the above copyright notice,
#  this list of conditions and the following disclaimer.
#
#  Redistributions in binary form must reproduce the above copyright
#  notice, this list of conditions and the following disclaimer in the
#  documentation and/or other materials provided with the distribution.
#
#  Neither the name of Arista Networks nor the names of its
#  contributors may be used to endorse or promote products derived from
#  this software without specific prior written permission.
#
# THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS
# "AS IS" AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT
# LIMITED TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR
# A PARTICULAR PURPOSE ARE DISCLAIMED. IN NO EVENT SHALL ARISTA NETWORKS
# BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR
# CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF
# SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA, OR PROFITS; OR
# BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY,
# WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT (INCLUDING NEGLIGENCE
# OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE OF THIS SOFTWARE, EVEN
# IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
#
# encoding: utf-8

Puppet::Type.newtype(:eos_vlan) do
  @doc = "Manage Vlans.  This type provides management of Layer 2 Vlans on
    EOS systems.   This type currently supports EOS 4.12.0 or greater
    using eAPI."

  ensurable

  def munge_boolean(value)
    case value
    when true, 'true', :true, 'yes', 'on'
      :true
    when false, 'false', :false, 'no', 'off'
      :false
    else
      fail('munge_boolean only takes booleans')
    end
  end

  # Parameters

  newparam(:vlanid, namevar: true) do
    desc "The vlanid parameter configures a virtual LAN in the range
        of 1 to 4094."

    # Make sure we have a string for the ID
    munge do |value|
      Integer(value).to_s
    end
  end

  # Properties (state management)

  newproperty(:vlan_name) do
    desc "The vlan_name property configures the VLAN name. The name consists
      of up to 32 characters. The default name for VLAN 1 is default. The
      default name for all other VLANs is VLANxxxx, where xxxx is the VLAN
      number. The default name for VLAN 55 is VLAN0055.

      The name command accepts all characters except the space."

    validate do |value|
      case value
      when String
        super(value)
        validate_features_per_value(value)
      else fail "value #{value.inspect} is invalid, must be a string."
      end
    end
  end

  newproperty(:enable, boolean: true) do
    desc "The enable property configures the VLAN transmission state of
        configured VLAN.  When enable is True, ports forward VLAN traffic
        and when enable is False, ports block VLAN traffic.

        The default configuration for enable is True"

    newvalue(:true)
    newvalue(:false)

    munge do |value|
      @resource.munge_boolean(value)
    end
  end

  newproperty(:vni) do
    desc 'The VXLAN Virtual Network Identifier'

    # Make sure we have a string for the ID
    munge do |value|
      Integer(value).to_s
    end

    validate do |value|
      unless value.to_i.between?(1, 16_777_215)
        fail "value #{value.inspect} is not between 1 and 16777215"
      end
    end
  end

  newproperty(:trunk_groups, array_matching: :all) do
    desc "The trunk group property assigns the array of trunk groups to
        the specified VLAN.  A trunk group is the set of physical interfaces
        that comprise the trunk and th ecollections of VLANs whose traffic
        is carried only on ports that are members of trunk groups to which
        the VLAN belongs.

        The default configuration is an empty list"
  end
end
