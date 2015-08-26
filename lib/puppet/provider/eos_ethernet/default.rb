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

Puppet::Type.type(:eos_ethernet).provide(:eos) do
  # Create methods that set the @property_hash for the #flush method
  mk_resource_methods

  # Mix in the api as instance methods
  include PuppetX::Eos::EapiProviderMixin

  # Mix in the api as class methods
  extend PuppetX::Eos::EapiProviderMixin

  def self.instances
    interfaces = node.api('interfaces').getall
    return [] if !interfaces || interfaces.empty?
    interfaces.each_with_object([]) do |(name, attrs), arry|
      next unless attrs[:type] == 'ethernet'
      provider_hash = { name: name }
      provider_hash[:enable] = attrs[:shutdown] ? :false : :true
      provider_hash[:description] = attrs[:description]
      provider_hash[:flowcontrol_send] = attrs[:flowcontrol_send].to_sym
      provider_hash[:flowcontrol_receive] = attrs[:flowcontrol_receive].to_sym
      arry << new(provider_hash)
    end
  end

  def create
    node.api('interfaces').create(resource[:name])
    @property_hash = { name: resource[:name], ensure: :present }
    self.enable = resource[:enable] if resource[:enable]
    self.description = resource[:description] if resource[:description]
    self.flowcontrol_send = resource[:flowcontrol_send] \
                            if resource[:flowcontrol_send]
    self.flowcontrol_receive = resource[:flowcontrol_receive] \
                               if resource[:flowcontrol_receive]
  end

  def destroy
    node.api('interfaces').delete(resource[:name])
    @property_hash = { name: resource[:name], ensure: :absent }
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

  def flowcontrol_send=(val)
    node.api('interfaces').set_flowcontrol_send(resource[:name], value: val)
    @property_hash[:flowcontrol_send] = val
  end

  def flowcontrol_receive=(val)
    node.api('interfaces').set_flowcontrol_receive(resource[:name], value: val)
    @property_hash[:flowcontrol_receive] = val
  end
end
