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

Puppet::Type.newtype(:eos_bgp_neighbor) do
  @doc = <<-EOS
    Provides stateful management of the neighbor statements for the BGP
    routing process for Arista EOS nodes.
  EOS

  ensurable

  # Parameters

  newparam(:name) do
    desc <<-EOS
      The name of the BGP neighbor to manage.  This value can be either
      an IPv4 address or string (in the case of managing a peer group).
    EOS
  end

  # Properties (state management)

  newproperty(:peer_group) do
    desc <<-EOS
      The name of the peer-group value to associate with the neighbor.  This
      argument is only valid if the neighbor is an IPv4 address.
    EOS
  end

  newproperty(:remote_as) do
    desc <<-EOS
      Configures the BGP neighbors remote-as value.  Valid AS values are
      in the range of 1 to 65535.
    EOS

    munge { |value| Integer(value) }

    validate do |value|
      unless value.to_i.between?(1, 65_535)
        fail "value #{value.inspect} is not between 1 and 65535"
      end
    end
  end

  newproperty(:send_community) do
    desc <<-EOS
      Configures the BGP neighbors send-community value.  If enabled then
      the BGP send-community value is enable.  If disabled, then the
      BGP send-community value is disabled.
    EOS
    newvalues(:enable, :disable)
  end

  newproperty(:next_hop_self) do
    desc <<-EOS
      Configures the BGP neighbors next-hop-self value.  If enabled then
      the BGP next-hop-self value is enabled.  If disabled, then the BGP
      next-hop-self community value is disabled
    EOS
    newvalues(:enable, :disable)
  end

  newproperty(:route_map_in) do
    desc <<-EOS
      Configures the BGP neigbhors route-map in value.  The value specifies
      the name of the route-map.
    EOS
  end

  newproperty(:route_map_out) do
    desc <<-EOS
      Configures the BGP neigbhors route-map out value.  The value specifies
      the name of the route-map.
    EOS
  end

  newproperty(:description) do
    desc <<-EOS
      Configures the BGP neighbors description value.  The value specifies
      an arbitrary description to add to the neighbor statement in the
      nodes running-configuration.
    EOS
  end

  newproperty(:enable, boolean: true) do
    desc <<-EOS
      Configures the administrative state for the BGP neighbor
      process. If enable is True then the BGP neighbor process is
      administartively enabled and if enable is False then
      the BGP neighbor process is administratively disabled.
    EOS
    newvalues(:true, :false)
  end
end
