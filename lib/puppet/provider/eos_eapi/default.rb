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
require 'puppet/type'
require 'puppet_x/eos/provider'

Puppet::Type.type(:eos_eapi).provide(:eos) do

  commands cli: 'FastCli'

  # Create methods that set the @property_hash for the #flush method
  mk_resource_methods

  # Mix in the api as instance methods
  include PuppetX::Eos::EapiProviderMixin

  # Mix in the api as class methods
  extend PuppetX::Eos::EapiProviderMixin

  def self.instances
    commands = 'show running-config section management api http-commands'
    resp = cli('-p', '15', '-A', '-c', "#{commands}")
    Puppet.debug("#{resp}")

    provider_hash = { name: 'eapi', ensure: :present }

    state = !/no\sshutdown/.match(resp).nil?
    protocol = /no\sprotocol\shttp/.match(resp).nil? ? 'https' : 'http'
    port = /'port\s(?<port>\d+)'/.match(resp)
    port = protocol == 'http' ? '443' : '80' if port.nil?

    provider_hash['enable'] = state
    provider_hash['protocol'] = protocol
    provider_hash['port'] = port

    [new(provider_hash)]
  end

  def self.prefetch(resources)
    provider_hash = instances.each_with_object({}) do |provider, hsh|
      hsh[provider.name] = provider
    end

    resources.each_pair do |name, resource|
      resource.provider = provider_hash[name] if provider_hash[name]
    end
  end

  def initialize(resource = {})
    super(resource)
    @property_flush = {}
  end

  def protocol=(val)
    @property_flush[:protocol] = val
  end

  def port=(val)
    @property_flush[:port] = val
  end

  def enable=(val)
    @property_flush[:enable] = val
  end

  def exists?
    return @property_hash[:ensure] == 'present'
  end

  def flush
    flush_protocol_and_port
    flush_enable
    @property_hash = resource.to_hash
  end

  def create
    commands = ['configure', 'management api http-commands']
    case resource[:protocol]
    when 'http'
      commands << 'no protocol https' << "protocol http port #{port}"
    when 'https'
      commands << 'no protocol http' << "protocol https port #{port}"
    end
    commands << 'no shutdown'
    commands = commands.join('\n')
    cli('-p', '15', '-A', '-e', '-c', "$'#{commands}'")
    @property_hash = { name: resource[:name],  ensure: :present }
  end

  def destroy
    cli('-p', '15', '-A', '-c',
        'configure\nmanagement api http-commands\nshutdown')
  end

  def flush_protocol_and_port
    protocol = @property_flush[:protocol] || resource[:protocol]
    port = @property_flush[:port] || resource[:port]
    commands = %w(enable, config) << 'management api http-commands'
    case protocol
    when 'https'
      commands << 'no protocol http' << "protocol https port #{port}"
    when 'http'
      commands << 'no protocol https' << "protocol http port #{port}"
    end
    cli('-p', '15', '-A', '-c', commands)
  end

  def flush_enable
    value = @property_flush[:enable]
    return nil unless value
    args = value ? 'shutdown' : 'no shutdown'
    commands = %w(enable, config) << 'management api http-commands'
    commands << args
    cli('-p', '15', '-A', '-c', commands)
  end
end

