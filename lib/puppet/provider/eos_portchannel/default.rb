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
require 'puppet_x/eos/provider'

Puppet::Type.type(:eos_portchannel).provide(:eos) do

  # Create methods that set the @property_hash for the #flush method
  mk_resource_methods

  # Mix in the api as instance methods
  include PuppetX::Eos::EapiProviderMixin

  # Mix in the api as class methods
  extend PuppetX::Eos::EapiProviderMixin

  def self.instances
    eapi.Portchannel.getall.map do |attrs|
      provider_hash = { name: attrs['name'], ensure: :present }
      provider_hash[:lacp_mode] = attrs['lacp_mode'].to_sym
      provider_hash[:members] = attrs['members']
      provider_hash[:lacp_fallback] = attrs['lacp_fallback'].to_sym
      provider_hash[:lacp_timeout] = attrs['lacp_timeout']
      new(provider_hash)
    end
  end

  def lacp_mode=(val)
    eapi.Portchannel.set_lacp_mode(resource[:name], value: val)
    @property_hash[:lacp_mode] = val
  end

  def members=(val)
    eapi.Portchannel.set_members(resource[:name], val)
    @property_hash[:members] = val
  end

  def lacp_fallback=(val)
    eapi.Portchannel.set_lacp_fallback(resource[:name], value: val)
    @property_hash[:lacp_fallback] = val
  end

  def lacp_timeout=(val)
    eapi.Portchannel.set_lacp_timeout(resource[:name], value: val)
    @property_hash[:lacp_timeout] = val
  end

  def exists?
    @property_hash[:ensure] == :present
  end

  def create
    eapi.Portchannel.create(resource[:name])
    @property_hash = { name: resource[:name], ensure: :present }
    self.lacp_mode = resource[:lacp_mode] if resource[:lacp_mode]
    self.members = resource[:members] if resource[:members]
    self.lacp_fallback = resource[:lacp_fallback] if resource[:lacp_fallback]
    self.lacp_timeout = resource[:lacp_timeout] if resource[:lacp_timeout]
  end

  def destroy
    eapi.Portchannel.delete(resource[:name])
    @property_hash = { name: resource[:name], ensure: :absent }
  end
end
