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

describe Puppet::Type.type(:eos_varp_interface).provider(:eos) do
  # Puppet RAL memoized methods
  let(:resource) do
    resource_hash = {
      ensure: :present,
      name: 'Vlan100',
      addresses: ['1.2.3.4'],
      provider: described_class.name
    }
    Puppet::Type.type(:eos_varp_interface).new(resource_hash)
  end

  let(:provider) { resource.provider }

  let(:api) { double('varp') }
  let(:interfaces) { double('varp.interfaces') }

  def varp
    varp = Fixtures[:varp]
    return varp if varp
    file = get_fixture('varp.json')
    Fixtures[:varp] = JSON.load(File.read(file))
  end

  before :each do
    allow(described_class.node).to receive(:api).with('varp').and_return(api)
    allow(provider.node).to receive(:api).with('varp').and_return(api)
    allow(api).to receive(:interfaces).and_return(interfaces)
  end

  context 'class methods' do
    before { allow(api).to receive(:get).and_return(varp) }

    describe '.instances' do
      subject { described_class.instances }

      it { is_expected.to be_an Array }

      it 'has one entry' do
        expect(subject.size).to eq 1
      end

      it 'has an instance for interface Vlan1234' do
        instance = subject.find { |p| p.name == 'Vlan1234' }
        expect(instance).to be_a described_class
      end

      context "eos_varp_interface { 'Vlan1234': }" do
        subject { described_class.instances.find { |p| p.name == 'Vlan1234' } }

        include_examples 'provider resource methods',
                         ensure: :present,
                         name: 'Vlan1234',
                         addresses: ['1.1.1.1', '2.2.2.2']
      end
    end

    describe '.prefetch' do
      let :resources do
        {
          'Vlan1234' => Puppet::Type.type(:eos_varp_interface)
            .new(name: 'Vlan1234'),
          'Vlan1' => Puppet::Type.type(:eos_varp_interface).new(name: 'Vlan1')
        }
      end

      subject { described_class.prefetch(resources) }

      it 'resource providers are absent prior to calling .prefetch' do
        resources.values.each do |rsrc|
          expect(rsrc.provider.addresses).to eq(:absent)
        end
      end

      it 'sets the provider instance of the managed resource' do
        subject
        expect(resources['Vlan1234'].provider.name).to eq('Vlan1234')
        expect(resources['Vlan1234'].provider.exists?).to be_truthy
        expect(resources['Vlan1234'].provider.addresses)
          .to eq(['1.1.1.1', '2.2.2.2'])
      end

      it 'does not set the provider instance of the unmanaged resource' do
        subject
        expect(resources['Vlan1'].provider.name).to eq('Vlan1')
        expect(resources['Vlan1'].provider.exists?).to be_falsey
        expect(resources['Vlan1'].provider.addresses).to be(:absent)
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
          allow(api).to receive(:get).and_return(varp)
          described_class.instances.first
        end
        it { is_expected.to be_truthy }
      end
    end

    describe '#create' do
      before :each do
        expect(interfaces).to receive(:create).with(resource[:name])
        allow(interfaces).to receive_messages(
          set_addresses: true
        )
      end

      it 'sets ensure to :present' do
        provider.create
        expect(provider.ensure).to eq(:present)
      end

      it 'sets addresses to the resource value' do
        provider.create
        expect(provider.addresses).to eq(provider.resource[:addresses])
      end
    end

    describe '#destroy' do
      it 'sets ensure to :absent' do
        expect(interfaces).to receive(:delete).with(resource[:name])
        provider.destroy
        expect(provider.ensure).to eq(:absent)
      end
    end

    describe '#address=(val)' do
      let(:name) { resource[:name] }
      let(:addresses) { %w(1.1.1.1 2.2.2.2) }

      it 'updates addresses in the provider' do
        expect(interfaces).to receive(:set_addresses)
          .with(name, value: addresses)
        provider.addresses = addresses
        expect(provider.addresses).to eq addresses
      end
    end
  end
end
