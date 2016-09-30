#
# Copyright (c) 2016, Arista Networks, Inc.
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

Puppet::Type.newtype(:eos_prefixlist) do
  @doc = <<-EOS
    Configures prefix lists in EOS
  EOS

  ensurable

  # Parameters

  newparam(:name, namevar: true) do
    @doc = <<-EOS
      The name parameter is a composite namevar that combines the
      prefix-list name and the sequence number delimited by the
      colon (:) character

      For example, if the prefix-list name is foo and the sequence
      number for this rule is 10 the namevar would be constructed as
      "foo:10"

      The composite namevar is required to uniquely identify the
      specific list and rule to configure
    EOS

    validate do |value|
      unless value.is_a? String
        fail "value #{value.inspect} is invalid, must be a String."
      end

      seqno = value.partition(':').last if value.include?(':')

      if seqno
        unless seqno.to_i.to_s == seqno
          fail "value #{seqno} must be numeric."
        end

        unless seqno.to_i.is_a? Integer
          fail "value #{seqno} must be an integer."
        end

        unless seqno.to_i.between?(1, 65_535)
          fail "value #{seqno} is invalid, 
               must be an integer between 1-65535."
        end
      else
        fail "value #{value.inspect} must be a composite 'name:seqno'"
      end
    end
  end

  # Properties (state management)

  newproperty(:prefix_list) do
    @doc = <<-EOS
      Name of the prefix list
    EOS

    validate do |value|
      unless value.is_a? String
        fail "value #{value.inspect} is invalid, must be a String."
      end
    end
  end

  newproperty(:seqno) do
    @doc = <<-EOS
      Rule sequence number
    EOS

    munge { |value| Integer(value) }

    validate do |value|
      unless value.to_i.between?(0, 65_535)
        fail "value #{value.inspect} is not between 0 and 65535"
      end
    end
  end

  newproperty(:action) do
    @doc = <<-EOS
      Rule type, either a permit or deny
    EOS

    newvalues(:permit, :deny)
  end

  newproperty(:prefix) do
    @doc = <<-EOS
      The network prefix to match
    EOS

    validate do |value|
      unless value.is_a? String
        fail "value #{value.inspect} is invalid, must be a String."
      end
    end
  end

  newproperty(:masklen) do
    @doc = <<-EOS
      The network prefix mask length.
    EOS

    munge { |value| Integer(value) }

    validate do |value|
      unless value.to_i.between?(0, 32)
        fail "value #{value.inspect} is not between 0 and 32"
      end
    end
  end

  newproperty(:eq) do
    @doc = <<-EOS
      Mask length for the conditional operator 'equal'. Allowed values 1-32.
    EOS

    munge { |value| Integer(value) }

    validate do |value|
      unless value.to_i.between?(1, 32)
        fail "value #{value.inspect} is not between 1 and 32"
      end
    end

  end

  newproperty(:ge) do
    @doc = <<-EOS
      Mask length for the conditional operator 'greater than'. Allowed values 1-32.
    EOS

    munge { |value| Integer(value) }

    validate do |value|
      unless value.to_i.between?(1, 32)
        fail "value #{value.inspect} is not between 1 and 32"
      end
    end
  end

  newproperty(:le) do
    @doc = <<-EOS
      Mask length for the conditional operator 'less than'. Allowed values 1-32.
    EOS

    munge { |value| Integer(value) }

    validate do |value|
      unless value.to_i.between?(1, 32)
        fail "value #{value.inspect} is not between 1 and 32"
      end
    end
  end
end