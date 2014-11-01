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
      name: 'Port-Channel1',
      lacp_mode: :active,
      members: %w(Ethernet1 Ethernet2),
      lacp_fallback: :static,
      lacp_timeout: 100,
      provider: described_class.name
    }
    Puppet::Type.type(:eos_portchannel).new(resource_hash)
  end

  let(:provider) { resource.provider }

  def portchannels
    portchannels = Fixtures[:portchannels]
    return portchannels if portchannels
    file = File.join(File.dirname(__FILE__), 'fixtures/portchannels.json')
    Fixtures[:portchannels] = JSON.load(File.read(file))
  end

  before :each do
    allow_message_expectations_on_nil
    allow(described_class).to receive(:eapi)
    allow(described_class.eapi).to receive(:Portchannel)
    allow(described_class.eapi.Portchannel).to receive(:getall)
      .and_return(portchannels)
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

      context "eos_portchannel { 'Port-Channel1': }" do
        subject do
          described_class.instances.find do |p|
            p.name == 'Port-Channel1'
          end
        end

        include_examples 'provider resource methods',
                         ensure: :present,
                         name: 'Port-Channel1',
                         lacp_mode: :active,
                         members: %w(Ethernet1 Ethernet2),
                         lacp_fallback: :static,
                         lacp_timeout: 100
      end

      context "eos_portchannel { 'Port-Channel2': }" do
        subject do
          described_class.instances.find do |p|
            p.name == 'Port-Channel2'
          end
        end

        include_examples 'provider resource methods',
                         ensure: :present,
                         name: 'Port-Channel2',
                         lacp_mode: :passive,
                         members: %w(Ethernet3 Ethernet4),
                         lacp_fallback: :individual,
                         lacp_timeout: 100
      end
    end

    describe '.prefetch' do
      let :resources do
        {
          'Port-Channel1' => Puppet::Type.type(:eos_portchannel)
            .new(name: 'Port-Channel1'),
          'Port-Channel5' => Puppet::Type.type(:eos_portchannel)
            .new(name: 'Port-Channel5')
        }
      end

      subject { described_class.prefetch(resources) }

      it 'resource providers are absent prior to calling .prefetch' do
        resources.values.each do |rsrc|
          expect(rsrc.provider.lacp_mode).to eq(:absent)
        end
      end

      it 'sets the provider instance of the managed resource' do
        subject
        expect(resources['Port-Channel1'].provider.name).to eq 'Port-Channel1'
        expect(resources['Port-Channel1'].provider.exists?).to be_truthy
      end

      it 'does not set the provider instance of the unmanaged resource' do
        subject
        expect(resources['Port-Channel5'].provider.name).to eq('Port-Channel5')
        expect(resources['Port-Channel5'].provider.exists?).to be_falsey
      end
    end
  end

  context 'resource (instance) methods' do

    let(:eapi) { double }

    before do
      allow(provider).to receive(:eapi)
      allow(provider.eapi).to receive(:Portchannel).and_return(eapi)
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
        allow(eapi).to receive(:set_lacp_mode)
        allow(eapi).to receive(:set_lacp_fallback)
        allow(eapi).to receive(:set_lacp_timeout)
        allow(eapi).to receive(:set_members)
      end

      it "calls Portchannel#create('Port-Channel1')" do
        expect(eapi).to receive(:create).with('Port-Channel1')
        provider.create
      end

      it 'sets ensure to :present' do
        provider.create
        expect(provider.ensure).to eq(:present)
      end

      it 'sets lacp_mode to the resource value' do
        provider.create
        expect(provider.lacp_mode).to eq provider.resource[:lacp_mode]
      end

      it 'sets members to the resource value' do
        provider.create
        value = provider.resource[:members]
        expect(provider.members).to eq value
      end

      it 'sets lacp_fallback to the resource value' do
        provider.create
        value = provider.resource[:lacp_fallback]
        expect(provider.lacp_fallback).to eq value
      end

      it 'sets lacp_timeout to the resource value' do
        provider.create
        value = provider.resource[:lacp_timeout]
        expect(provider.lacp_timeout).to eq value
      end
    end

    describe '#destroy' do
      before :each do
        allow(eapi).to receive(:delete)
        allow(eapi).to receive(:create)
        allow(eapi).to receive(:set_lacp_mode)
        allow(eapi).to receive(:set_lacp_fallback)
        allow(eapi).to receive(:set_lacp_timeout)
        allow(eapi).to receive(:set_members)
      end

      it "calls Portchannel#delete('Port-Channel1')" do
        expect(eapi).to receive(:delete).with('Port-Channel1')
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

    describe '#lacp_mode=(val)' do
      before :each do
        allow(provider.eapi.Portchannel).to receive(:set_lacp_mode)
      end

      %w(active passive on).each do |value|
        let(:value) { value }
        it "class Portchannel#set_lacp_mode(#{value})" do
          expect(eapi).to receive(:set_lacp_mode)
            .with('Port-Channel1', value: value)
          provider.lacp_mode = value
        end

        it 'updates the lacp_mode property in the provider' do
          expect(provider.lacp_mode).not_to eq value
          provider.lacp_mode = value
          expect(provider.lacp_mode).to eq value
        end
      end
    end

    describe '#members=(val)' do
      before :each do
        allow(provider.eapi.Portchannel).to receive(:set_members)
      end

      it 'handles both add and remove member operations' do
        expect(eapi).to receive(:set_members)
          .with('Port-Channel1', %w(Ethernet1 Ethernet3))
        provider.members = %w(Ethernet1 Ethernet3)
      end
    end

    describe '#lacp_fallback=(val)' do
      before :each do
        allow(provider.eapi.Portchannel).to receive(:set_lacp_fallback)
      end

      %w(static individual).each do |value|
        let(:value) { value }
        it "calls Portchannel#set_lacp_fallback=#{value}" do
          expect(eapi).to receive(:set_lacp_fallback)
            .with('Port-Channel1', value: value)
          provider.lacp_fallback = value
        end

        it 'updates the lacp_fallback property in the provider' do
          expect(provider.lacp_fallback).not_to eq value
          provider.lacp_fallback = value
          expect(provider.lacp_fallback).to eq value
        end
      end
    end

    describe '#lacp_timeout=(val)' do
      before :each do
        allow(provider.eapi.Portchannel).to receive(:set_lacp_timeout)
      end

      it 'class Portchannel#set_lacp_timeout=100' do
        expect(eapi).to receive(:set_lacp_timeout)
          .with('Port-Channel1', value: 900)
        provider.lacp_timeout = 900
      end

      it 'updates the lacp_timeout property in the provider' do
        expect(provider.lacp_timeout).not_to eq 900
        provider.lacp_timeout = 900
        expect(provider.lacp_timeout).to eq 900
      end
    end
  end
end
