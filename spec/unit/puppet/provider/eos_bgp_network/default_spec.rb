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

describe Puppet::Type.type(:eos_bgp_network).provider(:eos) do
  # Puppet RAL memoized methods
  let(:resource) do
    resource_hash = {
      name: '192.168.254.1/32',
      ensure: :present,
      provider: described_class.name
    }
    Puppet::Type.type(:eos_bgp_network).new(resource_hash)
  end

  let(:provider) { resource.provider }

  let(:api) { double('bgp_network') }

  def bgp_config
    bgp_config = Fixtures[:bgp_config]
    return bgp_config if bgp_config
    fixture('bgp_config')
  end

  before :each do
    allow(described_class.node).to receive(:api).with('bgp').and_return(api)
    allow(provider.node).to receive(:api).with('bgp').and_return(api)
  end

  context 'class methods' do
    before { allow(api).to receive(:get).and_return(bgp_config) }

    describe '.instances' do
      subject { described_class.instances }

      it { is_expected.to be_an Array }

      it 'has three entries' do
        expect(subject.size).to eq(3)
      end

      it 'has an instance 192.168.254.1/32' do
        instance = subject.find { |p| p.name == '192.168.254.1/32' }
        expect(instance).to be_a described_class
      end

      context 'eos_bgp_network { 192.168.254.1/32 }' do
        subject do
          described_class.instances.find { |p| p.name == '192.168.254.1/32' }
        end

        include_examples 'provider resource methods',
                         name: '192.168.254.1/32'
      end
    end

    describe '.prefetch' do
      let :resources do
        {
          '192.168.254.1/32' => Puppet::Type.type(:eos_bgp_network)
            .new(name: '192.168.254.1/32'),
          '192.168.254.1/31' => Puppet::Type.type(:eos_bgp_network)
            .new(name: '192.168.254.1/31')
        }
      end

      subject { described_class.prefetch(resources) }

      it 'resource providers are absent prior to calling .prefetch' do
        resources.values.each do |rsrc|
          expect(rsrc.provider.route_map).to eq(:absent)
        end
      end

      it 'sets provider instance of the managed resource 192.168.254.1/32' do
        subject
        expect(resources['192.168.254.1/32'].provider.name)
          .to eq('192.168.254.1/32')
        expect(resources['192.168.254.1/32'].provider.route_map).to eq(:absent)
      end

      it 'does not set the provider instance of the unmanaged resource' do
        subject
        expect(resources['192.168.254.1/31'].provider.route_map).to eq(:absent)
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
          allow(api).to receive(:get).and_return(bgp_config)
          described_class.instances.first
        end
        it { is_expected.to be_truthy }
      end
    end

    describe '#create' do
      it 'sets ensure on the resource' do
        expect(api).to receive(:add_network).with('192.168.254.1', 32, nil)
        provider.create
        provider.flush
        expect(provider.ensure).to eq(:present)
      end
    end

    describe '#route_map=(value)' do
      it 'sets route_map on the resource' do
        expect(api).to receive(:add_network).with('192.168.254.1', 32, 'rmap')
        provider.create
        provider.route_map = 'rmap'
        provider.flush
        expect(provider.route_map).to eq('rmap')
      end
    end

    describe '#destroy' do
      it 'sets ensure to :absent' do
        resource[:ensure] = :absent
        expect(api).to receive(:remove_network).with('192.168.254.1', 32, nil)
        provider.destroy
        provider.flush
        expect(provider.ensure).to eq(:absent)
      end
    end
  end
end
