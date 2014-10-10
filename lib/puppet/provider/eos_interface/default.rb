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

Puppet::Type.type(:eos_interface).provide(:eos) do

  # Create methods that set the @property_hash for the #flush method
  mk_resource_methods

  # Mix in the api as instance methods
  include PuppetX::Eos::EapiProviderMixin
  # Mix in the api as class methods
  extend PuppetX::Eos::EapiProviderMixin

  def self.instances
    interfaces = eapi.enable('show interfaces')
    interfaces = interfaces.first['interfaces']

    interfaces.map do |name, attr_hash|
      provider_hash = { name: name }
      state = attr_hash['interfaceStatus'] == 'disabled' ? :false : :true
      provider_hash[:enable] = state
      provider_hash[:description] = attr_hash['description']
      provider_hash.merge! flowcontrol_to_value(name)
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

  def description=(val)
    @property_flush[:description] = val
  end

  def flowcontrol_send=(val)
    @property_flush[:flowcontrol_send] = val
  end

  def flowcontrol_receive=(val)
    @property_flush[:flowcontrol_receive] = val
  end

  def flush
    flush_enable
    flush_description
    flush_flowcontrol
    @property_hash = resource.to_hash
  end

  def flush_description
    description = @property_flush[:description]
    return nil unless description
    eapi.config(["interface #{resource[:name]}", "description #{description}"])
  end

  def flush_enable
    value = @property_flush[:enable]
    return nil unless value
    arg = value ? 'no shutdown' : 'shutdown'
    eapi.config(["interface #{resource[:name]}", arg])
  end

  def flush_flowcontrol
    [:flowcontrol_send, :flowcontrol_receive].each do |param|
      value = @property_flush[param]
      cmds = []
      case param
      when :flowcontrol_send
          cmds = ["flowcontrol send #{value}"] if !value.nil?
      when :flowcontrol_receive
          cmds = ["flowcontrol receive #{value}"] if !value.nil?
      end
      return nil unless cmds
      cmds.insert(0, "interface #{resource[:name]}") 
      eapi.config(cmds)
    end
  end
end
