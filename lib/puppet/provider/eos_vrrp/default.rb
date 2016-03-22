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

Puppet::Type.type(:eos_vrrp).provide(:eos) do
  desc 'Manage Virtual Router (VRRP) settings on Arista EOS. Requires rbeapi'

  confine operatingsystem: [:AristaEOS] unless ENV['RBEAPI_CONNECTION']
  confine feature: :rbeapi

  # Create methods that set the @property_hash for the #flush method
  mk_resource_methods

  # Mix in the api as instance methods
  include PuppetX::Eos::EapiProviderMixin

  # Mix in the api as class methods
  extend PuppetX::Eos::EapiProviderMixin

  # rubocop:disable Metrics/MethodLength
  def self.instances
    entries = node.api('vrrp').getall
    return [] if !entries || entries.empty?
    # iterate over the interfaces
    entries.each_with_object([]) do |(iname, vrids), arry|
      # iterate over the virtual routers
      vrids.each do |vrid, attrs|
        provider_hash = { name: namevar(iname, vrid), ensure: :present }

        unless attrs[:secondary_ip].nil?
          provider_hash[:secondary_ip] = attrs[:secondary_ip]
        end

        provider_hash[:description] = attrs[:description] if attrs[:description]
        unless attrs[:track].nil?
          # Convert any keys in the track array of hashses that are symbols to
          # strings for puppet
          track_arry = []
          attrs[:track].each do |track|
            # Convert the amount from an integer to a string.
            track[:amount] = track[:amount].to_s if track.key?(:amount)
            track_arry << convert_keys(track, 'strings')
          end
          provider_hash[:track] = track_arry
        end

        # The following values will always have a value defined in attr
        # because they always have a value defined in EOS. Even if they
        # the value in EOS is negated it will return its default value.
        provider_hash[:primary_ip] = attrs[:primary_ip]
        provider_hash[:priority] = attrs[:priority].to_s
        provider_hash[:timers_advertise] = attrs[:timers_advertise].to_s
        provider_hash[:preempt] = attrs[:preempt] ? :true : :false
        provider_hash[:enable] = attrs[:enable] ? :true : :false
        provider_hash[:ip_version] = attrs[:ip_version].to_s
        provider_hash[:mac_addr_adv_interval] = \
          attrs[:mac_addr_adv_interval].to_s
        provider_hash[:preempt_delay_min] = attrs[:preempt_delay_min].to_s
        provider_hash[:preempt_delay_reload] = attrs[:preempt_delay_reload].to_s
        provider_hash[:delay_reload] = attrs[:delay_reload].to_s

        arry << new(provider_hash)
      end
    end
  end

  def initialize(resource = {})
    super(resource)
    @property_flush = {}
  end

  def primary_ip=(value)
    @property_flush[:primary_ip] = value
  end

  def priority=(value)
    @property_flush[:priority] = value
  end

  def timers_advertise=(value)
    @property_flush[:timers_advertise] = value
  end

  def preempt=(value)
    @property_flush[:preempt] = value
  end

  def enable=(value)
    @property_flush[:enable] = value
  end

  def secondary_ip=(value)
    @property_flush[:secondary_ip] = value
  end

  def description=(value)
    @property_flush[:description] = value
  end

  def track=(value)
    @property_flush[:track] = value
  end

  def ip_version=(value)
    @property_flush[:ip_version] = value
  end

  def mac_addr_adv_interval=(value)
    @property_flush[:mac_addr_adv_interval] = value
  end

  def preempt_delay_min=(value)
    @property_flush[:preempt_delay_min] = value
  end

  def preempt_delay_reload=(value)
    @property_flush[:preempt_delay_reload] = value
  end

  def delay_reload=(value)
    @property_flush[:delay_reload] = value
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

  ##
  # set_defaults checks to see if a key with a default value is
  # set in the property_hash. If not, then it assigns the default
  # value to the key. The defaults used are the same as the default
  # values specified in the type file. Setting the defaults is required
  # because a prefetch will return default values for these keys and if
  # the property_hash does not have the value set then puppet will try
  # to unset these values which is not possible on EOS. A different approach
  # could get the resource from EOS after a create and adjust any values
  # that were set by EOS. This approach was chosen to avoid an extra
  # 'show running-config' and it enforces the default values documented in
  # the type.
  #
  # @api private
  #
  def set_defaults
    defaults = { primary_ip: '0.0.0.0',
                 priority: 100,
                 timers_advertise: 1,
                 preempt: true,
                 enable: true,
                 ip_version: 2,
                 mac_addr_adv_interval: 30,
                 preempt_delay_min: 0,
                 preempt_delay_reload: 0,
                 delay_reload: 0 }

    # If the value is not set in the @property_hash then set
    # the value in the @property_flush.
    defaults.keys.each do |key|
      @property_flush[key] = defaults[key] unless @property_hash.key?(key)
    end
  end
  private :set_defaults

  def flush
    api = node.api('vrrp')
    @property_hash.merge!(@property_flush)

    # Extract the interface name and virtual router ID from the name
    comp = resource[:name].split(':')
    name = comp[0]
    vrid = comp[1].to_i
    # Remove the composite name
    @property_flush.delete(:name)

    case @property_hash[:ensure]
    when :present
      # The :enable and :preempt attributes stores :true or :false
      # (i.e. symbols). The rbeapi library expects a boolean value.
      # Modify the :enable value passed into the create call to store
      # a boolean value.
      map_boolean(@property_flush, :enable)
      map_boolean(@property_flush, :preempt)

      remove_puppet_keys(@property_flush)

      # Convert any keys in the track array of hashses that are strings to
      # symbols for the create call to rbeapi
      if @property_flush.key?(:track)
        arry = []
        @property_flush[:track].each do |track|
          arry << convert_keys(track, 'symbols')
        end
        @property_flush[:track] = arry
      end

      set_defaults
      api.create(name, vrid, @property_flush)
    when :absent
      api.delete(name, vrid)
    end
    @property_flush = {}
  end

  def self.namevar(name, vrid)
    "#{name}:#{vrid}"
  end
end
