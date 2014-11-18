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
# Eos is the toplevel namespace for working with Arista EOS nodes
module PuppetX
  ##
  # Eapi is module namesapce for working with the EOS command API
  module Eos
    ##
    # The Ipinterface class provides an instance for managing logical
    # IP interfaces configured using eAPI.
    class Ipinterface
      def initialize(api)
        @api = api
      end

      ##
      # Retrieves all logical IP interfaces from the running-configuration
      # and returns all instances
      #
      # Example:
      #   {
      #     "Ethernet1": {
      #       "address" => "1.2.3.4/5",
      #       "mtu" => "1500",
      #       "helper_addresses" => ["5.6.7.8", "9.10.11.12"]
      #     },
      #     "Ethernet2": {...}
      #   }
      #
      # @return [Hash] all IP interfaces found in the running-config
      def getall
        result = @api.enable('show ip interface')
        response = {}
        result.first['interfaces'].each do |name, attrs|
          interface = {}
          addr = attrs['interfaceAddress']['primaryIp']['address']
          mask = attrs['interfaceAddress']['primaryIp']['maskLen']
          interface['address'] = "#{addr}/#{mask}"
          interface['mtu'] = attrs['mtu']
          interface['helper_address'] = get_helper_address(name)
          response[name] = interface
        end
        response
      end

      ##
      # Create a new logical IP interface in the running-config
      #
      # @param [String] name The name of the interface
      #
      # @return [Boolean] True if the create succeeds otherwise False
      def create(name)
        @api.config(["interface #{name}", 'no switchport']) == [{}, {}]
      end

      ##
      # Deletes a logical IP interface from the running-config
      #
      # @param [String] name The name of the interface
      #
      # @return [Boolean] True if the create succeeds otherwise False
      def delete(name)
        @api.config(["interface #{name}", 'no ip address',
                     'switchport']) == [{}, {}, {}]
      end

      ##
      ## Configures the IP address and mask length for the interface
      #
      # @param [String] name The name of the interface to configure
      # @param [Hash] opts The configuration parameters for the interface
      # @option opts [string] :value The value to set the address to
      # @option opts [Boolean] :default The value should be set to default
      #
      # @return [Boolean] True if the commands succeed otherwise False
      def set_address(name, opts = {})
        value = opts[:value]
        default = opts[:default] || false

        cmds = ["interface #{name}"]
        case default
        when true
          cmds << 'default ip address'
        when false
          cmds << (value.nil? ? 'no ip address' : "ip address #{value}")
        end
        @api.config(cmds) == [{}, {}]
      end

      ##
      ## Configures the MTU value for the interface
      #
      # @param [String] name The name of the interface to configure
      # @param [Hash] opts The configuration parameters for the interface
      # @option opts [string] :value The value to set the MTU to
      # @option opts [Boolean] :default The value should be set to default
      #
      # @return [Boolean] True if the commands succeed otherwise False
      def set_mtu(name, opts = {})
        value = opts[:value]
        default = opts[:default] || false

        cmds = ["interface #{name}"]
        case default
        when true
          cmds << 'default mtu'
        when false
          cmds << (value.nil? ? 'no mtu' : "mtu #{value}")
        end
        @api.config(cmds) == [{}, {}]
      end

      ##
      ## Configures ip helper addresses for the interface
      #
      # @param [String] name The name of the interface to configure
      # @param [Hash] opts The configuration parameters for the interface
      # @param [opts] [Array] :value list of addresses to configure as
      #   helper address on the specified interface
      # @option opts [Boolean] :default The value should be set to default
      def set_helper_address(name, opts = {})
        value = opts[:value]
        default = opts[:default] || false

        cmds = ["interface #{name}"]
        case default
        when true
          cmds << 'default ip helper-address'
        when false
          if value.nil?
            cmds << 'no ip helper-address'
          else
            cmds << 'default ip helper-address'
            value.each { |addr| cmds << "ip helper-address #{addr}" }
          end
        end
        @api.config(cmds)
      end

      private

      def get_helper_address(name)
        config = @api.enable("show running-config interfaces #{name}",
                             format: 'text')
        output = config.first['output']
        output.scan(/(?<=\-address\s)\d{1,3}\.\d{1,3}\.\d{1,3}\.\d{1,3}/)
      end
    end
  end
end
