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

Puppet::Type.newtype(:eos_config) do
  @doc = <<-EOS
    Apply arbitrary configuration commands in Arista EOS.  Commands will only
    be applied based on the absence or presence of regular expression matches.
    configuration for a specific command.  If the command are either
    present or absent, the eos_config will configure the node using
    the command argument.

    Examples:

        eos_config { 'Set location':
          command => 'snmp-server location Here',
        }

        eos_config { 'Set interface description':
          section => 'interface Ethernet1',
          command => 'description My Description',
          regexp  => 'description [A-z]',
        }
  EOS

  # Parameters

  newparam(:name) do
    desc <<-EOS
      The name parameter is the name associated with the resource.
    EOS

    validate do |value|
      unless value.is_a? String
        fail "value #{value.inspect} is invalid, must be a String."
      end
    end
  end

  # Properties (state management)

  newproperty(:command) do
    desc <<-EOS
      Specifies the configuration command to send to the node if the
      regexp does not evalute to true.
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

  newproperty(:section) do
    desc <<-EOS
      Restricts the configuration evaluation to a single configuration
      section.  If the configuration section argument is not provided,
      then the global configuration is used.
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

  newproperty(:regexp) do
    desc <<-EOS
      Specifies the regular expression to use to evaluate the current nodes
      running configuration.  This optional argument will default to use the
      command argument if none is provided.
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
end
