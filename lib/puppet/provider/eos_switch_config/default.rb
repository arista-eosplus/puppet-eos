#
# Copyright (c) 2016, Arista Networks, Inc.
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
require 'rbeapi/switchconfig'

module_lib = Pathname.new(__FILE__).parent.parent.parent.parent
require File.join module_lib, 'puppet_x/eos/provider'

Puppet::Type.type(:eos_switch_config).provide(:eos) do
  desc 'Manage switch configuration settings on Arista EOS. Requires rbeapi'

  confine operatingsystem: [:AristaEOS] unless ENV['RBEAPI_CONNECTION']
  confine feature: :rbeapi

  # Create methods that set the @property_hash for the #flush method
  mk_resource_methods

  # Mix in the api as instance methods
  include PuppetX::Eos::EapiProviderMixin

  # Mix in the api as class methods
  extend PuppetX::Eos::EapiProviderMixin

  def self.instances
    # Get the current running config
    conf = node.get_config(config: 'running-config', as_string: true)

    # Remove comment lines and the end statement from conf
    # The end statement is removed to allow comparison with user
    # specified switch configs that do not have the end statement.
    conf_arr = []
    conf.each_line do |line|
      next if line.start_with?('!') || line.start_with?('end')
      conf_arr.push(line)
    end

    provider_hash = { name: 'running-config', content: conf_arr.join }
    [new(provider_hash)]
  end

  def initialize(resource = {})
    super(resource)
    @property_flush = {}
  end

  def content=(value)
    @property_flush[:content] = value
  end

  def force=(value)
    @property_flush[:force] = value
  end

  def rollback_on_error=(value)
    @property_flush[:rollback_on_error] = value
  end

  ##
  # run_commands runs the array of commands on the switch.
  # If running the commands failed and a backup filename was
  # specified then restore the backup configuration.
  #
  # rubocop:disable Lint/RescueException
  #
  # @api private
  #
  # @param cmds [Array<String>] The commands to run on the switch.
  # @param bu_filename [String] The backup filename.
  def run_commands(cmds, bu_filename)
    return unless cmds.length > 0
    begin
      node.config(cmds)
    rescue Exception => e1
      # If requested, Restore the switch config if there was an error
      # and delete the backup file.
      if bu_filename
        begin
          Puppet.notice 'Error detected rolling back switch config'
          node.config(["configure replace #{bu_filename} force"])
          node.config(["delete #{bu_filename}"])
        rescue Exception => e2
          Puppet.notice "Rollback of configuration failed: #{e2}"
        end
      end
      raise e1
    end
  end
  private :run_commands

  ##
  # process_config process the switch config resource and applies
  # the required changes to the switch.
  #
  # @api private
  def process_config
    bu_filename = nil

    # Backup the current running config on switch if needed
    if @property_hash[:rollback_on_error] == :true
      bu_filename = 'file:/tmp/puppet-rollback-config'
      node.config(["copy running-config #{bu_filename}"])
    end

    # Get the new running config in a SwitchConfig object
    new_conf = @property_hash[:content]
    new_swc = Rbeapi::SwitchConfig::SwitchConfig.new('', new_conf)

    # If force flag set then just apply the new config to the switch,
    # otherwise get current running config and diff with new config.
    if @property_hash[:force] == :true
      Puppet.notice 'Force flag enabled, overwritting existing config'
      cmds = new_swc.global.gen_commands
    else
      # XXX What about the configed that was prefetched?
      # Get the current running config
      conf = node.get_config(config: 'running-config', as_string: true)
      org_swc = Rbeapi::SwitchConfig::SwitchConfig.new('', conf)

      # Compare the existing and new config
      # If results are both empty then nothing needs to change,
      # run_commands won't do anything for this case.
      results = org_swc.compare(new_swc)

      # Set the switch configuration commands that are in the existing
      # configuration, but not in the new configuration, to their
      # default value.
      default_cmds = results[0].gen_commands(add_default: true)
      run_commands(default_cmds, bu_filename)

      # Generated the commands to add to the current switch configuration
      cmds = results[1].gen_commands
    end
    run_commands(cmds, bu_filename)
    node.config(["delete #{bu_filename}"]) if bu_filename
  end
  private :process_config

  def flush
    # Merge in values from resource to pick up default values for parameters
    @property_hash[:force] = @resource[:force]
    @property_hash[:rollback_on_error] = @resource[:rollback_on_error]

    # Merge in values that have changed
    @property_hash.merge!(@property_flush)

    process_config

    @property_flush = {}
  end
end
