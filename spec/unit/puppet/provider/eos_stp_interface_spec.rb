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

describe Puppet::Type.type(:eos_stp_interface).provider(:eos) do

  # Puppet RAL memoized methods
  let(:resource) do
    resource_hash = {
      ensure: :present,
      name: 'Ethernet1',
      portfast: 'enable',
      provider: described_class.name
    }
    Puppet::Type.type(:eos_stp_interface).new(resource_hash)
  end

  let(:provider) { resource.provider }

  def stp_interface
    stp_interface = Fixtures[:stp_interface]
    return stp_interface if stp_interface
    file = File.join(File.dirname(__FILE__), 'fixtures/stp_interfaces.json')
    Fixtures[:stp_interface] = JSON.load(File.read(file))
  end

  # Stub the Api method class to obtain all vlans.
  before :each do
    allow_message_expectations_on_nil
    allow(described_class).to receive(:eapi)
    allow(described_class.eapi).to receive(:Stp)
    allow(described_class.eapi.Stp).to receive(:interfaces)
    allow(described_class.eapi.Stp.interfaces).to receive(:getall)
      .and_return(stp_interface)
  end

  context 'class methods' do

    describe '.instances' do
      subject { described_class.instances }

      it { is_expected.to be_an Array }

      it 'has one entry' do
        expect(subject.size).to eq 1
      end

      it 'has an instance for Ethernet 1' do
        instance = subject.find { |p| p.name == 'Ethernet1' }
        expect(instance).to be_a described_class
      end

      context "eos_stp_interface { 'Ethernet1': }" do
        subject { described_class.instances.find { |p| p.name == 'Ethernet1' } }

        include_examples 'provider resource methods',
                         ensure: :present,
                         name: 'Ethernet1',
                         portfast: 'enable'
      end

    end

    describe '.prefetch' do
      let :resources do
        {
          'Ethernet1' => Puppet::Type.type(:eos_stp_interface)
            .new(name: 'Ethernet1'),
          'Ethernet2' => Puppet::Type.type(:eos_stp_interface)
            .new(name: 'Ethernet2')
        }
      end

      subject { described_class.prefetch(resources) }

      it 'resource providers are absent prior to calling .prefetch' do
        resources.values.each do |rsrc|
          expect(rsrc.provider.portfast).to eq(:absent)
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
    let(:name) { provider.resource[:name] }

    before do
      allow(provider).to receive(:eapi)
      allow(provider.eapi).to receive(:Stp)
      allow(provider.eapi.Stp).to receive(:interfaces).and_return(stp_interface)
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
        allow(stp_interface).to receive(:create).with(name)
        allow(stp_interface).to receive(:set_portfast)
      end

      it 'calls Stp.interface#create(name)' do
        expect(provider.eapi.Stp.interfaces).to receive(:create).with(name)
        provider.create
      end

      it 'sets ensure to :present' do
        provider.create
        expect(provider.ensure).to eq(:present)
      end

      it 'sets portfast to the resource value' do
        provider.create
        expect(provider.portfast).to eq(provider.resource[:portfast])
      end

    end

    describe '#destroy' do
      before :each do
        allow(stp_interface).to receive(:delete).with(name)
        allow(stp_interface).to receive(:create)
        allow(stp_interface).to receive(:set_portfast)
      end

      it 'calls Stp.interface#delete(name)' do
        expect(stp_interface).to receive(:delete).with(name)
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
            .to eq(name: name, ensure: :absent)
        end
      end
    end

    describe '#portfast=(val)' do
      before :each do
        allow(stp_interface).to receive(:set_portfast)
          .with(name, value: 'enable')
      end

      it 'calls Stp#set_portfast(name, val: name)' do
        expect(stp_interface).to receive(:set_portfast)
          .with(name, value: 'enable')
        provider.portfast = 'enable'
      end

      it 'updates the portfast property in the provider' do
        expect(provider.portfast).not_to eq 'enable'
        provider.portfast = 'enable'
        expect(provider.portfast).to eq 'enable'
      end
    end

  end
end
