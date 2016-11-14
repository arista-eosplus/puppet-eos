#
# Copyright (c) 2015-2016, Arista Networks, Inc.
# All rights reserved.
#
# Redistribution and use in source and binary forms, with or without
# modification, are permitted provided that the following conditions are
# met:
#
#  Redistributions of source code must retain the above copyright notice,
#  this list of conditions and the following disclaimer.
#
#  Redistributions in binary form must reproduce the above copyright
#  notice, this list of conditions and the following disclaimer in the
#  documentation and/or other materials provided with the distribution.
#
#  Neither the name of Arista Networks nor the names of its
#  contributors may be used to endorse or promote products derived from
#  this software without specific prior written permission.
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

# Work around due to autoloader issues: https://projects.puppetlabs.com/issues/4248
require File.dirname(__FILE__) + '/../../puppet_x/eos/utils/helpers'

Puppet::Type.newtype(:eos_vrrp) do
  @doc = <<-EOS
    Manage VRRP settings on Arista EOS. Configures the Virtual Router
    Redundancy Protocol settings.

    Example:

        eos_vrrp { 'Vlan50:10':
          description      => 'Virtual IP'
          priority         => 100,
          preempt          => true,
          primary_ip       => '192.0.2.1',
          secondary_ip     => ['10.2.4.5'],
          timers_advertise => 10,
        }
  EOS

  ensurable

  def munge_boolean(value)
    case value
    when true, 'true', :true, 'yes', 'on'
      :true
    when false, 'false', :false, 'no', 'off'
      :false
    else
      fail('munge_boolean only takes booleans')
    end
  end

  # Parameters

  newparam(:name) do
    desc <<-EOS
      The name parameter is a composite namevar that combines the
      name of the layer 3 interface with the virtual router ID.
      The virtual router ID must be between 1 - 255.
      Both values are seperated by the colon (:) character

      For example, if the interface name is Vlan50 and the virtual
      router ID is 10 then the namvar would be constructed as
      "Vlan50:10"

      The composite namevar is required to uniquely identify the
      specific layer 3 interface and virtual router ID to configure.
    EOS

    validate do |value|
      fail "value #{value.inspect} must contain a colon" unless value =~ /:/
      w = value.split(':')
      unless w[1].to_i.between?(1, 255)
        fail "value #{value.inspect} is invalid, " \
               'virtual router ID must be between 1 and 255'
      end
    end
  end

  # Properties (state management)

  newproperty(:primary_ip) do
    desc <<-EOS
      The primary IPv4 address for the specified VRRP virtual router.
      The address must be in the form of A.B.C.D. Default value is
      0.0.0.0
    EOS

    validate do |value|
      unless value =~ IPADDR_REGEXP
        fail "value #{value.inspect} is invalid, must be a IP address"
      end
    end
  end

  newproperty(:priority) do
    desc <<-EOS
      The priority setting for the virtual router. The value must be
      between 1 and 254. Default value is 100.
    EOS

    munge { |value| Integer(value) }

    validate do |value|
      unless value.to_i.between?(1, 254)
        fail "value #{value.inspect} is not between 1 and 254"
      end
    end
  end

  newproperty(:timers_advertise) do
    desc <<-EOS
      The interval between successive advertisement messages that the
      switch sends to routers in the specified virtual router ID.
      The value must be between 1 and 255. Default value is 1.
    EOS

    munge { |value| Integer(value) }

    validate do |value|
      unless value.to_i.between?(1, 255)
        fail "value #{value.inspect} is not between 1 and 255"
      end
    end
  end

  newproperty(:preempt, boolean: :true) do
    desc <<-EOS
      A virtual router preempt mode setting. When preempt mode is enabled,
      if the switch has a higher priority it will preempt the current master
      virtual router. When preempt mode is disabled, the switch can become
      the master virtual router only when a master virtual router is not
      present on the subnet, regardless of priority settings. Default value
      is :true
    EOS

    newvalues(:true, :yes, :on, :false, :no, :off)

    munge do |value|
      @resource.munge_boolean(value)
    end
  end

  newproperty(:enable, boolean: :true) do
    desc <<-EOS
      Enable the virtual router. Default value is :true
    EOS

    newvalues(:true, :yes, :on, :false, :no, :off)

    munge do |value|
      @resource.munge_boolean(value)
    end
  end

  newproperty(:secondary_ip, array_matching: :all) do
    desc <<-EOS
      The secondary IPv4 address array for the specified virtual router.  The
      IP address list must be identical for all VRRP routers in a virtual
      router group.  The array cannot be empty. The address must be in the
      form of A.B.C.D
    EOS
    # Sort the arrays before comparing
    def insync?(current)
      current.sort == should.sort
    end

    validate do |value|
      unless value =~ IPADDR_REGEXP
        fail "value #{value.inspect} is invalid, must be a IP address"
      end
    end
  end

  newproperty(:description) do
    desc <<-EOS
      Associates a text string to a virtual router.
    EOS

    validate do |value|
      case value
      when String
        super(value)
        validate_features_per_value(value)
      else fail "value #{value.inspect} is invalid, must be a String."
      end
    end
  end

  newproperty(:track, array_matching: :all) do
    desc <<-EOS
      Array of track settings. Each option in the array is a hash containing
      track settings.  An example of the track property follows:
        track: [ { name: 'Ethernet2', action: 'decrement', amount: 33 },
                 { name: 'Ethernet2', action: 'decrement', amount: 22 },
                 { name: 'Ethernet2', action: 'shutdown' } ]

      The hash key definitions for a track entry follow:
        name - Name of an interface to track.
        action - Action to take on state-change of the tracked interface.
        amount - Amount to decrement the priority. Only specified if the
                 action is set to 'decrement'.
    EOS

    # Step through the array of hashes comparing each hash
    def insync?(current)
      return false if current.length != should.length
      current_set = Set.new current
      should_set = Set.new should
      current_set == should_set
    end

    valid_keys = %w(name action amount)
    valid_acts = %w(decrement shutdown)

    validate do |value|
      if value.is_a?(Hash)
        super(value)
        validate_features_per_value(value)
        # Make sure the correct keys are in the hash
        value.keys.each do |key|
          unless valid_keys.include?(key)
            fail "Invalid key: #{key.inspect} valid keys #{valid_keys}"
          end
        end
        # Make sure the action value is correct
        action = value['action']
        unless valid_acts.include?(action)
          fail "Invalid action: #{action.inspect} valid actions #{valid_acts}"
        end
        # Make sure the decrement has amount specified and shutdown does not
        case action
        when 'decrement'
          unless value.key?('amount')
            fail 'decrement action requires amount to be specified'
          end
        when 'shutdown'
          if value.key?('amount')
            fail 'amount cannot be specified when action is shutdown'
          end
        end
      else fail "value #{value.inspect} is invalid, must be a Hash."
      end
    end
  end

  newproperty(:ip_version) do
    desc <<-EOS
      The VRRP version for the VRRP virtual router. Valid values are
      2 and 3. Default value is 2.
    EOS
    munge { |value| Integer(value) }

    validate do |value|
      unless value.to_i.between?(2, 3)
        fail "value #{value.inspect} is not between 2 and 3"
      end
    end
  end

  newproperty(:mac_addr_adv_interval) do
    desc <<-EOS
      Interval in seconds between advertisement packets sent to VRRP group
      members. Value must be a postive integer. Default value is 30.
    EOS
    munge { |value| Integer(value) }

    validate do |value|
      unless value.to_i >= 0
        fail "value #{value.inspect} must be a positive integer"
      end
    end
  end

  newproperty(:preempt_delay_min) do
    desc <<-EOS
      The minimum time in seconds for the virtual router to wait before
      taking over the active role. Value must be a postive integer.
      Default value is 0.
    EOS
    munge { |value| Integer(value) }

    validate do |value|
      unless value.to_i >= 0
        fail "value #{value.inspect} must be a positive integer"
      end
    end
  end

  newproperty(:preempt_delay_reload) do
    desc <<-EOS
      The preemption delay after a reload only. This delay period applies
      only to the first interface-up event after the router has reloaded.
      Value must be a postive integer.  Default value is 0.
    EOS
    munge { |value| Integer(value) }

    validate do |value|
      unless value.to_i >= 0
        fail "value #{value.inspect} must be a positive integer"
      end
    end
  end

  newproperty(:delay_reload) do
    desc <<-EOS
      Delay between system reboot and VRRP initialization. Value must be
      a postive integer. Default value is 0.
    EOS
    munge { |value| Integer(value) }

    validate do |value|
      unless value.to_i >= 0
        fail "value #{value.inspect} must be a positive integer"
      end
    end
  end
end
