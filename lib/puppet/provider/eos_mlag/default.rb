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
require 'puppet_x/eos/eapi'

Puppet::Type.type(:eos_mlag).provide(:eos) do

  # Create methods that set the @property_hash for the #flush method
  mk_resource_methods

  # Mix in the api as instance methods
  include PuppetX::Eos::EapiProviderMixin
  # Mix in the api as class methods
  extend PuppetX::Eos::EapiProviderMixin

  def self.instances
    resp = eapi.enable('show mlag')
    result = resp.first

    return [] if !result.key?('domainId')

    provider_hash = { name: result['domainId'],  ensure: :present }
    provider_hash[:domain_id] = result['domainId']
    provider_hash[:local_interface] = result['localInterface']
    provider_hash[:peer_address] = result['peerAddress']
    provider_hash[:peer_link] = result['peerLink']

    resp = eapi.enable('show mlag interfaces')
    interfaces_hash = {}
    resp.first['interfaces'].each do |id, values|
      interfaces_hash[id] = values['localInterface']
    end
    provider_hash[:interfaces] = interfaces_hash
        
    state = result['state'] == 'disabled' ? :true : :false
    provider_hash[:enable] = state

    provider_hash[:primary_priority] = 0
    [new(provider_hash)]
  end

  def self.prefetch(resources)
    provider_hash = instances.each_with_object({}) do |provider, hsh|
      hsh[provider.name] = provider
    end

    resources.each_pair do |name, resource|
      resource.provider = provider_hash[name] if provider_hash[name]
    end
  end

  def initialize(resource = {})
    super(resource)
    @property_flush = {}
  end

  def local_interface=(val)
    @property_flush[:local_interface] = val
  end
  
  def peer_address=(val)
    @property_flush[:peer_address] = val
  end

  def peer_link=(val)
    @property_flush[:peer_link] = val
  end
  
  def enable=(val)
    @property_flush[:enable] = val
  end

  def interfaces=(val)
    @property_flush[:interfaces] = val
  end

  def exists?
    @property_hash[:ensure] == :present
  end

  def create
    id = resource[:name]
    eapi.config(["mlag configuration", "domain-id #{id}"])
    @property_hash = { name: id, ensure: :present }
    self.local_interface = resource[:local_interface] if resource[:local_interface]
    self.peer_address = resource[:peer_address] if resource[:peer_address]
    self.peer_link = resource[:peer_link] if resource[:peer_link]
    self.enable = resource[:enable] if resource[:enable]
    self.interfaces = resource[:interfaces] if resource[:interfaces]
  end

  def destroy
    eapi.config('no mlag configuration')
    @property_hash = { name: resource[:name],  ensure: :absent }
  end

  def flush
    flush_local_interface
    flush_peer_address
    flush_peer_link
    flush_interfaces
    flush_enable
    @property_hash = resource.to_hash
  end

  def flush_local_interface
    value = @property_flush[:local_interface]
    return nil unless value
    eapi.config(["mlag configuration", "local-interface #{value}"])
  end
  
  def flush_peer_address
    value = @property_flush[:peer_address]
    return nil unless value
    eapi.config(["mlag configuration", "peer-address #{value}"])
  end
  
  def flush_peer_link
    value = @property_flush[:peer_link]
    return nil unless value
    eapi.config(["mlag configuration", "peer-link #{value}"])
  end
  
  def flush_enable
    value = @property_flush[:enable]
    return nil unless value
    state = value ? 'no shutdown' : 'shutdown'
    eapi.config(["mlag configuration", state])
  end

  def flush_interfaces
    values = @property_flush[:interfaces]
    return nil unless values
    values.each do |intf, id|
      eapi.config(["interface #{intf}", "mlag #{id}"])
    end
  end
end

