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

describe Puppet::Type.type(:eos_ospf_instance).provider(:eos) do
  # Puppet RAL memoized methods
  let(:resource) do
    resource_hash = {
      ensure: :present,
      name: '1',
      router_id: '1.1.1.1',
      max_lsa: 12_000,
      maximum_paths: 16,
      passive_interfaces: [],
      active_interfaces: %w(Ethernet49 Ethernet50 Vlan4093),
      passive_interface_default: :true,
      provider: described_class.name
    }
    Puppet::Type.type(:eos_ospf_instance).new(resource_hash)
  end

  let(:provider) { resource.provider }

  let(:api) { double('ospf') }

  def ospf
    ospf = Fixtures[:ospf]
    return ospf if ospf
    fixture('ospf')
  end

  # Stub the Api method class to obtain all ospf instances.
  before :each do
    allow(described_class.node).to receive(:api).with('ospf').and_return(api)
    allow(provider.node).to receive(:api).with('ospf').and_return(api)
    allow_message_expectations_on_nil
  end

  context 'class methods' do
    before { allow(api).to receive(:getall).and_return(ospf) }

    describe '.instances' do
      subject { described_class.instances }

      it { is_expected.to be_an Array }

      it 'has two entries' do
        expect(subject.size).to eq 2
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
                         router_id: '1.1.1.1',
                         max_lsa: '12000',
                         maximum_paths: '16',
                         passive_interfaces: [],
                         active_interfaces: %w(Ethernet49 Ethernet50 Vlan4093),
                         passive_interface_default: :true
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
        expect(resources['1'].provider.name).to eq('1')
        expect(resources['1'].provider.exists?).to be_truthy
      end

      it 'does not set the provider instance of the unmanaged resource' do
        subject
        expect(resources['2'].provider.name).to eq('2')
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
          allow(api).to receive(:getall).and_return(ospf)
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
          set_router_id: true,
          set_max_lsa: true,
          set_maximum_paths: true,
          set_passive_interfaces: true,
          set_active_interfaces: true,
          set_passive_interface_default: true
        )
      end

      it 'sets ensure to :present' do
        provider.create
        expect(provider.ensure).to eq(:present)
      end

      it 'sets router_id to the resource value' do
        provider.create
        expect(provider.router_id).to eq(provider.resource[:router_id])
      end

      it 'sets max_lsa to the resource value' do
        provider.create
        expect(provider.max_lsa).to eq(provider.resource[:max_lsa])
      end

      it 'sets maximum_paths to the resource value' do
        provider.create
        expect(provider.maximum_paths).to eq(provider.resource[:maximum_paths])
      end

      it 'sets passive_interfaces to the resource value' do
        provider.create
        expect(provider.passive_interfaces)
          .to eq(provider.resource[:passive_interfaces])
      end

      it 'sets active_interfaces to the resource value' do
        provider.create
        expect(provider.active_interfaces)
          .to eq(provider.resource[:active_interfaces])
      end

      it 'sets passive_interface_default to the resource value' do
        provider.create
        expect(provider.passive_interface_default)
          .to eq(provider.resource[:passive_interface_default])
      end
    end

    describe '#destroy' do
      it 'sets ensure to :absent' do
        expect(api).to receive(:delete).with(resource[:name])
        provider.destroy
        expect(provider.ensure).to eq(:absent)
      end
    end

    describe '#router_id=(val)' do
      %w(1.1.1.1 2.2.2.2 3.3.3.3 4.4.4.4).each do |value|
        let(:value) { value }

        it 'updates router_id in the provider' do
          expect(api).to receive(:set_router_id)
            .with(resource[:name], value: value)
          provider.router_id = value
          expect(provider.router_id).to eq(value)
        end
      end
    end

    describe '#max_lsa=(val)' do
      %w(100 10000 100000).each do |value|
        let(:value) { value }

        it 'updates max_lsa in the provider' do
          expect(api).to receive(:set_max_lsa)
            .with(resource[:name], value: value)
          provider.max_lsa = value
          expect(provider.max_lsa).to eq(value)
        end
      end
    end

    describe '#maximum_paths=(val)' do
      %w(1 16 32).each do |value|
        let(:value) { value }

        it 'updates maximum_paths in the provider' do
          expect(api).to receive(:set_maximum_paths)
            .with(resource[:name], value: value)
          provider.maximum_paths = value
          expect(provider.maximum_paths).to eq(value)
        end
      end
    end

    describe '#passive_interfaces=(val)' do
      [%w(Ethernet1 Ethernet2), ['Loopback0'], []].each do |value|
        let(:value) { value }

        it 'updates passive_interfaces in the provider' do
          expect(api).to receive(:set_passive_interfaces)
            .with(resource[:name], value: value)
          provider.passive_interfaces = value
          expect(provider.passive_interfaces).to eq(value)
        end
      end
    end

    describe '#active_interfaces=(val)' do
      [%w(Ethernet1 Ethernet2), ['Loopback0'], []].each do |value|
        let(:value) { value }

        it 'updates active_interfaces in the provider' do
          expect(api).to receive(:set_active_interfaces)
            .with(resource[:name], value: value)
          provider.active_interfaces = value
          expect(provider.active_interfaces).to eq(value)
        end
      end
    end

    describe '#passive_interface_default=(val)' do
      [false, true].each do |value|
        let(:value) { value }

        it 'updates passive_interface_default in the provider' do
          expect(api).to receive(:set_passive_interface_default)
            .with(resource[:name], value: value)
          provider.passive_interface_default = value.to_s.to_sym
          expect(provider.passive_interface_default).to eq(value.to_s.to_sym)
        end
      end
    end
  end
end
