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

Puppet::Type.type(:eos_config).provide(:eos) do
  desc 'The eos_config provider allows for the evaluation of the current
    configuration for a specific command.  The prefetch is a no-op because
    it is not possible to know if the command is set without the properties.
    Cannot define an exists? method since XXX
    The exists? method always returns false unless the properties have been
    set. The eos_config will configure the node using the command argument
    when the resource is present and not set on the switch.'

  confine operatingsystem: [:AristaEOS] unless ENV['RBEAPI_CONNECTION']
  confine feature: :rbeapi

  # Create methods that set the @property_hash for the #flush method
  mk_resource_methods

  # Mix in the api as instance methods
  include PuppetX::Eos::EapiProviderMixin

  # Mix in the api as class methods
  extend PuppetX::Eos::EapiProviderMixin

  def self.instances
    []
  end

  def initialize(resource = {})
    super(resource)
    @property_flush = {}
  end

  def command=(value)
    @property_flush[:command] = value
  end

  def section=(value)
    @property_flush[:section] = value
  end

  def regexp=(value)
    @property_flush[:regexp] = value
  end

  ##
  # get_config returns the part of the running-config to evaluate.
  # If the section property is set then return the part of the
  # running config that corresponds to the section. If the section
  # property is not set then return the running config.
  #
  # @api private
  #
  # @return [String] Part or all of the running config
  def get_config
    if @property_hash[:section]
      return node.get_config(param: @property_hash[:section], as_string: true)
    end
    node.running_config
  end
  private :get_config

  ##
  # config_exists? checks the regexp against the running config if the
  # regexp is known. If not, and the command is known, then check to see
  # if the command is set in the running config.
  #
  # @api private
  #
  # @return [Boolean] Configuration is set
  def config_exists?
    exists = false
    cfg = get_config
    return exists unless cfg
    if !@property_hash[:regexp].nil?
      regexp = Regexp.new(@property_hash[:regexp])
      exists = true unless cfg.scan(regexp).empty?
    else
      unless @property_hash[:command].nil?
        exists = true unless cfg.scan(@property_hash[:command]).empty?
      end
    end
    exists
  end
  private :config_exists?

  ##
  # run_cmd runs resource[:command] on the switch.
  #
  # @api private
  #
  # @return [String] Part or all of the running config
  def run_cmd
    commands = []
    commands << @property_hash[:section] if @property_hash[:section]
    commands << @property_hash[:command]
    node.config(commands)
  end
  private :run_cmd

  def flush
    @property_hash.merge!(@property_flush)

    # Run the command if the resource does not exist
    run_cmd unless config_exists?

    @property_flush = {}
  end
end
