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

Puppet::Type.type(:eos_vxlan).provide(:eos) do
  # Create methods that set the @property_hash for the #flush method
  mk_resource_methods

  # Mix in the api as instance methods
  include PuppetX::Eos::EapiProviderMixin

  # Mix in the api as class methods
  extend PuppetX::Eos::EapiProviderMixin

  def self.instances
    interfaces = node.api('interfaces').getall
    interfaces.each_with_object([]) do |(name, attrs), arry|
      next unless attrs[:type] == 'vxlan'
      provider_hash = { name: name, ensure: :present }
      provider_hash.merge!(attrs)
      provider_hash[:enable] = attrs[:shutdown] ? :false : :true
      arry << new(provider_hash)
    end
  end

  def source_interface=(val)
    node.api('interfaces').set_source_interface(resource[:name], value: val)
    @property_hash[:source_interface] = val
  end

  def multicast_group=(val)
    node.api('interfaces').set_multicast_group(resource[:name], value: val)
    @property_hash[:multicast_group] = val
  end

  def udp_port=(val)
    node.api('interfaces').set_udp_port(resource[:name], value: val)
    @property_hash[:udp_port] = val
  end

  def enable=(val)
    value = val == :true ? true : false
    node.api('interfaces').set_shutdown(resource[:name], enable: value)
    @property_hash[:enable] = val
  end

  def description=(val)
    node.api('interfaces').set_description(resource[:name], value: val)
    @property_hash[:description] = val
  end

  def exists?
    @property_hash[:ensure] == :present
  end

  def create
    node.api('interfaces').create(resource[:name])
    @property_hash = { name: resource[:name], ensure: :present }
    self.enable = resource[:enable] if resource[:enable]
    self.description = resource[:description] if resource[:description]
    self.udp_port = resource[:udp_port] if resource[:udp_port]
    self.source_interface = resource[:source_interface] \
                            if resource[:source_interface]
    self.multicast_group = resource[:multicast_group] \
                           if resource[:multicast_group]
  end

  def destroy
    node.api('interfaces').delete(resource[:name])
    @property_hash = { name: resource[:name], ensure: :absent }
  end
end
