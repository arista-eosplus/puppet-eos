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
    # The Mlag class provides a base class instance for working with
    # the global mlag configuration
    #
    class Mlag
      ##
      # Initialize instance of Snmp
      #
      # @param [PuppetX::Eos::Eapi] api An instance of Eapi
      #
      # @return [PuppetX::Eos::Mlag]
      def initialize(api)
        @api = api
      end

      ##
      # Returns the Mlag hash representing global snmp configuration
      #
      # Example
      #   {
      #     "domain_id": <String>,
      #     "local_interface": <String>,
      #     "peer_address": <String>,
      #     "peer_link": <String>,
      #     "enable": [true, false]
      #   }
      #
      # @return [Array<Hash>] returns a Hash of attributes derived from eAPI
      def get
        result = @api.enable('show mlag')
        attr_hash = {
          'domain_id' => result[0]['domainId'],
          'peer_link' => result[0]['peerLink'],
          'local_interface' => result[0]['localInterface'],
          'peer_address' => result[0]['peerAddress'],
          'enable' => result[0]['state'] == 'disabled' ? :false : :true
        } if result[0].key?('domainId')
        attr_hash || {}
      end

      ##
      # Creates a new mlag instance
      #
      # @param [String] name The domain id of the mlag instance
      #
      # @return [Boolean] True if the commands succeed otherwise False
      def create(name)
        @api.config(['mlag configuration', "domain-id #{name}"]) == [{}, {}]
      end

      ##
      # Deletes the current mlag configuration from the running-config
      #
      # @return [Boolean] True if the commands succeed otherwise False
      def delete
        @api.config('no mlag configuration') == [{}]
      end

      ##
      # Defaults the current mlag configuration
      #
      # @return [Boolean] True if the command succeeds otherwise False
      def default
        @api.config('default mlag configuration') == [{}]
      end

      ##
      # Retrieves the interfaces that are mlag enabled from the running-config
      #
      # @return [Array<Hash>] returns an Array of Hashes keyed by the mlag id
      def get_interfaces
        @api.enable('show mlag interfaces')
      end

      ##
      # Adds a new interface to the MLAG domain with specified Mlag id
      #
      # @param [String] name The name of the interface to add
      # @param [String] id The MLAG ID to assign to the interface
      #
      # @return [Boolean] True if the command succeeds otherwise False
      def add_interface(name, id)
        @api.config(["interface #{name}", "mlag #{id}"]) == [{}, {}]
      end

      ##
      # Removes a previously configured interface from the Mlag domain
      #
      # @param [String] name The name of the interface to remove
      #
      # @return [Boolean] True if the command succeeds otherwise False
      def remove_interface(name)
        @api.config(["interface #{name}", 'no mlag']) == [{},  {}]
      end

      ##
      # Configures the mlag id for an interface
      #
      # @param [String] name The interface to configure
      # @param [Hash] opts The configuration parameters for mlag
      # @option opts [string] :value The value to set the interface mlag id
      # @option opts [Boolean] :default The value should be set to default
      #
      # @return [Boolean] True if the commands succeed otherwise False
      def set_mlag_id(name, opts = {})
        value = opts[:value] || false
        default = opts[:default] || false

        cmds = ["interface #{name}"]
        case default
        when true
          cmds << 'default mlag'
        when false
          cmds << (value ? "mlag #{value}" : 'no mlag')
        end
        @api.config(cmds) == [{}, {}]
      end

      ##
      # Configures the mlag domain_id
      #
      # @param [Hash] opts The configuration parameters for mlag
      # @option opts [string] :value The value to set the domain-id to
      # @option opts [Boolean] :default The value should be set to default
      #
      # @return [Boolean] True if the commands succeed otherwise False
      def set_domain_id(opts = {})
        value = opts[:value] || false
        default = opts[:default] || false

        cmds = ['mlag configuration']
        case default
        when true
          cmds << 'default domain-id'
        when false
          cmds << (value ? "domain-id #{value}" : 'no domain-id')
        end
        @api.config(cmds) == [{}, {}]
      end

      ##
      # Configures the mlag peer_link
      #
      # @param [Hash] opts The configuration parameters for mlag
      # @option opts [string] :value The value to set the peer-link to
      # @option opts [Boolean] :default The value should be set to default
      #
      # @return [Boolean] True if the commands succeed otherwise False
      def set_peer_link(opts = {})
        value = opts[:value] || false
        default = opts[:default] || false

        cmds = ['mlag configuration']
        case default
        when true
          cmds << 'default peer-link'
        when false
          cmds << (value ? "peer-link #{value}" : 'no peer-link')
        end
        @api.config(cmds) == [{}, {}]
      end

      ##
      # Configures the mlag peer_address
      #
      # @param [Hash] opts The configuration parameters for mlag
      # @option opts [string] :value The value to set the peer-address to
      # @option opts [Boolean] :default The value should be set to default
      #
      # @return [Boolean] True if the commands succeed otherwise False
      def set_peer_address(opts = {})
        value = opts[:value] || false
        default = opts[:default] || false

        cmds = ['mlag configuration']
        case default
        when true
          cmds << 'default peer-address'
        when false
          cmds << (value ? "peer-address #{value}" : 'no peer-address')
        end
        @api.config(cmds) == [{}, {}]
      end

      ##
      # Configures the mlag local_interface
      #
      # @param [Hash] opts The configuration parameters for mlag
      # @option opts [string] :value The value to set the local-interface to
      # @option opts [Boolean] :default The value should be set to default
      #
      # @return [Boolean] True if the commands succeed otherwise False
      def set_local_interface(opts = {})
        value = opts[:value] || false
        default = opts[:default] || false

        cmds = ['mlag configuration']
        case default
        when true
          cmds << 'default local-interface'
        when false
          cmds << (value ? "local-interface #{value}" : 'no local-interface')
        end
        @api.config(cmds) == [{}, {}]
      end

      ##
      # Configures the mlag operational state
      #
      # @param [Hash] opts The configuration parameters for mlag
      # @option opts [string] :value The value to set the state to
      # @option opts [Boolean] :default The value should be set to default
      #
      # @return [Boolean] True if the commands succeed otherwise False
      def set_shutdown(opts = {})
        value = opts[:value] || false
        default = opts[:default] || false

        cmds = ['mlag configuration']
        case default
        when true
          cmds << 'default shutdown'
        when false
          cmds << (value ? 'shutdown' : 'no shutdown')
        end
        @api.config(cmds) == [{}, {}]
      end
    end
  end
end
