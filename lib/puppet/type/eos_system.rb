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

Puppet::Type.newtype(:eos_system) do
  @doc = <<-EOS
    Manage global EOS switch settings.

    Example:

        eos_system { 'settings':
          hostname   => 'dc02-pod2-rack3-leaf1',
          ip_routing => true,
          timezone   => 'Europe/Berlin',
        }
  EOS

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

  newparam(:name) do
    desc <<-EOS
      The name parameter identifies the global node instance for
      configuration and should be configured as 'settings'.  All
      other values for name will be siliently ignored by the eos_system
      provider.
    EOS
    isnamevar
  end

  # Properties (state management)

  newproperty(:hostname) do
    desc <<-EOS
      The global system hostname is a locally significant value that
      identifies the host portion of the nodes fully qualified domain
      name (FQDN).

      The default hostname for a new system is localhost'
    EOS

    validate do |value|
      case value
      when String then super(resource)
      else fail "value #{value.inspect} is invalid, must be a String."
      end
    end
  end

  newproperty(:ip_routing, boolean: true) do
    desc <<-EOS
      Configures the ip routing state
    EOS

    newvalues(:true, :yes, :on, :false, :no, :off)

    munge do |value|
      @resource.munge_boolean(value)
    end
  end

  newproperty(:timezone) do
    desc <<-EOS
      Configures the clock timezone of the device.

      It expects a string with a valid timezone (in tz format)
    EOS

    validate do |value|
      case value
      when String then super(resource)
      else fail "value #{value.inspect} is invalid, must be a String."
      end
    end
  end
end
