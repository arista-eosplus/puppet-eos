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
    # The Snmp class provides a base class instance for working with
    # the global SNMP configuration
    #
    class Snmp
      ##
      # Initialize instance of Snmp
      #
      # @param [PuppetX::Eos::Eapi] api An instance of Eapi
      #
      # @return [PuppetX::Eos::Snmp]
      def initialize(api)
        @api = api
      end

      ##
      # Returns the SNMP hash representing global snmp configuration
      #
      # Example
      #   {
      #     "contact": <String>,
      #     "location": <String>,
      #     "chassis_id": <String>,
      #     "source_interface": <String>
      #   }
      #
      # @return [Array<Hash>] returns an Array of Hashes
      def get
        result =  @api.enable(['show snmp contact',
                               'show snmp location',
                               'show snmp chassis',
                               'show snmp source-interface'],
                              format: 'text')

        attr_hash = {}

        (0..3).each do |i|
          m = /(?<=:\s)(.*)$/.match(result[i]['output'])
          case i
          when 0
            attr_hash[:contact] = !m.nil? ? m[0] : ''
          when 1
            attr_hash[:location] = !m.nil? ? m[0] : ''
          when 2
            attr_hash[:chassis_id] = !m.nil? ? m[0] : ''
          when 3
            attr_hash[:source_interface] = !m.nil? ? m[0] : ''
          end
        end
        attr_hash
      end

      ##
      # Configures the snmp contact
      #
      # @param [Hash] opts The configuration parameters for snmp
      # @option opts [string] :value The value to set the contact to
      # @option opts [Boolean] :default The value should be set to default
      #
      # @return [Boolean] True if the commands succeed otherwise False
      def set_contact(opts = {})
        value = opts[:value] || false
        default = opts[:default] || false

        case default
        when true
          cmds = 'default snmp contact'
        when false
          cmds = (value ? "snmp contact #{value}" : 'no snmp contact')
        end
        @api.config(cmds) == [{}]
      end

      ##
      # Configures the snmp location
      #
      # @param [Hash] opts The configuration parameters for snmp
      # @option opts [string] :value The value to set the location to
      # @option opts [Boolean] :default The value should be set to default
      #
      # @return [Boolean] True if the commands succeed otherwise False
      def set_location(opts = {})
        value = opts[:value] || false
        default = opts[:default] || false

        case default
        when true
          cmds = 'default snmp location'
        when false
          cmds = (value ? "snmp location #{value}" : 'no snmp location')
        end
        @api.config(cmds) == [{}]
      end

      ##
      # Configures the snmp chassis-id
      #
      # @param [Hash] opts The configuration parameters for snmp
      # @option opts [string] :value The value to set the chassis-id to
      # @option opts [Boolean] :default The value should be set to default
      #
      # @return [Boolean] True if the commands succeed otherwise False
      def set_chassis_id(opts = {})
        value = opts[:value] || false
        default = opts[:default] || false

        case default
        when true
          cmds = 'default snmp chassis'
        when false
          cmds = (value ? "snmp chassis #{value}" : 'no snmp chassis')
        end
        @api.config(cmds) == [{}]
      end

      ##
      # Configures the snmp source-interface
      #
      # @param [Hash] opts The configuration parameters for snmp
      # @option opts [string] :value The value to set the source-interface to
      # @option opts [Boolean] :default The value should be set to default
      #
      # @return [Boolean] True if the commands succeed otherwise False
      def set_source_interface(opts = {})
        value = opts[:value] || false
        default = opts[:default] || false

        case default
        when true
          cmds = 'default snmp source-interface'
        when false
          cmds = (value ? "snmp source-interface #{value}" : \
                          'no snmp source-interface')
        end
        @api.config(cmds) == [{}]
      end
    end
  end
end
