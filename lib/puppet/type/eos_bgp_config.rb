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

Puppet::Type.newtype(:eos_bgp_config) do
  @doc = <<-EOS
    Provides resource management of the global BGP routing process for
    Arista EOS nodes.
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

  newparam(:bgp_as, namevar: true) do
    desc <<-EOS
      The BGP autonomous system number to be configured for the
      local BGP routing instance.  The value must be in the valid
      BGP AS range of 1 to 65535.  The value is a String.
    EOS

    # Make sure we have a string for the AS since it is the namevar.
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

  def validate_within_range(value)
    # Return true if maximum_ecmp_paths is within valid range
    if value.to_i >= self[:maximum_paths].to_i
      return true
    else
      return false
    end
  end

  newproperty(:enable, boolean: true) do
    desc <<-EOS
      Configures the administrative state for the global BGP routing
      process. If enable is True then the BGP routing process is
      administartively enabled and if enable is False then
      the BGP routing process is administratively disabled.
    EOS

    newvalues(:true, :yes, :on, :false, :no, :off)

    munge do |value|
      @resource.munge_boolean(value)
    end
  end

  newproperty(:router_id) do
    desc <<-EOS
      Configures the BGP routing process router-id value. The router
      id must be in the form of A.B.C.D
    EOS

    validate do |value|
      unless value =~ IPADDR_REGEXP
        fail "value #{value.inspect} is invalid, must be a IP address"
      end
    end
  end

  newproperty(:maximum_paths) do
    desc <<-EOS
      Maximum number of equal cost paths. This value should be less than
      or equal to maximum_ecmp_paths.
    EOS

    munge { |value| Integer(value) }

    validate do |value|
      unless value.to_i.between?(1, 128)
        fail "value #{value.inspect} is not between 1 and 128"
      end
    end
  end

  newproperty(:maximum_ecmp_paths) do
    desc <<-EOS
      Maximum number of installed ECMP routes. This value should be
      greater than or equal to maximum_paths.
    EOS

    munge { |value| Integer(value) }

    validate do |value|
      unless value.to_i.between?(1, 128)
        fail "value #{value.inspect} is not between 1 and 128"
      end
      unless @resource.validate_within_range(value)
        fail "value #{value.inspect} is not greater or equal to maximum-paths"
      end
    end
  end
end
