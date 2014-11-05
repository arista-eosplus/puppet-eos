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

Puppet::Type.type(:eos_ipinterface).provide(:eos) do

  # Create methods that set the @property_hash for the #flush method
  mk_resource_methods

  # Mix in the api as instance methods
  include PuppetX::Eos::EapiProviderMixin

  # Mix in the api as class methods
  extend PuppetX::Eos::EapiProviderMixin

  def self.instances
    result = eapi.Ipinterface.getall
    helper_addresses = result[1]['ipHelperAddresses']
    result.first['interfaces'].map do |name, attr_hash|
      provider_hash = { name: name, ensure: :present }
      addr = attr_hash['interfaceAddress']['primaryIp']['address']
      mask = attr_hash['interfaceAddress']['primaryIp']['maskLen']
      provider_hash[:address] = "#{addr}/#{mask}" if !addr.nil? || !mask.nil?
      provider_hash[:mtu] = attr_hash['mtu']
      provider_hash[:helper_address] = helper_addresses[name]
      new(provider_hash)
    end
  end

  def address=(val)
    eapi.Ipinterface.set_address(resource['name'], value: val)
    @property_hash[:address] = val
  end

  def helper_address=(val)
    eapi.Ipinterface.set_helper_address(resource['name'], value: val)
    @property_hash[:helper_address] = val
  end

  def mtu=(val)
    eapi.Ipinterface.set_mtu(resource['name'], value: val)
    @property_hash[:mtu] = val
  end

  def exists?
    @property_hash[:ensure] == :present
  end

  def create
    eapi.Ipinterface.create(resource[:name])
    @property_hash = { name: resource[:name], ensure: :present }
    self.address = resource[:address] if resource[:address]
    self.mtu = resource[:mtu] if resource[:mtu]
    self.helper_address = resource[:helper_address] if resource[:helper_address]
  end

  def destroy
    eapi.Ipinterface.delete(resource[:name])
    @property_hash = { name: resource[:name], ensure: :absent }
  end
end
