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

describe Puppet::Type.type(:eos_vxlan).provider(:eos) do

  # Puppet RAL memoized methods
  let(:resource) do
    resource_hash = {
      ensure: :present,
      name: 'Vxlan1',
      source_interface: 'Looback0',
      multicast_group: '239.10.10.10',
      provider: described_class.name
    }
    Puppet::Type.type(:eos_vxlan).new(resource_hash)
  end

  let(:provider) { resource.provider }

  def vxlan
    vxlan = Fixtures[:vxlan]
    return vxlan if vxlan
    file = File.join(File.dirname(__FILE__), 'fixtures/vxlan.json')
    Fixtures[:vxlan] = JSON.load(File.read(file))
  end

  # Stub the Api method class to obtain all vlans.
  before :each do
    allow_message_expectations_on_nil
    allow(described_class).to receive(:eapi)
    allow(described_class.eapi).to receive(:Vxlan)
    allow(described_class.eapi.Vxlan).to receive(:getall)
      .and_return(vxlan)
  end

  context 'class methods' do

    describe '.instances' do
      subject { described_class.instances }

      it { is_expected.to be_an Array }

      it 'has only one entry' do
        expect(subject.size).to eq 1
      end

      it 'has an instance for interface vxlan 1' do
        instance = subject.find { |p| p.name == 'Vxlan1' }
        expect(instance).to be_a described_class
      end

      context "eos_vxlan { 'Vxlan1': }" do
        subject { described_class.instances.find { |p| p.name == 'Vxlan1' } }

        include_examples 'provider resource methods',
                         ensure: :present,
                         name: 'Vxlan1',
                         source_interface: 'Loopback0',
                         multicast_group: '239.10.10.10'
      end
    end

    describe '.prefetch' do
      let :resources do
        {
          'Vxlan1' => Puppet::Type.type(:eos_vxlan).new(name: 'Vxlan1'),
          'Vxlan2' => Puppet::Type.type(:eos_vxlan).new(name: 'Vxlan2')
        }
      end

      subject { described_class.prefetch(resources) }

      it 'resource providers are absent prior to calling .prefetch' do
        resources.values.each do |rsrc|
          expect(rsrc.provider.source_interface).to eq(:absent)
          expect(rsrc.provider.multicast_group).to eq(:absent)
        end
      end

      it 'sets the provider instance of the managed resource' do
        subject
        expect(resources['Vxlan1'].provider.name).to eq 'Vxlan1'
        expect(resources['Vxlan1'].provider.exists?).to be_truthy
      end

      it 'does not set the provider instance of the unmanaged resource' do
        subject
        expect(resources['Vxlan2'].provider.name).to eq('Vxlan2')
        expect(resources['Vxlan2'].provider.exists?).to be_falsey
      end
    end
  end

  context 'resource (instance) methods' do

    let(:eapi) { double }

    before do
      allow(provider).to receive(:eapi)
      allow(provider.eapi).to receive(:Vxlan).and_return(eapi)
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
        allow(eapi).to receive(:create)
        allow(eapi).to receive(:set_source_interface)
        allow(eapi).to receive(:set_multicast_group)
      end

      it 'calls Vxlan#create' do
        expect(eapi).to receive(:create).with(no_args)
        provider.create
      end

      it 'sets ensure to :present' do
        provider.create
        expect(provider.ensure).to eq(:present)
      end

      it 'sets source_interface to the resource value' do
        provider.create
        value = provider.resource[:source_interface]
        expect(provider.source_interface).to eq value
      end

      it 'sets multicast_group to the resource value' do
        provider.create
        value = provider.resource[:multicast_group]
        expect(provider.multicast_group).to eq value
      end
    end

    describe '#destroy' do
      before :each do
        allow(eapi).to receive(:delete)
        allow(eapi).to receive(:create)
        allow(eapi).to receive(:set_source_interface)
        allow(eapi).to receive(:set_multicast_group)
      end

      it 'calls Vxlan#delete' do
        expect(eapi).to receive(:delete).with(no_args)
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
            .to eq(name: 'Vxlan1', ensure: :absent)
        end
      end
    end

    describe '#source_interface=(val)' do
      before :each do
        allow(eapi).to receive(:set_source_interface)
      end

      it "calls Vxlan#set_source_interface='Looback0'" do
        expect(eapi).to receive(:set_source_interface)
          .with(value: 'Loopback0')
        provider.source_interface = 'Loopback0'
      end

      it 'updates the source_interface property in the provider' do
        expect(provider.source_interface).not_to eq 'Loopback0'
        provider.source_interface = 'Loopback0'
        expect(provider.source_interface).to eq 'Loopback0'
      end
    end

    describe '#multicast_group=(val)' do
      before :each do
        allow(eapi).to receive(:set_multicast_group)
      end

      it "calls Vxlan#set_multicast_group='Looback0'" do
        expect(eapi).to receive(:set_multicast_group)
          .with(value: '239.10.10.10')
        provider.multicast_group = '239.10.10.10'
      end

      it 'updates the multicast_group property in the provider' do
        expect(provider.multicast_group).not_to eq '239.10.10.10'
        provider.multicast_group = '239.10.10.10'
        expect(provider.multicast_group).to eq '239.10.10.10'
      end
    end
  end
end
