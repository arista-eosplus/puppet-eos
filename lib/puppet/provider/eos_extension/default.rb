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

Puppet::Type.type(:eos_extension).provide(:eos) do

  # Create methods that set the @property_hash for the #flush method
  mk_resource_methods

  # Mix in the api as instance methods
  include PuppetX::Eos::EapiProviderMixin

  # Mix in the api as class methods
  extend PuppetX::Eos::EapiProviderMixin

  def self.instances
    eapi.Extension.get.map do |name, hsh|
      provider_hash = { name: name, ensure: :present }
      value = eapi.Extension.autoload?(name) ? :true : :false
      provider_hash[:autoload] = value
      Puppet.debug(provider_hash)
      new(provider_hash)
    end
  end

  def initialize(resource = {})
    super(resource)
    @property_flush = {}
  end

  def force=(val)
    @property_flush[:force] = val
  end

  def autoload=(val)
    @property_flush[:autoload] = val
  end

  def exists?
    @property_hash[:ensure] == :present
  end

  def flush
    flush_autoload
    @property_hash = resource.to_hash
  end

  def create
    url = resource[:name]
    url = url.insert(0, "#{resource[:source_url]}/") if resource[:source_url]
    eapi.Extension.install(url, resource[:force])
    @property_hash = { name: resource[:name], ensure: :present }
    self.autoload = resource[:autoload] if resource[:autoload]
  end

  def destroy
    eapi.Extension.delete(resource[:name])
    @property_hash = { name: resource[:name], ensure: :absent }
  end

  def flush_autoload
    value = @property_flush[:autoload]
    return nil unless value
    name = resource[:name]
    force = @property_flush[:force] || false
    eapi.Extension.set_autoload(value, name, force)
  end
end
