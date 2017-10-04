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

Puppet::Type.type(:eos_acl_entry).provide(:eos) do
  desc 'Manage IP access-lists in Arista EOS. Requires rbeapi rubygem.'

  confine operatingsystem: [:AristaEOS] unless ENV['RBEAPI_CONNECTION']
  confine feature: :rbeapi

  # Create methods that set the @property_hash for the #flush method
  mk_resource_methods

  # Mix in the api as instance methods
  include PuppetX::Eos::EapiProviderMixin

  # Mix in the api as class methods
  extend PuppetX::Eos::EapiProviderMixin

  def self.instances
    acls = node.api('acl').getall
    return [] if !acls || acls.empty?
    acls.each_with_object([]) do |(name, entries), arry|
      entries.each_with_object([]) do |(seqno, attrs), _hsh|
        provider_hash = { name: namevar(name, seqno), ensure: :present }
        acltype = attrs[:acltype]
        provider_hash[:acltype] = acltype ? acltype.to_sym : :standard
        action = attrs[:action]
        provider_hash[:action] = action ? action.to_sym : :deny
        if action == 'remark'
          provider_hash[:remark] = attrs[:remark]
        else
          provider_hash[:srcaddr] = attrs[:srcaddr]
          provider_hash[:srcprefixlen] = attrs[:srcprefixlen]
          provider_hash[:log] = attrs[:log] ? :true : :false
        end
        arry << new(provider_hash)
      end
    end
  end

  def initialize(resource = {})
    super(resource)
    @property_flush = {}
  end

  def acltype=(value)
    @property_flush[:acltype] = value
  end

  def action=(value)
    @property_flush[:action] = value
  end

  def remark=(value)
    @property_flush[:remark] = value
  end

  def srcaddr=(value)
    @property_flush[:srcaddr] = value
  end

  def srcprefixlen=(value)
    @property_flush[:srcprefixlen] = value
  end

  def log=(value)
    @property_flush[:log] = value
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
    desired_state = @property_hash.merge!(@property_flush)
    # Extract the acl name and seqno from the name
    comp = desired_state[:name].split(':')
    acl_name = comp[0]
    desired_state[:seqno] = comp[1].to_i

    api = node.api('acl')
    case desired_state[:ensure]
    when :present
      api.update_entry(acl_name, desired_state)
    when :absent
      api.remove_entry(acl_name, desired_state[:seqno])
    end
    @property_hash = desired_state
  end

  def self.namevar(name, seqno)
    "#{name}:#{seqno}"
  end
end
