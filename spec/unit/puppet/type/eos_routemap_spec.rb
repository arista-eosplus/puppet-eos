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

describe Puppet::Type.type(:eos_routemap) do
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
    include_examples 'rejects values', %w(test test20)
    include_examples 'rejects non integer seqno values',
                     %w(test:abc test:*a test:65_536)
  end

  describe 'description' do
    let(:attribute) { :description }
    subject { described_class.attrclass(attribute) }

    include_examples 'property'
    include_examples '#doc Documentation'
    include_examples 'string value'
  end

  describe 'action' do
    let(:attribute) { :action }
    subject { described_class.attrclass(attribute) }

    include_examples 'property'
    include_examples '#doc Documentation'
    include_examples 'accepts values without munging', %w(permit deny)
    include_examples 'rejects values', %w(anyting else0101)
  end

  describe 'match' do
    let(:attribute) { :match }
    subject { described_class.attrclass(attribute) }

    include_examples 'property'
    include_examples 'array of strings value'
    include_examples 'accepts values without munging',
                     [['ip address prefix-list MYLOOPBACK',
                       'interface Loopback0']]
  end

  describe 'set' do
    let(:attribute) { :set }
    subject { described_class.attrclass(attribute) }

    include_examples 'property'
    include_examples 'array of strings value'
    include_examples 'accepts values without munging',
                     [['community internet 5555:5555']]
  end

  describe 'continue' do
    let(:attribute) { :continue }
    subject { described_class.attrclass(attribute) }

    include_examples 'property'
    include_examples '#doc Documentation'
    include_examples 'accepts values without munging', [1, 16_777_215]
    include_examples 'rejects values', [0, 16_777_216]
  end
end
