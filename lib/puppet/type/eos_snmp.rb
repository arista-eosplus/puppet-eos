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

Puppet::Type.newtype(:eos_snmp) do
  @doc = <<-EOS
    Manage global SNMP configuration on Arista EOS.

    Example:

        eos_snmp { 'settings':
          contact          => 'DC02-ops@example.com',
          location         => 'DC02 POD12 Rack3'
          chassis_id       => 'JMB00000',
          source_interface => 'Loopback0',
        }
  EOS

  # Parameters

  newparam(:name) do
    desc <<-EOS
      The name parameter identifis the global SNMP instance for
      configuration and should be configured as 'settings'.  All
      other values for name will be silently ignored by the eos_snmp
      provider.
    EOS
  end

  # Properties (state management)

  newproperty(:contact) do
    desc <<-EOS
      The contact property provides configuration management of the
      SNMP contact value.  This setting provides informative text that
      typically displays the name of a person or organization associated
      with the SNMP agent.

      The default value for contact is ''
    EOS

    validate do |value|
      case value
      when String
        super(value)
        validate_features_per_value(value)
      else raise "value #{value.inspect} is invalid, must be a String."
      end
    end
  end

  newproperty(:location) do
    desc <<-EOS
      The location property provides configuration management of the
      SNMP location value.  This setting typcially provides information
      about the physical lcoation of the SNMP agent.

      The default value for location is ''
    EOS

    validate do |value|
      case value
      when String
        super(value)
        validate_features_per_value(value)
      else raise "value #{value.inspect} is invalid, must be a string."
      end
    end
  end

  newproperty(:chassis_id) do
    desc <<-EOS
      The chassis id propperty provides configuration management of
      the SNMP chassis-id value.  This setting typically provides
      information to uniquely identify the SNMP agent host.

      The default value for chassis_id is ''
    EOS

    validate do |value|
      case value
      when String
        super(value)
        validate_features_per_value(value)
      else raise "value #{value.inspect} is invalid, must be a string."
      end
    end
  end

  newproperty(:source_interface) do
    desc <<-EOS
      The source interface property provides configuration management
      of the SNMP source-interface value.  The source interface value
      configures the interface address to use as the source address
      when sending SNMP packets on the network.

      The default value for source_interface is ''
    EOS

    validate do |value|
      unless value =~ /^[EMPLV]/
        raise "value #{value.inspect} is invalid, must be an interface name"
      end
    end
  end
end
