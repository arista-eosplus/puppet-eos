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

require 'puppet_x/eos/utils/helpers'

Puppet::Type.newtype(:eos_mlag) do
  @doc = <<-EOS
    This type manages the global MLAG instance on EOS nodes.  It
    provides configuration for global MLAG configuration parameters.
  EOS

  # Parameters

  newparam(:name) do
    desc <<-EOS
      The name parameter identifies the global MLAG instance for
      configuration and should be configured as 'settings'.  All
      other values for name will be siliently ignored by the eos_mlag
      provider.
    EOS
    isnamevar
  end

  # Properties (state management)

  newproperty(:domain_id) do
    desc <<-EOS
      The domain_id property configures the MLAG domain-id value for
      the global MLAG configuration instance.  The domain-id setting
      identifies the domain name for the MLAG domain. Valid values
      include alphanumeric characters
    EOS

    validate do |value|
      case value
      when String then super(value)
      else fail "value #{value.inspect} is invalid, must be a string."
      end
    end
  end

  newproperty(:local_interface) do
    desc <<-EOS
      The local_interface property configures the MLAG local-interface
      value for the global MLAG configuration instance.  The local-interface
      setting specifies the VLAN SVI to send MLAG control traffic on.

      Valid values must be a VLAN SVI identifier
    EOS

    validate do |value|
      unless value =~ /^Vlan\d+$/
        fail "value #{value.inspect} is invalid, must be a VLAN SVI"
      end
    end
  end

  newproperty(:peer_address) do
    desc <<-EOS
      The peer_address property configures the MLAG peer-address value
      for the global MLAG configuration instance.  The peer-address setting
      specifieds the MLAG peer control endpoint IP address.

      The specified value must be a valid IP address
    EOS

    validate do |value|
      unless value =~ IPADDR_REGEXP
        fail "value #{value.inspect} is invalid, must be an IP address"
      end
    end
  end

  newproperty(:peer_link) do
    desc <<-EOS
      The peer_link property configures the MLAG peer-link value for the
      glboal MLAG configuration instance.  The peer-link setting specifies
      the interface used to communicate control traffic to the MLAG peer

      The provided value must be a valid Ethernet or Port-Channel interface
      identifer
    EOS

    validate do |value|
      unless value =~ /^[Et|Po].+/
        fail "value #{value.inspect} is invalid, must be a valid " \
             'Ethernet or Port-Channel interface identifier'
      end
    end
  end

  newproperty(:enable) do
    desc <<-EOS
      The enable property configures the admininstrative state of the
      global MLAG configuration.  Valid values for enable are:

      * true - globally enables the MLAG configuration
      * false - glboally disables the MLAG configuration
    EOS

    newvalues(:true, :false)
  end
end
