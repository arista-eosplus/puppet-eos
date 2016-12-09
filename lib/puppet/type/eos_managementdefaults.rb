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
# encoding: utf-8

# Work around due to autoloader issues: https://projects.puppetlabs.com/issues/4248
require File.dirname(__FILE__) + '/../../puppet_x/eos/utils/helpers'

Puppet::Type.newtype(:eos_managementdefaults) do
  @doc = <<-EOS
    Configure the management defaults on Arista EOS.
    It allows to set the value for secret hash.
    Accepted values are: md5 and sha512

    Example:

        eos_managementdefaults { 'settings':
          secret_hash     => 'sha512',
        }
  EOS

  # Parameters

  newparam(:name) do
    desc <<-EOS
      The name parameter identifies the global management defaults
      configuration and should be configured as 'settings'.  All
      other values for name will be silently ignored by the
      eos_managementdefaults provider.
    EOS
    isnamevar
  end

  # Properties (state management)

  newproperty(:secret_hash) do
    desc <<-EOS
      The secret_hash property configures the hash algoritm to use
      to store secrets.
    EOS

    validate do |value|
      unless value =~ /(md5|sha512)/
        fail "value #{value.inspect} is invalid, must be a either " \
             'md5 or sha512"'
      end
    end
  end
end
