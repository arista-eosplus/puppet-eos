#
# Copyright (c) 2016, Arista Networks, Inc.
# All rights reserved.
#
# Redistribution and use in source and binary forms, with or without
# modification, are permitted provided that the following conditions are
# met:
#
#  Redistributions of source code must retain the above copyright notice,
#  this list of conditions and the following disclaimer.
#
#  Redistributions in binary form must reproduce the above copyright
#  notice, this list of conditions and the following disclaimer in the
#  documentation and/or other materials provided with the distribution.
#
#  Neither the name of Arista Networks nor the names of its
#  contributors may be used to endorse or promote products derived from
#  this software without specific prior written permission.
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

Puppet::Type.newtype(:eos_switchconfig) do
  @doc = <<-EOS
    Manage the complete EOS config as a file

    Use files, templates, or concatenated files/template blocks to build
    and manage the entire EOS configuration as a single object.  By default,
    changes will be written to flash:startup-config then the 'configure
    replace' in EOS will safely overwrite the running-config.

    Examples:

        eos_switchconfig { 'running-config':
          source  => template(),
        }

        eos_switchconfig { 'running-config':
          content => template(),
        }


        eos_switchconfig { 'running-config':
          source  => template(),
          file    => 'config-puppet',
        }
  EOS

  require 'rbeapi/switchconfig'
  require 'set'

  ensurable

  # Parameters

  newparam(:name) do
    desc <<-EOS
      The name of this resource should always be 'running-config'
    EOS

    validate do |value|
      unless value.to_s =~ /^running-config$/
        fail 'value #{value.inspect} is invalid, must be ' \
            '"running-config"'
      end
    end
  end

  # Properties (state management)

  newproperty(:source, :array_matching => :all) do
    desc <<-EOS
      Source is a list of templates which will be concatenated to create the
      desired running-config.

      Example configuration

      source => ['tg1', 'tg2']

      The default configure is an empty list
    EOS

    # TODO: Not implemented?

    validate do |value|
      unless value.is_a? String
        fail "value #{value.inspect} is not a String"
      end
    end
  end

  newproperty(:content) do
    desc <<-EOS
      The content is a string or URI to a file to be used as the EOS
      running-config.
    EOS
    validate do |value|
      unless value.is_a? String
        fail "value #{value.inspect} is not a String"
      end
    end

    def insync?(current)
      # Compare the current and desired configs
      org_swc = Rbeapi::SwitchConfig::SwitchConfig.new(current)
      new_swc = Rbeapi::SwitchConfig::SwitchConfig.new(should)
      @results = org_swc.compare(new_swc)

      # If results are both empty then nothing needs to change.
      @results[0].cmds.empty? && \
        @results[0].children.empty? && \
        @results[1].cmds.empty? && \
        @results[1].children.empty?
    end

    def change_to_s(_current, _desired)
      # Update the output when there are differences to show the
      # EOS config blocks that were changed.
      current_lines = []
      desired_lines = []
      @results[0].children.each do |block|
        current_lines << ([block.line] + block.cmds).join("\n")
      end
      @results[1].children.each do |block|
        desired_lines << ([block.line] + block.cmds).join("\n")
      end
      "changed '#{current_lines.join("\n")}' to
        '#{desired_lines.join("\n")}'"
    end
  end

  newproperty(:staging_file) do
    desc <<-EOS
      The staging_file is the actual file which will be managed on flash:
      on the switch before running 'configure replace'.

      The default value is 'puppet-config' stored on flash:.
    EOS

    validate do |value|
      unless value.is_a? String
        fail "value #{value.inspect} is not a String"
      end
    end

    def insync?(_current)
      if File.exist?("/mnt/flash/#{should}")
        true
      else
        false
      end
    end
  end
end
