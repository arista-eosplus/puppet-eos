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

Puppet::Type.newtype(:eos_portchannel) do
  @doc = <<-EOS
    Manage logical Port-Channel interfaces on Arista EOS.

    Example:

        eos_portchannel { 'Port-Channel30':
          ensure        => present,
          description   => 'Host 39b',
          minimum_links => 2,
          lacp_mode     => active,
          lacp_fallback => individual,
          lacp_timeout  => 30,
        }

        eos_portchannel { 'Port-Channel31':
          ensure => absent,
        }
  EOS

  ensurable

  # Parameters

  newparam(:name) do
    desc <<-EOS
      The name parameter specifies the name of the Port-Channel
      interface to configure.  The value must be the full
      interface name identifier that corresponds to a valid
      interface name in EOS.
    EOS

    validate do |value|
      unless value =~ /^Port-Channel/
        fail "value #{value.inspect} is invalid, must be a valid " \
             'Port-Channel interface name'
      end
    end
  end

  # Properties (state management)

  newproperty(:description) do
    desc <<-EOS
      The one line description to configure for the interface.  The
      description can be any valid alphanumeric string including symbols
      and spaces.

      The default value for description is ''
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

      The default value for enable is :true
    EOS
    newvalues(:true, :false)
  end

  newproperty(:lacp_mode) do
    desc <<-EOS
      The lacp_mode property configures the LACP operating mode of
      the Port-Channel interface.  The LACP mode supports the following
      valid values

        * active - Interface is an active LACP port that transmits and
            receives LACP negotiation packets.
        * passive - Interface is a passive LACP port that only responds
            to LACP negotiation packets.
        * on - Interface is a static port channel, LACP disabled.

      The default value for lacp_mode is :on
    EOS

    newvalues(:active, :passive, :on)
  end

  newproperty(:members, array_matching: :all) do
    desc <<-EOS
      The members property manages the Array of physical interfaces
      that comprise the logical Port-Channel interface.  Each entry
      in the members Array must be the full interface identifer of
      a physical interface name.

      The default value for members is []
    EOS

    validate do |value|
      unless value =~ %r{^Ethernet\d(:\/\d+)?}
        fail "value #{value.inspect} is invalid, must be an Ethernet interface"
      end
    end
  end

  newproperty(:minimum_links) do
    desc <<-EOS
      The minimum links property configures the port-channel min-links
      value.  This setting specifies the minimum number of physical
      interfaces that must be operationally up for the Port-Channel
      interface to be considered operationally up.

      Valid range of values for the minimum_links property are from
      0 to 16.

      The default value for minimum_links is 0
    EOS

    munge { |value| Integer(value) }

    validate do |value|
      unless value.to_i.between?(0, 16)
        fail "value #{value.inspect} is not between 0 and 16"
      end
    end
  end

  newproperty(:lacp_fallback) do
    desc <<-EOS
      The lacp_fallback property configures the port-channel lacp
      fallback setting in EOS for the specified interface.  This
      setting accepts the following values

        * static  - Fallback to static LAG mode
        * individual - Fallback to individual ports
        * disabled - Disable LACP fallback

      The default value for lacp_fallback is :disabled
    EOS

    newvalues(:static, :individual, :disabled)
  end

  newproperty(:lacp_timeout) do
    desc <<-EOS
      The lacp_timeout property configures the port-channel lacp
      timeout value in EOS for the specified interface.  The fallback
      timeout configures the period an interface in fallback mode
      remains in LACP mode without receiving a PDU.

      The lacp_timeout value is configured in seconds.
    EOS

    munge do |value|
      Integer(value)
    end
  end
end
