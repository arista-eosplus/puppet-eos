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
    # The Ntp class provides a base class instance for working with
    # the global NTP configuration
    #
    class Ntp
      ##
      # Initialize instance of Snmp
      #
      # @param [PuppetX::Eos::Eapi] api An instance of Eapi
      #
      # @return [PuppetX::Eos::Ntp]
      def initialize(api)
        @api = api
      end

      ##
      # Returns the Ntp hash representing global snmp configuration
      #
      # Example
      #   {
      #     "source_interface": <String>,
      #     "servers": [Array]
      #   }
      #
      # @return [Array<Hash>] returns a Hash of attributes derived from eAPI
      def get
        result = @api.enable('show running-config section ntp', format: 'text')
        output = result.first['output']

        m_source = /(?<=source\s)(\w|\d)+$/.match(output)
        m_servers = output.scan(/\d{1,3}\.\d{1,3}\.\d{1,3}\.\d{1,3}/)

        attr_hash = {
          source_interface: m_source[0] || '',
          servers: m_servers || []
        }
        attr_hash
      end

      ##
      # Adds a new NTP server to the configured list
      #
      # @param [String] name The name of the interface to add
      #
      # @return [Boolean] True if the command succeeds otherwise False
      def add_server(name)
        return @api.config("ntp server #{name}") == [{}]
      end

      ##
      # Removes a previously configured interface from the Mlag domain
      #
      # @param [String] name The name of the interface to remove
      #
      # @return [Boolean] True if the command succeeds otherwise False
      def remove_server(name)
        return @api.config("no ntp server #{name}") == [{}]
      end

      ##
      # Configures the ntp source interface
      #
      # @param [Hash] opts The configuration parameters for mlag
      # @option opts [string] :value The value to set the domain-id to
      # @option opts [Boolean] :default The value should be set to default
      #
      # @return [Boolean] True if the commands succeed otherwise False
      def set_source_interface(opts = {})
        value = opts[:value] || false
        default = opts[:default] || false

        case default
        when true
          cmd = 'default ntp source'
        when false
          cmd = (value ? "ntp source #{value}" : "no ntp source")
        end
        @api.config(cmd) == [{}]
      end
    end
  end
end
