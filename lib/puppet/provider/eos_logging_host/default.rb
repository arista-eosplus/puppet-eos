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

Puppet::Type.type(:eos_logging_host).provide(:eos) do
  desc 'Manage logging hosts on EOS.  Requires rbeapi rubygem.'
  confine operatingsystem: [:AristaEOS] unless ENV['RBEAPI_CONNECTION']
  confine feature: :rbeapi

  # Create methods that set the @property_hash for the #flush method
  mk_resource_methods

  # Mix in the api as instance methods
  include PuppetX::Eos::EapiProviderMixin

  # Mix in the api as class methods
  extend PuppetX::Eos::EapiProviderMixin

  def self.instances
    result = node.api('logging').get
    result[:hosts].each_with_object([]) do |(host, attr), arry|
      provider_hash = { :name => host, :ensure => :present }
      provider_hash[:port] = attr[:port]
      provider_hash[:protocol] = attr[:protocol]
      provider_hash[:vrf] = attr[:vrf] if attr[:vrf]
      arry << new(provider_hash)
    end
  end

  def initialize(resource = {})
    super(resource)
    @property_flush = {}
  end

  def exists?
    @property_hash[:ensure] == :present
  end

  def port=(value)
    @property_flush[:port] = value
  end

  def protocol=(value)
    @property_flush[:protocol] = value
  end

  def vrf=(value)
    @property_flush[:vrf] = value
  end

  def create
    @property_flush = resource.to_hash
    @property_flush[:ensure] = :present
  end

  def destroy
    @property_flush = resource.to_hash
    @property_flush[:ensure] = :absent
  end

  def flush
    @property_hash.merge!(@property_flush)
    opts = {}
    opts[:port] = @property_hash[:port] ? @property_hash[:port] : 514
    protocol = @property_hash[:protocol]
    opts[:protocol] = protocol ? protocol : :udp
    opts[:vrf] = @property_hash[:vrf] if @property_hash[:vrf]

    if @property_flush[:ensure] == :absent
      node.api('logging').remove_host(resource[:name], opts)
      @property_hash = { name: resource[:name], ensure: :absent }
      return
    end

    node.api('logging').add_host(resource[:name], opts)
    @property_flush = {}
  end
end
