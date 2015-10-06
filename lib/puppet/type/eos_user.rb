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

Puppet::Type.newtype(:eos_user) do
  @doc = <<-EOS
    Configures user settings.
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

  newparam(:name, namevar: true) do
    desc <<-EOS
      The switch CLI username.
    EOS

    validate do |value|
      fail 'value cannot be blank' if value !~ /[^[:space:]]/
    end
  end

  # Properties (state management)

  newproperty(:nopassword, boolean: true) do
    desc <<-EOS
      Create a user with no password assigned.
    EOS

    newvalues(:true, :false)

    munge do |value|
      @resource.munge_boolean(value)
    end
  end

  newproperty(:encryption) do
    desc <<-EOS
      Defines the encryption format of the password provided in the
      corresponding secret key. Note that cleartext passwords are allowed
      via manual CLI user creation but are not supported in this module
      due to security concerns and idempotency.
    EOS

    validate do |value|
      case value
      when String
        super(resource)
      else
        fail "value #{value.inspect} is invalid, must be a String."
      end
    end
  end

  newproperty(:secret) do
    desc <<-EOS
      This key is used in conjunction with encryption. The value should be
      a hashed password that was previously generated.
    EOS

    validate do |value|
      case value
      when String
        super(resource)
      else
        fail "value #{value.inspect} is invalid, must be a String."
      end
    end
  end

  newproperty(:role) do
    desc <<-EOS
      Configures the role assigned to the user. The EOS default for this
      attribute is managed with aaa authorization policy local default-role;
      this is typically the network-operator role.
    EOS

    validate do |value|
      case value
      when String
        super(resource)
      else
        fail "value #{value.inspect} is invalid, must be a String."
      end
    end
  end

  newproperty(:privilege) do
    desc <<-EOS
      Configures the privilege level for the user. Permitted values are
      integers between 0 and 15. The EOS default privilege is 1.
    EOS

    munge { |value| Integer(value) }

    validate do |value|
      unless value.to_i.between?(0, 15)
        fail "value #{value.inspect} must be in the range of 0 and 15"
      end
    end
  end

  newproperty(:sshkey) do
    desc <<-EOS
      Configures an sshkey for the CLI user. This sshkey will end up in
      /home/USER/.ssh/authorized_keys. Typically this is the public key
      from the client SSH node.
    EOS

    validate do |value|
      case value
      when String
        super(resource)
      else
        fail "value #{value.inspect} is invalid, must be a String."
      end
    end
  end
end
