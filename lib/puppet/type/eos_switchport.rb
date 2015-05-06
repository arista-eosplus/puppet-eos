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

Puppet::Type.newtype(:eos_switchport) do
  @doc = <<-EOS
    This type provides a resource for configuring logical layer 2
    switchports in EOS.  The resource provides configuration for both
    access and trunk operating modes.

    When creating a logical switchport interface, if the specified
    physical interface was previously configured with an IP interface,
    the logical IP interface will be removed.
  EOS

  ensurable

  # Parameters

  newparam(:name) do
    desc <<-EOS
      The name parameter specifies the full interface identifier of
      the Arista EOS interface to manage.  This value must correspond
      to a valid interface identifier in EOS.

      Only Ethernet and Port-Channel interfaces can be configured as
      switchports.
    EOS

    validate do |value|
      unless value =~ /^[Et|Po]/
        fail 'value #{value.inspect} is invalid, must be of type ' \
             'Ethernet or Port-Channel'
      end
    end
  end

  # Properties (state management)

  newproperty(:mode) do
    desc <<-EOS
      The mode property configures the operating mode of the
      logical switchport.  Suppport modes of operation include
      access port or trunk port.  The default value for a new
      switchport is access

      * access - Configures the switchport mode to access
      * trunk - Configures the switchport mode to trunk

    EOS
    newvalues(:access, :trunk)
  end

  newproperty(:trunk_allowed_vlans, array_matching: :all) do
    desc <<-EOS
      The trunk_allowed_vlans property configures the list of
      VLAN IDs that are allowed to pass on the switchport operting
      in trunk mode.  If the switchport is configured for access
      mode, this property is configured but has no effect.

      The list of allowed VLANs must be configured as an Array with
      each entry in the valid VLAN range of 1 to 4094.

      The default value for a new switchport is to allow all valid
      VLAN IDs (1-4094).
    EOS

    munge do |value|
      Integer(value)
    end

    validate do |value|
      unless value.to_i.between?(1, 4_094)
        fail "value #{value.inspect} is not between 1 and 4094"
      end
    end
  end

  newproperty(:trunk_native_vlan) do
    desc <<-EOS
      The trunk_native_vlan property specifies the VLAN ID to
      be used for untagged traffic that enters the switchport
      in trunk mode.  If the switchport is configured for access
      mode, this value is configured but has no effect.  The value
      must be an integer in the valid VLAN ID range of 1 to 4094.

      The default value for the trunk_natve_vlan is 1
    EOS

    munge do |value|
      Integer(value)
    end

    validate do |value|
      unless value.to_i.between?(1, 4_094)
        fail "value #{value.inspect} is not between 1 and 4094"
      end
    end
  end

  newproperty(:access_vlan) do
    desc <<-EOS
      The access_vlan property specifies the VLAN ID to be used
      for untagged traffic that enters the switchport when configured
      in access mode.  If the switchport is configured for trunk mode,
      this value is configured but has no effect.  The value must be
      an integer in the valid VLAN ID range of 1 to 4094.

      The default value for the access_vlan is 1
    EOS

    munge do |value|
      Integer(value)
    end

    validate do |value|
      unless value.to_i.between?(1, 4_094)
        fail "value #{value.inspect} is not between 1 and 4094"
      end
    end
  end
end
