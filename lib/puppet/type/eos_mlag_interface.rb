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

Puppet::Type.newtype(:eos_mlag_interface) do
  @doc = <<-EOS
    Manage MLAG interfaces on Arista EOS. Configure a valid MLAG with a
    peer switch.  The mlag_id parameter is required.

    Example:

        eos_mlag_interface { 'Port-Channel10':
          mlag_id => 10,
        }
  EOS

  ensurable

  # Parameters

  newparam(:name) do
    desc <<-EOS
      The name property identifies the interface to be present
      or absent from the MLAG interface list.  The interface must
      be of type portchannel.

      This property expectes the full interface identifier
    EOS

    validate do |value|
      unless value =~ /^Port-Channel/
        raise "value #{value.inspect} is invalid, must be a Port-Channel"
      end
    end
  end

  # Properties (state management)

  newproperty(:mlag_id) do
    desc <<-EOS
      The mlag_id property assigns a MLAG ID to a Port-Channel interface
      used for forming a MLAG with a peer switch.  Only one MLAG ID can
      be associated with an interface.

      Valid values are in the range of 1 to 2000

      **Note**
      Changing this value on an operational link will cause traffic
      distruption
    EOS

    munge do |value|
      Integer(value).to_i
    end

    validate do |value|
      unless value.to_i.between?(1, 2_000)
        raise "value #{value.inspect} is not between 1 and 2000"
      end
    end
  end
end
