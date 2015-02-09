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

  let(:api) { double('mlag') }

  def mlag
    mlag = Fixtures[:mlag]
    return mlag if mlag
    file = get_fixture('mlag.json')
    Fixtures[:mlag] = JSON.load(File.read(file))
  end

  before :each do
    allow(described_class.node).to receive(:api).with('mlag').and_return(api)
    allow(provider.node).to receive(:api).with('mlag').and_return(api)
  end

  context 'class methods' do

    before { allow(api).to receive(:get).and_return(mlag) }

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
        subject { described_class.instances.find { |p| p.name == 'settings' } }

        include_examples 'provider resource methods',
                         name: 'settings',
                         domain_id: 'MLAG-Domain',
                         local_interface: 'Port-Channel1',
                         peer_address: '1.1.1.1',
                         peer_link: 'Vlan4094',
                         enable: :true
      end
    end

    describe '.prefetch' do
      let :resources do
        {
          'settings' => Puppet::Type.type(:eos_mlag).new(name: 'settings'),
          'alternative' => Puppet::Type.type(:eos_mlag).new(name: 'alternative')
        }
      end

      subject { described_class.prefetch(resources) }

      it 'resource providers are absent prior to calling .prefetch' do
        resources.values.each do |rsrc|
          expect(rsrc.provider.domain_id).to eq(:absent)
          expect(rsrc.provider.local_interface).to eq(:absent)
          expect(rsrc.provider.peer_address).to eq(:absent)
          expect(rsrc.provider.peer_link).to eq(:absent)
          expect(rsrc.provider.enable).to eq(:absent)
        end
      end

      it 'sets the provider instance of the managed resource' do
        subject
        expect(resources['settings'].provider.name).to eq 'settings'
        expect(resources['settings'].provider.exists?).to be_truthy
        expect(resources['settings'].provider.domain_id).to eq 'MLAG-Domain'
        expect(resources['settings'].provider.local_interface).to eq 'Port-Channel1'
        expect(resources['settings'].provider.peer_address).to eq '1.1.1.1'
        expect(resources['settings'].provider.peer_link).to eq 'Vlan4094'
        expect(resources['settings'].provider.enable).to eq :true
      end

      it 'does not set the provider instance of the unmanaged resource' do
        subject
        expect(resources['alternative'].provider.name).to eq 'alternative'
        expect(resources['alternative'].provider.exists?).to be_falsy
        expect(resources['alternative'].provider.domain_id).to eq :absent
        expect(resources['alternative'].provider.local_interface).to eq :absent
        expect(resources['alternative'].provider.peer_address).to eq :absent
        expect(resources['alternative'].provider.peer_link).to eq :absent
        expect(resources['alternative'].provider.enable).to eq :absent
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
          allow(api).to receive(:get).and_return(mlag)
          described_class.instances.first
        end
        it { is_expected.to be_truthy }
      end
    end

    describe '#local_interface=(val)' do
      it 'updates the local_interface with Loopback1' do
        expect(api).to receive(:set_local_interface).with(value: 'Loopback1')
        provider.local_interface = 'Loopback1'
        expect(provider.local_interface).to eq('Loopback1')
      end
    end

    describe '#domain_id=(val)' do
      it 'updates the domain_id with value "foo"' do
        expect(api).to receive(:set_domain_id).with(value: 'foo')
        provider.domain_id = 'foo'
        expect(provider.domain_id).to eq('foo')
      end
    end

    describe '#peer_address=(val)' do
      it 'updates the peer_address with value "2.2.2.2"' do
        expect(api).to receive(:set_peer_address).with(value: '2.2.2.2')
        provider.peer_address = '2.2.2.2'
        expect(provider.peer_address).to eq('2.2.2.2')
      end
    end


    describe '#peer_link=(val)' do
      it 'updates the peer_link with value "Vlan1234"' do
        expect(api).to receive(:set_peer_link).with(value: 'Vlan1234')
        provider.peer_link = 'Vlan1234'
        expect(provider.peer_link).to eq('Vlan1234')
      end
    end

    describe '#enable=(val)' do
      it 'updates enable with value :true' do
        expect(api).to receive(:set_shutdown).with(value: false)
        provider.enable = :true
        expect(provider.enable).to eq(:true)
      end

      it 'updates enable with the value :false' do
        expect(api).to receive(:set_shutdown).with(value: true)
        provider.enable = :false
        expect(provider.enable).to eq(:false)
      end
    end
  end
end
