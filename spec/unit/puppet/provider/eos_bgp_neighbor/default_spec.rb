#
# Copyright (c) 2015, Arista Networks, Inc.
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

describe Puppet::Type.type(:eos_bgp_neighbor).provider(:eos) do
  # Puppet RAL memoized methods
  let(:resource) do
    resource_hash = {
      name: 'Edge',
      enable: :true,
      send_community: :enable,
      description: 'a description',
      next_hop_self: :disable,
      route_map_in: 'map in',
      route_map_out: 'map out',
      ensure: :present,
      provider: described_class.name
    }
    Puppet::Type.type(:eos_bgp_neighbor).new(resource_hash)
  end

  let(:provider) { resource.provider }

  let(:api) { double('bgp_config') }
  let(:neighbors) { double('bgp.neighbors') }

  def bgp_config
    bgp_config = Fixtures[:bgp_config]
    return bgp_config if bgp_config
    fixture('bgp_config')
  end

  before :each do
    allow(described_class.node).to receive(:api).with('bgp').and_return(api)
    allow(api).to receive(:neighbors).and_return(neighbors)
  end

  context 'class methods' do
    before do
      allow(neighbors).to receive(:getall).and_return(bgp_config[:neighbors])
    end

    describe '.instances' do
      subject { described_class.instances }

      it { is_expected.to be_an Array }

      it 'has three entries' do
        expect(subject.size).to eq(3)
      end

      %w(Edge 192.168.255.1 192.168.255.3).each do |name|
        it "has an instance for neighbor #{name}" do
          instance = subject.find { |p| p.name == name }
          expect(instance).to be_a described_class
        end
      end
      it 'has an instance Edge' do
        instance = subject.find { |p| p.name == 'Edge' }
        expect(instance).to be_a described_class
      end

      context 'eos_bgp_neighbor { Edge }' do
        subject { described_class.instances.find { |p| p.name == 'Edge' } }

        include_examples 'provider resource methods',
                         name: 'Edge',
                         send_community: :enable,
                         enable: :true,
                         description: 'a description',
                         next_hop_self: :disable,
                         route_map_in: 'map in',
                         route_map_out: 'map out'
      end
    end

    describe '.prefetch' do
      let :resources do
        {
          'Edge' => Puppet::Type.type(:eos_bgp_neighbor).new(name: 'Edge'),
          'TOR' => Puppet::Type.type(:eos_bgp_neighbor).new(name: 'TOR')
        }
      end

      subject { described_class.prefetch(resources) }

      it 'resource providers are absent prior to calling .prefetch' do
        resources.values.each do |rsrc|
          expect(rsrc.provider.peer_group).to eq(:absent)
          expect(rsrc.provider.remote_as).to eq(:absent)
          expect(rsrc.provider.send_community).to eq(:absent)
          expect(rsrc.provider.next_hop_self).to eq(:absent)
          expect(rsrc.provider.route_map_in).to eq(:absent)
          expect(rsrc.provider.route_map_out).to eq(:absent)
          expect(rsrc.provider.description).to eq(:absent)
          expect(rsrc.provider.enable).to eq(:absent)
        end
      end

      it 'sets the provider instance of the managed resource Edge' do
        subject
        expect(resources['Edge'].provider.name).to eq('Edge')
        expect(resources['Edge'].provider.peer_group).to eq(:absent)
        expect(resources['Edge'].provider.remote_as).to eq(:absent)
        expect(resources['Edge'].provider.send_community).to eq(:enable)
        expect(resources['Edge'].provider.next_hop_self).to eq(:disable)
        expect(resources['Edge'].provider.route_map_in).to eq('map in')
        expect(resources['Edge'].provider.route_map_out).to eq('map out')
        expect(resources['Edge'].provider.description).to eq('a description')
        expect(resources['Edge'].provider.enable).to eq(:true)
      end

      it 'does not set the provider instance of the unmanaged resource' do
        subject
        expect(resources['TOR'].provider.name).to eq('TOR')
        expect(resources['TOR'].provider.peer_group).to eq(:absent)
        expect(resources['TOR'].provider.remote_as).to eq(:absent)
        expect(resources['TOR'].provider.send_community).to eq(:absent)
        expect(resources['TOR'].provider.next_hop_self).to eq(:absent)
        expect(resources['TOR'].provider.route_map_in).to eq(:absent)
        expect(resources['TOR'].provider.route_map_out).to eq(:absent)
        expect(resources['TOR'].provider.description).to eq(:absent)
        expect(resources['TOR'].provider.enable).to eq(:absent)
      end
    end
  end

  context 'resource exists method' do
    describe '#exists?' do
      subject { provider.exists? }

      context 'when the resource does not exist on the system' do
        it { is_expected.to be_falsey }
      end

      context 'when the resource exists on the system' do
        let(:provider) do
          allow(neighbors).to receive(:getall)
            .and_return(bgp_config[:neighbors])
          described_class.instances.first
        end
        it { is_expected.to be_truthy }
      end
    end
  end

  context 'resource (instance) methods' do
    before do
      allow(provider.node).to receive(:api).with('bgp').and_return(api)
      allow(api).to receive(:neighbors).and_return(neighbors)
      expect(neighbors).to receive(:create).with('Edge')
      expect(neighbors).to receive(:set_send_community).with('Edge',
                                                             enable: true)
      expect(neighbors).to receive(:set_next_hop_self).with('Edge',
                                                            enable: false)
      expect(neighbors).to receive(:set_route_map_in).with('Edge',
                                                           value: 'map in')
      expect(neighbors).to receive(:set_route_map_out).with('Edge',
                                                            value: 'map out')
      expect(neighbors).to receive(:set_description)
        .with('Edge', value: 'a description')
      expect(neighbors).to receive(:set_shutdown).once
      provider.create
    end

    describe '#create' do
      it 'sets ensure on the resource' do
        expect(provider.ensure).to eq(:present)
      end
    end

    describe '#peer_group=(value)' do
      it 'sets peer_group on the resource' do
        expect(neighbors).to receive(:set_peer_group).with('Edge', value: 'TOR')
        provider.peer_group = 'TOR'
        expect(provider.peer_group).to eq('TOR')
      end
    end

    describe '#remote_as=(value)' do
      it 'sets remote_as on the resource' do
        expect(neighbors).to receive(:set_remote_as).with('Edge', value: '1000')
        provider.remote_as = '1000'
        expect(provider.remote_as).to eq('1000')
      end
    end

    describe '#send_community=(value)' do
      it 'sets send_community on the resource' do
        expect(neighbors).to receive(:set_send_community).with('Edge',
                                                               enable: true)
        provider.send_community = :enable
        expect(provider.send_community).to eq(:enable)
      end
    end

    describe '#next_hop_self=(value)' do
      it 'sets next_hop_self on the resource' do
        expect(neighbors).to receive(:set_next_hop_self).with('Edge',
                                                              enable: true)
        provider.next_hop_self = :enable
        expect(provider.next_hop_self).to eq(:enable)
      end
    end

    describe '#route_map_in=(value)' do
      it 'sets route_map_in on the resource' do
        expect(neighbors).to receive(:set_route_map_in).with('Edge',
                                                             value: 'in_map')
        provider.route_map_in = 'in_map'
        expect(provider.route_map_in).to eq('in_map')
      end
    end

    describe '#route_map_out=(value)' do
      it 'sets route_map_out on the resource' do
        expect(neighbors).to receive(:set_route_map_out)
          .with('Edge', value: 'out_map')
        provider.route_map_out = 'out_map'
        expect(provider.route_map_out).to eq('out_map')
      end
    end

    describe '#description=(value)' do
      it 'sets description on the resource' do
        expect(neighbors).to receive(:set_description)
          .with('Edge', value: 'a description')
        provider.description = 'a description'
        expect(provider.description).to eq('a description')
      end
    end

    describe '#enable=(value)' do
      it 'sets enable on the resource' do
        expect(neighbors).to receive(:set_shutdown).once
        provider.enable = :true
        expect(provider.enable).to eq(:true)
      end
    end

    describe '#destroy' do
      it 'sets ensure to :absent' do
        resource[:ensure] = :absent
        expect(neighbors).to receive(:delete)
        provider.destroy
        expect(provider.ensure).to eq(:absent)
      end
    end
  end
end
