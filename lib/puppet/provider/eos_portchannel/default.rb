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

Puppet::Type.type(:eos_portchannel).provide(:eos) do
  desc 'Manage port-channel interfaces on EOS.  Requires rbeapi rubygem.'
  confine operatingsystem: [:AristaEOS] unless ENV['RBEAPI_CONNECTION']
  confine feature: :rbeapi

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
      next unless attrs[:type] == 'portchannel'
      provider_hash = { name: name, ensure: :present }
      provider_hash.merge!(attrs)
      provider_hash[:enable] = attrs[:shutdown] ? :false : :true
      provider_hash[:lacp_mode] = attrs[:lacp_mode].to_sym
      provider_hash[:lacp_fallback] = attrs[:lacp_fallback].to_sym
      Puppet.debug("#{provider_hash}")
      arry << new(provider_hash)
    end
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

  def lacp_mode=(val)
    node.api('interfaces').set_lacp_mode(resource[:name], val.to_s)
    @property_hash[:lacp_mode] = val
  end

  def members=(val)
    node.api('interfaces').set_members(resource[:name], val)
    @property_hash[:members] = val
  end

  def minimum_links=(val)
    node.api('interfaces').set_minimum_links(resource[:name], value: val)
    @property_hash[:minimum_links] = val
  end

  def lacp_fallback=(val)
    if val.to_s.eql? 'disabled'
      node.api('interfaces').set_lacp_fallback(resource[:name], enable: false)
    else
      node.api('interfaces').set_lacp_fallback(resource[:name], value: val.to_s)
    end
    @property_hash[:lacp_fallback] = val
  end

  def lacp_timeout=(val)
    node.api('interfaces').set_lacp_timeout(resource[:name], value: val)
    @property_hash[:lacp_timeout] = val
  end

  def exists?
    @property_hash[:ensure] == :present
  end

  def create
    node.api('interfaces').create(resource[:name])
    @property_hash = { name: resource[:name], ensure: :present }
    self.enable = resource[:enable] if resource[:enable]
    self.description = resource[:description] if resource[:description]
    self.lacp_mode = resource[:lacp_mode] if resource[:lacp_mode]
    self.members = resource[:members] if resource[:members]
    self.lacp_fallback = resource[:lacp_fallback] if resource[:lacp_fallback]
    self.lacp_timeout = resource[:lacp_timeout] if resource[:lacp_timeout]
    self.minimum_links = resource[:minimum_links] if resource[:minimum_links]
  end

  def destroy
    node.api('interfaces').delete(resource[:name])
    @property_hash = { name: resource[:name], ensure: :absent }
  end
end
