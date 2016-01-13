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

Puppet::Type.type(:eos_mlag_interface).provide(:eos) do
  desc 'Manage MLAG interface configuration on EOS.  Requires rbeapi rubygem.'
  confine operatingsystem: [:AristaEOS] unless ENV['RBEAPI_CONNECTION']
  confine feature: :rbeapi

  # Create methods that set the @property_hash for the #flush method
  mk_resource_methods

  # Mix in the api as instance methods
  include PuppetX::Eos::EapiProviderMixin

  # Mix in the api as class methods
  extend PuppetX::Eos::EapiProviderMixin

  def self.instances
    mlag = node.api('mlag').get
    return [] if !mlag || mlag.empty?
    mlag[:interfaces].map do |(name, attrs)|
      provider_hash = { name: name, ensure: :present,
                        mlag_id: attrs[:mlag_id] }
      new(provider_hash)
    end
  end

  def initialize(resource = {})
    super(resource)
    @property_flush = {}
  end

  def mlag_id=(value)
    node.api('mlag').set_mlag_id(resource[:name], value: value)
    @property_hash[:mlag_id] = value
  end

  def exists?
    @property_hash[:ensure] == :present
  end

  def create
    @property_hash = resource.to_hash
  end

  def destroy
    @property_hash = resource.to_hash
  end

  def flush
    api = node.api('mlag')
    desired_state = @property_hash.merge!(@property_flush)
    case desired_state[:ensure]
    when :present
      api.set_mlag_id(desired_state[:name], value: desired_state[:mlag_id])
    when :absent
      api.set_mlag_id(desired_state[:name], enable: false)
    end
    @property_hash = desired_state
  end
end
