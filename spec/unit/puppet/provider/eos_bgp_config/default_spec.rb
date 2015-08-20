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

describe Puppet::Type.type(:eos_bgp_config).provider(:eos) do
  # Puppet RAL memoized methods
  let(:resource) do
    resource_hash = {
      name: '64600',
      bgp_as: '64600',
      router_id: '192.168.254.1',
      enable: true,
      ensure: :present,
      provider: described_class.name
    }
    Puppet::Type.type(:eos_bgp_config).new(resource_hash)
  end

  let(:provider) { resource.provider }

  let(:api) { double('bgp_config') }

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

      it 'has one entry' do
        expect(subject.size).to eq(1)
      end

      it 'has an instance 64600' do
        instance = subject.find { |p| p.bgp_as == '64600' }
        expect(instance).to be_a described_class
      end

      context 'eos_bgp_config { 64600 }' do
        subject { described_class.instances.find { |p| p.bgp_as == '64600' } }

        include_examples 'provider resource methods',
                         bgp_as: '64600',
                         enable: :true,
                         router_id: '192.168.254.1'
      end
    end

    describe '.prefetch' do
      let :resources do
        {
          '64600' => Puppet::Type.type(:eos_bgp_config).new(bgp_as: '64600'),
          '64601' => Puppet::Type.type(:eos_bgp_config).new(bgp_as: '64601')
        }
      end

      subject { described_class.prefetch(resources) }

      it 'resource providers are absent prior to calling .prefetch' do
        resources.values.each do |rsrc|
          expect(rsrc.provider.enable).to eq(:absent)
          expect(rsrc.provider.router_id).to eq(:absent)
        end
      end

      it 'sets the provider instance of the managed resource 64600' do
        subject
        expect(resources['64600'].provider.bgp_as).to eq('64600')
        expect(resources['64600'].provider.enable).to eq(:true)
        expect(resources['64600'].provider.router_id).to eq('192.168.254.1')
      end

      it 'does not set the provider instance of the unmanaged resource' do
        subject
        expect(resources['64601'].provider.enable).to eq(:absent)
        expect(resources['64601'].provider.router_id).to eq(:absent)
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
          allow(api).to receive(:get).and_return(bgp_config)
          described_class.instances.first
        end
        it { is_expected.to be_truthy }
      end
    end
  end

  context 'resource (instance) methods' do
    before do
      expect(api).to receive(:create).with(resource[:name])
      provider.create
    end

    describe '#create' do
      it 'sets ensure on the resource' do
        expect(provider.ensure).to eq(:present)
      end
    end

    describe '#enable=(value)' do
      it 'sets enable on the resource' do
        expect(api).to receive(:set_shutdown).with(enable: true)
        provider.enable = :true
        expect(provider.enable).to eq(:true)
      end
    end

    describe '#router_id=(value)' do
      it 'sets router_id on the resource' do
        expect(api).to receive(:set_router_id).with(value: '1.2.3.4')
        provider.router_id = '1.2.3.4'
        expect(provider.router_id).to eq('1.2.3.4')
      end
    end

    describe '#destroy' do
      it 'sets ensure to :absent' do
        resource[:ensure] = :absent
        expect(api).to receive(:delete)
        provider.destroy
        expect(provider.ensure).to eq(:absent)
      end
    end
  end
end
