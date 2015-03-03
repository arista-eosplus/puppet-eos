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

Puppet::Type.newtype(:eos_vxlan) do
  @doc = <<-EOS
    This type mananges VXLAN interface configuration on Arista
    EOS nodes.  It provides configuration of logical Vxlan interface
    instances and settings
  EOS

  ensurable

  # Parameters

  newparam(:name) do
    desc <<-EOS
      The name parameter specifies the name of the Vxlan
      interface to configure.  The value must be the full
      interface name identifier that corresponds to a valid
      interface name in EOS.
    EOS

    validate do |value|
      unless value =~ /^Vxlan\d+/
        fail "value #{value.inspect} is invalid, must be a valid "
             "Vxlan interface name"
      end
    end
  end

  # Properties (state management)

  newproperty(:description) do
    desc <<-EOS
      The one line description to configure for the interface.  The
      description can be any valid alphanumeric string including symbols
      and spaces.

      The default value for description is ''
    EOS

    validate do |value|
      case value
      when String then super(value)
      else fail "value #{value.inspect} is invalid, must be a String."
      end
    end
  end

  newproperty(:enable) do
    desc <<-EOS
      The enable value configures the administrative state of the
      specified interface.   Valid values for enable are:

        * true - Administratively enables the interface
        * false - Administratively disables the interface

      The default value for enable is :true
    EOS
    newvalues(:true, :false)
  end

  newproperty(:source_interface) do
    desc <<-EOS
      The source interface property specifies the interface address
      to use to source Vxlan packets from.  This value configures
      the vxlan source-interface value in EOS

      The default value for source_interface is ''
    EOS

    validate do |value|
      case value
      when String then super(resource)
      else fail "value #{value.inspect} is invalid, must be a String."
      end
    end
  end

  newproperty(:multicast_group) do
    desc <<-EOS
      The multicast group property specifies the multicast group
      address to use for VTEP communication.  This value configures
      the vxlan multicast-group value in EOS.  The configured value
      must be a valid multicast address in the range of 224/8.

      The default value for multicast_group is ''
    EOS

    MCAST_REGEXP = /^2(?:2[4-9]|3\d)
                    (?:\.(?:25[0-5]|2[0-4]\d|1\d\d|[1-9]\d?|0)){3}$/x

    validate do |value|
      unless value =~ MCAST_REGEXP
        fail "value #{value.inspect} is invalid, must a multicast address"
      end
    end
  end

  newproperty(:udp_port) do
    desc <<-EOS
      The udp_port property specifies the VXLAN UDP port associated
      with sending and receiveing VXLAN traffic.  This value configures
      the vxlan udp-port value in EOS.  The configured value must be
      an integer in the range of 1024 to 65535.

      The default value for the udp_port setting is 4789
    EOS

    munge { |value| Integer(value) }

    validate do |value|
      unless value.to_i.between?(1024, 65_535)
        fail "value #{value.inspect} must be between 1024 and 65535"
      end
    end
  end


  newproperty(:flood_list, array_matching: :all) do
    desc <<-EOS
      This parameter mantains the default VXLAN flood list for all
      VNIs that do not have an explicit flood list configured.  The
      flood list supports forwarding broadcast, unicast, and multicast
      traffic for head-end replication.

      The flood list value is configured as an Array of IP addresses.

        flood => ['1.1.1.1', '2.2.2.2']

      The default flood_list value is []
    EOS


    IPADDR_REGEXP = /^(?:(?:25[0-5]|2[0-4][0-9]|[01]?[0-9][0-9]?)\.){3}
                      (?:25[0-5]|2[0-4][0-9]|[01]?[0-9][0-9]?)$/x

    validate do |value|
      unless value =~ IPADDR_REGEXP
        fail "value #{value.inspect} is invalid, must be an IP address"
      end
    end
  end
end
