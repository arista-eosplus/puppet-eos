#
# Copyright (c) 2014-2016, Arista Networks, Inc.
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

describe Puppet::Type.type(:eos_ipinterface).provider(:eos) do
  # Puppet RAL memoized methods
  let(:resource) do
    resource_hash = {
      ensure: :present,
      name: 'Ethernet1',
      address: '1.2.3.4/5',
      helper_addresses: %w(5.6.7.8 9.10.11.12),
      secondary_addresses: %w(1.2.3.4/31 1.2.3.5/31),
      mtu: '9000',
      provider: described_class.name
    }
    Puppet::Type.type(:eos_ipinterface).new(resource_hash)
  end

  let(:provider) { resource.provider }

  let(:api) { double('ipinterfaces') }

  def ipinterfaces
    ipinterfaces = Fixtures[:ipinterfaces]
    return ipinterfaces if ipinterfaces
    fixture('ipinterfaces', dir: File.dirname(__FILE__))
  end

  before :each do
    allow(described_class.node).to receive(:api).with('ipinterfaces')
      .and_return(api)
    allow(provider.node).to receive(:api).with('ipinterfaces').and_return(api)
  end

  context 'class methods' do
    before { allow(api).to receive(:getall).and_return(ipinterfaces) }

    describe '.instances' do
      subject { described_class.instances }

      it { is_expected.to be_an Array }

      it 'has one entry' do
        expect(subject.size).to eq 1
      end

      it 'has an instance for Ethernet1' do
        instance = subject.find { |p| p.name == 'Ethernet1' }
        expect(instance).to be_a described_class
      end

      context "eos_ipinterface { 'Ethernet1': }" do
        subject { described_class.instances.find { |p| p.name == 'Ethernet1' } }

        include_examples 'provider resource methods',
                         ensure: :present,
                         name: 'Ethernet1',
                         address: '1.2.3.4/5',
                         helper_addresses: %w(5.6.7.8 9.10.11.12),
                         secondary_addresses: %w(1.2.3.4/31 1.2.3.5/31),
                         mtu: '1500',
                         exists?: true
      end
    end

    describe '.prefetch' do
      let :resources do
        {
          'Ethernet1' => Puppet::Type.type(:eos_ipinterface)
                                     .new(name: 'Ethernet1'),
          'Ethernet2' => Puppet::Type.type(:eos_ipinterface)
                                     .new(name: 'Ethernet2')
        }
      end

      subject { described_class.prefetch(resources) }

      it 'resource providers are absent prior to calling .prefetch' do
        resources.values.each do |rsrc|
          expect(rsrc.provider.address).to eq(:absent)
          expect(rsrc.provider.mtu).to eq(:absent)
          expect(rsrc.provider.helper_addresses).to eq(:absent)
        end
      end

      it 'sets the provider instance of the managed resource' do
        subject
        expect(resources['Ethernet1'].provider.name).to eq 'Ethernet1'
        expect(resources['Ethernet1'].provider.address).to eq '1.2.3.4/5'
        expect(resources['Ethernet1'].provider.mtu).to eq '1500'
        expect(resources['Ethernet1'].provider.helper_addresses).to \
          eq %w(5.6.7.8 9.10.11.12)
        expect(resources['Ethernet1'].provider.secondary_addresses).to \
          eq %w(1.2.3.4/31 1.2.3.5/31)
        expect(resources['Ethernet1'].provider.exists?).to be_truthy
      end

      it 'does not set the provider instance of the unmanaged resource' do
        subject
        expect(resources['Ethernet2'].provider.name).to eq('Ethernet2')
        expect(resources['Ethernet2'].provider.address).to eq(:absent)
        expect(resources['Ethernet2'].provider.mtu).to eq(:absent)
        expect(resources['Ethernet2'].provider.helper_addresses).to eq(:absent)
        expect(resources['Ethernet2'].provider.exists?).to be_falsey
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
          allow(api).to receive(:getall).and_return(ipinterfaces)
          described_class.instances.first
        end
        it { is_expected.to be_truthy }
      end
    end

    describe '#create' do
      let(:name) { resource[:name] }

      before do
        expect(api).to receive(:create).with(name)
        allow(api).to receive_messages(
          set_address: true,
          set_mtu: true,
          set_helper_addresses: true,
          set_secondary_addresses: true
        )
      end

      it 'sets ensure to :present' do
        provider.create
        expect(provider.ensure).to eq(:present)
      end

      it 'sets address to the resource value' do
        provider.create
        expect(provider.address).to eq(provider.resource[:address])
      end

      it 'sets mtu to the resource value' do
        provider.create
        expect(provider.mtu).to eq(provider.resource[:mtu])
      end

      it 'sets helper_addresses to the resource value' do
        provider.create
        expect(provider.helper_addresses).to eq(resource[:helper_addresses])
      end

      it 'sets secondary_addresses to the resource value' do
        provider.create
        expect(provider.secondary_addresses).to eq(resource[:secondary_addresses])
      end
    end

    describe '#destroy' do
      it 'sets ensure to :absent' do
        expect(api).to receive(:delete).with(resource[:name])
        provider.destroy
        expect(provider.ensure).to eq(:absent)
      end
    end

    describe '#address=(val)' do
      it 'updates address on the provider' do
        expect(api).to receive(:set_address)
          .with(resource[:name], value: '1.2.3.4/5')
        provider.address = '1.2.3.4/5'
        expect(provider.address).to eq('1.2.3.4/5')
      end
    end

    describe '#mtu=(val)' do
      it 'updates mtu on the provider' do
        expect(api).to receive(:set_mtu).with(resource[:name], value: 1600)
        provider.mtu = 1600
        expect(provider.mtu).to eq(1600)
      end
    end

    describe '#helper_addresses=(val)' do
      let(:value) { %w(5.6.7.8 9.10.11.12) }

      it 'updates helper_addresses on the provider' do
        expect(api).to receive(:set_helper_addresses)
          .with(resource[:name], value: value)
        provider.helper_addresses = value
        expect(provider.helper_addresses).to eq(value)
      end
    end

    describe '#secondary_addresses=(val)' do
      let(:value) { %w(5.6.7.8 9.10.11.12) }

      it 'updates secondary_addresses on the provider' do
        expect(api).to receive(:set_secondary_addresses)
          .with(resource[:name], value: value)
        provider.secondary_addresses = value
        expect(provider.secondary_addresses).to eq(value)
      end
    end
  end
end
