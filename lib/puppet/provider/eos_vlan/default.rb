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
require 'pathname'

module_lib = Pathname.new(__FILE__).parent.parent.parent.parent
require File.join module_lib, 'puppet_x/eos/provider'

Puppet::Type.type(:eos_vlan).provide(:eos) do
  unless ENV['RBEAPI_CONNECTION']
    confine :operatingsystem => [:AristaEOS]
  end
  confine :feature => :rbeapi

  # Create methods that set the @property_hash for the #flush method
  mk_resource_methods

  # Mix in the api as instance methods
  include PuppetX::Eos::EapiProviderMixin

  # Mix in the api as class methods
  extend PuppetX::Eos::EapiProviderMixin

  def self.instances
    vlans = node.api('vlans').getall
    return [] if !vlans || vlans.empty?
    vlans.map do |name, attrs|
      provider_hash = { name: name, vlanid: name, ensure: :present }
      provider_hash[:vlan_name] = attrs[:name]
      provider_hash[:enable] = attrs[:state] == 'active' ? :true : :false
      provider_hash[:trunk_groups] = attrs[:trunk_groups]
      new(provider_hash)
    end
  end

  def enable=(value)
    val = value == :true ? 'active' : 'suspend'
    node.api('vlans').set_state(resource[:vlanid], value: val)
    @property_hash[:enable] = value
  end

  def vlan_name=(value)
    node.api('vlans').set_name(resource[:vlanid], value: value)
    @property_hash[:vlan_name] = value
  end

  def trunk_groups=(value)
    node.api('vlans').set_trunk_group(resource[:vlanid], value: value)
    @property_hash[:trunk_groups] = value
  end

  def exists?
    @property_hash[:ensure] == :present
  end

  def create
    node.api('vlans').create(resource[:name])
    @property_hash = { name: resource[:name], vlanid: resource[:vlanid],
                       ensure: :present }

    self.enable = resource[:enable] if resource[:enable]
    self.vlan_name = resource[:vlan_name] if resource[:vlan_name]
    self.trunk_groups = resource[:trunk_groups] if resource[:trunk_groups]
  end

  def destroy
    node.api('vlans').delete(resource[:vlanid])
    @property_hash = { vlanid: resource[:vlanid], ensure: :absent }
  end
end
