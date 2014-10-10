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

Puppet::Type.type(:eos_switchport).provide(:eos) do

  # Create methods that set the @property_hash for the #flush method
  mk_resource_methods

  # Mix in the api as instance methods
  include PuppetX::Eos::EapiProviderMixin
  # Mix in the api as class methods
  extend PuppetX::Eos::EapiProviderMixin

  def self.instances
    resp = eapi.enable('show interfaces')
    interfaces = resp.first['interfaces']

    interfaces.map do |name, attr_hash|
      resp = eapi.enable("show interfaces #{name} switchport", format: 'text')
      output = resp.first['output']
      provider_hash = { name: name }
      
      enabled = switchport_enabled(output) ? :present : :absent
      provider_hash[:ensure] = enabled 
      Puppet.debug("ENABLED #{enabled}")

      if enabled == :present
        mode = switchport_mode_to_value(output)
        case switchport_mode_to_value(output)
        when 'trunk'
          provider_hash[:mode] = :trunk
        when 'access'
          provider_hash[:mode] = :access
        end
        vlans = switchport_trunk_vlans_to_value(output)
        vlans = [] if vlans == 'ALL'
        Puppet.debug("VLANS #{vlans}")
        provider_hash[:trunk_allowed_vlans] = vlans
      #else
      #  provider_hash[:mode] = :access
      #  provider_hash[:trunk_allowed_vlans] = 'ALL'
      end
    
      Puppet.debug("HASH #{provider_hash}")

      new(provider_hash)
    end
  end

  def self.prefetch(resources)
    Puppet.debug("#{instances}")
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

  def mode=(val)
    @property_flush[:mode] = val
  end

  def trunk_allowed_vlans=(val)
    @property_flush[:trunk_allowed_vlans] = val
  end

  def exists?
    @property_hash[:ensure] == :present
  end

  def create
    id = resource[:name]
    eapi.config(["interface #{id}", "switchport"])
    @property_hash = { name: id, ensure: :present }
    self.mode = resource[:mode] if resource[:mode]
    self.trunk_allowed_vlans = resource[:trunk_allowed_vlans] if resource[:trunk_allowed_vlans]
  end

  def destroy
    id = resource[:name]
    eapi.config(["interface #{id}", "no switchport"])
    @property_hash = { name: id, ensure: :absent }
  end

  def flush
    flush_mode
    flush_trunk_allowed_vlans
    @property_hash = resource.to_hash
  end

  def flush_mode
    value = @property_flush[:mode]
    name = resource[:name]
    return nil unless value
    eapi.config(["interface #{name}", "switchport mode #{value}"])
  end

  def flush_trunk_allowed_vlans
    proposed = @property_flush[:trunk_allowed_vlans]
    return nil unless proposed
    name = resource[:name]
    current = @property_hash[:trunk_allowed_vlans]
    #current = [] if current == 'ALL' || current == 'NONE'
    current = []

    Puppet.debug("PROPOSED #{proposed}")
    Puppet.debug("CURRENT #{current}")

    eapi.config(["interface #{name}", "switchport trunk allowed vlan none"])

    #(current - proposed).each do |vid|
    #  eapi.config(["interface #{name}", "switchport trunk allowed vlan remove #{vid}"])
    #end
    (proposed - current).each do |vid|
      eapi.config(["interface #{name}", "switchport trunk allowed vlan add #{vid}"])
    end
  end
end

