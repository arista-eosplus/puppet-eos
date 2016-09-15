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

Puppet::Type.newtype(:eos_ospf_instance) do
  @doc = <<-EOS
    Manage OSPF instance configuration.

    Example:

        eos_ospf_instance { '1':
          router_id                 => 192.168.1.1,
          max_lsa                   => 12000,
          maximum_paths             => 16,
          passive_interfaces        => [],
          active_interfaces         => ['Ethernet49', 'Ethernet50'],
          passive_interface_default => true,
        }
  EOS

  ensurable

  # Parameters

  newparam(:name, :namevar => true) do
    @doc = <<-EOS
      The name parameter specifies the ospf intstance identifier of
      the Arista EOS ospf instance to manage. This value must correspond
      to a valid ospf instance identifier in EOS and must have a value between
      1 and 65535.
    EOS

    # min: 1 max: 65535
    munge do |value|
      Integer(value).to_s
    end

    validate do |value|
      unless value.to_i.between?(1, 65_535)
        fail "value #{value.inspect} is not between 1 and 65535"
      end
    end
  end

  # Properties (state management)

  newproperty(:router_id) do
    desc <<-EOS
      The router_id property configures the router id on the specified ospf
      instance. The router_id value must be a valid IPv4 address. The router ID
      is a 32-bit number assigned to a router running OSPFv2. This number
      uniquely labels the router within an Autonomous System. Status commands
      identify the switch through the router ID.

      For example

        router_id => 192.168.1.1
    EOS

    # IPV4 Address
    # min: 0.0.0.0 max: 255.255.255.255
    validate do |value|
      case value
      when String
        super(value)
        validate_features_per_value(value)
      else fail "value #{value.inspect} is invalid, must be a string."
      end
    end
  end

  newproperty(:max_lsa) do
    desc <<-EOS
      The max_lsa property configures the LSA Overload on the specified ospf
      instance. The max_lsa property must have a value between 0 and 100000.
      The max_lsa property specifies the maximum number of LSAs allowed in an
      LSDB database and configures the switch behavior when the limit is
      approached or exceeded.

      For example

        max_lsa => 12000,
    EOS

    munge { |value| Integer(value) }

    validate do |value|
      unless value.to_i.between?(0, 100_000)
        fail "value #{value.inspect} is not between 0 and 100000"
      end
    end
  end

  newproperty(:maximum_paths) do
    desc <<-EOS
      The maximum_paths property configures the maximum-paths on the specified
      ospf instance. The maximum_paths property must have a value between 1 and
      N where N is the number of interfaces available per ECMP group. The
      maximum_paths command controls the number of parallel routes that OSPFv2
      supports. The default maximum is 16 paths.

      For example

        maximum_paths => 16,
    EOS

    munge { |value| Integer(value) }

    validate do |value|
      unless value.to_i.between?(1, 32)
        fail "value #{value.inspect} is not between 1 and 32"
      end
    end
  end

  newproperty(:passive_interfaces, :array_matching => :all) do
    desc <<-EOS
      The passive_interface property configures all ospf disabled interfaces
      on the specified ospf instance. The passive_interface property must be an
      array of EOS interfaces.

      For example

        passive_interfaces => ['Loopback0'],
    EOS

    def insync?(is)
      is.sort == @should.sort.map(&:to_s)
    end
  end

  newproperty(:active_interfaces, :array_matching => :all) do
    desc <<-EOS
      The active_interface property configures all ospf enabled interfaces
      on the specified ospf instance. The active_interface property must be an
      array of EOS interfaces.

      For example

        active_interfaces => ['Ethernet49', 'Ethernet50', 'Vlan4093'],
    EOS

    def insync?(is)
      is.sort == @should.sort.map(&:to_s)
    end
  end

  newproperty(:passive_interface_default) do
    desc <<-EOS
      The passive_interface_default property configures all interfaces passive
      by default on the specified ospf instance. The switch advertises the
      passive interface as part of the router LSA. The
      passive_interface_default value must be true or false. When it is set to
      false, all interfaces are OSPFv2 active by default and passive interfaces
      must be specified in the passive_interfaces property. When
      passive_interface_default is set to true, all interfaces are OSPFv2
      passive by default and active interfaces must be specified in the
      active_interfaces property.

      For example

        passive_interface_default => false,
    EOS
    newvalues(:true, :false)
  end

end