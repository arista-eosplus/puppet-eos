# Copyright (c) 2016, Arista Networks, Inc.
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
require 'puppet/type'
require 'pathname'

module_lib = Pathname.new(__FILE__).parent.parent.parent.parent
require File.join module_lib, 'puppet_x/eos/provider'

Puppet::Type.type(:eos_switchconfig).provide(:eos) do
  desc 'Manage the entire running-config on Arista EOS. Requires rbeapi.'

  confine operatingsystem: [:AristaEOS] unless ENV['RBEAPI_CONNECTION']
  confine feature: :rbeapi

  # Create methods that set the @property_hash for the #flush method
  mk_resource_methods

  # Mix in the api as instance methods
  include PuppetX::Eos::EapiProviderMixin

  # Mix in the api as class methods
  extend PuppetX::Eos::EapiProviderMixin

  def self.instances
    # Get the current value
    conf = node.get_config(config: 'running-config', as_string: true)
    provider_hash = { name: 'running-config', ensure: :present }
    provider_hash[:content] = conf
    provider_hash[:staging_file] = 'puppet-config'
    [new(provider_hash)]
  end

  def self.prefetch(resources)
    instances.each do |prov|
      # rubocop:disable Lint/AssignmentInCondition
      if resource = resources[prov.name]
        resource.provider = prov
      end
    end
  end

  def exists?
    @property_hash[:ensure] == :present
  end

  def initialize(resource = {})
    super(resource)
    @property_flush = {}
  end

  def content=(value)
    @property_flush[:content] = value
  end

  def staging_file=(value)
    @property_flush[:staging_file] = value
  end

  def flush
    begin
      # Write staging_file to flash
      File.open('/mnt/flash/' + @property_flush[:staging_file], 'w') do |f|
        f.puts @property_flush[:content]
      end

      # Run 'configure replace' on the switch
      command = ['FastCli -p15 -c "',
                 'configure replace flash:',
                 @property_flush[:staging_file],
                 '"'].join
      result = `#{command}`
      fail result if $CHILD_STATUS.to_i.nonzero? || !result.empty?
    rescue StandardError => msg
      fail msg
    end

    # Merge in values that have changed
    @property_hash.merge!(@property_flush)
  end
end
