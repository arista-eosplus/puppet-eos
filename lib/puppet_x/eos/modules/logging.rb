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
    # The Logging class provides an implementation for working with
    # the global logging configuration on the specified node
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
      # configuration in EOS.  The hosts key is populated by the
      # LoggingHosts instance
      #
      # Example
      #   {
      #     "hosts": {...}
      #   }
      #
      # @return [Hash] returns a hash of key/value pairs
      def get
        { 'hosts' => hosts.getall }
      end

      ##
      # Returns an instace of LoggingHosts for configuring the
      # collection of host destinations in the nodes configuration
      #
      # @return [PuppetX::Eos::LoggingHosts
      def hosts
        return @hosts if @hosts
        @hosts = LoggingHosts.new(@api)
      end
    end

    ##
    # The LoggingHosts class provides an implementation for configuring
    # individual host destinations in the current nodes running config
    #
    class LoggingHosts
      ##
      # Initialize instance of Logging host
      #
      # @param [PuppetX::Eos::Eapi] api An instance of Eapi
      #
      # @return [PuppetX::Eos::LoggingHosts]
      def initialize(api)
        @api = api
      end

      ##
      # Returns a hash of all configured logging hosts.  For the initial
      # release, the hosts key/value pairs will always return an empty
      # hash.  This will be used in the future for additional attributes
      #
      # Example
      #   {
      #     "1.2.3.4": {},
      #     "log.example.net": {}
      #   }
      #
      # @return [Hash] returns a hash with the host name as the index
      def getall
        result = @api.enable('show running-config section ^logging\shost',
                             format: 'text')
        output = result.first['output']
        hosts = output.scan(/(?<=host\s)[\d|\.|\w]*/)
        hosts.each_with_object({}) do |host, hsh|
          hsh[host] = {}
        end
      end

      ##
      # Adds a new host to the set of destination hosts for sending
      # logging information to
      #
      # @param [String] host The IP address or hostname of the destination
      #     host to configure
      #
      # @returns [Boolean] True if the commands succeed otherwise False
      def create(host)
        @api.config("logging host #{host}") == [{}]
      end

      ##
      # Removes the specified host from the set of destinations for sending
      # logging information to
      #
      # @param [String] host The IP address or hostname of the destination
      #     host to remove
      #
      # @return [Boolean] True if the command succeeds otherwise False
      def delete(host)
        @api.config("no logging host #{host}") == [{}]
      end
    end
  end
end
