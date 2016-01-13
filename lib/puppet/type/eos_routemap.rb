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

Puppet::Type.newtype(:eos_routemap) do
  @doc = <<-EOS
    Manage route-maps on Arista EOS.

    Examples:

        eos_routemap { 'my_routemap:10':
          description => 'test 10',
          action      => permit,
          match       => 'ip address prefix-list 8to24',
        }

        eos_routemap { 'bgp_map:10':
          action   => permit,
          match    => 'as 10',
          set      => 'local-preference 100',
          continue => 20,
        }

        eos_routemap { 'bgp_map:20':
          action => permit,
          match  => [' metric-type type-1', 'as 100'],
        }
  EOS

  ensurable

  # Parameters

  newparam(:name, namevar: true) do
    desc <<-EOS
      The name of the routemap namevar composite name:seqno.
    EOS

    validate do |value|
      unless value.is_a? String
        fail "value #{value.inspect} is invalid, must be a String."
      end
      seqno = value.partition(':').last if value.include?(':')
      if seqno
        unless seqno.to_i.is_a? Integer
          fail "value #{seqno} must be an integer."
        end
        unless seqno.to_i.between?(1, 65_535)
          fail "value #{seqno} is invalid, /
               must be an integer from 1-65535."
        end
      else
        fail "value #{value.inspect} must be a composite name:seqno"
      end
    end
  end

  # Properties (state management)

  newproperty(:description) do
    desc <<-EOS
      A description for the route-map.
    EOS

    validate do |value|
      unless value.is_a? String
        fail "value #{value.inspect} is invalid, must be a String."
      end
    end
  end

  newproperty(:action) do
    desc <<-EOS
      A description for the route-map.
    EOS

    validate do |value|
      unless value.is_a? String
        fail "value #{value.inspect} is invalid, must be a String."
      end
      unless value == 'permit' || value == 'deny'
        fail "value #{value.inspect} can only be deny or permit"
      end
    end
  end

  newproperty(:match, array_matching: :all) do
    desc <<-EOS
      Route map match rule.
    EOS

    # Sort the arrays before comparing
    def insync?(current)
      current.sort == should.sort
    end

    validate do |value|
      unless value.is_a? String
        fail "value #{value.inspect} is invalid, must be a String."
      end
    end
  end

  newproperty(:set, array_matching: :all) do
    desc <<-EOS
      Set route attribute.
    EOS

    # Sort the arrays before comparing
    def insync?(current)
      current.sort == should.sort
    end

    validate do |value|
      unless value.is_a? String
        fail "value #{value.inspect} is invalid, must be a String."
      end
    end
  end

  newproperty(:continue) do
    desc <<-EOS
      A route-map sequence number to continue on.
    EOS

    munge { |value| Integer(value) }

    validate do |value|
      unless value.to_i.is_a? Integer
        fail "value #{value.inspect} is invalid, must be an Integer."
      end
      unless value.to_i.between?(1, 16_777_215)
        fail "value #{value.inspect} is invalid, /
             must be an integer from 1-16777215."
      end
    end
  end
end
