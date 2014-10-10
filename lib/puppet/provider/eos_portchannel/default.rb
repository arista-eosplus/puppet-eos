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

Puppet::Type.type(:eos_portchannel).provide(:eos) do

  # Create methods that set the @property_hash for the #flush method
  mk_resource_methods

  # Mix in the api as instance methods
  include PuppetX::Eos::EapiProviderMixin
  # Mix in the api as class methods
  extend PuppetX::Eos::EapiProviderMixin

  def self.instances
    resp = eapi.enable('show interfaces')
    result = resp.first['interfaces']
    result = result.each_with_object([]) { |(k, v), array| array << v if /^Port/.match(v['name']) }
    
    result.map do |attr_hash|
      name = attr_hash['name']
      provider_hash = { name: name, ensure: :present }
      
      members = portchannel_members_to_value(name)
      provider_hash[:members] = members
      
      if !members.empty?
        provider_hash[:lacp_mode] = portchannel_lacp_mode_to_value(members[0])
      end

      if attr_hash['fallbackEnabled']
        case attr_hash['fallbackEnabledType']
        when 'fallbackStatic'
          fallback = 'static'
        when 'fallbackIndividual'
          fallback = 'individual'
        end
      end

      provider_hash[:lacp_fallback] = fallback || ''
      provider_hash[:lacp_timeout] = attr_hash['fallbackTimeout'] 

      new(provider_hash)
    end

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

  def lacp_mode=(val)
    @property_flush[:lacp_mode] = val
  end

  def members=(val)
    @property_flush[:members] = val
  end

  def lacp_fallback=(val)
    @property_flush[:lacp_fallback] = val
  end
  
  def lacp_timeout=(val)
    @property_flush[:lacp_timeout] = val
  end

  def exists?
    @property_hash[:ensure] == :present
  end

  def create
    id = resource[:name]
    eapi.config(["interface #{id}"])
    @property_hash = { name: id, ensure: :present }
    self.lacp_mode = resource[:lacp_mode] if resource[:lacp_mode]
    self.members = resource[:members] if resource[:members]
    self.lacp_fallback = resource[:lacp_fallback] if resource[:lacp_fallback]
    self.lacp_timeout = resource[:lacp_timeout] if resource[:lacp_timeout]
  end

  def destroy
    id = resource[:id]
    eapi.config("no interface #{id}")
    @property_hash = { name: id, ensure: :absent }
  end

  def flush
    flush_lacp_mode
    flush_members
    flush_lacp_fallback
    flush_lacp_timeout
    @property_hash = resource.to_hash
  end

  def flush_lacp_mode
    value = @property_flush[:lacp_mode]
    return nil unless value
    name = resource[:name]
    grp = /\d+(\/\d+)*/.match(name)[0]
    members = resource[:members]
    resource[:members].each do |member|
      eapi.config(["interface #{member}", "no channel-group", "channel-group #{grp} mode #{value}"])
    end
  end

  def flush_members
    proposed = @property_flush[:members]
    return nil unless proposed
    name = resource[:name]
    current = @property_hash[:members]
    lacp = resource[:lacp_mode]
    grp = /\d+(\/\d+)*/.match(name)[0]

    (current - proposed).each do |member|
      eapi.config(["interface #{member}", "no channel-group"])
    end
    (proposed - current).each do |member|
      eapi.config(["interface #{member}", "channel-group #{grp} mode #{lacp}"])
    end
  end

  def flush_lacp_fallback
    value = @property_flush[:lacp_fallback]
    return nil unless value
    name = resource[:name]
    eapi.config(["interface #{name}", "port-channel lacp fallback #{value}"])
  end
  
  def flush_lacp_timeout
    value = @property_flush[:lacp_timeout]
    return nil unless value
    name = resource[:name]
    eapi.config(["interface #{name}", "port-channel lacp fallback timeout #{value}"])
  end

end

