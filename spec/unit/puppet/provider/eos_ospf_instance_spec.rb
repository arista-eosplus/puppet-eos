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

describe Puppet::Type.type(:eos_ospf_instance).provider(:eos) do

  # Puppet RAL memoized methods
  let(:resource) do
    resource_hash = {
      ensure: :present,
      name: '1',
      router_id: '1.1.1.1',
      provider: described_class.name
    }
    Puppet::Type.type(:eos_ospf_instance).new(resource_hash)
  end

  let(:provider) { resource.provider }

  let(:api) { double('ospf') }

  def ospf
    ospf = Fixtures[:ospf]
    return ospf if ospf
    file = get_fixture('ospf.json')
    Fixtures[:ospf] = JSON.load(File.read(file))
  end

  before :each do
    allow(described_class.node).to receive(:api).with('ospf').and_return(api)
    allow(provider.node).to receive(:api).with('ospf').and_return(api)
  end

  context 'class methods' do

    before { allow(api).to receive(:getall).and_return(ospf) }

    describe '.instances' do
      subject { described_class.instances }

      it { is_expected.to be_an Array }

      it 'has one entry' do
        expect(subject.size).to eq 1
      end

      it 'has an instance for ospf 1' do
        instance = subject.find { |p| p.name == '1' }
        expect(instance).to be_a described_class
      end

      context "eos_ospf_instance { '1': }" do
        subject { described_class.instances.find { |p| p.name == '1' } }

        include_examples 'provider resource methods',
                         ensure: :present,
                         name: '1',
                         router_id: '1.1.1.1'
      end

    end

    describe '.prefetch' do
      let :resources do
        {
          '1' => Puppet::Type.type(:eos_ospf_instance).new(name: '1'),
          '2' => Puppet::Type.type(:eos_ospf_instance).new(name: '2')
        }
      end

      subject { described_class.prefetch(resources) }

      it 'resource providers are absent prior to calling .prefetch' do
        resources.values.each do |rsrc|
          expect(rsrc.provider.router_id).to eq(:absent)
        end
      end

      it 'sets the provider instance of the managed resource' do
        subject
        expect(resources['1'].provider.name).to eq '1'
        expect(resources['1'].provider.exists?).to be_truthy
        expect(resources['1'].provider.router_id).to eq '1.1.1.1'
      end

      it 'does not set the provider instance of the unmanaged resource' do
        subject
        expect(resources['2'].provider.name).to eq('2')
        expect(resources['2'].provider.exists?).to be_falsey
        expect(resources['2'].provider.router_id).to eq :absent
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

      before :each do
        expect(api).to receive(:create).with(resource[:name])
        allow(api).to receive_messages(
          :set_router_id => true
        )
      end

      it 'sets ensure to :present' do
        provider.create
        expect(provider.ensure).to eq(:present)
      end

      it 'sets router_id to the resource value' do
        provider.create
        expect(provider.router_id).to eq(resource[:router_id])
      end
    end

    describe '#destroy' do
      it 'sets ensure to :basent' do
        expect(api).to receive(:delete).with(resource[:name])
        provider.destroy
        expect(provider.ensure).to eq(:absent)
        end
    end

    describe '#router_id=(val)' do
      it 'updates router_id with value 2.2.2.2' do
        expect(api).to receive(:set_router_id)
          .with(resource[:name], value: '2.2.2.2')
        provider.router_id = '2.2.2.2'
        expect(provider.router_id).to eq('2.2.2.2')
      end
    end
  end
end
