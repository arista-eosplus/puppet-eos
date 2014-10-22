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
    # The Vlan class provides an interface for working wit VLAN resources
    # in EOS.  All configuration is sent and received using eAPI.  In order
    # to use this class, eAPI must be enablined in EOS.  This class
    # can be instatiated either using the Eos::Eapi::Switch.load_class
    # method or used directly.
    #
    # @example Get vlan 100
    #   >> eapi = Eos::Eapi::Switch.new(hostname=>'192.168.1.16')
    #   >> vlans = Eos::Eapi::Vlan.new(eapi)
    #   >> vl100 = vlans.get(100)
    #   >> vl100['name']
    #   => 'Vlan100'
    class Vlan
      def initialize(api)
        @api = api
      end

      ##
      # Returns the vlan data for the provided id with the
      # show vlan <id> command.  If the id doesn't exist then
      # nil is returned
      #
      # @param [String] id The VLAN ID (e.g. 1)
      #
      # @return [nil, Hash<String, String|Hash|Array>] Hash describing the
      #   vlan configuration specified by id.  If the id is not
      #   found then nil is returned
      def get(id = nil)
        if id.nil?
          cmd = [ 'show vlan', 'show vlan trunk group' ]
        else
          cmd = [ "show vlan #{id}", "show vlan #{id} trunk group" ]
        end
        resp = @api.enable(cmd)
        result = resp.first['vlans']
        result.each do |vid, hsh|
          result[vid]['trunkGroups'] = resp[1]['trunkGroups'][vid]['names']
        end
      end

      ##
      # Adds a new VLAN resource in EOS setting the VLAN ID to id.  The
      # VLAN ID must be in the valid range of 1 through 4094
      #
      # @param [String] id The VLAN identifier (e.g. 1)
      #
      # @return [Boolean] returns true if the command completed successfully
      def add(id)
        @api.config("vlan #{id}") == [{}]
      end

      ##
      # Deletes an existing VLAN resource in EOS as specified by ID.  If
      # the supplied VLAN ID does not exist no error is raised
      #
      # @param [String] id The VLAN identifier (e.g. 1)
      #
      # @return [Boolean] always returns true
      def delete(id)
        @api.config("no vlan #{id}") == [{}]
      end

      ##
      # Defaults an existing VLAN resource in EOS as specified by ID.  If
      # the supplied VLAN ID does not exist no error is raised.  Note: setting
      # a vlan to default is equivalent to negating it
      #
      # @param [String] id The VLAN identifier (e.g. 1)
      #
      # @return [Boolean] returns true if the command completed successfully
      def default(id)
        @api.config("default vlan #{id}") == [{}]
      end

      ##
      # Configures the VLAN name of the VLAN specified by ID.  set_name maps
      # to the EOS name WORD command.  Spaces in the name will be converted
      # to _
      #
      # @param [Hash] opts The configuration parameters for the VLAN
      # @option opts [String] :id The VLAN ID to change
      # @option opts [string] :value The value to set the name to
      # @option opts [Boolean] :default The value should be set to default
      #
      # @return [Boolean] returns true if the command completed successfully
      def set_name(opts = {})
        id = opts[:id]
        value = opts[:value]
        default = opts[:default] || false

        cmds = ["vlan #{id}"]
        case default
        when true
          cmds << 'default name'
        when false
          cmds << (value.nil? ?  'no name': "name #{value}")
        end
        @api.config(cmds) == [{}, {}]
      end

      ##
      # Configures the administrative state of the VLAN specified by ID.  The
      # set_state function accepts 'active' or 'suspend' to configure the
      # VLAN state.
      #
      # @param [Hash] opts The configuration parameters for the VLAN
      # @option opts [String] :id The VLAN ID to change
      # @option opts [string] :value The value to set the state to
      # @option opts [Boolean] :default The value should be set to default
      #
      # @return [Boolean] returns true if the command completed successfully
      def set_state(opts = {})
        id = opts[:id]
        value = opts[:value]
        default = opts[:default] || false

        cmds = ["vlan #{id}"]
        case default
        when true
          cmds << 'default state'
        when false
          cmds << (value.nil? ? 'no state' : "state #{value}")
        end
        @api.config(cmds) == [{}, {}]
      end

      ##
      # Configures the trunk group value for the VLAN specified by ID.  The
      # trunk group setting is typically used to associate VLANs with MLAG
      # configurations
      #
      # @param [Hash] opts The configuration parameters for the VLAN
      # @option opts [String] :id The VLAN ID to change
      # @option opts [string] :value The value to set the trunk group to
      # @option opts [Boolean] :default The value should be set to default
      #
      # @return [Boolean] returns true if the command completed successfully
      def set_trunk_group(params = {})
        id = params[:id]
        value = params[:value]
        default = params[:default] || false

        cmds = ["vlan #{id}"]
        case default
        when true
          cmds << 'default trunk group'
        when false
          cmds << (value.nil? ? 'no trunk group' : "trunk group #{value}")
        end
        @api.config(cmds) == [{}, {}]
      end
    end
  end
end
