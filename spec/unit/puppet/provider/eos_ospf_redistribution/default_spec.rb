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
require 'spec_helper'

include FixtureHelpers

describe Puppet::Type.type(:eos_ospf_redistribution).provider(:eos) do
  # Puppet RAL memoized methods
  let(:resource) do
    resource_hash = {
      ensure: :present,
      name: 'static',
      instance_id: 1,
      route_map: 'test',
      provider: described_class.name
    }
    Puppet::Type.type(:eos_ospf_redistribution).new(resource_hash)
  end

  let(:provider) { resource.provider }

  let(:api) { double('ospf') }

  def ospf
    ospf = Fixtures[:ospf]
    return ospf if ospf
    fixture('ospf')
  end

  # Stub the Api method class to obtain all ospf networks.
  before :each do
    allow(described_class.node).to receive(:api).with('ospf').and_return(api)
    allow(provider.node).to receive(:api).with('ospf').and_return(api)
  end

  context 'class methods' do

    before { allow(api).to receive(:getall).and_return(ospf) }

    describe '.instances' do
      subject { described_class.instances }

      it { is_expected.to be_an Array }

      it 'has three entries' do
        expect(subject.size).to eq 2
      end

      it 'has a ospf redistribution static' do
        instance = subject.find { |p| p.name == 'static' }
        expect(instance).to be_a described_class
      end

      context "eos_ospf_redistribution { 'static': }" do
        subject { described_class.instances.find { |p| p.name == 'static' } }
        include_examples 'provider resource methods',
                         ensure: :present,
                         name: 'static',
                         instance_id: 1,
                         route_map: 'test'
      end
    end

    describe '.prefetch' do
      let :resources do
        {
          'static' => Puppet::Type.type(:eos_ospf_redistribution).new(name: 'static'),
          'rip' => Puppet::Type.type(:eos_ospf_redistribution).new(name: 'rip')
        }
      end

      subject { described_class.prefetch(resources) }

      it 'resource providers are absent prior to calling .prefetch' do
        resources.values.each do |rsrc|
          expect(rsrc.provider.instance_id).to eq(:absent)
        end
      end

      it 'sets the provider instance of the managed resource' do
        subject
        expect(resources['static'].provider.name).to eq('static')
        expect(resources['static'].provider.exists?).to be_truthy
      end

      it 'does not set the provider instance of the unmanaged resource' do
        subject
        expect(resources['rip'].provider.name).to eq('rip')
        expect(resources['rip'].provider.exists?).to be_falsey
      end
    end
  end

  context 'resource (instance) methods' do

    describe '#exists?' do
      subject { provider.exists? }

      context 'when the resource does not exist on the system' do
        it { is_expected.to be_falsey }
      end

      context 'when the resource exists on the system' do
        let(:provider) do
          allow(api).to receive(:getall).and_return(ospf)
          described_class.instances.first
        end
        it { is_expected.to be_truthy }
      end
    end

    describe '#create' do
      it 'sets ensure on the resource' do
        expect(api).to receive(:set_redistribute).with('static', 1, 'test')
        provider.create
        provider.flush
        expect(provider.ensure).to eq(:present)
      end
    end

    describe '#route_map=(value)' do
      it 'sets route_map on the resource' do
        expect(api).to receive(:set_redistribute).with('static', 1, 'foo')
        provider.create
        provider.route_map = 'foo'
        provider.flush
        expect(provider.route_map).to eq('foo')
      end
    end

    describe '#instance_id=(value)' do
      it 'sets instance_id on the resource' do
        expect(api).to receive(:set_redistribute).with('static', 2, 'test')
        provider.create
        provider.instance_id = 2
        provider.flush
        expect(provider.instance_id).to eq(2)
      end
    end

    describe '#destroy' do
      it 'sets ensure to :absent' do
        resource[:ensure] = :absent
        expect(api).to receive(:set_redistribute).with('static', 1)
        provider.destroy
        provider.flush
        expect(provider.ensure).to eq(:absent)
      end
    end
  end
end