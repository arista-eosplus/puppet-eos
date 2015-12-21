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

Puppet::Type.newtype(:eos_vlan) do
  @doc = <<-EOS
    Manage VLANs on Arista EOS.

    Examples:

        eos_vlan { '1':
          vlan_name => 'default',
        }

        eos_vlan { '4094':
          enable       => true,
          vlan_name    => 'MLAG_control',
          trunk_groups => 'mlag',
        }

        # Remove all un-managed VLANs
        resources { 'eos_vlan': purge => true }
  EOS

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
    desc <<-EOS
      The name parameter specifies the VLAN ID to manage on the
      node.  The VLAN ID parameter must be in the valid VLAN ID
      range of 1 to 4094 expressed as a String.
    EOS

    # Make sure we have a string for the ID
    munge do |value|
      Integer(value).to_s
    end

    validate do |value|
      unless value.to_i.between?(1, 4_094)
        fail "value #{value.inspect} must be between 1 and 4094"
      end
    end
  end

  # Properties (state management)

  newproperty(:vlan_name) do
    desc <<-EOS
      The vlan_name property configures the alphanumber VLAN name
      setting in EOS.  TThe name consists of up to 32 characters.  The
      system will automatically truncate any value larger than 32
      characters.
    EOS

    validate do |value|
      unless value =~ /[^\s]/
        fail "value #{value.inspect} is invalid, must not contain spaces"
      end
    end
  end

  newproperty(:enable, boolean: true) do
    desc <<-EOS
      The enable property configures the administrative state of the
      VLAN ID.  When enable is configured as true, the ports forward traffic
      configured with the specified VLAN and when enable is false, the
      specified VLAN ID is blocked.  Valid VLAN ID values:

      * true - Administratively enable (active) the VLAN
      * false - Administratively disable (suspend) the VLAN
    EOS

    newvalues(:true, :false)

    munge do |value|
      @resource.munge_boolean(value)
    end
  end

  newproperty(:trunk_groups, array_matching: :all) do
    desc <<-EOS
      The trunk_groups property assigns an array of trunk group names to
      the specified VLANs.  A trunk group is the set of physical interfaces
      that comprise the trunk and the collection of VLANs whose traffic
      is carried only on ports that are members of the trunk gorups to which
      the VLAN belongs

      Example configuration

        trunk_groups => ['group1', 'group2']

      The default configure is an empty list
    EOS

    validate do |value|
      case value
      when String then super(value)
      else fail "value #{value.inspect} is invalid, elements must be Strings"
      end
    end
  end
end
