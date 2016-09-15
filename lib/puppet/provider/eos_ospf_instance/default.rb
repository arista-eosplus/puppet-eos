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

Puppet::Type.type(:eos_ospf_instance).provide(:eos) do
  desc 'Manage OSPF instances on EOS. Requires rbeapi rubygem.'
  confine operatingsystem: [:AristaEOS] unless ENV['RBEAPI_CONNECTION']
  confine feature: :rbeapi

  # Create methods that set the @property_hash for the #flush method
  mk_resource_methods

  # Mix in the api as instance methods
  include PuppetX::Eos::EapiProviderMixin

  # Mix in the api as class methods
  extend PuppetX::Eos::EapiProviderMixin

  def self.instances
    result = node.api('ospf').getall
    return [] if !result || result.empty?
    result.map do |(name, attrs)|
      next if name.eql? "interfaces"
      provider_hash = { name: name, ensure: :present }
      provider_hash[:router_id] = attrs[:router_id]
      provider_hash[:max_lsa] = attrs[:max_lsa]
      provider_hash[:maximum_paths] = attrs[:maximum_paths]
      value = attrs[:passive_interface_default].to_s.to_sym
      provider_hash[:passive_interface_default] = value
      provider_hash[:active_interfaces] = attrs[:active_interfaces]
      provider_hash[:passive_interfaces] = attrs[:passive_interfaces]
      new(provider_hash)
    end
  end

  def router_id=(val)
    node.api('ospf').set_router_id(resource[:name], :value => val)
    @property_hash[:router_id] = val
  end

  def max_lsa=(val)
    node.api('ospf').set_max_lsa(resource[:name], :value => val)
    @property_hash[:max_lsa] = val
  end

  def maximum_paths=(val)
    node.api('ospf').set_maximum_paths(resource[:name], :value => val)
    @property_hash[:maximum_paths] = val
  end

  def passive_interfaces=(val)
    node.api('ospf').set_passive_interfaces(resource[:name], :value => val)
    @property_hash[:passive_interfaces] = val
  end

  def active_interfaces=(val)
    node.api('ospf').set_active_interfaces(resource[:name], :value => val)
    @property_hash[:active_interfaces] = val
  end

  def passive_interface_default=(val)
    value = val == :true
    node.api('ospf').set_passive_interface_default(resource[:name], :value => value)
    @property_hash[:passive_interface_default] = val
  end

  def exists?
    @property_hash[:ensure] == :present
  end

  def create
    node.api('ospf').create(resource[:name])
    @property_hash = { name: resource[:name], ensure: :present }
    self.router_id = resource[:router_id] if resource[:router_id]
    self.max_lsa = resource[:max_lsa] if resource[:max_lsa]
    self.maximum_paths = resource[:maximum_paths] if resource[:maximum_paths]
    self.passive_interface_default = resource[:passive_interface_default] if resource[:passive_interface_default]
    self.passive_interfaces = resource[:passive_interfaces] if (resource[:passive_interfaces] && resource[:passive_interface_default])
    self.active_interfaces = resource[:active_interfaces] if (resource[:active_interfaces] && resource[:passive_interface_default])
  end

  def destroy
    node.api('ospf').delete(resource[:name])
    @property_hash = { name: resource[:name], ensure: :absent }
  end
end