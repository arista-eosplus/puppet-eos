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
    # The Varp class provides a base class instance for working with
    # the EOS VARP configuration
    #
    class Varp
      ##
      # Initialize instance of Varp
      #
      # @param [PuppetX::Eos::Eapi] api An instance of Eapi
      #
      # @return [PuppetX::Eos::Varp]
      def initialize(api)
        @api = api
      end

      ##
      # Returns the Varp hash representing the current running varp
      # configuration from eAPI.
      #
      # Example
      #   {
      #     "mac_address": "aaaa.bbbb.cccc",
      #     "interfaces": {
      #         "Vlan100": {
      #             "addresses": [ "1.1.1.1", "2.2.2.2"]
      #         },
      #         "Vlan200": [...]
      #     }
      #   }
      #
      # @return [Hash] returns a Hash of attributes derived from eAPI
      def get
        result = @api.enable('show ip virtual-router')
        response = { 'mac_address' => result[0]['virtualMac'] }
        result = result[0]['virtualRouters']
        response['interfaces'] = result.each_with_object({}) do |intf, hsh|
          hsh[intf['interface']] = intf['virtualIps']
        end
        response
      end

      ##
      # Configures the virtual mac address globally
      #
      # @param [Hash] opts The configuration parameters for varp
      # @option opts [string] :value The value to set the mac-address to
      # @option opts [Boolean] :default The value should be set to default
      #
      # @return [Boolean] True if the commands succeed otherwise False
      def set_mac_address(opts = {})
        value = opts[:value]
        default = opts[:default] || false

        case default
        when true
          cmd = 'default ip virtual-router mac-address'
        when false
          cmd = (value ? "ip virtual-router mac-address #{value}" : \
                         'no ip virtual-router mac-address')
        end
        @api.config(cmd) == [{}]
      end

      ##
      # Configures the set of address for a given interface
      #
      # @param [String] name The name of the interface to configure
      # @param [Array] values The values to configure for the interface
      def set_addresses(name, values)
        get['interfaces'].each do |intf, attrs|
          attrs.each { |attr| remove_address(intf, attr) }
        end
        values.each { |value| add_address(name, value) }
      end

      ##
      ## Adds a virtual address to an interface
      #
      # @param [String] name The name of the interface to configure
      # @param [String] value The value to set the interface virtual
      #     address to
      #
      # @return [Boolean] True if the commands succeed otherwise false
      def add_address(name, value)
        @api.config(["interface #{name}",
                     "ip virtual-address address #{value}"]) == [{}, {}]
      end

      ##
      # Removes a virtual address from a given interface
      #
      # @param [String] name The name of the interface to configure
      # @param [String] value The value to remove from the list of virtual
      #     address configured for the interface
      #
      # @return [Boolean] True if the commands succeed otherwise False
      def remove_address(name, value)
        @api.config(["interface #{name}",
                     "no ip virtual-address address #{value}"]) == [{}, {}]
      end
    end
  end
end
