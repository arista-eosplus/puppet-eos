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

# Work around due to autoloader issues: https://projects.puppetlabs.com/issues/4248
require File.dirname(__FILE__) + '/../../puppet_x/eos/utils/helpers'

Puppet::Type.newtype(:eos_ospf_network) do
  @doc = <<-EOS
    Manage OSPF network statements.

    Example:

        eos_ospf_network { '192.168.10.0/24':
          instance_id => 1,
          area        => 0.0.0.0,
        }
  EOS

  ensurable

  # Parameters

  newparam(:name, namevar: true) do
    @doc = <<-EOS
      The name parameter specifies the ospf network address identifier of the
      Arista EOS ospf network to manage. This value must correspond to a valid
      ip network address including a network mask length in EOS and must have a
      value between 0.0.0.0/1 and 255.255.255.255/32.
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

  newproperty(:area) do
    desc <<-EOS
      The area property configures the ospf area of the specified ospf network.
      The area property must be a valid area in the dotted decimal notation (ip
      address).

      For example

        area => 0.0.0.0,
    EOS

    validate do |value|
      unless value =~ IPADDR_REGEXP
        fail "value #{value.inspect} is invalid, must contain valid IPv4_Prefix"
      end
    end
    
  end

  newproperty(:instance_id) do
    @doc = <<-EOS
      The instance_id parameter specifies the ospf intstance identifier of
      the Arista EOS ospf instance which contains the ospf network to manage.
      This value must correspond to a valid ospf instance identifier in EOS and
      must have a value between 1 and 65535.
    EOS

    # min: 1 max: 65535
    munge { |value| Integer(value) }

    validate do |value|
      unless value.to_i.between?(1, 65_535)
        fail "value #{value.inspect} is not between 1 and 65535"
      end
    end
  end

end