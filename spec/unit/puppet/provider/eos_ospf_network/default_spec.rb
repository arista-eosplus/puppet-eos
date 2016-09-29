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

describe Puppet::Type.type(:eos_ospf_network).provider(:eos) do
  # Puppet RAL memoized methods
  let(:resource) do
    resource_hash = {
      ensure: :present,
      name: '192.168.10.0/24',
      instance_id: 1,
      area: '0.0.0.0',
      provider: described_class.name
    }
    Puppet::Type.type(:eos_ospf_network).new(resource_hash)
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
        expect(subject.size).to eq 3
      end

      it 'has a ospf network 192.168.10.0/24' do
        instance = subject.find { |p| p.name == '192.168.10.0/24' }
        expect(instance).to be_a described_class
      end

      context "eos_ospf_network { '192.168.10.0/24': }" do
        subject { described_class.instances.find { |p| p.name == '192.168.10.0/24' } }
        include_examples 'provider resource methods',
                         ensure: :present,
                         name: '192.168.10.0/24',
                         instance_id: 1,
                         area: '0.0.0.0'
      end
    end

    describe '.prefetch' do
      let :resources do
        {
          '192.168.10.0/24' => Puppet::Type.type(:eos_ospf_network).new(name: '192.168.10.0/24'),
          '192.168.20.0/24' => Puppet::Type.type(:eos_ospf_network).new(name: '192.168.20.0/24')
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
        expect(resources['192.168.10.0/24'].provider.name).to eq('192.168.10.0/24')
        expect(resources['192.168.10.0/24'].provider.exists?).to be_truthy
      end

      it 'does not set the provider instance of the unmanaged resource' do
        subject
        expect(resources['192.168.20.0/24'].provider.name).to eq('192.168.20.0/24')
        expect(resources['192.168.20.0/24'].provider.exists?).to be_falsey
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
        expect(api).to receive(:add_network).with(1, '192.168.10.0/24', '0.0.0.0')
        provider.create
        provider.flush
        expect(provider.ensure).to eq(:present)
      end
    end

    describe '#area=(value)' do
      it 'sets area on the resource' do
        expect(api).to receive(:add_network).with(1, '192.168.10.0/24', '0.0.0.1')
        provider.create
        provider.area = '0.0.0.1'
        provider.flush
        expect(provider.area).to eq('0.0.0.1')
      end
    end

    describe '#instance_id=(value)' do
      it 'sets instance_id on the resource' do
        expect(api).to receive(:add_network).with(2, '192.168.10.0/24', '0.0.0.0')
        provider.create
        provider.instance_id = 2
        provider.flush
        expect(provider.instance_id).to eq(2)
      end
    end

    describe '#destroy' do
      it 'sets ensure to :absent' do
        resource[:ensure] = :absent
        expect(api).to receive(:remove_network).with(1, '192.168.10.0/24', '0.0.0.0')
        provider.destroy
        provider.flush
        expect(provider.ensure).to eq(:absent)
      end
    end
  end
end