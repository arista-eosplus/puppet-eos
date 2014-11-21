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
    # The Stp class provides a base class instance for working with
    # the EOS spanning-tree configuration
    #
    class Stp
      ##
      # Initialize instance of Stp
      #
      # @param [PuppetX::Eos::Eapi] api An instance of Eapi
      #
      # @return [PuppetX::Eos::Stp]
      def initialize(api)
        @api = api
      end

      ##
      # Returns the STP hash representing the current running
      # configuration from eAPI.
      #
      # Example
      #   {
      #     "mode": "mstp",
      #     "instances": {
      #         "1": {
      #             "priority": "4096"
      #         }
      #         "2": {...}
      #     }
      #     "interfaces": {
      #         "Ethernet1": {
      #             "portfast": "enable"
      #         },
      #         "Ethernet2": {...}
      #     }
      #   }
      #
      # @return [Hash] returns a Hash of attributes derived from eAPI
      def get
        result = @api.enable('show running-config section spanning-tree mode')
        mode = /(?<=mode\s)(\w+)$/.match(result.first['output'])
        response = { 'mode' => mode[0] }
        response['instances'] = {}
        response['interfaces'] = {}
        response
      end

      ##
      # Returns all spanning-tree instances as key/value hash
      #
      # @return [PuppetX::Eos::StpInstances]
      def instances
        return @instances if @instances
        @instances = StpInstances.new(@api)
      end

      ##
      # Configures the spanning-tree mode on the switch
      #
      # @param [Hash] opts The configuration parameters for mode
      # @option opts [string] :value The value to set the mode
      # @option opts [Boolean] :default The value should be set to default
      #
      # @return [Boolean] True if the commands succeed otherwise False
      def set_mode(opts = {})
        value = opts[:value]
        default = opts[:default] || false

        case default
        when true
          cmd = 'default spanning-tree mode'
        when false
          cmd = (value ? "spanning-tree mode #{value}" : \
                         'no spanning-tree mode')
        end
        @api.config(cmd) == [{}]
      end
    end

    ##
    # The StpInstances class provides a class instance for working with
    # spanning-tree instances in EOS
    #
    class StpInstances
      ##
      # Initialize instance of StpInstances
      #
      # @param [PuppetX::Eos::Eapi] api An instance of Eapi
      #
      # @return [PuppetX::Eos::StpInstances
      def initialize(api)
        @api = api
      end

      ##
      # Returns all of the spanning-tree instances found in the current
      # nodes running-configuration
      #
      # Example
      #   {
      #     "1": {
      #       "priority": 4096
      #     },
      #     "2": {...}
      #   }
      #
      # @return [Hash] instance attributes from eAPI
      def getall
        result = @api.enable('show spanning-tree')
        result = result.first['spanningTreeInstances']
        response = {}
        result.each do |inst, attrs|
          instance = inst.gsub('MST', '')
          priority = attrs['bridge']['priority']
          response[instance] = { 'priority' => priority }
        end
        response
      end

      ##
      # Deletes a configured MST instance
      #
      # @param [String] inst The MST instance to delete
      #
      # @return [Boolean] True if the commands succeed otherwise False
      def delete(inst)
        @api.config(['spanning-tree mst configuration', "no instance #{inst}",
                     'exit']) == [{}, {}, {}]
      end

      ##
      # Configures the spanning-tree MST priority
      #
      # @param [String] inst The MST instance to configure
      # @param [Hash] opts The configuration parameters for the priority
      # @option opts [string] :value The value to set the priority to
      # @option opts [Boolean] :default The value should be set to default
      #
      # @return [Boolean] True if the commands succeed otherwise False
      def set_priority(inst, opts = {})
        value = opts[:value]
        default = opts[:default] || false

        case default
        when true
          cmd = "default spanning-tree mst #{inst} priority"
        when false
          cmd = (value ? "spanning-tree mst #{inst} priority #{value}" : \
                         "no spanning-tree mst #{inst} priority")
        end
        @api.config(cmd) == [{}]
      end
    end
  end
end
