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
    # The Ospf class provides a base class instance for working with
    # instances of OSPF
    #
    class Ospf
      ##
      # Initialize instance of Ospf
      #
      # @param [PuppetX::Eos::Eapi] api An instance of Eapi
      #
      # @return [PuppetX::Eos::Ospf]
      def initialize(api)
        @api = api
      end

      ##
      # Returns the base interface hash representing physical and logical
      # interfaces in EOS using eAPI
      #
      # Example
      #   {
      #       "1": { "router_id": <string> },
      #       "2": {...}
      #   }
      #
      # @return [Hash] returns an Hash
      def getall
        result = @api.enable('show ip ospf', format: 'text')
        output = result.first['output']
        match = /(?<=ospf\s)(?<instance>\d+)"/.match(output)
        return {} if match .nil?
        instance = match['instance']
        match = /(?<=ID\s)(?<routerid>[\d|\.]*)\s/.match(output)
        routerid = match['routerid'].nil? ? {} : match['routerid']
        { instance => { 'router_id' => routerid } }
      end

      ##
      # Creates a new instance of OSPF routing
      #
      # @param [String] inst The instance id to create
      #
      # @return [Boolean] True if the commands succeed otherwise False
      def create(inst)
        @api.config("router ospf #{inst}") == [{}]
      end

      ##
      # Deletes an instance of OSPF routing
      #
      # @param [String] inst The instance id to delete
      #
      # @return [Boolean] True if the commands succeed otherwise False
      def delete(inst)
        @api.config("no router ospf #{inst}") == [{}]
      end

      ##
      # Defaults an instance of OSPF routing
      #
      # @param [String] inst The instance id to delete
      #
      # @return [Boolean] True if the commands succeed otherwise False
      def default(inst)
        @api.config("default router ospf #{inst}") == [{}]
      end

      ##
      # Configures the OSPF process router-id
      #
      # @param [String] inst The instance of ospf to configure
      # @param [Hash] opts The configuration parameters
      # @option opts [string] :value The value to set the router-id to
      # @option opts [Boolean] :default The value should be set to default
      #
      # @return [Boolean] True if the commands succeed otherwise False
      def set_router_id(inst, opts = {})
        value = opts[:value] || false
        default = opts[:default] || false

        cmds = ["router ospf #{inst}"]
        case default
        when true
          cmds << 'default router-id'
        when false
          cmds << (value ? "router-id #{value}" : 'no router-id')
        end
        @api.config(cmds) == [{}, {}]
      end

      private

      ##
      # Parses the running-configuration to retreive all OSPF interfaces
      #
      # @return [Hash] a hash of key/value pairs
      def get_interfaces
        result = @api.enable('show ip interface')
        response = {}
        result.first['interfaces'].keys do |name|
          response[key] = _parse_intf_config name
        end
        response
      end

      ##
      # Returns the ospf interface config from the running-config
      #
      # @param [String] name The name of the interface to retreive the
      #     the running config for
      #
      # @return [Hash] key/value pairs that represent the interface
      #     configuration
      def _parse_intf_config(name)
        result = @api.enable("show running-config all interface #{name}")
        output = result[0]['output']
        response = {}
        nettype = output.scan(/(?<=ospf\snetwork\s)(?<nettype>.*)$/)
        response['network_type'] = nettype
        response
      end
    end
  end
end
