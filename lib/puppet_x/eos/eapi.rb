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
require 'net/http'
require 'json'
# require 'SecureRandom'

require 'puppet_x/eos/autoload'

##
# PuppetX namespace
module PuppetX
  ##
  # Eos namespace
  module Eos
    ##
    # Eapi class
    class Eapi
      attr_reader :hostname
      attr_reader :port
      attr_reader :username
      attr_reader :password
      attr_reader :enable_pwd
      attr_reader :use_ssl
      attr_reader :uri

      ##
      # Initialize an instance of Eapi.  This class provides direct API
      # connectivity to command API running on Arista EOS switches.  This
      # class will send and receive eAPI calls using JSON-RPC over HTTP/S.
      #
      # @param [Hash] opt The eAPI configuration options
      # @option opts [String]  :hostname Hostname or IP address of eAPI endpoint
      # @option opts [String]  :username eAPI username
      # @option opts [String]  :password eAPI password
      # @option opts [String]  :enable_pwd Enable mode password
      # @option opts [Boolean] :use_ssl eAPI protocol
      # @option opts [Integer] :port eAPI port
      #
      # @return [Eos::Eapi] instance of Eos::Eapi
      def initialize(opts = {})
        @hostname = opts[:hostname] || 'localhost'
        @username = opts[:username] || 'admin'
        @password = opts[:password] || ''
        @enable_pwd = opts[:enable_pwd] || ''
        @protocol = (!opts[:use_ssl] && opts.key?(:use_ssl)) ? 'http' : 'https'
        @port = opts[:port] || (@protocol == 'https' ? '443' : '80')
      end

      ##
      # uri returns a URI object
      #
      # @return [Uri]
      def uri
        return @uri if @uri
        @uri = URI("#{@protocol}://#{@hostname}:#{@port}")
      end

      ##
      # http returns a memoized HTTP object instance
      #
      # @return [Net::Http]
      def http
        return @http if @http
        @http = Net::HTTP.new(uri.host, uri.port)
      end

      ##
      # Autloads an eAPI provider module for working with EOS objects
      #
      # @return [Object]
      def method_missing(name)
        name = "PuppetX::Eos::#{name}"
        klass = name..split('::').inject(Object) { |o, c| o.const_get c }
        klass.new self
      end

      ##
      # The request method converts an array of commands to a valid
      # eAPI request hash.  The request message can be then sent to the eAPI
      # end point using JSON-RPC over HTTP/S.  eAPI exposes a single method,
      # runCmds.
      #
      # @param [Array<String>] command An array of commands to be inserted
      #
      # @return [Hash] returns a hash that can be serialized to JSON and sent
      #   to the command API end point
      def request(command, params = {})
        # id = params[:id] || SecureRandom.uuid
        id = 1
        format = params[:format] || 'json'
        cmds = [*command]
        params = { 'version' => 1, 'cmds' => cmds, 'format' => format }
        { 'jsonrpc' => '2.0', 'method' => 'runCmds',
          'params' => params, 'id' => id }
      end

      ##
      # The invoke method takes the JSON formatted message and sends it
      # to the eAPI end point.   The response return value from command API
      # is parsed from JSON and returned as an array of hashes with the output
      # for each command
      #
      # @param [Array<String>] ordered list of commands to send to the host
      #
      # return [Array<Hash>] ordered list of ouput from the command execution
      def invoke(body)
        request = Net::HTTP::Post.new('/command-api')
        request.body = JSON.dump(body)
        request.basic_auth @username, @password
        response = http.request(request)
        JSON(response.body)
      end

      ##
      # The execute method takes the array of commands and inserts
      # the 'enable' command to make certain the commands are executed in
      # priviledged mode.   If an enable password is needed, it is inserted
      # into the command stack as well.  Since the enable command will generate
      # an empty hash on the response, it is popped off before returning the
      # array of hashes
      #
      # @param [Array<String>] ordered list of commands to insert into the
      #   POST request
      #
      # @return [Array<Hash>] ordered list of output from the command
      #
      # @raise [Eos::Eapi::CommandError] if the response from invoke contains
      #   the key error
      def execute(commands, options = {})
        commands.insert(0, cmd: 'enable', input: @enable_pwd)
        resp = invoke(request(commands, options))
        fail 'Unable to execute commands' if resp.key?('error')
        result = resp['result']
        result.shift
        result
      end

      ##
      # The config method is a convenience method that will handling putting
      # the switch into config mode prior to executing commands.  The method
      # will insert 'config' at the top of the command stack and then pop
      # the empty hash from the response output before return the array
      # to the caller
      #
      # @param [Array<String>] commands An ordered list of commands to execute
      #
      # @return [Array<Hash>] ordered list of output from commands
      def enable(commands, options = {})
        commands = [*commands] unless commands.respond_to?('each')
        execute(commands, options)
      end

      ##
      # The enable method is a convenience method that will handling putting
      # the switch into priviledge mode prior to executing commands.
      #
      # @param [Array<String>] commands An ordered list of commands to execute
      #
      # @return [Array<Hash>] ordered list of output from commands
      def config(commands)
        begin
          commands = [*commands] unless commands.respond_to?('each')
          commands.insert(0, 'configure')
          result = enable(commands)
          result.shift
          result
        rescue
          return nil
        end
      end
    end
  end
end
