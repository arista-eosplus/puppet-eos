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

Puppet::Type.newtype(:eos_interface) do
  @doc = <<-EOS
    Manage common attributes of all Arista EOS interfaces.

    Example:

        eos_interface { 'Management1':
          enable      => true,
          description => 'OOB management to mgmt-sw1 Ethernet42',
          autostate   => true,
        }
  EOS

  ensurable

  # Parameters
  newparam(:name) do
    desc <<-EOS
      The name parameter specifies the full interface identifier of
      the Arista EOS interface to manage.  This value must correspond
      to a valid interface identifier in EOS.
    EOS
  end

  # Properties (state management)

  newproperty(:description) do
    desc <<-EOS
      The one line description to configure for the interface.  The
      description can be any valid alphanumeric string including symbols
      and spaces.
    EOS

    validate do |value|
      case value
      when String then super(value)
      else fail "value #{value.inspect} is invalid, must be a String."
      end
    end
  end

  newproperty(:enable) do
    desc <<-EOS
      The enable value configures the administrative state of the
      specified interface.   Valid values for enable are:

      * true - Administratively enables the interface
      * false - Administratively disables the interface
    EOS
    newvalues(:true, :false)
  end

  newproperty(:autostate) do
    desc <<-EOS
      This option configures autostate on a VLAN interface.
      Valid values for enable are:

      * true - Enable autostate (default setting on EOS)
      * false - Set no autostate
    EOS
    newvalues(:true, :false)
  end
end
