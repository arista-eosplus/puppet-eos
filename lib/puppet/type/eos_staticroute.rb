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

require 'puppet_x/eos/utils/helpers'

Puppet::Type.newtype(:eos_staticroute) do
  @doc = <<-EOS
    Configure static route settings

    Example:

        eos_static_route { '192.168.99.0/24/10.0.0.1': }

        eos_static_route { '192.168.99.0/24/10.0.0.1': 
          ensure => absent,
        }

        eos_static_route { '192.168.10.0/24/Ethernet1':
          route_name => 'Edge10',
          distance   => 3,
        }
  EOS

  ensurable

  # Parameters

  newparam(:name, namevar: true) do
    @doc = <<-EOS
      A composite string consisting of <prefix>/<masklen>/<next_hop>. (namevar)

      prefix    - IP destination subnet prefix
      masklen   - Number of mask bits to apply to the destination
      next_hop - Next_hop IP address or interface name
    EOS

    validate do |value|
      if value.is_a? String then super(value)
      else fail "value #{value.inspect} is invalid, must be a String."
      end
      fail "value #{value.inspect} must contain a slash (/)" unless value =~ /\//
    end
  end

  # Properties (state management)

  newproperty(:route_name) do
    @doc = <<-EOS
      The name assigned to the static route
    EOS

    validate do |value|
      case value
      when String
        super(value)
        validate_features_per_value(value)
      else fail "value #{value.inspect} is invalid, must be a string."
      end
    end
  end

  newproperty(:distance) do
    @doc = <<-EOS
      Administrative distance (1-255) of the route
    EOS

    newvalues(1..255)

    validate do |value|
      unless value.to_i.between?(1, 255)
        fail "value #{value.inspect} is invalid, must be an integer from 1-255."
      end
    end
  end

  newproperty(:tag) do
    @doc = <<-EOS
      Route tag (1-255)
    EOS

    newvalues(1..255)

    validate do |value|
      unless value.to_i.between?(1, 255)
        fail "value #{value.inspect} is invalid, must be an integer from 1-255."
      end
    end
  end
end
