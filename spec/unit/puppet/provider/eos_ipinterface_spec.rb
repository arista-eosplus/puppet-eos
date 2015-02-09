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

describe Puppet::Type.type(:eos_ipinterface).provider(:eos) do

  # Puppet RAL memoized methods
  let(:resource) do
    resource_hash = {
      ensure: :present,
      name: 'Ethernet1',
      address: '1.2.3.4/5',
      helper_address: %w(5.6.7.8 9.10.11.12),
      mtu: '9000',
      provider: described_class.name
    }
    Puppet::Type.type(:eos_ipinterface).new(resource_hash)
  end

  let(:provider) { resource.provider }

  let(:api) { double('rbeapi').as_null_object }

  def ipinterfaces
    ipinterfaces = Fixtures[:ipinterfaces]
    return ipinterfaces if ipinterfaces
    file = get_fixture('ipinterfaces.json')
    Fixtures[:ipinterfaces] = JSON.load(File.read(file))
  end

  before :each do
    allow(described_class.node).to receive(:api).with('ipinterfaces').and_return(api)
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
                         helper_address: %w(5.6.7.8 9.10.11.12),
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
          expect(rsrc.provider.helper_address).to eq(:absent)
        end
      end

      it 'sets the provider instance of the managed resource' do
        subject
        expect(resources['Ethernet1'].provider.name).to eq 'Ethernet1'
        expect(resources['Ethernet1'].provider.address).to eq '1.2.3.4/5'
        expect(resources['Ethernet1'].provider.mtu).to eq '1500'
        expect(resources['Ethernet1'].provider.helper_address).to eq %w(5.6.7.8 9.10.11.12)
        expect(resources['Ethernet1'].provider.exists?).to be_truthy
      end

      it 'does not set the provider instance of the unmanaged resource' do
        subject
        expect(resources['Ethernet2'].provider.name).to eq('Ethernet2')
        expect(resources['Ethernet2'].provider.address).to eq(:absent)
        expect(resources['Ethernet2'].provider.mtu).to eq(:absent)
        expect(resources['Ethernet2'].provider.helper_address).to eq(:absent)
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
        let(:provider) { described_class.instances.first }
        it { is_expected.to be_truthy }
      end
    end

    describe '#create' do
      let(:name) { resource[:name] }

      it 'sets ensure to :present' do
        expect(api).to receive(:create).with(name)
        provider.create
        expect(provider.ensure).to eq(:present)
      end

      it 'sets address to the resource value' do
        expect(api).to receive(:set_address)
          .with(name, value: resource[:address])
        provider.create
        expect(provider.address).to eq(provider.resource[:address])
      end

      it 'sets mtu to the resource value' do
        expect(api).to receive(:set_mtu).with(name, value: resource[:mtu])
        provider.create
        expect(provider.mtu).to eq(provider.resource[:mtu])
      end

      it 'sets helper_address to the resource value' do
        expect(api).to receive(:set_helper_address)
          .with(name, value: resource[:helper_address])
        provider.create
        expect(provider.helper_address).to eq(resource[:helper_address])
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

    describe '#helper_address=(val)' do
      let(:value) { %w(5.6.7.8 9.10.11.12) }

      it 'updates helper_address on the provider' do
        expect(api).to receive(:set_helper_address)
          .with(resource[:name], value: value)
        provider.helper_address = value
        expect(provider.helper_address).to eq(value)
      end
    end
  end
end
