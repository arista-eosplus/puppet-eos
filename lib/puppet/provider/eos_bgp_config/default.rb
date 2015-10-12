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

Puppet::Type.type(:eos_bgp_config).provide(:eos) do
  # Create methods that set the @property_hash for the #flush method
  mk_resource_methods

  # Mix in the api as instance methods
  include PuppetX::Eos::EapiProviderMixin

  # Mix in the api as class methods
  extend PuppetX::Eos::EapiProviderMixin

  def self.instances
    attrs = node.api('bgp').get
    return [] if !attrs || attrs.empty?
    name = attrs[:bgp_as]
    provider_hash = { name: name, bgp_as: name, ensure: :present }
    provider_hash[:enable] = attrs[:shutdown] ? :false : :true
    provider_hash[:router_id] = attrs[:router_id] if attrs[:router_id]
    if attrs[:maximum_paths]
      provider_hash[:maximum_paths] = attrs[:maximum_paths]
    end
    if attrs[:maximum_ecmp_paths]
      provider_hash[:maximum_ecmp_paths] = attrs[:maximum_ecmp_paths]
    end
    [new(provider_hash)]
  end

  def initialize(resource = {})
    super(resource)
    @property_flush = {}
  end

  def enable=(value)
    @property_flush[:enable] = value
  end

  def router_id=(value)
    @property_flush[:router_id] = value
  end

  def maximum_paths=(value)
    @property_flush[:maximum_paths] = value
  end

  def maximum_ecmp_paths=(value)
    @property_flush[:maximum_ecmp_paths] = value
  end

  def exists?
    @property_hash[:ensure] == :present
  end

  def create
    @property_flush = resource.to_hash
  end

  def destroy
    @property_flush = resource.to_hash
  end

  def flush
    api = node.api('bgp')
    @property_hash.merge!(@property_flush)

    case @property_hash[:ensure]
    when :present
      # The :enable attribute stores :true or :false (i.e. symbols)
      # The rbeapi library expects a boolean value. Modify the :enable
      # value passed into the create call to store a boolean value.
      if @property_flush.key?(:enable)
        enable = @property_flush[:enable]
        @property_flush[:enable] = (enable == :true ? true : false)
      end
      maximum_ecmp_paths = @property_flush.key?(:maximum_ecmp_paths)
      desired_maximum = @property_hash.key?(:maximum_paths)
      if maximum_ecmp_paths && desired_maximum
        @property_flush[:maximum_paths] = @property_hash[:maximum_paths]
      end
      @property_flush.delete(:provider)
      @property_flush.delete(:ensure)
      @property_flush.delete(:loglevel)
      api.create(resource[:name], @property_flush)
    when :absent
      api.delete
    end
  end
end
