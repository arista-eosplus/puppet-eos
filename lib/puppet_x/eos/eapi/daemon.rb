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
    # The Daemon class provides management of daemons using EOS CLI
    # commands over eAPI.  This class provides method for creating and
    # deleting daemons
    #
    class Daemon
      ##
      # Initializes a new instance of Daemon.
      #
      # @param [PuppetX::Eos::Eapi] api An instance of Eapi
      #
      # @return [PuppetX::Eos::Daemon] instance
      def initialize(api)
        @api = api
      end

      ##
      # Returns a hash of configured daemons from the running config
      #
      # Example
      #   {
      #     "agent": "command"
      #   }
      #
      # @return [Hash<String, String>] Hash of configured agents
      def get
        result = @api.enable('show running-config section daemon',
                             format: 'text')
        response = {}
        key = nil
        result.first['output'].split("\n").each do |entry|
          token = entry.strip.match(/^daemon\s(?<name>.*)$/)
          if !token.nil?
            key = token['name']
            response[key] = nil
          end
          token = entry.strip.match(/^command\s(?<command>.*)$/)
          if !token.nil?
            value = token['command']
            response[key] = value
          end
        end
        response
      end

      ##
      # Configures a new daemon agent in EOS using eAPI
      #
      # @param [String] name The name of the daemon agent
      # @param [String] command The path to the daemon executable
      #
      # @return [Boolean] True if the commands succeed otherwise False
      def create(name, command)
        return false unless File.executable?(command)
        return @api.config(["daemon #{name}", "command #{command}"]) == [{}, {}]
      end

      ##
      # Deletes a previously configured daemon from the running-configuration
      # in EOS using eAPI
      #
      # @param [String] name The name of the agent to delete
      #
      # @return [Boolean] True if the operation was successful otherwise
      #   False
      def delete(name)
        return @api.config("no daemon #{name}") == [{}]
      end
    end
  end
end
