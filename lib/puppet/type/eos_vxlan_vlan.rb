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

Puppet::Type.newtype(:eos_vxlan_vlan) do
  @doc = <<-EOS
    This type manages the VXLAN VLAN to VNI mappings in the nodes
    current running configuration.  It provides a resources for
    ensuring specific mappings are present or absent
  EOS

  ensurable

  # Parameters

  newparam(:name, :namevar => true) do
    desc <<-EOS
      The VLAN ID that is associated with this mapping in the valid
      VLAN ID range of 1 to 4094.  The VLAN ID is configured on the
      VXLAN VTI with a one-to-one mapping to VNI.
    EOS

    munge { |value| Integer(value).to_s }

    validate do |value|
      unless value.to_i.between?(1, 4_094)
        fail "value #{value.inspect} is not between 1 and 4094"
      end
    end
  end

  # Properties (state management)

  newproperty(:vni) do
    desc <<-EOS
      The VNI associate with the VLAN ID mapping on the VXLAN VTI
      interface.  The VNI value is an integer value in the range
      of 1 to 16777215.
    EOS

    munge { |value| Integer(value).to_s }

    validate do |value|
      unless value.to_i.between?(1, 16_777_215)
        fail "value #{value.inspect} is not between 1 and 16777215"
      end
    end
  end
end
