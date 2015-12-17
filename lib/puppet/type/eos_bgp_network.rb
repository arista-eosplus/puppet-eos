#
# Copyright (c) 2015, Arista Networks, Inc.
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

Puppet::Type.newtype(:eos_bgp_network) do
  @doc = <<-EOS
    Manage BGP network statements on Arista EOS.

    Example:

        eos_bgp_network{ '192.0.3.0/24':
          ensure    => present,
          route_map => 'neighbor3_map',
        }
  EOS

  ensurable

  # Parameters

  newparam(:name) do
    desc <<-EOS
      The name is a composite name that contains the IPv4_Prefix/Masklen.
      The IPv4 prefix to configure as part of the network statement.
      The value must be a valid IPv4 prefix.  The IPv4 subnet mask
      length in bits.  The value for the masklen must be in the valid
      range of 1 to 32.
    EOS

    validate do |value|
      unless value =~ %r{/}
        fail "value #{value.inspect} is invalid, must be an IPv4_Prefix/Masklen"
      end
      w = value.split('/')
      unless w[0] =~ IPADDR_REGEXP
        fail "value #{value.inspect} is invalid, must contain valid IPv4_Prefix"
      end
      unless w[1].to_i.between?(1, 32)
        fail "value #{value.inspect} is invalid, " \
               'masklen must be between 1 and 32'
      end
    end
  end

  # Properties (state management)

  newproperty(:route_map) do
    desc <<-EOS
      Configures the BGP route-map name to apply to the network statement
      when configured.  Note this module does not create the route-map.
    EOS

    validate do |value|
      case value
      when String
        super(value)
        validate_features_per_value(value)
      else fail "value #{value.inspect} is invalid, must be a String."
      end
    end
  end
end
