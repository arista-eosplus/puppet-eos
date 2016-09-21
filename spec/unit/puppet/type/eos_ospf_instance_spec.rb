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

describe Puppet::Type.type(:eos_ospf_instance) do
  let(:catalog) { Puppet::Resource::Catalog.new }
  let(:type) { described_class.new(:name => '1', :catalog => catalog) }

  # Cannot use the helper ensurable type check because even though the
  # namevar is always a string, for this type the namevar is really an integer
  # and the type will validate that the name can be converted to an integer.

  describe 'name' do
    let(:attribute) { :name }
    subject { described_class.attrclass(attribute) }

    include_examples 'parameter'
    include_examples '#doc Documentation'
    include_examples 'rejects values', [0, 65_536]
    include_examples 'rejected parameter values'

    [100, '100'].each do |val|
      it "validates #{val.inspect} as isomorphic to '100'" do
        type[attribute] = val
        expect(type[attribute]).to eq(val.to_s)
      end
    end
  end

  describe 'router_id' do
    let(:attribute) { :router_id }
    subject { described_class.attrclass(attribute) }

    include_examples 'property'
    include_examples '#doc Documentation'
    include_examples 'accepts values without munging',\
                     %w(0.0.0.0 255.255.255.255)
    include_examples 'rejects values', [[1], { :two => :three }]
  end

  describe 'max_lsa' do
    let(:attribute) { :max_lsa }
    subject { described_class.attrclass(attribute) }

    include_examples 'property'
    include_examples '#doc Documentation'
    include_examples 'numeric parameter', min: 0, max: 100000
    include_examples 'rejects values', -1, 100001, 'test', [5, 6]
  end

  describe 'maximum_paths' do
    let(:attribute) { :maximum_paths }
    subject { described_class.attrclass(attribute) }

    include_examples 'property'
    include_examples '#doc Documentation'
    include_examples 'numeric parameter', min: 1, max: 32
    include_examples 'rejects values', 0, 33, 'test', [5, 6]
  end

  describe 'passive_interfaces' do
    let(:attribute) { :passive_interfaces }
    subject { described_class.attrclass(attribute) }
  
    include_examples 'property'
    include_examples '#doc Documentation'
    include_examples 'accepts values without munging',\
                     [['Loopback0'], ['Ethernet1', 'Ethernet2', 'Ethernet3']]
  end

  describe 'active_interfaces' do
    let(:attribute) { :active_interfaces }
    subject { described_class.attrclass(attribute) }
  
    include_examples 'property'
    include_examples '#doc Documentation'
    include_examples 'accepts values without munging',\
                     [['Loopback0'], ['Ethernet1', 'Ethernet2', 'Ethernet3']]
  end

  describe 'passive_interface_default' do
    let(:attribute) { :passive_interface_default }
    subject { described_class.attrclass(attribute) }
  
    include_examples 'property'
    include_examples '#doc Documentation'
    include_examples 'boolean value'
    include_examples 'rejected parameter values'
  end

end