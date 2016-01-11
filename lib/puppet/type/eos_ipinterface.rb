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

require 'puppet_x/eos/utils/helpers'

Puppet::Type.newtype(:eos_ipinterface) do
  @doc = <<-EOS
    Manage logical IP (L3) interfaces in Arista EOS. Used for IPv4 physical
    interfaces and logical virtual interfaces.

    Example:

        eos_ipinterface { 'Ethernet3':
          address => '192.0.3.2/24',
          mtu     => 1514,

        }
        eos_ipinterface { 'Vlan201':
          address          => '192.0.2.1/24',
          helper_addresses => ['192.168.10.254', '192.168.11.254'],
        }
  EOS

  ensurable

  # Parameters

  newparam(:name) do
    desc <<-EOS
      The name parameter specifies the full interface identifier of
      the Arista EOS interface to manage.  This value must correspond
      to a valid interface identifier in EOS.
    EOS
  end

  # Properties (state management)

  newproperty(:address) do
    desc <<-EOS
      The address property configures the IPv4 address on the
      specified interface.  The address value is configured using
      address/mask format.

      For example

        address => 192.168.10.16/24
    EOS

    validate do |value|
      begin
        IPAddr.new value
      rescue ArgumentError => exc
        raise "value #{value.inspect} is invalid, #{exc.message}"
      end
    end
  end

  newproperty(:helper_addresses, array_matching: :all) do
    desc <<-EOS
      The helper_addresses property configures the list of IP
      helper addresses on the specified interface.  IP helper
      addresses configure a list of forwarding address to send
      send broadcast traffic to as unicast, typically used to
      assist DHCP relay.

      Helper addresses are configured using dotted decimal
      notation.  For example

        helper_addresses => ['192.168.10.254', '192.168.11.254']
    EOS

    # Sort the arrays before comparing
    def insync?(current)
      current.sort == should.sort
    end

    validate do |value|
      unless value =~ IPADDR_REGEXP
        fail "value #{value.inspect} is invalid, must be an IP address"
      end
    end
  end

  newproperty(:mtu) do
    desc <<-EOS
      The mtu property configures the IP interface MTU value
      which specifies the largest IP datagram that can pass
      over the interface without fragementation.  The MTU value
      is specified in bytes and accepts an integer in the range of
      68 to 9214.
    EOS

    munge do |value|
      Integer(value)
    end

    validate do |value|
      unless value.to_i.between?(68, 9214)
        fail "value #{value.inspect} must be in the range of 68 and 9214"
      end
    end
  end
end
