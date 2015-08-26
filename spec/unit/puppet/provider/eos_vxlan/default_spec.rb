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

describe Puppet::Type.type(:eos_vxlan).provider(:eos) do
  # Puppet RAL memoized methods
  let(:resource) do
    resource_hash = {
      name: 'Vxlan1',
      description: 'test interface',
      enable: :true,
      source_interface: 'Loopback0',
      multicast_group: '239.10.10.10',
      udp_port: 4789,
      provider: described_class.name
    }
    Puppet::Type.type(:eos_vxlan).new(resource_hash)
  end

  let(:provider) { resource.provider }

  let(:api) { double('interfaces') }

  def vxlan
    vxlan = Fixtures[:vxlan]
    return vxlan if vxlan
    fixture('vxlan', dir: File.dirname(__FILE__))
  end

  before :each do
    allow(described_class.node).to receive(:api).with('interfaces')
      .and_return(api)

    allow(provider.node).to receive(:api).with('interfaces').and_return(api)
  end

  context 'class methods' do
    before { allow(api).to receive(:getall).and_return(vxlan) }

    describe '.instances' do
      subject { described_class.instances }

      it { is_expected.to be_an Array }

      it 'has one entry' do
        expect(subject.size).to eq(1)
      end

      it 'has an instance for interface Vxlan1' do
        instance = subject.find { |p| p.name == 'Vxlan1' }
        expect(instance).to be_a described_class
      end

      context 'eos_vxlan { Vxlan1: }' do
        subject { described_class.instances.find { |p| p.name == 'Vxlan1' } }

        include_examples 'provider resource methods',
                         name: 'Vxlan1',
                         description: 'test interface',
                         enable: :true,
                         source_interface: 'Loopback0',
                         multicast_group: '239.10.10.10',
                         udp_port: 4789
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
          expect(rsrc.provider.description).to eq(:absent)
          expect(rsrc.provider.enable).to eq(:absent)
        end
      end

      it 'sets the provider instance of the managed resource' do
        subject
        expect(resources['Vxlan1'].provider.description).to eq('test interface')
        expect(resources['Vxlan1'].provider.enable).to eq :true
        expect(resources['Vxlan1'].provider.source_interface).to eq 'Loopback0'
        expect(resources['Vxlan1'].provider.multicast_group).to \
          eq '239.10.10.10'
      end

      it 'does not set the provider instance of the unmanaged resource' do
        subject
        expect(resources['Vxlan2'].provider.description).to eq :absent
        expect(resources['Vxlan2'].provider.enable).to eq :absent
        expect(resources['Vxlan2'].provider.source_interface).to eq :absent
        expect(resources['Vxlan2'].provider.multicast_group).to eq :absent
      end
    end
  end

  context 'resource (instance) methods' do
    describe '#create' do
      let(:name) { 'Vxlan1' }

      before do
        expect(api).to receive(:create).with(resource[:name])
        allow(api).to receive_messages(
          set_shutdown: true,
          set_description: true,
          set_source_interface: true,
          set_multicast_group: true,
          set_udp_port: true
        )
      end

      it 'sets enable on the resource' do
        provider.create
        expect(provider.enable).to be_truthy
      end

      it 'sets description on the resource' do
        provider.create
        expect(provider.description).to eq(resource[:description])
      end

      it 'sets source_interface on the resource' do
        provider.create
        expect(provider.source_interface).to eq(resource[:source_interface])
      end

      it 'sets multicast_group on the resource' do
        provider.create
        expect(provider.multicast_group).to eq(resource[:multicast_group])
      end

      it 'sets udp_port on the resource' do
        provider.create
        expect(provider.udp_port).to eq(resource[:udp_port])
      end
    end

    describe '#destroy' do
      it 'sets ensure to :absent' do
        expect(api).to receive(:delete).with(resource[:name])
        provider.destroy
      end
    end

    describe '#description=(value)' do
      it 'updates description in the provider' do
        expect(api).to receive(:set_description)
          .with(resource[:name], value: 'foo')
        provider.description = 'foo'
        expect(provider.description).to eq('foo')
      end
    end

    describe '#enable=(value)' do
      %w(true false).each do |val|
        let(:value) { !val }
        let(:name) { 'Vxlan1' }

        it 'updates enable in the provider' do
          expect(api).to receive(:set_shutdown).with(name, enable: !val)
          provider.enable = val
          expect(provider.enable).to eq(val)
        end
      end
    end

    describe '#source_interface=(value)' do
      it 'updates source_interface in the provder' do
        expect(api).to receive(:set_source_interface)
          .with('Vxlan1', value: 'Loopback1')
        provider.source_interface = 'Loopback1'
        expect(provider.source_interface).to eq('Loopback1')
      end
    end

    describe '#multicast_group=(value)' do
      it 'updates multicast_group in the provder' do
        expect(api).to receive(:set_multicast_group)
          .with('Vxlan1', value: '239.11.11.11')
        provider.multicast_group = '239.11.11.11'
        expect(provider.multicast_group).to eq('239.11.11.11')
      end
    end

    describe '#udp_port=(value)' do
      it 'updates udp_port in the provider' do
        expect(api).to receive(:set_udp_port).with('Vxlan1', value: 1024)
        provider.udp_port = 1024
        expect(provider.udp_port).to eq(1024)
      end
    end
  end
end
