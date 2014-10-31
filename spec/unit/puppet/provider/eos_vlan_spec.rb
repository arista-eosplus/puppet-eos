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

describe Puppet::Type.type(:eos_vlan).provider(:eos) do

  # Puppet RAL memoized methods
  let(:resource) do
    resource_hash = {
      ensure: :present,
      name: '1234',
      vlanid: '1234',
      vlan_name: 'VLAN1234',
      enable: true,
      trunk_groups: [],
      provider: described_class.name
    }
    Puppet::Type.type(:eos_vlan).new(resource_hash)
  end

  let(:provider) { resource.provider }

  def all_vlans
    all_vlans = Fixtures[:all_vlans]
    return all_vlans if all_vlans
    file = File.join(File.dirname(__FILE__), 'fixtures/vlans.json')
    Fixtures[:all_vlans] = JSON.load(File.read(file))
  end

  # Stub the Api method class to obtain all vlans.
  before :each do
    allow_message_expectations_on_nil
    allow(described_class).to receive(:eapi)
    allow(described_class.eapi).to receive(:Vlan)
    allow(described_class.eapi.Vlan).to receive(:get).and_return(all_vlans)
  end

  context 'class methods' do

    describe '.instances' do
      subject { described_class.instances }

      it { is_expected.to be_an Array }

      it 'has three instances' do
        expect(subject.size).to eq(3)
      end

      %w(1 2 3).each do |name|
        it "has an instance for VLAN #{name}" do
          instance = subject.find { |p| p.name == name }
          expect(instance).to be_a described_class
        end
      end

      context 'eos_vlan { 1: }' do
        subject { described_class.instances.find { |p| p.name == '1' } }

        include_examples 'provider resource methods',
                         ensure: :present,
                         vlanid: '1',
                         vlan_name: 'default',
                         enable: :true,
                         exists?: true,
                         trunk_groups: [],
                         vni: :absent
      end

      context 'eos_vlan { 2: }' do
        subject { described_class.instances.find { |p| p.name == '2' } }

        include_examples 'provider resource methods',
                         ensure: :present,
                         vlanid: '2',
                         vlan_name: 'VLAN0002',
                         enable: :true,
                         exists?: true,
                         trunk_groups: [],
                         vni: :absent
      end

      context 'eos_vlan { 3: }' do
        subject { described_class.instances.find { |p| p.name == '3' } }

        include_examples 'provider resource methods',
                         ensure: :present,
                         vlanid: '3',
                         vlan_name: 'VLAN0003',
                         enable: :true,
                         exists?: true,
                         trunk_groups: ['foo'],
                         vni: :absent
      end
    end

    describe '.prefetch' do
      let :resources do
        {
          '1' => Puppet::Type.type(:eos_vlan).new(vlanid: '1'),
          '2' => Puppet::Type.type(:eos_vlan).new(vlanid: '2'),
          '3' => Puppet::Type.type(:eos_vlan).new(vlanid: '3'),
          '4' => Puppet::Type.type(:eos_vlan).new(vlanid: '4')
        }
      end
      subject { described_class.prefetch(resources) }

      it 'resource providers are absent prior to calling .prefetch' do
        resources.values.each do |rsrc|
          expect(rsrc.provider.vlanid).to eq(:absent)
          expect(rsrc.provider.vlan_name).to eq(:absent)
        end
      end

      it 'sets the provider instance of the managed resource' do
        subject
        %w(1 2 3).each do |vid|
          expect(resources[vid].provider.vlanid).to eq(vid)
          name = vid == '1' ? 'default' : "VLAN000#{vid}"
          expect(resources[vid].provider.vlan_name).to eq(name)
          expect(resources[vid].provider.exists?).to eq(true)
        end
      end

      it 'does not set the provider instance of the unmanaged resource' do
        subject
        expect(resources['4'].provider.vlanid).to eq(:absent)
        expect(resources['4'].provider.vlan_name).to eq(:absent)
        expect(resources['4'].provider.exists?).to eq(false)
      end
    end
  end

  context 'resource (instance) methods' do

    before do
      allow(provider).to receive(:eapi)
      allow(provider.eapi).to receive(:Vlan)
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

    describe '#add' do

      let(:id) { provider.resource[:vlanid] }

      before :each do
        allow(provider.eapi.Vlan).to receive(:add).with(id)

        allow(provider.eapi.Vlan).to receive(:set_name)
          .with(id: id, value: provider.resource[:vlan_name])

        allow(provider.eapi.Vlan).to receive(:set_trunk_group)
          .with(id: id, value: provider.resource[:trunk_groups])

        allow(provider.eapi.Vlan).to receive(:set_state)
          .with(id: id, value: 'active')
      end

      it 'calls Eapi#add(id) with the resource id' do
        expect(provider.eapi.Vlan).to receive(:add)
          .with(provider.resource[:vlanid])
        provider.create
      end

      it 'sets ensure to :present' do
        provider.create
        expect(provider.ensure).to eq(:present)
      end

      it 'sets enable to the resource value' do
        provider.create
        expect(provider.enable).to be_truthy
      end

      it 'sets vlan_name to the resource value' do
        provider.create
        expect(provider.vlan_name).to eq(provider.resource[:vlan_name])
      end

      it 'sets trunk_groups to the resource value array' do
        provider.create
        expect(provider.trunk_groups).to eq(provider.resource[:trunk_groups])
      end
    end

    describe '#destroy' do

      let(:id) { provider.resource[:vlanid] }

      before :each do
        allow(provider.eapi.Vlan).to receive(:add).with(id)
        allow(provider.eapi.Vlan).to receive(:delete).with(id)
        allow(provider.eapi.Vlan).to receive(:set_state)
        allow(provider.eapi.Vlan).to receive(:set_name)
        allow(provider.eapi.Vlan).to receive(:set_trunk_group)
      end

      it 'calls Eapi#delete(id)' do
        expect(provider.eapi.Vlan).to receive(:delete)
          .with(id)
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
            .to eq(vlanid: id, ensure: :absent)
        end
      end
    end

    describe '#vlan_name=(value)' do
      before :each do
        allow(provider.eapi.Vlan).to receive(:set_name)
          .with(id: provider.resource[:vlanid], value: 'foo')
      end

      it 'calls Eapi#set_vlan_name("100", "foo")' do
        expect(provider.eapi.Vlan).to receive(:set_name)
          .with(id: provider.resource[:vlanid], value: 'foo')
        provider.vlan_name = 'foo'
      end

      it 'updates vlan_name in the provider' do
        expect(provider.vlan_name).not_to eq('foo')
        provider.vlan_name = 'foo'
        expect(provider.vlan_name).to eq('foo')
      end
    end

    describe '#enable=(value)' do
    end

    describe '#trunk_groups=(value)' do
      before :each do
        allow(provider.eapi.Vlan).to receive(:set_trunk_group)
          .with(id: provider.resource[:vlanid], value: ['foo'])
      end

      it 'calls Eapi#set_trunk_group("100", ["foo"])' do
        expect(provider.eapi.Vlan).to receive(:set_trunk_group)
          .with(id: provider.resource[:vlanid], value: ['foo'])
        provider.trunk_groups = ['foo']
      end

      it 'updates trunk_groups in the provider' do
        expect(provider.trunk_groups).not_to eq(['foo'])
        provider.trunk_groups = ['foo']
        expect(provider.trunk_groups).to eq(['foo'])
      end
    end

    describe '#enable=(value)' do
      context 'when value is :true' do
        before :each do
          allow(provider.eapi.Vlan).to receive(:set_state)
            .with(id: provider.resource[:vlanid], value: 'active')
        end

        it 'calls Eapi#set_enable("100", "active")' do
          expect(provider.eapi.Vlan).to receive(:set_state)
            .with(id: provider.resource[:vlanid], value: 'active')
          provider.enable = true
        end
      end

      context 'when value is :false' do
        before :each do
          allow(provider.eapi.Vlan).to receive(:set_state)
            .with(id: provider.resource[:vlanid], value: 'suspend')
        end

        it 'updates enable in the provider' do
          expect(provider.enable).not_to be_falsey
          provider.enable = false
          expect(provider.enable).to be_falsey
        end
      end
    end
  end
end
