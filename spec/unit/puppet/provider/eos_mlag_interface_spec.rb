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

describe Puppet::Type.type(:eos_mlag_interface).provider(:eos) do

  # Puppet RAL memoized methods
  let(:resource) do
    resource_hash = {
      ensure: :present,
      name: 'Port-Channel1',
      mlag_id: '1',
      provider: described_class.name
    }
    Puppet::Type.type(:eos_mlag_interface).new(resource_hash)
  end

  let(:provider) { resource.provider }

  def mlag_interfaces
    mlag_interfaces = Fixtures[:mlag_interfaces]
    return mlag_interfaces if mlag_interfaces
    file = File.join(File.dirname(__FILE__), 'fixtures/mlag_interfaces.json')
    Fixtures[:mlag_interfaces] = JSON.load(File.read(file))
  end

  # Stub the Api method class to obtain all vlans.
  before :each do
    allow_message_expectations_on_nil
    allow(described_class).to receive(:eapi)
    allow(described_class.eapi).to receive(:Mlag)
    allow(described_class.eapi.Mlag).to receive(:get_interfaces)
      .and_return(mlag_interfaces)
  end

  context 'class methods' do

    describe '.instances' do
      subject { described_class.instances }

      it { is_expected.to be_an Array }

      it 'has two entries' do
        expect(subject.size).to eq 2
      end

      %w(Port-Channel1 Port-Channel2).each do |name|
        it "has an instance for interface #{name}" do
          instance = subject.find { |p| p.name == name }
          expect(instance).to be_a described_class
        end
      end

      context "eos_mlag_interface { 'Port-Channel1': }" do
        subject do
          described_class.instances.find do |p|
            p.name == 'Port-Channel1'
          end
        end

        include_examples 'provider resource methods',
                         ensure: :present,
                         name: 'Port-Channel1',
                         mlag_id: '1'
      end

      context "eos_mlag_interface { 'Port-Channel2': }" do
        subject do
          described_class.instances.find do |p|
            p.name == 'Port-Channel2'
          end
        end

        include_examples 'provider resource methods',
                         ensure: :present,
                         name: 'Port-Channel2',
                         mlag_id: '2'
      end
    end

    describe '.prefetch' do
      let :resources do
        {
          'Port-Channel1' => Puppet::Type.type(:eos_mlag_interface)
            .new(name: 'Port-Channel1'),
          'Port-Channel3' => Puppet::Type.type(:eos_mlag_interface)
            .new(name: 'Port-Channel3')
        }
      end

      subject { described_class.prefetch(resources) }

      it 'resource providers are absent prior to calling .prefetch' do
        resources.values.each do |rsrc|
          expect(rsrc.provider.mlag_id).to eq(:absent)
        end
      end

      it 'sets the provider instance of the managed resource' do
        subject
        expect(resources['Port-Channel1'].provider.name).to eq 'Port-Channel1'
        expect(resources['Port-Channel1'].provider.exists?).to be_truthy
      end

      it 'does not set the provider instance of the unmanaged resource' do
        subject
        expect(resources['Port-Channel3'].provider.name).to eq('Port-Channel3')
        expect(resources['Port-Channel3'].provider.exists?).to be_falsey
      end
    end
  end

  context 'resource (instance) methods' do

    let(:eapi) { double }

    before do
      allow(provider).to receive(:eapi)
      allow(provider.eapi).to receive(:Mlag).and_return(eapi)
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
        allow(eapi).to receive(:add_interface)
        allow(eapi).to receive(:set_mlag_id)
      end

      it "calls Mlag#add_interface('Port-Channel1)" do
        expect(eapi).to receive(:add_interface)
          .with('Port-Channel1', '1')
        provider.create
      end

      it 'sets ensure to :present' do
        provider.create
        expect(provider.ensure).to eq(:present)
      end

      it 'sets mlag_id to the resource value' do
        provider.create
        expect(provider.mlag_id).to eq(provider.resource[:mlag_id])
      end
    end

    describe '#destroy' do
      before :each do
        allow(eapi).to receive(:remove_interface)
        allow(eapi).to receive(:add_interface)
        allow(eapi).to receive(:set_mlag_id)
      end

      it "calls Mlag#delete('Port-Channel1')" do
        expect(eapi).to receive(:remove_interface).with('Port-Channel1')
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
            .to eq(name: 'Port-Channel1', ensure: :absent)
        end
      end
    end

    describe '#mlag_id=(val)' do
      before :each do
        allow(provider.eapi.Mlag).to receive(:set_mlag_id)
          .with('Port-Channel1', value: '3')
      end

      it "calls Mlag#set_mlag_id='3')" do
        expect(eapi).to receive(:set_mlag_id)
          .with('Port-Channel1', value: '3')
        provider.mlag_id = '3'
      end

      it 'updates the mlag_id property in the provider' do
        expect(provider.mlag_id).not_to eq '3'
        provider.mlag_id = '3'
        expect(provider.mlag_id).to eq '3'
      end
    end
  end
end
