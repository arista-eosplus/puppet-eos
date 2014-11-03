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

describe Puppet::Type.type(:eos_snmp).provider(:eos) do

  # Puppet RAL memoized methods
  let(:resource) do
    resource_hash = {
      ensure: :present,
      name: 'configuration',
      contact: 'network operations',
      location: 'data center',
      provider: described_class.name
    }
    Puppet::Type.type(:eos_snmp).new(resource_hash)
  end

  let(:provider) { resource.provider }

  def snmp
    snmp = Fixtures[:snmp]
    return snmp if snmp
    file = File.join(File.dirname(__FILE__), 'fixtures/snmp.json')
    Fixtures[:snmp] = JSON.load(File.read(file))
  end

  # Stub the Api method class to obtain all vlans.
  before :each do
    allow_message_expectations_on_nil
    allow(described_class).to receive(:eapi)
    allow(described_class.eapi).to receive(:Snmp)
    allow(described_class.eapi.Snmp).to receive(:get)
      .and_return(snmp)
  end

  context 'class methods' do

    describe '.instances' do
      subject { described_class.instances }

      it { is_expected.to be_an Array }

      it 'has only one entry' do
        expect(subject.size).to eq 1
      end

      it 'has an instance for snmp configuration' do
        instance = subject.find { |p| p.name == 'configuration' }
        expect(instance).to be_a described_class
      end

      context "eos_snmp { 'configuration': }" do
        subject do
          described_class.instances.find do |p|
            p.name == 'configuration'
          end
        end

        include_examples 'provider resource methods',
                         ensure: :present,
                         name: 'configuration',
                         contact: 'network operations',
                         location: 'data center'
      end
    end

    describe '.prefetch' do
      let :resources do
        {
          'configuration' => Puppet::Type.type(:eos_snmp)
            .new(name: 'configuration'),
          'alternative' => Puppet::Type.type(:eos_snmp)
            .new(name: 'alternative')
        }
      end

      subject { described_class.prefetch(resources) }

      it 'resource providers are absent prior to calling .prefetch' do
        resources.values.each do |rsrc|
          expect(rsrc.provider.contact).to eq(:absent)
          expect(rsrc.provider.location).to eq(:absent)
        end
      end

      it 'sets the provider instance of the managed resource' do
        subject
        expect(resources['configuration'].provider.name).to eq 'configuration'
        expect(resources['configuration'].provider.exists?).to be_truthy
      end

      it 'does not set the provider instance of the unmanaged resource' do
        subject
        expect(resources['alternative'].provider.name).to eq('alternative')
        expect(resources['alternative'].provider.exists?).to be_falsey
      end
    end
  end

  context 'resource (instance) methods' do

    let(:eapi) { double }

    before do
      allow(provider).to receive(:eapi)
      allow(provider.eapi).to receive(:Snmp).and_return(eapi)
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
        allow(eapi).to receive(:set_contact)
        allow(eapi).to receive(:set_location)
      end

      it 'calls Snmp#create' do
        provider.create
      end

      it 'sets ensure to :present' do
        provider.create
        expect(provider.ensure).to eq(:present)
      end

      it 'sets contact to the resource value' do
        provider.create
        value = provider.resource[:contact]
        expect(provider.contact).to eq value
      end

      it 'sets location to the resource value' do
        provider.create
        value = provider.resource[:location]
        expect(provider.location).to eq value
      end
    end

    describe '#destroy' do
      before :each do
        allow(eapi).to receive(:delete)
        allow(eapi).to receive(:set_contact)
        allow(eapi).to receive(:set_location)
      end

      it 'calls Snmp#delete' do
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
            .to eq(name: 'configuration', ensure: :absent)
        end
      end
    end

    describe '#contact=(val)' do
      before :each do
        allow(eapi).to receive(:set_contact)
      end

      it "calls Snmp#set_contact='network operations'" do
        expect(eapi).to receive(:set_contact)
          .with(value: 'network operations')
        provider.contact = 'network operations'
      end

      it 'updates the contact property in the provider' do
        expect(provider.contact).not_to eq 'network operations'
        provider.contact = 'network operations'
        expect(provider.contact).to eq 'network operations'
      end
    end

    describe '#location=(val)' do
      before :each do
        allow(eapi).to receive(:set_location)
      end

      it "calls Snmp#set_location='data center'" do
        expect(eapi).to receive(:set_location)
          .with(value: 'data center')
        provider.location = 'data center'
      end

      it 'updates the location property in the provider' do
        expect(provider.location).not_to eq 'data center'
        provider.location = 'data center'
        expect(provider.location).to eq 'data center'
      end
    end
  end
end
