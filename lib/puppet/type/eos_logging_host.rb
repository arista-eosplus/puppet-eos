#
# Copyright (c) 2014, Arista Networks, Inc.
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

# Work around due to autoloader issues: https://projects.puppetlabs.com/issues/4248
require File.dirname(__FILE__) + '/../../puppet_x/eos/utils/helpers'

Puppet::Type.newtype(:eos_logging_host) do
  @doc = <<-EOS
    Manage logging destination hosts in Arista EOS to receive syslog messages.

    Example:

        eos_logging_host { '10.0.0.150': }
        eos_logging_host { '10.0.0.151':
          port     => 8514,
          protocol => 'tcp',
          vrf      => 'mgmt',
        }

  EOS

  ensurable

  # Parameters

  newparam(:name) do
    desc <<-EOS
      The parameter specifies the name for the logging host. It should be in
      either IP format or FQDN format.
    EOS

    validate do |value|
      if value.is_a? String then super(value)
      else fail "value #{value.inspect} is invalid, must be a String."
      end
    end
  end

  # Properties (state management)

  newproperty(:port) do
    desc <<-EOS
      Port to which logs will be sent on the host. Default: 514
    EOS

    munge { |value| Integer(value) }

    validate do |value|
      unless value.to_i.between?(1, 65_535)
        fail "value #{value.inspect} must be between 1 and 65535"
      end
    end
  end

  newproperty(:protocol) do
    desc <<-EOS
      Protocol may be 'udp' or 'tcp'.  Default: 'udp'
    EOS
    newvalues(:udp, :tcp)
  end

  newproperty(:vrf) do
    desc <<-EOS
      If present, configures the logging host in a non-default VRF.
    EOS

    validate do |value|
      if value.is_a? String then super(value)
      else fail "value #{value.inspect} is invalid, must be a String."
      end
    end
  end
end
