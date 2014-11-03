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
      address: '1.2.3.4/24',
      mtu: '9000',
      provider: described_class.name
    }
    Puppet::Type.type(:eos_ipinterface).new(resource_hash)
  end

  let(:provider) { resource.provider }

  def ipinterfaces
    ipinterfaces = Fixtures[:ipinterfaces]
    return ipinterfaces if ipinterfaces
    file = File.join(File.dirname(__FILE__), 'fixtures/ipinterfaces.json')
    Fixtures[:ipinterfaces] = JSON.load(File.read(file))
  end

  # Stub the Api method class to obtain all vlans.
  before :each do
    allow_message_expectations_on_nil
    allow(described_class).to receive(:eapi)
    allow(described_class.eapi).to receive(:Ipinterface)
    allow(described_class.eapi.Ipinterface).to receive(:getall)
      .and_return(ipinterfaces)
  end

  context 'class methods' do

    describe '.instances' do
      subject { described_class.instances }

      it { is_expected.to be_an Array }

      it 'has two entries' do
        expect(subject.size).to eq 2
      end

      %w(Ethernet1 Management1).each do |name|
        it "has an instance for interface #{name}" do
          instance = subject.find { |p| p.name == name }
          expect(instance).to be_a described_class
        end
      end

      context "eos_ipinterface { 'Ethernet1': }" do
        subject { described_class.instances.find { |p| p.name == 'Ethernet1' } }

        include_examples 'provider resource methods',
                         ensure: :present,
                         name: 'Ethernet1',
                         address: '172.16.10.1/24',
                         mtu: 1500
      end

      context "eos_ipinterface { 'Management1': )" do
        subject do
          described_class.instances.find do |p|
            p.name == 'Management1'
          end
        end

        include_examples 'provider resource methods',
                         ensure: :present,
                         name: 'Management1',
                         address: '192.168.1.16/24',
                         mtu: 1500
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
        end
      end

      it 'sets the provider instance of the managed resource' do
        subject
        expect(resources['Ethernet1'].provider.name).to eq 'Ethernet1'
        expect(resources['Ethernet1'].provider.exists?).to be_truthy
      end

      it 'does not set the provider instance of the unmanaged resource' do
        subject
        expect(resources['Ethernet2'].provider.name).to eq('Ethernet2')
        expect(resources['Ethernet2'].provider.exists?).to be_falsey
      end
    end
  end

  context 'resource (instance) methods' do

    let(:eapi) { double }

    before do
      allow(provider).to receive(:eapi)
      allow(provider.eapi).to receive(:Ipinterface).and_return(eapi)
    end

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

      before :each do
        allow(eapi).to receive(:create).with('Ethernet1')
        allow(eapi).to receive(:set_address)
        allow(eapi).to receive(:set_mtu)
      end

      it "calls Ipinterface#create('Ethernet1')" do
        expect(eapi).to receive(:create).with('Ethernet1')
        provider.create
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
    end

    describe '#destroy' do
      before :each do
        allow(eapi).to receive(:delete).with('Ethernet1')
        allow(eapi).to receive(:create)
        allow(eapi).to receive(:set_address)
        allow(eapi).to receive(:set_mtu)
      end

      it "calls Ipinterface#delete('Ethernet1')" do
        expect(eapi).to receive(:delete).with('Ethernet1')
        provider.destroy
      end

      context 'when the resource has been created' do
        subject do
          provider.create
          provider.destroy
        end

        it 'sets ensure to :absent' do
          subject
          expect(provider.ensure).to eq(:absent)
        end

        it 'clears the property hash' do
          subject
          expect(provider.instance_variable_get(:@property_hash))
            .to eq(name: 'Ethernet1', ensure: :absent)
        end
      end
    end

    describe '#address=(val)' do
      before :each do
        allow(provider.eapi.Ipinterface).to receive(:set_address)
          .with('Ethernet1', value: '1.2.3.4/5')
      end

      it "calls Ipinterface#set_address('Ethernet1', val: '1.2.3.4/5')" do
        expect(eapi).to receive(:set_address)
          .with('Ethernet1', value: '1.2.3.4/5')
        provider.address = '1.2.3.4/5'
      end

      it 'updates the address property in the provider' do
        expect(provider.address).not_to eq '1.2.3.4/5'
        provider.address = '1.2.3.4/5'
        expect(provider.address).to eq '1.2.3.4/5'
      end
    end

    describe '#mtu=(val)' do
      before :each do
        allow(provider.eapi.Ipinterface).to receive(:set_mtu)
          .with('Ethernet1', value: '9000')
      end

      it 'calls Ipinterface#set_mtu=9000' do
        expect(eapi).to receive(:set_mtu)
          .with('Ethernet1', value: '9000')
        provider.mtu = '9000'
      end

      it 'updates the mtu property in the provider' do
        expect(provider.mtu).not_to eq '9000'
        provider.mtu = '9000'
        expect(provider.mtu).to eq '9000'
      end
    end
  end
end
