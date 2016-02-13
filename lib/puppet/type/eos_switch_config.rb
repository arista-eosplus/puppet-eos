#
# Copyright (c) 2016, Arista Networks, Inc.
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

require 'puppet/parameter/boolean'
require 'rbeapi/switchconfig'

Puppet::Type.newtype(:eos_switch_config) do
  @doc = <<-EOS
    XXX Update
    There can only be one eos_switch_config defined per switch node.
  EOS

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
      The name is always 'running-config'.
    EOS

    validate do |value|
      case value
      when String
        super(value)
      else fail "value #{value.inspect} is invalid, must be a String."
      end
      unless value == 'running-config'
        fail "value #{value.inspect} is invalid, namevar must be 'settings'."
      end
    end
  end

  newparam(:force, boolean: :true, parent: Puppet::Parameter::Boolean) do
    desc <<-EOS
      Forces the switch configuration to be applied to the switch without
      first checking the configuration state of the switch.
    EOS
    defaultto(:false)

    munge do |value|
      @resource.munge_boolean(value)
    end
  end

  newparam(:rollback_on_error, boolean: :true,
                               parent: Puppet::Parameter::Boolean) do
    desc <<-EOS
      If true, get the switch configuration before making any changes. If an
      error occurs when applying configuration changes then replace the
      switches configuration with the saved switch configuration.
    EOS
    defaultto(:true)

    munge do |value|
      @resource.munge_boolean(value)
    end
  end

  # Properties (state management)

  newproperty(:content) do
    desc <<-EOS
      The switch config content which is a string. In the manfiest the
      be formatted exactly as an EOS switch configuration using 3 space
      indentation.
      XXX Update this and the top level desc
      http://docs.puppetlabs.com/puppet/latest/reference/lang_template.html
    EOS

    @results = []

    def insync?(current)
      # Get the current running config in a SwitchConfig object
      org_swc = Rbeapi::SwitchConfig::SwitchConfig.new('', current)

      # Get the new running config in a SwitchConfig object
      new_swc = Rbeapi::SwitchConfig::SwitchConfig.new('', should)

      @results = org_swc.compare(new_swc)
      @results[0].cmds.empty? && @results[0].children.empty? && \
        @results[1].cmds.empty? && @results[1].children.empty?
    end

    def should_to_s(_)
      # Display diffs between new and org
      @results[1].gen_commands
    end

    # rubocop:disable Style/PredicateName
    def is_to_s(_)
      # Display diffs between org and new
      @results[0].gen_commands
    end

    validate do |value|
      case value
      when String
        super(value)
        validate_features_per_value(value)
      else fail "value #{value.inspect} is invalid, must be a String."
      end
    end
  end
end
