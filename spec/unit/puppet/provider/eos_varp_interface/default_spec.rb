#
# Copyright (c) 2015-2016, Arista Networks, Inc.
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

describe Puppet::Type.type(:eos_varp_interface).provider(:eos) do
  # Puppet RAL memoized methods
  let(:resource) do
    resource_hash = {
      ensure: :present,
      name: 'Vlan99',
      shared_ip: ['1.1.1.1', '2.2.2.2'],
      provider: described_class.name
    }
    Puppet::Type.type(:eos_varp_interface).new(resource_hash)
  end

  let(:provider) { resource.provider }

  let(:api) { double('varp') }
  let(:interfaces) { double('varp.interfaces') }

  def varp
    varp = Fixtures[:varp]
    return varp if varp
    fixture('varp', dir: File.dirname(__FILE__))
  end

  before :each do
    allow(described_class.node).to receive(:api).with('varp')
      .and_return(api)
    allow(provider.node).to receive(:api).with('varp')
      .and_return(api)
    allow(api).to receive(:interfaces).and_return(interfaces)
  end

  context 'class methods' do
    before { allow(api).to receive(:get).and_return(varp) }

    describe '.instances' do
      subject { described_class.instances }

      it { is_expected.to be_an Array }

      it 'has one entry' do
        expect(subject.size).to eq(1)
      end

      it 'has an instance Vlan99' do
        instance = subject.find { |p| p.name == 'Vlan99' }
        expect(instance).to be_a described_class
      end

      context 'eos_varp_interface { Vlan99 }' do
        subject { described_class.instances.find { |p| p.name == 'Vlan99' } }

        include_examples 'provider resource methods',
                         ensure: :present,
                         name: 'Vlan99',
                         shared_ip: ['1.1.1.1', '2.2.2.2']
      end
    end

    describe '.prefetch' do
      let :resources do
        {
          'Vlan99' => Puppet::Type.type(:eos_varp_interface)
                                  .new(name: 'Vlan99'),
          'Vlan100' => Puppet::Type.type(:eos_varp_interface)
                                   .new(name: 'Vlan100')
        }
      end

      subject { described_class.prefetch(resources) }

      it 'resource providers are absent prior to calling .prefetch' do
        resources.values.each do |rsrc|
          expect(rsrc.provider.shared_ip).to eq(:absent)
        end
      end

      it 'sets the provider instance of the managed resource Vlan99' do
        subject
        expect(resources['Vlan99'].provider.name).to eq('Vlan99')
        expect(resources['Vlan99'].provider.shared_ip)
          .to eq(['1.1.1.1', '2.2.2.2'])
      end

      it 'does not set the provider instance of the unmanaged resource' do
        subject
        expect(resources['Vlan100'].provider.shared_ip).to eq(:absent)
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
          allow(api).to receive(:get).and_return(varp)
          described_class.instances.first
        end
        it { is_expected.to be_truthy }
      end
    end

    describe '#create' do
      let(:name) { resource[:name] }

      it 'sets ensure to :present' do
        expect(interfaces).to receive(:set_addresses)
          .with(name, value: ['1.1.1.1', '2.2.2.2'])
        provider.create
        provider.shared_ip = ['1.1.1.1', '2.2.2.2']
        provider.flush
        expect(provider.ensure).to eq(:present)
      end

      context 'when addresses are blank' do
        it 'sets ensure to :present' do
          resource[:ensure] = :present
          resource.delete(:shared_ip)
          expect { provider.create }.to raise_error
        end
      end
    end

    describe '#destroy' do
      let(:name) { resource[:name] }

      it 'sets ensure to :absent' do
        expect(interfaces).to receive(:set_addresses).with(name, enable: false)
        resource[:ensure] = :absent
        provider.destroy
        provider.flush
        expect(provider.ensure).to eq(:absent)
      end
    end

    describe '#shared_ip=(val)' do
      let(:name) { resource[:name] }

      it 'sets shared_ip to value ["1.1.1.1", "2.2.2.2"]' do
        expect(interfaces).to receive(:set_addresses)
          .with(name, value: ['1.1.1.1', '2.2.2.2'])
        provider.create
        provider.shared_ip = ['1.1.1.1', '2.2.2.2']
        provider.flush
        expect(provider.shared_ip).to eq(['1.1.1.1', '2.2.2.2'])
      end
    end
  end
end
