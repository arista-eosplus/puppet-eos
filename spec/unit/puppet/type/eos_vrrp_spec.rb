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
# encoding: utf-8

require 'spec_helper'

describe Puppet::Type.type(:eos_vrrp) do
  let(:catalog) { Puppet::Resource::Catalog.new }
  let(:type) { described_class.new(name: 'Vlan50:10', catalog: catalog) }

  it_behaves_like 'an ensurable type', name: 'Vlan50:10'

  describe 'name' do
    let(:attribute) { :name }
    subject { described_class.attrclass(attribute) }

    include_examples 'parameter'
    include_examples '#doc Documentation'
    include_examples 'accepts values without munging', %w(Vlan50:20)
    include_examples 'rejects values', [[1], { two: :three }, 'Vlan50/20',
                                        'Vlan50:0', 'Vlan50:256']
  end

  describe 'primary_ip' do
    let(:attribute) { :primary_ip }
    subject { described_class.attrclass(attribute) }

    include_examples 'property'
    include_examples '#doc Documentation'
    include_examples 'accepts values without munging', ['1.2.3.0']
    include_examples 'rejects values', ['1.2', '255.255.255.256', 'host',
                                        'host 1.2.3']
  end

  describe 'priority' do
    let(:attribute) { :priority }
    subject { described_class.attrclass(attribute) }

    include_examples 'property'
    include_examples '#doc Documentation'
    include_examples 'accepts values without munging', [1, 254]
    include_examples 'rejects values', [0, 255]
  end

  describe 'timers_advertise' do
    let(:attribute) { :timers_advertise }
    subject { described_class.attrclass(attribute) }

    include_examples 'property'
    include_examples '#doc Documentation'
    include_examples 'accepts values without munging', [1, 255]
    include_examples 'rejects values', [0, 256]
  end

  describe 'preempt' do
    let(:attribute) { :preempt }
    subject { described_class.attrclass(attribute) }

    include_examples 'property'
    include_examples '#doc Documentation'
    include_examples 'boolean value'
  end

  describe 'enable' do
    let(:attribute) { :enable }
    subject { described_class.attrclass(attribute) }

    include_examples 'property'
    include_examples '#doc Documentation'
    include_examples 'boolean value'
  end

  describe 'secondary_ip' do
    let(:attribute) { :secondary_ip }
    subject { described_class.attrclass(attribute) }

    include_examples 'property'
    include_examples '#doc Documentation'
    include_examples 'accepts values without munging', [['1.2.3.0']]
    include_examples 'rejects values', [['1.2', '255.255.255.256', 'host',
                                         'host 1.2.3']]
  end

  describe 'description' do
    include_examples 'string', name: 'Vlan50:10', attribute: :description
  end

  describe 'track' do
    let(:attribute) { :track }
    subject { described_class.attrclass(attribute) }

    include_examples 'property'
    include_examples '#doc Documentation'
    include_examples 'accepts values without munging',
                     [[{ 'name' => 'Ethernet2', 'action' => 'decrement',
                         'amount' => 33 }]]
    include_examples 'rejects values',
                     [['A string instead of a hash'],
                      [{ 'nom' => 'Ethernet2', 'action' => 'decrement',
                         'amt' => 33 }],
                      [{ 'name' => 'Ethernet2', 'act' => 'decrement',
                         'amount' => 33 }],
                      [{ 'name' => 'Ethernet2', 'action' => 'bogus',
                         'amount' => 33 }],
                      [{ 'name' => 'Ethernet2', 'action' => 'shutdown',
                         'amount' => 33 }],
                      [{ 'name' => 'Ethernet2', 'action' => 'decrement' }]]
  end

  describe 'ip_version' do
    let(:attribute) { :ip_version }
    subject { described_class.attrclass(attribute) }

    include_examples 'property'
    include_examples '#doc Documentation'
    include_examples 'accepts values without munging', [2, 3]
    include_examples 'rejects values', [-1, 1, 4, 'string']
  end

  describe 'mac_addr_adv_interval' do
    let(:attribute) { :mac_addr_adv_interval }
    subject { described_class.attrclass(attribute) }

    include_examples 'property'
    include_examples '#doc Documentation'
    include_examples 'accepts values without munging', [0, 3600]
    include_examples 'rejects values', [-1, 'string']
  end

  describe 'preempt_delay_min' do
    let(:attribute) { :preempt_delay_min }
    subject { described_class.attrclass(attribute) }

    include_examples 'property'
    include_examples '#doc Documentation'
    include_examples 'accepts values without munging', [0, 3600]
    include_examples 'rejects values', [-1, 'string']
  end

  describe 'preempt_delay_reload' do
    let(:attribute) { :preempt_delay_reload }
    subject { described_class.attrclass(attribute) }

    include_examples 'property'
    include_examples '#doc Documentation'
    include_examples 'accepts values without munging', [0, 3600]
    include_examples 'rejects values', [-1, 'string']
  end

  describe 'delay_reload' do
    let(:attribute) { :delay_reload }
    subject { described_class.attrclass(attribute) }

    include_examples 'property'
    include_examples '#doc Documentation'
    include_examples 'accepts values without munging', [0, 3600]
    include_examples 'rejects values', [-1, 'string']
  end
end
