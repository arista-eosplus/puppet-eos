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

describe Puppet::Type.type(:eos_bgp_neighbor) do
  let(:catalog) { Puppet::Resource::Catalog.new }
  let(:type) { described_class.new(name: '172.16.10.1', catalog: catalog) }

  it_behaves_like 'an ensurable type', name: '172.16.10.1'

  describe 'name' do
    include_examples 'name is the namevar'
  end

  describe 'peer_group' do
    include_examples 'string', name: '172.16.10.1', attribute: :peer_group
  end

  describe 'peer_group to fail' do
    # If name is not an IPv4 address then you cannot set the peer group
    let(:catalog) { Puppet::Resource::Catalog.new }
    let(:type) { described_class.new(name: 'Marketing', catalog: catalog) }
    subject { described_class.attrclass(:peer_group) }

    it 'rejects setting peer group' do
      expect { type[:peer_group] = 'BGP_edge' }
        .to raise_error Puppet::ResourceError, /neighbor is an IPv4 address/
    end
  end

  describe 'remote_as' do
    let(:attribute) { :remote_as }
    subject { described_class.attrclass(attribute) }

    include_examples 'property'
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

  describe 'send_community' do
    let(:attribute) { :send_community }
    subject { described_class.attrclass(attribute) }

    include_examples 'property'
    include_examples '#doc Documentation'
    include_examples 'accepts values', [:enable, :disable]
    include_examples 'rejected parameter values'
  end

  describe 'next_hop_self' do
    let(:attribute) { :next_hop_self }
    subject { described_class.attrclass(attribute) }

    include_examples 'property'
    include_examples '#doc Documentation'
    include_examples 'accepts values', [:enable, :disable]
    include_examples 'rejected parameter values'
  end

  describe 'route_map_in' do
    include_examples 'string', attribute: :route_map_in
  end

  describe 'route_map_out' do
    include_examples 'string', attribute: :route_map_out
  end

  describe 'description' do
    include_examples 'string', attribute: :description
  end

  describe 'enable' do
    let(:attribute) { :enable }
    subject { described_class.attrclass(attribute) }

    include_examples 'property'
    include_examples '#doc Documentation'
    include_examples 'boolean value'
    include_examples 'rejected parameter values'
  end
end
