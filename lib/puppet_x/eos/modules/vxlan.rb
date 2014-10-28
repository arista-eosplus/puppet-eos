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
    # The Vxlan provides an instance for managing vxlan virtual tunnel
    # interfaces in EOS
    #
    class Vxlan
      def initialize(api)
        @api = api
      end

      ##
      # Returns the vlan data for the provided id with the
      # show vlan <id> command.  If the id doesn't exist then
      # nil is returned
      #
      #
      # @return [nil, Hash<String, String|Hash|Array>] Hash describing the
      #   vlan configuration specified by id.  If the id is not
      #   found then nil is returned
      def get
        @api.enable('show interfaces vxlan 1')
      end

      ##
      # Creates a new logical vxlan virtual interface in the running-config
      #
      # @return [Boolean] returns true if the command completed successfully
      def create
        @api.config("interface vxlan 1") == [{}]
      end

      ##
      # Deletes an existing vxlan logical interface from the running-config
      #
      # @return [Boolean] always returns true
      def delete
        @api.config("no interface vxlan 1") == [{}]
      end

      ##
      # Defaults an existing vxlan logical interface from the running-config)
      #
      # @return [Boolean] returns true if the command completed successfully
      def default
        @api.config("default interface vxlan 1") == [{}]
      end

      ##
      # Configures the source-interface parameter for the Vxlan interface
      #
      # @param [Hash] opts The configuration parameters for the VLAN
      # @option opts [string] :value The value to set the name to
      # @option opts [Boolean] :default The value should be set to default
      #
      # @return [Boolean] returns true if the command completed successfully
      def set_source_interface(opts = {})
        value = opts[:value]
        default = opts[:default] || false

        cmds = ["interface vxlan 1"]
        case default
        when true
          cmds << 'default vxlan source-interface'
        when false
          cmds << (value.nil? ?  'no vxlan source-interface': \
                                 "vxlan source-interface #{value}")
        end
        @api.config(cmds) == [{}, {}]
      end

      ##
      # Configures the multicast-group parameter for the Vxlan interface
      #
      # @param [Hash] opts The configuration parameters for the VLAN
      # @option opts [string] :value The value to set the name to
      # @option opts [Boolean] :default The value should be set to default
      #
      # @return [Boolean] returns true if the command completed successfully
      def set_multicast_group(opts = {})
        value = opts[:value]
        default = opts[:default] || false

        cmds = ["interface vxlan 1"]
        case default
        when true
          cmds << 'default vxlan multicast-group'
        when false
          cmds << (value.nil? ?  'no vxlan multicast-group': \
                                 "vxlan multicast-group #{value}")
        end
        @api.config(cmds) == [{}, {}]
      end
    end
  end
end
