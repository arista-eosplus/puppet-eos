#
# Copyright (c) 2015, Arista Networks, Inc.
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

Puppet::Type.type(:eos_bgp_neighbor).provide(:eos) do
  # Create methods that set the @property_hash for the #flush method
  mk_resource_methods

  # Mix in the api as instance methods
  include PuppetX::Eos::EapiProviderMixin

  # Mix in the api as class methods
  extend PuppetX::Eos::EapiProviderMixin

  def self.instances
    entries = node.api('bgp').neighbors.getall
    return [] if !entries || entries.empty?
    entries.each_with_object([]) do |(neigh_name, attrs), arry|
      provider_hash = { name: neigh_name, ensure: :present }
      provider_hash[:peer_group] = attrs[:peer_group] if attrs[:peer_group]
      provider_hash[:remote_as] = attrs[:remote_as] if attrs[:remote_as]
      provider_hash[:send_community] = \
        attrs[:send_community] ? :enable : :disable
      provider_hash[:next_hop_self] = \
        attrs[:next_hop_self] ? :enable : :disable
      if attrs[:route_map_in]
        provider_hash[:route_map_in] = attrs[:route_map_in]
      end
      if attrs[:route_map_out]
        provider_hash[:route_map_out] = attrs[:route_map_out]
      end
      provider_hash[:description] = attrs[:description] if attrs[:description]
      provider_hash[:enable] = attrs[:shutdown] ? :false : :true
      arry << new(provider_hash)
    end
  end

  def peer_group=(value)
    node.api('bgp').neighbors.set_peer_group(resource[:name], value: value)
    @property_hash[:peer_group] = value
  end

  def remote_as=(value)
    node.api('bgp').neighbors.set_remote_as(resource[:name], value: value)
    @property_hash[:remote_as] = value
  end

  def send_community=(value)
    val = value == :enable ? true : false
    node.api('bgp').neighbors.set_send_community(resource[:name], enable: val)
    @property_hash[:send_community] = value
  end

  def next_hop_self=(value)
    val = value == :enable ? true : false
    node.api('bgp').neighbors.set_next_hop_self(resource[:name], enable: val)
    @property_hash[:next_hop_self] = value
  end

  def route_map_in=(value)
    node.api('bgp').neighbors.set_route_map_in(resource[:name], value: value)
    @property_hash[:route_map_in] = value
  end

  def route_map_out=(value)
    node.api('bgp').neighbors.set_route_map_out(resource[:name], value: value)
    @property_hash[:route_map_out] = value
  end

  def description=(value)
    node.api('bgp').neighbors.set_description(resource[:name], value: value)
    @property_hash[:description] = value
  end

  def enable=(value)
    val = value == :true ? true : false
    node.api('bgp').neighbors.set_shutdown(resource[:name], enable: val)
    @property_hash[:enable] = value
  end

  def exists?
    @property_hash[:ensure] == :present
  end

  def create
    node.api('bgp').neighbors.create(resource[:name])
    @property_hash = { name: resource[:name], ensure: :present }

    self.peer_group = resource[:peer_group] if resource[:peer_group]
    self.remote_as = resource[:remote_as] if resource[:remote_as]
    self.send_community = resource[:send_community] if resource[:send_community]
    self.next_hop_self = resource[:next_hop_self] if resource[:next_hop_self]
    self.route_map_in = resource[:route_map_in] if resource[:route_map_in]
    self.route_map_out = resource[:route_map_out] if resource[:route_map_out]
    self.description = resource[:description] if resource[:description]
    self.enable = resource[:enable] if resource[:enable]
  end

  def destroy
    node.api('bgp').neighbors.delete(resource[:name])
    @property_hash = { name: resource[:name], ensure: :absent }
  end
end
