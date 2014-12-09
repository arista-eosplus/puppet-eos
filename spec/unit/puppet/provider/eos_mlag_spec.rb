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

describe Puppet::Type.type(:eos_mlag).provider(:eos) do

  # Puppet RAL memoized methods
  let(:resource) do
    resource_hash = {
      name: 'settings',
      domain_id: 'MLAG-Domain',
      local_interface: 'Port-Channel1',
      peer_address: '10.1.1.1',
      peer_link: 'Vlan4094',
      enable: :true,
      provider: described_class.name
    }
    Puppet::Type.type(:eos_mlag).new(resource_hash)
  end

  let(:provider) { resource.provider }

  def mlag
    mlag = Fixtures[:mlag]
    return mlag if mlag
    file = File.join(File.dirname(__FILE__), 'fixtures/mlag.json')
    Fixtures[:mlag] = JSON.load(File.read(file))
  end

  # Stub the Api method class to obtain all vlans.
  before :each do
    allow_message_expectations_on_nil
    allow(described_class).to receive(:eapi)
    allow(described_class.eapi).to receive(:Mlag)
    allow(described_class.eapi.Mlag).to receive(:get)
      .and_return(mlag)
  end

  context 'class methods' do

    describe '.instances' do
      subject { described_class.instances }

      it { is_expected.to be_an Array }

      it 'has only one entry' do
        expect(subject.size).to eq 1
      end

      it 'has an instance for settings' do
        instance = subject.find { |p| p.name == 'settings' }
        expect(instance).to be_a described_class
      end

      context "eos_mlag { 'settings': }" do
        subject do
          described_class.instances.find do |p|
            p.name == 'settings'
          end
        end

        include_examples 'provider resource methods',
                         name: 'settings',
                         domain_id: 'MLAG-Domain',
                         local_interface: 'Port-Channel1',
                         peer_address: '10.1.1.1',
                         peer_link: 'Vlan4094',
                         enable: :true
      end
    end

    describe '.prefetch' do
      let :resources do
        {
          'settings' => Puppet::Type.type(:eos_mlag).new(name: 'settings')
        }
      end

      subject { described_class.prefetch(resources) }

      it 'resource providers are absent prior to calling .prefetch' do
        resources.values.each do |rsrc|
          expect(rsrc.provider.domain_id).to eq(:absent)
          expect(rsrc.provider.local_interface).to eq(:absent)
          expect(rsrc.provider.peer_address).to eq(:absent)
          expect(rsrc.provider.peer_link).to eq(:absent)
        end
      end

      it 'sets the provider instance of the managed resource' do
        subject
        expect(resources['settings'].provider.name).to eq 'settings'
        expect(resources['settings'].provider.exists?).to be_truthy
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

    describe '#local_interface=(val)' do
      before :each do
        allow(eapi).to receive(:set_local_interface)
      end

      it "calls Mlag#set_local_interface='Port-Channel1'" do
        expect(eapi).to receive(:set_local_interface)
          .with(value: 'Port-Channel1')
        provider.local_interface = 'Port-Channel1'
      end

      it 'updates the local_interface property in the provider' do
        expect(provider.local_interface).not_to eq 'Port-Channel1'
        provider.local_interface = 'Port-Channel1'
        expect(provider.local_interface).to eq 'Port-Channel1'
      end
    end

    describe '#peer_link=(val)' do
      before :each do
        allow(eapi).to receive(:set_peer_link)
      end

      it "calls Mlag#set_peer_link='Vlan4094'" do
        expect(eapi).to receive(:set_peer_link)
          .with(value: 'Vlan4094')
        provider.peer_link = 'Vlan4094'
      end

      it 'updates the peer_link property in the provider' do
        expect(provider.peer_link).not_to eq 'Vlan4094'
        provider.peer_link = 'Vlan4094'
        expect(provider.peer_link).to eq 'Vlan4094'
      end
    end

    describe '#peer_address=(val)' do
      before :each do
        allow(eapi).to receive(:set_peer_address)
      end

      it "calls Mlag#set_peer_address='10.1.1.1'" do
        expect(eapi).to receive(:set_peer_address)
          .with(value: '10.1.1.1')
        provider.peer_address = '10.1.1.1'
      end

      it 'updates the peer_address property in the provider' do
        expect(provider.peer_address).not_to eq '10.1.1.1'
        provider.peer_address = '10.1.1.1'
        expect(provider.peer_address).to eq '10.1.1.1'
      end
    end

    describe '#enable=(val)' do
      before :each do
        allow(eapi).to receive(:set_shutdown)
      end

      %w(:true, :false).each do |value|
        let(:value) { value }
        it "calls Mlag#set_shutdown=#{value}" do
          expect(eapi).to receive(:set_shutdown)
            .with(value: !value)
          provider.enable = value
        end

        it 'updates the enable property in the provider' do
          expect(provider.enable).not_to eq value
          provider.enable = value
          expect(provider.enable).to eq value
        end
      end
    end
  end
end
