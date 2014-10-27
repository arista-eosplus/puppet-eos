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
    # The Extensio class provides management of extensions in EOS. Extensions
    # are simply RPM packages that can loaded onto the switch.  This class
    # allows installing, deleting and configuring extensions
    #
    class Extension

      BOOTEXT = '/mnt/flash/boot-extensions'

      def initialize(api)
        @api = api
      end

      ##
      # Retrieves all of the extenions loaded in EOS and returns an array
      # of hashes using the 'show extensions' command over eAPI.
      #
      # Example:
      #   [{
      #     "ruby-1.9.3-1.swix": {
      #       "status": "installed",   # installed, forceInstalled
      #       "version": "1.9.3.484",
      #       "presence": "present",
      #       "release": "32.eos4",
      #       "numRpms": 10,
      #       "error": false
      #     }
      #   }]
      #
      # @return [Hash<Hash<String, String>>] Nested hash describing
      #   the extension details.  If there are no extensions then an
      #   empty Hash is returned
      def get
        @api.enable('show extensions')
      end

      ##
      # Returns if file is loaded on boot or not
      #
      # @param [String] name The name of the file
      #
      # @return [Boolean] True if it loades on boot otherwise False
      def autoload?(name)
        name = URI(name).to_s.split("/")[-1]
        return File.open(BOOTEXT).read.scan(/#{name}[\sforce\n|\n]/).size > 0
      end

      ##
      # Copies and installs the extension from a remote server to the
      # node running EOS using the eAPI coopy command.
      #
      # @param [String] url The full url to the RPM
      # @param [String] force Specifies the use of the force keyword
      #
      # @return [Boolean] True if the installation succeeds and False if it
      #   does not succeed
      def install(url, force)
        force = false if force.nil?
        result = @api.enable("copy #{url} extension:")
        return load(url, force)
      end

      ##
      # Loads an existing extension into EOS.  The extension must already
      # be copied over to the node using #create
      #
      # @params [String] name The name of the extension to load
      # @param [Hash] opt Options for loading the extions
      # @option opts [Boolean] :force Appends force to the command
      #
      # @return [Boolean] True if the command succeeds or False if it does
      #   not succeed
      def load(name, force)
        name = URI(name).to_s.split("/")[-1]
        command = "extension #{name}"
        command << ' force' if force
        return @api.enable(command) == [{}]
      end

      ##
      # Uninstalls and removes and extension from an EOS node.  The extension
      # will be unloaded and deleted from /mnt/flash
      #
      # @params [String] name The name of the extension to remove
      #
      # @return [Boolean] True if the command succeeds or False if it does
      #   not succeed
      def delete(name)
        name = URI(name).to_s.split("/")[-1]
        set_autoload(:false, name, false)
        @api.enable("no extension #{name}")
        return @api.enable("delete extension:#{name}") == [{}]
      end

      ##
      # Configures the extension to persistent on system restarts
      #
      # @param [String] enabled Whether or not the extension is enabled
      # @param [String] name The name of the extension
      # @param[Boolean] force Specifies if the force keyword should be used
      #
      # @return [Boolean] True if the extension was set to autoload or False
      #   if it was not
      def set_autoload(enabled, name, force)
        enabled = :true if enabled.nil?
        force = false if force.nil?

        name = URI(name).to_s.split("/")[-1]
        entry = "#{name}"
        entry << " force" if force

        case enabled
        when :true
          if File.open(BOOTEXT).read.scan(/#{name}[\sforce\n|\n]/).size == 0
            File.open(BOOTEXT, 'a') { |f| f << "#{entry}\n" }
            return true
          end
        when :false
          contents = File.readlines(BOOTEXT)
          contents.delete("#{name}\n")
          File.open(BOOTEXT, 'w') do |f|
            f.puts(contents)
          end
          return true
        end
        return false
      end
    end
  end
end
