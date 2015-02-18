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

  let(:api) { double('vlans') }

  def vlans
    vlans = Fixtures[:vlans]
    return vlans if vlans
    fixture('vlans', dir: File.dirname(__FILE__))
  end

  before :each do
    allow(described_class.node).to receive(:api).with('vlans').and_return(api)
    allow(provider.node).to receive(:api).with('vlans').and_return(api)
  end

  context 'class methods' do

    before { allow(api).to receive(:getall).and_return(vlans) }

    describe '.instances' do
      subject { described_class.instances }

      it { is_expected.to be_an Array }

      it 'has only one entry' do
        expect(subject.size).to eq 1
      end

      it 'has an instance for VLAN 1' do
        instance = subject.find { |p| p.name == '1' }
        expect(instance).to be_a described_class
      end

      context 'eos_vlan { 1: }' do
        subject { described_class.instances.find { |p| p.name == '1' } }

        include_examples 'provider resource methods',
                         ensure: :present,
                         vlanid: '1',
                         vlan_name: 'default',
                         enable: :true,
                         exists?: true,
                         trunk_groups: []
      end
    end

    describe '.prefetch' do
      let :resources do
        {
          '1' => Puppet::Type.type(:eos_vlan).new(vlanid: '1'),
          '2' => Puppet::Type.type(:eos_vlan).new(vlanid: '2'),
        }
      end

      subject { described_class.prefetch(resources) }

      it 'resource providers are absent prior to calling .prefetch' do
        resources.values.each do |rsrc|
          expect(rsrc.provider.vlanid).to eq(:absent)
          expect(rsrc.provider.vlan_name).to eq(:absent)
          expect(rsrc.provider.trunk_groups).to eq(:absent)
          expect(rsrc.provider.enable).to eq(:absent)
        end
      end

      it 'sets the provider instance of the managed resource' do
        subject
        expect(resources['1'].provider.vlanid).to eq '1'
        expect(resources['1'].provider.vlan_name).to eq 'default'
        expect(resources['1'].provider.enable).to eq :true
        expect(resources['1'].provider.trunk_groups).to eq []
        expect(resources['1'].provider.exists?).to be_truthy
      end

      it 'does not set the provider instance of the unmanaged resource' do
        subject
        expect(resources['2'].provider.vlanid).to eq :absent
        expect(resources['2'].provider.vlan_name).to eq :absent
        expect(resources['2'].provider.enable).to eq :absent
        expect(resources['2'].provider.trunk_groups).to eq :absent
        expect(resources['2'].provider.exists?).to be_falsey
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
          allow(api).to receive(:getall).and_return(vlans)
          described_class.instances.first
        end
        it { is_expected.to be_truthy }
      end
    end

    describe '#create' do
      let(:vid) { resource[:name] }

      before do
        allow(api).to receive_messages(
          :set_state => true,
          :set_name => true,
          :set_trunk_group => true
        )
        expect(api).to receive(:create).with(resource[:name])
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
      it 'sets ensure to :absent' do
        expect(api).to receive(:delete).with(resource[:name])
        provider.destroy
        expect(provider.ensure).to eq(:absent)
      end
    end

    describe '#vlan_name=(value)' do
      it 'updates vlan_name in the provider' do
        expect(api).to receive(:set_name).with(resource[:name], value: 'foo')
        provider.vlan_name = 'foo'
        expect(provider.vlan_name).to eq('foo')
      end
    end

    describe '#enable=(value)' do
      let(:vid) { resource[:name] }

      it 'updates enable with value :true' do
        expect(api).to receive(:set_state).with(vid, value: 'active')
        provider.enable = :true
        expect(provider.enable).to eq(:true)
      end

      it 'updates enable with value :false' do
        expect(api).to receive(:set_state).with(vid, value: 'suspend')
        provider.enable = :false
        expect(provider.enable).to eq(:false)
      end
    end

    describe '#trunk_groups=(value)' do
      let(:vid) { resource[:name] }
      let(:tgs) { %w(tg1 tg2 tg3) }

      it 'updates trunk_groups with array [tg1, tg2, tg3]' do
        expect(api).to receive(:set_trunk_group).with(vid, value: tgs)
        provider.trunk_groups = tgs
        expect(provider.trunk_groups).to eq(tgs)
      end
    end
  end
end
