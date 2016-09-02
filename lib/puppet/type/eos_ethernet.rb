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

Puppet::Type.newtype(:eos_ethernet) do
  @doc = <<-EOS
    Manage physical Ethernet interfaces on Arista EOS.  Physical Ethernet
    interfaces include the physical characteristics of front panel data plane
    ports but does not include out-of-band Management interfaces.

    Example:

        eos_ethernet { 'Ethernet3/17':
          enable              => true,
          description         => 'To switch2 Ethernet 1/3',
          flowcontrol_send    => on,
          flowcontrol_receive => on,
          speed               => 'forced 40gfull',
          lacp_priority       => 0,
        }
  EOS

  # Parameters
  newparam(:name) do
    desc <<-EOS
      The name of the physical interface to configure.  The interface
      name must coorelate to the full physical interface identifier
      in EOS.
    EOS
    isnamevar
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
      The enable value configures the administrative state of the physical
      Ethernet interfaces.   Valid values for enable are:

      * true - Administratively enables the Ethernet interface
      * false - Administratively disables the Ethernet interface
    EOS
    newvalues(:true, :false)
  end

  newproperty(:flowcontrol_send) do
    desc <<-EOS
      This property configures the flowcontrol send value for the
      specified Ethernet interface.  Valid values for flowcontrol are:

      * on - Configures flowcontrol send on
      * off - Configures flowcontrol send off
    EOS
    newvalues(:on, :off)
  end

  newproperty(:flowcontrol_receive) do
    desc <<-EOS
      This property configures the flowcontrol receive value for the
      specified Ethernet interface.  Valid values for flowcontrol are:

      * on - Configures flowcontrol receive on
      * off - Configures flowcontrol receive off
    EOS
    newvalues(:on, :off)
  end

  newproperty(:speed) do
    desc <<-EOS
      This property configures the interface speed for the specified Ethernet
      interface. Valid values for speed are:

      * 'default'
      * '100full'
      * '10full'
      * 'auto'
      * 'auto 100full'
      * 'auto 10full'
      * 'auto 40gfull'
      * 'forced 10000full'
      * 'forced 1000full'
      * 'forced 1000half'
      * 'forced 100full'
      * 'forced 100gfull'
      * 'forced 100half'
      * 'forced 10full'
      * 'forced 10half'
      * 'forced 40gfull'
      * 'sfp-1000baset auto 100full'
    EOS
    newvalues('default', '100full', '10full', 'auto', 'auto 100full',
              'auto 10full', 'auto 40gfull', 'forced 10000full',
              'forced 1000full', 'forced 1000half', 'forced 100full',
              'forced 100gfull', 'forced 100half', 'forced 10full',
              'forced 10half', 'forced 40gfull', 'sfp-1000baset auto 100full')
  end

  newproperty(:lacp_priority) do
    desc <<-EOS
      The lacp_priority property specifies the lacp port priority associated
      with the ethernet interface. The configured value must be an integer in
      the range of 0 to 65535.

      The default value for the lacp_priority setting is 32768
    EOS

    munge { |value| Integer(value) }

    validate do |value|
      unless value.to_i.between?(0, 65_535)
        fail "value #{value.inspect} must be between 0 and 65535"
      end
    end
  end
end
