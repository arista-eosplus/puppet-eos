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

##
# PuppetX is the toplevel namespace for working with Arista EOS nodes
module PuppetX
  ##
  # Eos is module namesapce for working with the EOS command API
  module Eos
    ##
    # The Portchannel class provides a base class instance for working with
    # logical link aggregation interfaces.
    #
    class Portchannel
      ##
      # Initialize innstance of Portchannel
      #
      # @param [PuppetX::Eos::Eapi] api An instance of Eapi
      #
      # @return [PuppetX::Eos::Interface]
      def initialize(api)
        @api = api
      end

      ##
      # Retrievess a port channel interface from the running-configuration
      #
      # Example
      #   {
      #     "name": <String>,
      #     "lacp_mode": [active, passive, off],
      #     "members": [Array],
      #     "lacp_fallback": [static, individual],
      #     "lacp_timeout": <0-900>
      #   }
      #
      # @param [String] name The name of the port-channel interface
      #
      # @return [Hash] A hash of the port channel attributes and properties
      def get(name)
        members = get_members name
        result = @api.enable("show interfaces #{name}")
        interface = result.first['interfaces']

        attr_hash = { name: name }
        attr_hash[:members] = members
        attr_hash[:lacp_mode] = get_lacp_mode members
        attr_hash[:lacp_fallback] = get_lacp_fallback interface
        attr_hash[:lacp_timeout] = interface['fallbackTimeout']
        attr_hash
      end

      ##
      # Retreives the member interfaces for the specified channel group
      #
      # @param [String] name The name of the port-channel interface to return
      #     members for
      #
      # @return [Array] An array of interface names that are members of the
      #   specified channel group id
      def get_members(name)
        result = @api.enable("show #{name} all-ports",
                             format: 'text')
        result.first['output'].scan(/Ethernet\d+/)
      end

      ##
      # Create a logical port-channel interface
      #
      # @param [String] name The name of the interface to create
      #
      # @return [Boolean] True if the create succeeds otherwise False
      def create(name)
        @api.config("interface #{name}") == [{}]
      end

      ##
      # Deletes a logical port-channel interface
      #
      # @param [String] name The name of the interface to create
      #
      # @return [Boolean] True if the create succeeds otherwise False
      def delete(name)
        @api.config("no interface #{name}") == [{}]
      end

      ##
      # Defaults a logical port-channel interface
      #
      # @param [String] name The name of the interface to create
      #
      # @return [Boolean] True if the create succeeds otherwise False
      def default(name)
        @api.config("default interface #{name}") == [{}]
      end

      ##
      # Adds a new member interface to the channel group
      #
      # @param [String] name The name of the port channel to add the interface
      # @param [String] member The name of the interface to add
      #
      # @return [Boolean] True if the create succeeds otherwise False
      def add_member(name, member)
        id = name.match(/\d+/)
        @api.config(["interface #{member}",
                     "channel-group #{id} mode on"]) == [{}, {}]
      end

      ## Removes a member interface from the channel group
      #
      # @param [String] name The name of the port-channel to add the interface
      # @param [String] member The name of the interface to remove
      #
      # @return [Boolean] True if the create succeeds otherwise False
      def remove_member(_name, member)
        @api.config(["interface #{member}", 'no channel-group']) == [{}, {}]
      end

      ##
      # Configures the lacp mode for the interface
      #
      # @param [String] name The name of the port-channel interface
      # @param [String] mode The LACP mode to configure
      #
      # @return [Boolean] True if the create succeeds otherwise False
      def set_lacp_mode(name, mode)
        id = name.match(/\d+/)
        members = get_members name

        commands = []
        config = []

        members.each do |member|
          commands << "interface #{member}" << 'no channel-group'
          config << "interface #{member}" << "channel-group #{id} mode #{mode}"
        end

        config.unshift(*commands)
        result =  @api.config(config)
        config.size == result.size
      end

      ##
      # Configures the lacp fallback value
      #
      # @param [String] name The name of the interface to configure
      # @param [Hash] opts The configuration parameters for the interface
      # @option opts [string] :value The value to set the value to
      # @option opts [Boolean] :default The value should be set to default
      #
      # @return [Boolean] True if the commands succeed otherwise False
      def set_lacp_fallback(name, opts = {})
        value = opts[:value]
        default = opts[:default] || false

        cmds = ["interface #{name}"]
        case default
        when true
          cmds << 'default port-channel lacp fallback'
        when false
          cmds << (value.nil? ? "no port-channel lacp fallback #{value}" : \
                                "port-channel lacp fallback #{value}")
        end
        @api.config(cmds) == [{}, {}]
      end

      ##
      # Configures the lacp fallback timeout value
      #
      # @param [String] name The name of the interface to configure
      # @param [Hash] opts The configuration parameters for the interface
      # @option opts [string] :value The value to set the timeout to
      # @option opts [Boolean] :default The value should be set to default
      #
      # @return [Boolean] True if the commands succeed otherwise False
      def set_lacp_timeout(name, opts = {})
        value = opts[:value]
        default = opts[:default] || false

        cmds = ["interface #{name}"]
        case default
        when true
          cmds << 'default port-channel lacp fallback timeout'
        when false
          cmds << (value.nil? ? 'no port-channel lacp fallback timeout' : \
                                "port-channel lacp fallback timeout #{value}")
        end
        @api.config(cmds) == [{}, {}]
      end

      private

      def get_lacp_mode(members)
        return '' if members.empty?
        name = members.first
        result = @api.enable("show running-config interfaces #{name}",
                             format: 'text')
        m = /channel-group\s\d+\smode\s(?<lacp>.*)/
            .match(result.first['output'])
        m['lacp']
      end

      def get_lacp_fallback(attr_hash)
        if attr_hash['fallbackEnabled']
          case attr_hash['fallbackEnabledType']
          when 'fallbackStatic'
            fallback = 'static'
          when 'fallbackIndividual'
            fallback = 'individual'
          end
        end
        fallback || ''
      end
    end
  end
end
