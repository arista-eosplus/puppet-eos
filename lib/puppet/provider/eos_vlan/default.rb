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

Puppet::Type.type(:eos_vlan).provide(:eos) do

  # Create methods that set the @property_hash for the #flush method
  mk_resource_methods

  # Mix in the api as instance methods
  include PuppetX::Eos::EapiProviderMixin
  # Mix in the api as class methods
  extend PuppetX::Eos::EapiProviderMixin

  def self.instances
    resp = eapi.enable('show vlan')
    vlans = resp.first['vlans']

    resp = eapi.enable('show vlan trunk group')
    trunks = resp.first['trunkGroups'] 

    vlans.map do |name, attr_hash|
      provider_hash = { name: name, vlanid: name, ensure: :present }
      provider_hash[:vlan_name] = attr_hash['name']
      enable = attr_hash['status'] == 'active' ? :true : :false
      provider_hash[:enable] = enable
      provider_hash[:trunk_groups] = trunks[name]
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

  def enable=(val)
    @property_flush[:enable] = val
  end

  def vlan_name=(val)
    @property_flush[:vlan_name] = val
  end

  def trunk_groups=(val)
    @property_flush[:trunk_groups] = val
  end

  def exists?
    @property_hash[:ensure] == :present
  end

  def create
    vid = resource[:vlanid]
    eapi.config("vlan #{vid}")
    @property_hash = { vlanid: vid, ensure: :present }
    self.enable = resource[:enable] if resource[:enable]
    self.vlan_name = resource[:vlan_name] if resource[:vlan_name]
    self.trunk_groups = resource[:trunk_groups] if resource[:trunk_groups]
  end

  def destroy
    vid = resource[:vlanid]
    eapi.config("no vlan #{vid}")
    @property_hash = { vlanid: vid, ensure: :absent }
  end

  def flush
    flush_enable_state
    flush_vlan_name
    flush_trunk_groups
    @property_hash = resource.to_hash
  end

  def flush_vlan_name
    value = @property_flush[:vlan_name]
    return nil unless value
    eapi.config(["vlan #{resource[:vlanid]}", "name #{value}"])
  end
 
  def flush_trunk_groups
    proposed = @property_flush[:trunk_groups]
    return nil unless proposed
    current = @property_hash[:trunk_groups]['names']
    id = resource[:vlanid]
    (current - proposed).each do |grp|
      eapi.config(["vlan #{id}", "no trunk group #{grp}"])
    end
    (proposed - current).each do |grp|
      eapi.config(["vlan #{id}", "trunk group #{grp}"])
    end
  end

  def flush_enable_state
    value = @property_flush[:enable]
    return nil unless value
    arg = value ? 'suspend' : 'active'
    eapi.config(["vlan #{resource[:vlanid]}", "state #{arg}"])
  end
end
