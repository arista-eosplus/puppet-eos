#
# Copyright (c) 2014, Arista Networks, Inc.
# All rights reserved.
#
# Redistribution and use in source and binary forms, with or without
# modification, are permitted provided that the following conditions are
# met:
#
#   Redistributions of source code must retain the above copyright notice,
#   this list of conditions and the following disclaimer.
#
#   Redistributions in binary form must reproduce the above copyright
#   notice, this list of conditions and the following disclaimer in the
#   documentation and/or other materials provided with the distribution.
#
#   Neither the name of Arista Networks nor the names of its
#   contributors may be used to endorse or promote products derived from
#   this software without specific prior written permission.
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
require 'puppet/type'
require 'puppet_x/eos/provider'

Puppet::Type.type(:eos_vxlan).provide(:eos) do

  # Create methods that set the @property_hash for the #flush method
  mk_resource_methods

  # Mix in the api as instance methods
  include PuppetX::Eos::EapiProviderMixin

  # Mix in the api as class methods
  extend PuppetX::Eos::EapiProviderMixin

  def self.instances
    eapi.Vxlan.get.first['interfaces'].map do |name, attrs|
      provider_hash = { name: name, ensure: :present }
      provider_hash[:source_interface] = attrs['srcIpIntf']
      provider_hash[:multicast_group] = attrs['floodMcastGrp']
      new(provider_hash)
    end
  end

  def source_interface=(val)
    eapi.Vxlan.set_source_interface(value: val)
    @property_hash[:source_interface] = val
  end

  def multicast_group=(val)
    eapi.Vxlan.set_multicast_group(value: val)
    @property_hash[:multicast_group] = val
  end

  def exists?
    @property_hash[:ensure] == :present
  end

  def create
    eapi.Vxlan.create
    @property_hash = { name: resource[:name], ensure: :present }
    self.source_interface = resource[:source_interface] \
                            if resource[:source_interface]
    self.multicast_group = resource[:multicast_group] \
                           if resource[:multicast_group]
  end

  def destroy
    eapi.Vxlan.delete
    @property_hash = { name: resource[:name], ensure: :absent }
  end
end
