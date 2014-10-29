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

Puppet::Type.type(:eos_interface).provide(:eos) do

  # Create methods that set the @property_hash for the #flush method
  mk_resource_methods

  # Mix in the api as instance methods
  include PuppetX::Eos::EapiProviderMixin

  # Mix in the api as class methods
  extend PuppetX::Eos::EapiProviderMixin

  def self.instances
    result = eapi.get
    flowcontrols = result['interfaceFlowControls']
    result['interfaces'].map do |name, attrs|
      provider_hash = { name: name }
      state = attrs['interfaceStatus'] == 'disabled' ? :false : :true
      provider_hash[:enable] = state
      provider_hash[:description] = attrs['description']
      provider_hash[:flowcontrol_send] = flowcontrols[name]['txAdminState'].to_sym
      provider_hash[:flowcontrol_receive] = flowcontrols[name]['rxAdminState'].to_sym
      new(provider_hash)
    end
  end

  def initialize(resource = {})
    super(resource)
    @property_flush = {}
  end

  def create
    eapi.Interface.create(resource[:name])
    @property_hash = { name: resource[:name], ensure: :present }
    self.enable = resource[:enable] if resource[:enable]
    self.description = resource[:description] if resource[:description]
    self.flowcontrol_send = resource[:flowcontrol_send] if resource[:flowcontrol_send]
    self.flowcontrol_receive = resource[:flowcontrol_receive] if resource[:flowcontrol_receive]
  end

  def destroy
    eapi.Interface.delete(resoruce[:name])
  end

  def enable=(val)
    eapi.Interface.set_shutdown(resource[:name], value: val)
    @property_flush[:enable] = val
  end

  def description=(val)
    eapi.Interface.set_description(resource[:name], val)
    @property_hash[:description] = val
  end

  def flowcontrol_send=(val)
    eapi.Interface.set_flowcontrol(resource[:name], 'send', val)
    @property_hash[:flowcontrol_send] = val
  end

  def flowcontrol_receive=(val)
    eapi.Interface.set_flowcontrol(resource[:name], 'receive', val)
    @property_hash[:flowcontrol_receive] = val
  end
end
