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

Puppet::Type.newtype(:eos_portchannel) do
  @doc = 'Manage port channels'

  ensurable

  # Parameters

  newparam(:name) do
    desc 'The resource name for the port channel instance'
  end

  # Properties (state management)

  newproperty(:channel) do
    desc 'Specifies the channel group identifier'

    # Validate each value is a valid channel group id
    validate do |value|
      unless value.between?(1, 1000)
        fail 'value #{value.inspect} is not between 1 and 1000'
      end
    end

    # Make sure we have a string for the ID
    munge do |value|
      Integer(value).to_s
    end
  end

  newproperty(:lacp_mode) do
    desc 'Specifies the interface LACP mode'
    newvalues(:active, :passive, :off)
  end

  newproperty(:members, array_matching: :all) do
    desc 'Array of interfaces that belong to the channel group'

    validate do |value|
      case value
      when String
        super(value)
        validate_features_per_value(value)
      else fail 'value #{value.inspect} is invalid, must be a string.'
      end
    end
  end

  newproperty(:lacp_fallback) do
    desc 'Specifies the LACP fallback setting'
    newvalues(:true, :false)
  end

  newproperty(:lacp_timeout) do
    desc 'LACP fallback timeout'
    munge { |v| Integer(v) }
    validate do |v|
      begin
        Integer(v) ? true : false
      rescue TypeError => err
        error "Cannot convert #{v.inspect} to an integer: #{err.message}"
      end
    end
  end

end
