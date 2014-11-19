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
      #     "address": <string>
      #     "interfaces": {...}
      #   }
      #
      # @return [Hash] returns a Hash of attributes derived from eAPI
      def get
        result = @api.enable('show ip virtual-router')
        { 'address' => result[0]['virtualMac'], 'interfaces' => {} }
      end

      ##
      # Configures the virtual mac address globally
      #
      # @param [Hash] opts The configuration parameters for varp
      # @option opts [string] :value The value to set the mac-address to
      # @option opts [Boolean] :default The value should be set to default
      #
      # @return [Boolean] True if the commands succeed otherwise False
      def set_address(opts = {})
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
    end
  end
end
