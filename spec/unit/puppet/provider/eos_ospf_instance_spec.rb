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

describe Puppet::Type.type(:eos_ospf_instance).provider(:eos) do

  # Puppet RAL memoized methods
  let(:resource) do
    resource_hash = {
      ensure: :present,
      name: '1',
      router_id: '1.1.1.1',
      provider: described_class.name
    }
    Puppet::Type.type(:eos_ospf_instance).new(resource_hash)
  end

  let(:provider) { resource.provider }

  def ospf_instance
    ospf_instance = Fixtures[:ospf_instance]
    return ospf_instance if ospf_instance
    file = File.join(File.dirname(__FILE__), 'fixtures/ospf.json')
    Fixtures[:ospf_instance] = JSON.load(File.read(file))
  end

  # Stub the Api method class to obtain all vlans.
  before :each do
    allow_message_expectations_on_nil
    allow(described_class).to receive(:eapi)
    allow(described_class.eapi).to receive(:Ospf)
    allow(described_class.eapi.Ospf).to receive(:getall)
      .and_return(ospf_instance)
  end

  context 'class methods' do

    describe '.instances' do
      subject { described_class.instances }

      it { is_expected.to be_an Array }

      it 'has one entry' do
        expect(subject.size).to eq 1
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
                         router_id: '1.1.1.1'
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
        expect(resources['1'].provider.name).to eq '1'
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

    let(:eapi) { double }

    before do
      allow(provider).to receive(:eapi)
      allow(provider.eapi).to receive(:Ospf).and_return(eapi)
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
        allow(eapi).to receive(:create).with('1')
        allow(eapi).to receive(:set_router_id)
      end

      it "calls Ospf#create('1')" do
        expect(eapi).to receive(:create).with('1')
        provider.create
      end

      it 'sets ensure to :present' do
        provider.create
        expect(provider.ensure).to eq(:present)
      end

      it 'sets router_id to the resource value' do
        provider.create
        expect(provider.router_id).to eq(provider.resource[:router_id])
      end

    end

    describe '#destroy' do
      before :each do
        allow(eapi).to receive(:delete).with('1')
        allow(eapi).to receive(:create)
        allow(eapi).to receive(:set_router_id)
      end

      it "calls Ospf#delete('1')" do
        expect(eapi).to receive(:delete).with('1')
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
            .to eq(name: '1', ensure: :absent)
        end
      end
    end

    describe '#router_id=(val)' do
      before :each do
        allow(provider.eapi.Ospf).to receive(:set_router_id)
          .with('1', value: '1.1.1.1')
      end

      it "calls Ospf#set_router_id('1', val: '1.1.1.1')" do
        expect(eapi).to receive(:set_router_id)
          .with('1', value: '1.1.1.1')
        provider.router_id = '1.1.1.1'
      end

      it 'updates the router_id property in the provider' do
        expect(provider.router_id).not_to eq '1.1.1.1'
        provider.router_id = '1.1.1.1'
        expect(provider.router_id).to eq '1.1.1.1'
      end
    end

  end
end
