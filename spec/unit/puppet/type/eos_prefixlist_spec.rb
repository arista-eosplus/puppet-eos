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
# encoding: utf-8

require 'spec_helper'

describe Puppet::Type.type(:eos_prefixlist) do
  let(:catalog) { Puppet::Resource::Catalog.new }
  let(:type) { described_class.new(name: 'test:10', catalog: catalog) }

  it_behaves_like 'an ensurable type', name: 'test:10'

  describe 'name' do
    let(:attribute) { :name }
    subject { described_class.attrclass(attribute) }

    include_examples 'parameter'
    include_examples '#doc Documentation'
    include_examples 'accepts values without munging',
                     %w(test:10 test:20)
    include_examples 'rejects values',
                     ['test', 'test-10', 'test_20', 'test30',
                      40, '50:test', 'test:0', :test]
    include_examples 'rejects non integer seqno values',
                     %w(test:abc test:*a test:65_536 test:1O test:5S)
  end

  describe 'prefix_list' do
    let(:attribute) { :prefix_list }
    subject { described_class.attrclass(attribute) }

    include_examples 'property'
    include_examples '#doc Documentation'
    include_examples 'string value'
  end

  describe 'seqno' do
    let(:attribute) { :seqno }
    subject { described_class.attrclass(attribute) }

    include_examples 'property'
    include_examples '#doc Documentation'
    include_examples 'accepts values without munging', [0, 65_535]
    include_examples 'rejects values', [-1, 65_536]
  end

  describe 'action' do
    let(:attribute) { :action }
    subject { described_class.attrclass(attribute) }

    include_examples 'property'
    include_examples '#doc Documentation'
    include_examples 'accepts values without munging', [:permit, :deny]
    include_examples 'rejects values', %w(anyting else0101 permits)
  end

  describe 'prefix' do
    let(:attribute) { :prefix }
    subject { described_class.attrclass(attribute) }

    include_examples 'property'
    include_examples '#doc Documentation'
    include_examples 'string value'
  end

  describe 'masklen' do
    let(:attribute) { :masklen }
    subject { described_class.attrclass(attribute) }

    include_examples 'property'
    include_examples '#doc Documentation'
    include_examples 'accepts values without munging', [0, 32]
    include_examples 'rejects values', [-1, 33]
  end

  describe 'eq' do
    let(:attribute) { :eq }
    subject { described_class.attrclass(attribute) }

    include_examples 'property'
    include_examples '#doc Documentation'
    include_examples 'accepts values without munging', [1, 32]
    include_examples 'rejects values', [0, 33]
  end

  describe 'ge' do
    let(:attribute) { :ge }
    subject { described_class.attrclass(attribute) }

    include_examples 'property'
    include_examples '#doc Documentation'
    include_examples 'accepts values without munging', [1, 32]
    include_examples 'rejects values', [0, 33]
  end

  describe 'le' do
    let(:attribute) { :le }
    subject { described_class.attrclass(attribute) }

    include_examples 'property'
    include_examples '#doc Documentation'
    include_examples 'accepts values without munging', [1, 32]
    include_examples 'rejects values', [0, 33]
  end
end
