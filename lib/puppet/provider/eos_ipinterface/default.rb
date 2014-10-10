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

Puppet::Type.type(:eos_ipinterface).provide(:eos) do

  # Create methods that set the @property_hash for the #flush method
  mk_resource_methods

  # Mix in the api as instance methods
  include PuppetX::Eos::EapiProviderMixin
  # Mix in the api as class methods
  extend PuppetX::Eos::EapiProviderMixin

  def self.instances
    resp = eapi.enable('show ip interface')
    result = resp.first['interfaces']
    
    result.map do |name, attr_hash|
      provider_hash = { name: name, ensure: :present }
      addr = attr_hash['interfaceAddress']['primaryIp']['address']
      mask = attr_hash['interfaceAddress']['primaryIp']['maskLen']
      provider_hash[:address] = "#{addr}/#{mask}" if !addr.nil? || !mask.nil?
      Puppet.debug("EOS_IPINTERFACE #{provider_hash}")
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

  def address=(val)
    @property_flush[:address] = val
  end

  def exists?
    @property_hash[:ensure] == :present
  end

  def create
    id = resource[:name]
    commands = ["interface #{id}"]
    commands << 'no switchport' if /^[Eth|Port]/.match(id)
    eapi.config(commands)
    @property_hash = { name: id, ensure: :present }
    self.address = resource[:address] if resource[:address]
  end

  def destroy
    id = resource[:name]
    eapi.config(["interface #{id}", "no ip address"])
    @property_hash = { name: id, ensure: :absent }
  end

  def flush
    flush_address
    @property_hash = resource.to_hash
  end

  def flush_address
    value = @property_flush[:address]
    id = resource[:name]
    return nil unless value
    eapi.config(["interface #{id}", "ip address #{value}"])
  end

end

