#
# Copyright (c) 2014-2016, Arista Networks, Inc.
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

Puppet::Type.newtype(:eos_mst_instance) do
  @doc = <<-EOS
    Configure MST instance settings.

    Example:

        eos_mst_instance { '0':
          priority => 8192,
        }
  EOS

  ensurable

  # Parameters

  newparam(:name) do
    @doc = <<-EOS
      The name parameter specifies the MST instance identifier of the Arista
      EOS MST instance identifier to manage. This value must correspond to a
      valid MST instance identifier in EOS. It's value must be between
      0 and 4094.
    EOS

    # Make sure we have a string for the ID
    munge do |value|
      Integer(value).to_s
    end

    validate do |value|
      unless value.to_i.between?(0, 4_094)
        fail "value #{value.inspect} is not between 0 and 4094"
      end
    end
  end

  # Properties (state management)

  newproperty(:priority) do
    @doc = <<-EOS
      Specifies the MST bridge priority. The MST priority must have a value
      between 0 and 61440 in increments of 4096.
    EOS

    # Make sure we have a string for the ID
    munge do |value|
      Integer(value).to_s
    end

    validate do |value|
      unless value.to_i.between?(0, 61_440) && (value.to_i % 4096).zero?
        fail "value #{value.inspect} is not between 0 and 65535"
      end
    end
  end
end
