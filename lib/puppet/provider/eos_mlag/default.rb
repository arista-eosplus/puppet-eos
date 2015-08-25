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

Puppet::Type.type(:eos_mlag).provide(:eos) do
  # Create methods that set the @property_hash for the #flush method
  mk_resource_methods

  # Mix in the api as instance methods
  include PuppetX::Eos::EapiProviderMixin

  # Mix in the api as class methods
  extend PuppetX::Eos::EapiProviderMixin

  def self.instances
    api = node.api('mlag').get
    result = api[:global]
    provider_hash = { name: 'settings', ensure: :present }
    provider_hash.merge!(result)
    enable = result[:shutdown] ? :false : :true
    provider_hash[:enable] = enable
    [new(provider_hash)]
  end

  def domain_id=(val)
    node.api('mlag').set_domain_id(value: val)
    @property_hash[:domain_id] = val
  end

  def local_interface=(val)
    node.api('mlag').set_local_interface(value: val)
    @property_hash[:local_interface] = val
  end

  def peer_address=(val)
    node.api('mlag').set_peer_address(value: val)
    @property_hash[:peer_address] = val
  end

  def peer_link=(val)
    node.api('mlag').set_peer_link(value: val)
    @property_hash[:peer_link] = val
  end

  def enable=(val)
    value = val == :true ? true : false
    node.api('mlag').set_shutdown(enable: value)
    @property_hash[:enable] = val
  end

  def exists?
    @property_hash[:ensure] == :present
  end
end
