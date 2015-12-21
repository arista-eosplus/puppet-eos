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
# encoding: utf-8

Puppet::Type.newtype(:eos_command) do
  @doc = <<-EOS
    Execute arbitrary CLI commands on Arista EOS. Commands can be executed
    in priviledged mode (enable) or configuration commands.

    Example:

        eos_command { 'Save running-config':
          mode     => 'enable',
          commands => 'copy running-config startup-config',
        }
  EOS

  # Parameters

  newparam(:name) do
    desc <<-EOS
      The resource name for the command instance.
    EOS
  end

  # Properties (state management)

  newproperty(:mode) do
    desc <<-EOS
      Specifies the command mode to execute the commands in. If this
      value is config then the command list is executed in config mode.
      If the value is enable, then the command list is executed in
      privileged (enable) mode. The default is enable mode.
    EOS
    newvalues(:enable, :config)
  end

  newproperty(:commands, array_matching: :all) do
    desc <<-EOS
      Array of commands to execute on the node. Mutliple commands can be
      sent to the node as a comma delimited set of values.
    EOS

    validate do |value|
      case value
      when String
        super(value)
        validate_features_per_value(value)
      else fail 'value #{value.inspect} is invalid, must be a string.'
      end
    end
  end
end
