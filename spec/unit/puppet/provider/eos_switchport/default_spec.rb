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

describe Puppet::Type.type(:eos_switchport).provider(:eos) do
  # Puppet RAL memoized methods
  let(:resource) do
    resource_hash = {
      ensure: :present,
      name: 'Ethernet1',
      mode: :trunk,
      trunk_allowed_vlans: ['1','10','100-500','1000'],
      trunk_native_vlan: '1',
      access_vlan: '1',
      trunk_groups: [],
      provider: described_class.name
    }
    Puppet::Type.type(:eos_switchport).new(resource_hash)
  end

  let(:provider) { resource.provider }

  let(:api) { double('switchports') }

  def switchports
    switchports = Fixtures[:switchports]
    return switchports if switchports
    fixture('switchports', dir: File.dirname(__FILE__))
  end

  before :each do
    allow(described_class.node).to receive(:api)
      .with('switchports')
      .and_return(api)

    allow(provider.node).to receive(:api).with('switchports').and_return(api)
  end

  context 'class methods' do
    before { allow(api).to receive(:getall).and_return(switchports) }

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

      context "eos_switchport { 'Ethernet1': }" do
        subject { described_class.instances.find { |p| p.name == 'Ethernet1' } }

        include_examples 'provider resource methods',
                         ensure: :present,
                         name: 'Ethernet1',
                         mode: :trunk,
                         trunk_allowed_vlans: ['1', '10', '100-500', '1000'],
                         trunk_native_vlan: '1',
                         access_vlan: '1',
                         trunk_groups: []
      end
    end

    describe '.prefetch' do
      let :resources do
        {
          'Ethernet1' => Puppet::Type.type(:eos_switchport)
            .new(name: 'Ethernet1'),
          'Ethernet2' => Puppet::Type.type(:eos_switchport)
            .new(name: 'Ethernet2')
        }
      end

      subject { described_class.prefetch(resources) }

      it 'resource providers are absent prior to calling .prefetch' do
        resources.values.each do |rsrc|
          expect(rsrc.provider.mode).to eq(:absent)
          expect(rsrc.provider.trunk_native_vlan).to eq(:absent)
          expect(rsrc.provider.access_vlan).to eq(:absent)
          expect(rsrc.provider.trunk_allowed_vlans).to eq(:absent)
          expect(rsrc.provider.trunk_groups).to eq(:absent)
        end
      end

      it 'sets the provider instance of the managed resource' do
        subject
        expect(resources['Ethernet1'].provider.name).to eq 'Ethernet1'
        expect(resources['Ethernet1'].provider.exists?).to be_truthy
        expect(resources['Ethernet1'].provider.mode).to eq :trunk
        expect(resources['Ethernet1'].provider.access_vlan).to eq '1'
        expect(resources['Ethernet1'].provider.trunk_native_vlan).to eq '1'
        expect(resources['Ethernet1'].provider.trunk_allowed_vlans).to \
          eq ['1', '10', '100-500', '1000']
        expect(resources['Ethernet1'].provider.trunk_groups).to eq []
      end

      it 'does not set the provider instance of the unmanaged resource' do
        subject
        expect(resources['Ethernet2'].provider.name).to eq('Ethernet2')
        expect(resources['Ethernet2'].provider.exists?).to be_falsey
        expect(resources['Ethernet2'].provider.mode).to eq :absent
        expect(resources['Ethernet2'].provider.access_vlan).to eq :absent
        expect(resources['Ethernet2'].provider.trunk_native_vlan).to eq :absent
        expect(resources['Ethernet2'].provider.trunk_allowed_vlans).to \
          eq :absent
        expect(resources['Ethernet2'].provider.trunk_groups).to eq :absent
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
          allow(api).to receive(:getall).and_return(switchports)
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
          set_mode: true,
          set_access_vlan: true,
          set_trunk_native_vlan: true,
          set_trunk_allowed_vlans: true,
          set_trunk_groups: true
        )
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
        expect(provider.trunk_allowed_vlans).to eq \
          resource[:trunk_allowed_vlans]
      end

      it 'sets trunk_native_vlan to the resource value' do
        provider.create
        expect(provider.trunk_native_vlan).to eq resource[:trunk_native_vlan]
      end

      it 'sets access_vlan to the resource value' do
        provider.create
        expect(provider.access_vlan).to eq resource[:access_vlan]
      end

      it 'sets trunk_groups to the resource value array' do
        provider.create
        expect(provider.trunk_groups).to eq(provider.resource[:trunk_groups])
      end
    end

    describe '#destroy' do
      it 'sets ensure to :absent' do
        expect(api).to receive(:delete).with(resource[:name])
        provider.destroy
        expect(provider.ensure).to eq(:absent)
      end
    end

    describe '#mode=(val)' do
      %w(access trunk).each do |value|
        let(:value) { value }

        it 'updates mode in the provider' do
          expect(api).to receive(:set_mode).with(resource[:name], value: value)
          provider.mode = value
          expect(provider.mode).to eq(value)
        end
      end
    end

    describe '#trunk_native_vlan=(val)' do
      it 'updates trunk_native_vlan in the provider' do
        expect(api).to receive(:set_trunk_native_vlan)
          .with(resource[:name], value: '100')
        provider.trunk_native_vlan = '100'
        expect(provider.trunk_native_vlan).to eq('100')
      end
    end

    describe '#trunk_allowed_vlans=(val)' do
      let(:vlans) { ['1','10','100-500','1000'] }

      it 'updates trunk_allowed_vlans in the provider' do
        expect(api).to receive(:set_trunk_allowed_vlans)
          .with(resource[:name], value: vlans)
        provider.trunk_allowed_vlans = vlans
        expect(provider.trunk_allowed_vlans).to eq(vlans)
      end
    end

    describe '#access_vlan=(val)' do
      it 'updates access_vlan in the provider' do
        expect(api).to receive(:set_access_vlan)
          .with(resource[:name], value: 1000)
        provider.access_vlan = 1000
        expect(provider.access_vlan).to eq(1000)
      end
    end

    describe '#trunk_groups=(value)' do
      let(:vid) { resource[:name] }
      let(:tgs) { %w(tg1 tg2 tg3) }

      it 'updates trunk_groups with array [tg1, tg2, tg3]' do
        expect(api).to receive(:set_trunk_groups).with(vid, value: tgs)
        provider.trunk_groups = tgs
        expect(provider.trunk_groups).to eq(tgs)
      end
    end
  end
end
