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

# Work around due to autoloader issues: https://projects.puppetlabs.com/issues/4248
require File.dirname(__FILE__) + '/../../puppet_x/eos/utils/helpers'

Puppet::Type.newtype(:eos_ospf_redistribution) do
  @doc = <<-EOS
    Manage OSPF redistribution settings on Arista EOS.

    Example:

        eos_ospf_redistribution { 'static':
          instance_id => '1',
          route_map   => 'test',
        }
        eos_ospf_redistribution { 'connected':
          instance_id => '1',
        }
  EOS

  ensurable

  # Parameters

  newparam(:name) do
    desc <<-EOS
      Protocol name for the OSPF redistribution.
    EOS

    validate do |value|
      unless value.is_a? String
        fail "value #{value.inspect} is invalid, must be a String."
      end
      unless value == 'bgp' || value == 'connected' || value == 'rip' \
        || value == 'static'
        fail "value #{value.inspect} can only be bgp, connected, rip or static"
      end
    end
  end

  # Properties (state management)

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

  newproperty(:route_map) do
    desc <<-EOS
      The route_map property attaches a route map to the OSPF redistribution.      
      By default, no route_map is configured.

    EOS

    validate do |value|
      unless value.is_a? String
        fail "value #{value.inspect} is invalid, must be a String."
      end
    end
  end
end