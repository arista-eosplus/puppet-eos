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

Puppet::Type.newtype(:eos_bgp_neighbor) do
  @doc = <<-EOS
    Manage BGP neighbor configuration on Arista EOS.

    Example:

        eos_bgp_neighbor { 'Edge':
          ensure         => present,
          enable         => true,
          description    => 'some text',
          send_community => true,
          route_map_in   => 'in_map',
          route_map_out  => 'out_map',
          next_hop_self  => false,
        }

        eos_bgp_neighbor { '192.0.3.1':
          ensure         => present,
          enable         => true,
          peer_group     => 'Edge',
          remote_as      => 65004,
          send_community => true,
          next_hop_self  => true,
        }
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

  newparam(:name) do
    desc <<-EOS
      The name of the BGP neighbor to manage.  This value can be either
      an IPv4 address or string (in the case of managing a peer group).
    EOS

    validate do |value|
      unless value.is_a? String
        fail "value #{value.inspect} is invalid, must be a String."
      end
    end
  end

  # Properties (state management)

  def name_ip?
    # Return true if name parameter is an IPv4 address
    self[:name] =~ IPADDR_REGEXP ? true : false
  end

  newproperty(:peer_group) do
    desc <<-EOS
      The name of the peer-group value to associate with the neighbor.  This
      argument is only valid if the neighbor is an IPv4 address.
    EOS

    validate do |value|
      case value
      when String
        super(value)
        validate_features_per_value(value)
      else fail "value #{value.inspect} is invalid, must be a String."
      end
      unless @resource.name_ip?
        fail 'peer_group cannot be set unless the neighbor is an IPv4 address'
      end
    end
  end

  newproperty(:remote_as) do
    desc <<-EOS
      Configures the BGP neighbors remote-as value.  Valid AS values are
      in the range of 1 to 65535. The value is an Integer.
    EOS

    # Make sure we have a string for the AS
    munge do |value|
      Integer(value).to_s
    end

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

    validate do |value|
      case value
      when String
        super(value)
        validate_features_per_value(value)
      else fail "value #{value.inspect} is invalid, must be a String."
      end
    end
  end

  newproperty(:route_map_out) do
    desc <<-EOS
      Configures the BGP neigbhors route-map out value.  The value specifies
      the name of the route-map.
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

  newproperty(:description) do
    desc <<-EOS
      Configures the BGP neighbors description value.  The value specifies
      an arbitrary description to add to the neighbor statement in the
      nodes running-configuration.
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

  newproperty(:enable, boolean: true) do
    desc <<-EOS
      Configures the administrative state for the BGP neighbor
      process. If enable is True then the BGP neighbor process is
      administartively enabled and if enable is False then
      the BGP neighbor process is administratively disabled.
    EOS

    newvalues(:true, :yes, :on, :false, :no, :off)

    munge do |value|
      @resource.munge_boolean(value)
    end
  end
end
