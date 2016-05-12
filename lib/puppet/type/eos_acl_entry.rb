#
# Copyright (c) 2015, Arista Networks, Inc.
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

Puppet::Type.newtype(:eos_acl_entry) do
  @doc = <<-EOS
    Manage access-lists on Arista EOS.

    Example:

        eos_acl_entry{ 'test1:10':
          ensure       => present,
          acltype      => standard,
          action       => permit,
          srcaddr      => '1.2.3.0',
          srcprefixlen => 8,
          log          => true,
        }
  EOS

  ensurable

  # Parameters

  newparam(:name) do
    desc <<-EOS
      The name parameter is a composite namevar that combines the
      access-list name and the sequence number delimited by the
      colon (:) character

      For example, if the access-list name is foo and the sequence
      number for this rule is 10 the namvar would be constructed as
      "foo:10"

      The composite namevar is required to uniquely identify the
      specific list and rule to configure
    EOS

    validate do |value|
      fail "value #{value.inspect} must contain a colon" unless value =~ /:/
    end
  end

  # Properties (state management)

  newproperty(:acltype) do
    desc <<-EOS
      The ACL type which is either standard and extended. Standard ACLs
      filter only on the source IP address. Extended ACLs allow
      specification of source and destination IP addresses.
    EOS
    newvalues(:standard, :extended)
  end

  newproperty(:action) do
    desc <<-EOS
      The action for the rule can be either permit or deny. Deny is the
      default value. Packets filtered by a permit rule are accepted by
      interfaces to which the ACL is applied. Packets filtered by a
      deny rule are dropped by interfaces to which the ACL is applied.
    EOS
    newvalues(:permit, :deny)
  end

  newproperty(:srcaddr) do
    desc <<-EOS
      The source IP address. The following options are supported:

      network_address - subnet address where srcprefixlen defines mask
      any             - Packets from all addresses are filtered.
      host ip_addr    - IP address (dotted decimal notation)
    EOS

    validate do |value|
      w = value.split
      unless value =~ IPADDR_REGEXP || value =~ /^any$/ ||
             (w.length == 2 && w[0].eql?('host') && w[1] =~ IPADDR_REGEXP)
        fail "value #{value.inspect} is invalid, must be a network " \
             "address, 'any', or 'host IP address'"
      end
    end
  end

  newproperty(:srcprefixlen) do
    desc <<-EOS
      The source address prefix len used when srcaddr is a network address
      to define the subnet. Values range from 0 to 32.
    EOS

    munge { |value| Integer(value) }

    validate do |value|
      unless value.to_i.between?(0, 32)
        fail "value #{value.inspect} must be between 0 and 32"
      end
    end
  end

  newproperty(:log, boolean: false) do
    desc <<-EOS
      When set to true, triggers an informational log message to the
      console about hte matching packet.
    EOS
    newvalues(:true, :false)
  end
end
