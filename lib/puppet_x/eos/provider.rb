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
require 'rbeapi/client'

##
# PuppetX namespace
module PuppetX
  ##
  # Eos namesapece
  module Eos
    ##
    # EapiProviderMixin module
    module EapiProviderMixin
      def prefetch(resources)
        provider_hash = instances.each_with_object({}) do |provider, hsh|
          hsh[provider.name] = provider
        end

        resources.each_pair do |name, resource|
          resource.provider = provider_hash[name] if provider_hash[name]
        end
      end

      ##
      # Instance of Rbeapi::Client::Node used to sending and receiving
      # eAPI messages.  In addition, the node object provides access to
      # Ruby Client for eAPI API modules used to configure EOS resources.
      #
      # @return [Node] An instance of Rbeapi::Client::Node used to send
      #   and receive eAPI messages
      def node
        return @node if @node
        Rbeapi::Client.load_config(ENV['RBEAPI_CONF']) if ENV['RBEAPI_CONF']
        connection_name = ENV['RBEAPI_CONNECTION'] || 'localhost'
        @node = Rbeapi::Client.connect_to(connection_name)
      end

      ##
      # validate checkes the set of opts that have been configured for a
      # resource against the required options.  If any of the required options
      # are missing, this method will fail.
      #
      # @api private
      #
      # @param [Hash] :opts The set of options configured on the resource
      #
      # @param [Array] :req The set of required option keys
      def validate(req, opts = {})
        missing = req.reject { |k| opts[k] }
        errors = !missing.empty?
        msg = "Invalid options #{opts.inspect} missing: #{missing.join(', ')}"
        fail Puppet::Error, msg if errors
      end
      private :validate

      ##
      # remove_puppet_keys deletes the :provider, :ensure, :loglevel keys
      # from the passed in hash. This allows the provider to pass in
      # property_flush to the rbeapi calls without having key:value pairs
      # in the hash that are not required for the rbeapi call.
      #
      # @api private
      #
      # @param [Hash] :property_flush The providers property_flush hash.
      def remove_puppet_keys(property_flush)
        property_flush.delete(:provider)
        property_flush.delete(:ensure)
        property_flush.delete(:loglevel)
      end
      private :remove_puppet_keys

      ##
      # map_boolean maps a ruby symbol of a boolean value to an actual
      # ruby value for the specified key in the specified hash.
      # (ex: :true => true or :false => false). This is required
      # because puppet uses the symbol but the rbeapi library expects
      # a boolean value.
      #
      # @api private
      #
      # @param [Hash] :property_flush The providers property_flush hash.
      # @param [Hash] :key The key in the hash whose value is a boolean.
      def map_boolean(property_flush, key)
        return unless property_flush.key?(key)
        property_flush[key] = (property_flush[key] == :true ? true : false)
      end
      private :map_boolean

      ##
      # convert_keys recursivly converts the type of the keys in the hash.
      # The keys are converted to either symbols or strings depending on
      # the value of the 'to' parameter.
      #
      # @api private
      #
      # @param [Hash] :hash The hash to have the keys converted to symbols.
      # @param [String] :to If set to 'symbols' then the keys are converted
      #   symbols. If set to 'strings' then the keys are converted to strings.
      #   For any other value then the original key is used.
      #
      # @return [Hash] The new converted hash.
      def convert_keys(hash, to)
        hash.each_with_object({}) do |(key, value), result|
          new_key = case key
                    when String then to == 'symbols' ? key.to_sym : key
                    when Symbol then to == 'strings' ? key.to_s : key
                    else key
                    end
          new_value = case value
                      when Hash then symbolize_keys(value)
                      else value
                      end
          result[new_key] = new_value
          result
        end
      end
      private :convert_keys
    end
  end
end
