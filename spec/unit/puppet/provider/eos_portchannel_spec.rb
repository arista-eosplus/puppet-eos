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

describe Puppet::Type.type(:eos_portchannel).provider(:eos) do

  # Puppet RAL memoized methods
  let(:resource) do
    resource_hash = {
      ensure: :present,
      name: 'Ethernet1',
      mode: :trunk,
      trunk_allowed_vlans: %w(1 10 100 1000),
      trunk_native_vlan: '1',
      access_vlan: '1',
      provider: described_class.name
    }
    Puppet::Type.type(:eos_portchannel).new(resource_hash)
  end

  let(:provider) { resource.provider }

  def switchports
    switchports = Fixtures[:switchports]
    return switchports if switchports
    file = File.join(File.dirname(__FILE__), 'fixtures/switchports.json')
    Fixtures[:switchports] = JSON.load(File.read(file))
  end

  # Stub the Api method class to obtain all vlans.
  before :each do
    allow_message_expectations_on_nil
    allow(described_class).to receive(:eapi)
    allow(described_class.eapi).to receive(:Switchport)
    allow(described_class.eapi.Switchport).to receive(:getall)
      .and_return(switchports)
  end

  context 'class methods' do
    describe '.instances' do
      subject { described_class.instances }

      it { is_expected.to be_an Array }

      it 'has three entries' do
        expect(subject.size).to eq 3
      end

      %w(Ethernet1 Ethernet2 Ethernet3).each do |name|
        it "has an instance for interface #{name}" do
          instance = subject.find { |p| p.name == name }
          expect(instance).to be_a described_class
        end
      end

      context "eos_switchport { 'Ethernet1': }" do
        subject { described_class.instances.find { |p| p.name == 'Ethernet1' } }

        include_examples 'provider resource methods',
                         ensure: :present,
                         name: 'Ethernet1',
                         mode: :trunk,
                         trunk_allowed_vlans: %w(1 10 100 1000),
                         trunk_native_vlan: '1',
                         access_vlan: '1'

      end

      context "eos_switchport { 'Ethernet2': }" do
        subject { described_class.instances.find { |p| p.name == 'Ethernet2' } }

        include_examples 'provider resource methods',
                         ensure: :present,
                         name: 'Ethernet2',
                         mode: :access,
                         trunk_allowed_vlans: [],
                         trunk_native_vlan: '1',
                         access_vlan: '1'

      end

      context "eos_switchport { 'Ethernet3': }" do
        subject { described_class.instances.find { |p| p.name == 'Ethernet3' } }

        include_examples 'provider resource methods',
                         ensure: :present,
                         name: 'Ethernet3',
                         mode: :trunk,
                         trunk_allowed_vlans: %w(1 10 100 1000),
                         trunk_native_vlan: '1',
                         access_vlan: '1'

      end
    end

    describe '.prefetch' do
      let :resources do
        {
          'Ethernet1' => Puppet::Type.type(:eos_switchport)
            .new(name: 'Ethernet1'),
          'Ethernet4' => Puppet::Type.type(:eos_switchport)
            .new(name: 'Ethernet4')
        }
      end

      subject { described_class.prefetch(resources) }

      it 'resource providers are absent prior to calling .prefetch' do
        resources.values.each do |rsrc|
          expect(rsrc.provider.mode).to eq(:absent)
        end
      end

      it 'sets the provider instance of the managed resource' do
        subject
        expect(resources['Ethernet1'].provider.name).to eq 'Ethernet1'
        expect(resources['Ethernet1'].provider.exists?).to be_truthy
      end

      it 'does not set the provider instance of the unmanaged resource' do
        subject
        expect(resources['Ethernet4'].provider.name).to eq('Ethernet4')
        expect(resources['Ethernet4'].provider.exists?).to be_falsey
      end
    end
  end

  context 'resource (instance) methods' do

    let(:eapi) { double }

    before do
      allow(provider).to receive(:eapi)
      allow(provider.eapi).to receive(:Switchport).and_return(eapi)
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
        allow(eapi).to receive(:set_mode)
        allow(eapi).to receive(:set_trunk_allowed_vlans)
        allow(eapi).to receive(:set_trunk_native_vlan)
        allow(eapi).to receive(:set_access_vlan)
      end

      it "calls Switchport#create('Ethernet1')" do
        expect(eapi).to receive(:create).with('Ethernet1')
        provider.create
      end

      it 'sets ensure to :present' do
        provider.create
        expect(provider.ensure).to eq(:present)
      end

      it 'sets mode to the resource value' do
        provider.create
        expect(provider.mode).to eq provider.resource[:mode]
      end

      it 'sets trunk_allowed_vlans to the resource value' do
        provider.create
        value = provider.resource[:trunk_allowed_vlans]
        expect(provider.trunk_allowed_vlans).to eq value
      end

      it 'sets trunk_native_vlan to the resource value' do
        provider.create
        value = provider.resource[:trunk_native_vlan]
        expect(provider.trunk_native_vlan).to eq value
      end

      it 'sets access_vlan to the resource value' do
        provider.create
        value = provider.resource[:access_vlan]
        expect(provider.access_vlan).to eq value
      end
    end

    describe '#destroy' do
      before :each do
        allow(eapi).to receive(:delete).with('Ethernet1')
        allow(eapi).to receive(:create).with('Ethernet1')
        allow(eapi).to receive(:set_mode)
        allow(eapi).to receive(:set_trunk_allowed_vlans)
        allow(eapi).to receive(:set_trunk_native_vlan)
        allow(eapi).to receive(:set_access_vlan)

      end

      it "calls Switchport#delete('Ethernet1')" do
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

    describe 'set_mode=(val)' do
      before :each do
        allow(provider.eapi.Switchport).to receive(:set_mode)
      end

      %w(access trunk).each do |value|
        let(:value) { value }
        it "class Switchport#set_mode(#{value})" do
          expect(eapi).to receive(:set_mode)
            .with('Ethernet1', value: value)
          provider.mode = value
        end

        it 'updates the mode property in the provider' do
          expect(provider.mode).not_to eq value
          provider.mode = value
          expect(provider.mode).to eq value
        end
      end
    end

    describe 'set_trunk_native_vlan=(val)' do
      before :each do
        allow(provider.eapi.Switchport).to receive(:set_trunk_native_vlan)
          .with('Ethernet1', value: vlanid)
      end

      let(:vlanid) { '1' }

      it 'calls Switchport#set_trunk_native_vlan' do
        expect(eapi).to receive(:set_trunk_native_vlan)
          .with('Ethernet1', value: vlanid)
        provider.trunk_native_vlan = vlanid
      end

      it 'updates the address property in the provider' do
        expect(provider.trunk_native_vlan).not_to eq vlanid
        provider.trunk_native_vlan = vlanid
        expect(provider.trunk_native_vlan).to eq vlanid
      end
    end

    describe 'set_trunk_allowed_vlans=(val)' do
      before :each do
        allow(provider.eapi.Switchport).to receive(:set_trunk_allowed_vlans)
          .with('Ethernet1', value: vlan_array)
      end

      let(:vlan_array) { %w(1 10 100 1000) }

      it 'calls Switchport#set_trunk_allowed_vlans' do
        expect(eapi).to receive(:set_trunk_allowed_vlans)
          .with('Ethernet1', value: vlan_array)
        provider.trunk_allowed_vlans = vlan_array
      end

      it 'updates the address property in the provider' do
        expect(provider.trunk_allowed_vlans).not_to eq vlan_array
        provider.trunk_allowed_vlans = vlan_array
        expect(provider.trunk_allowed_vlans).to eq vlan_array
      end
    end

    describe 'set_access_vlan=(val)' do
      before :each do
        allow(provider.eapi.Switchport).to receive(:set_access_vlan)
          .with('Ethernet1', value: vlanid)
      end

      let(:vlanid) { '1' }

      it 'calls Switchport#set_access_vlan' do
        expect(eapi).to receive(:set_access_vlan)
          .with('Ethernet1', value: vlanid)
        provider.access_vlan = vlanid
      end

      it 'updates the address property in the provider' do
        expect(provider.access_vlan).not_to eq vlanid
        provider.access_vlan = vlanid
        expect(provider.access_vlan).to eq vlanid
      end
    end
  end
end
