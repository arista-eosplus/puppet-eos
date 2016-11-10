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

describe Puppet::Type.type(:eos_staticroute).provider(:eos) do
  # Puppet RAL memoized methods
  let(:resource) do
    resource_hash = {
      ensure: :present,
      name: '192.0.3.0/24/192.0.3.1',
      route_name: 'Edge10',
      distance: 3,
      tag: 4,
      provider: described_class.name
    }
    Puppet::Type.type(:eos_staticroute).new(resource_hash)
  end

  let(:provider) { resource.provider }

  let(:api) { double('staticroutes') }

  def staticroutes
    staticroutes = Fixtures[:staticroutes]
    return staticroutes if staticroutes
    fixture('staticroute', dir: File.dirname(__FILE__))
  end

  before :each do
    allow(described_class.node).to receive(:api).with('staticroutes')
      .and_return(api)
    allow(provider.node).to receive(:api).with('staticroutes').and_return(api)
  end

  context 'class methods' do
    before { allow(api).to receive(:getall).and_return(staticroutes) }

    describe '.instances' do
      subject { described_class.instances }

      it { is_expected.to be_an Array }

      it 'has three entries' do
        expect(subject.size).to eq(3)
      end

      %w(1.2.3.4/32/Null0 192.0.3.0/24/192.0.3.1).each do |name|
        it "has an instance for interface #{name}" do
          instance = subject.find { |p| p.name == name }
          expect(instance).to be_a described_class
        end
      end

      context 'eos_staticroute { 1.2.3.4/32/Null0: }' do
        subject do
          described_class.instances.find { |p| p.name == '1.2.3.4/32/Null0' }
        end

        include_examples 'provider resource methods',
                         name: '1.2.3.4/32/Null0',
                         distance: '3',
                         route_name: 'Edge10'
      end
    end

    describe '.prefetch' do
      let :resources do
        {
          '1.2.3.4/32/Null0' => Puppet::Type.type(:eos_staticroute)
                                            .new(name: '1.2.3.4/32/Null0'),
          '192.0.3.0/24/192.0.3.1' => Puppet::Type.type(:eos_staticroute)
                                                  .new(name:
                                                       '192.0.3.0/24/
                                                       192.0.3.1'),
          '192.0.4.0/24/Ethernet1' => Puppet::Type.type(:eos_staticroute)
                                                  .new(name:
                                                       '192.0.4.0/24/Ethernet1')
        }
      end
      subject { described_class.prefetch(resources) }

      it 'resource providers are absent prior to calling .prefetch' do
        resources.values.each do |rsrc|
          expect(rsrc.provider.distance).to eq(:absent)
          expect(rsrc.provider.route_name).to eq(:absent)
          expect(rsrc.provider.tag).to eq(:absent)
        end
      end

      it 'sets the provider instance of the managed resource' do
        subject
        res = resources['1.2.3.4/32/Null0']
        expect(res.provider.distance).to eq('3')
        expect(res.provider.route_name).to eq('Edge10')
        expect(res.provider.tag).to eq('4')

        res = resources['192.0.3.0/24/192.0.3.1']
        expect(res.provider.distance).to eq('1')
        expect(res.provider.route_name).to eq('dummy2')
        expect(res.provider.tag).to eq('0')
      end

      it 'does not set the provider instance of the unmanaged resource' do
        subject
        res = resources['192.0.4.0/24/Ethernet1']
        expect(res.provider.distance).to eq :absent
        expect(res.provider.route_name).to eq :absent
        expect(res.provider.tag).to eq :absent
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
          allow(api).to receive(:getall).and_return(staticroutes)
          described_class.instances.first
        end
        it { is_expected.to be_truthy }
      end
    end

    describe '#create' do
      it 'sets ensure on the resource' do
        expect(api).to receive(:create).with('192.0.3.0/24', '192.0.3.1',
                                             distance: 3,
                                             name: 'Edge10',
                                             tag: 4)
        provider.create
        provider.flush
        expect(provider.ensure).to eq(:present)
      end
    end

    describe '#route_name' do
      it 'sets route_name to the resource value' do
        expect(api).to receive(:create).with('192.0.3.0/24', '192.0.3.1',
                                             distance: 3,
                                             name: 'Edge10',
                                             tag: 4)
        provider.create
        provider.flush
        expect(provider.route_name).to eq(provider.resource[:route_name])
      end
    end

    describe '#distance' do
      it 'sets distance to the resource value' do
        expect(api).to receive(:create).with('192.0.3.0/24', '192.0.3.1',
                                             distance: 3,
                                             name: 'Edge10',
                                             tag: 4)
        provider.create
        provider.flush
        expect(provider.distance).to eq(provider.resource[:distance])
      end
    end

    describe '#tag' do
      it 'sets tag to the resource value' do
        expect(api).to receive(:create).with('192.0.3.0/24', '192.0.3.1',
                                             distance: 3,
                                             name: 'Edge10',
                                             tag: 4)
        provider.create
        provider.flush
        expect(provider.tag).to eq(provider.resource[:tag])
      end
    end

    describe '#destroy' do
      it 'sets ensure to :absent' do
        resource[:ensure] = :absent
        expect(api).to receive(:delete).with('192.0.3.0/24', '192.0.3.1')
        provider.destroy
        provider.flush
        expect(provider.ensure).to eq(:absent)
      end
    end
  end
end
