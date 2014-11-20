#
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
    class Logging
      ##
      # Initialize instance of Logging
      #
      # @param [PuppetX::Eos::Eapi] api An instance of Eapi
      #
      # @return [PuppetX::Eos::Logging]
      def initialize(api)
        @api = api
      end

      ##
      # Returns a hash of key/value pairs that repesent the logging
      # configuration in EOS
      #
      # Example
      #   {
      #     "hosts": [Array]
      #   }
      #
      # @return [Hash] returns a hash of key/value pairs
      def get
        result = @api.enable('show running-config section ^logging\shost',
                             format: 'text')
        output = result.first['output']
        { 'hosts' => output.scan(/(?<=host\s)[\d|\.]+/) }
      end

      ##
      # Configures the list of host to set as destination targets for
      # for sending syslog messages to
      #
      # @param [Array] values The list of targest to configure as destination
      #     hosts for receiving syslog messages
      #
      # @return [Boolean] True if the commands succeed otherwise False
      def set_hosts(values)
        get['hosts'].each { |host| remove_host(host) }
        values.each { |host| add_host(host) }
      end

      ##
      # Adds a new host to the set of destination hosts for sending
      # logging information to
      #
      # @param [String] host The IP address or hostname of the destination
      #     host to configure
      #
      # @returns [Boolean] True if the commands succeed otherwise False
      def add_host(host)
        @api.config("logging host #{host}") == [{}]
      end

      ##
      # Removes the specified host from the set of destinations for sending
      # logging information to
      #
      # @paraam [String] host The IP address or hostname of the destination
      #     host to remove
      #
      # @return [Boolean] True if the command succeeds otherwise False
      def remove_host(host)
        @api.config("no logging host #{host}") == [{}]
      end
    end
  end
end
