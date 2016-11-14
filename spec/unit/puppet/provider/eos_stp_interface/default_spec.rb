#
# Copyright (c) 2014-2016, Arista Networks, Inc.
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

describe Puppet::Type.type(:eos_stp_interface).provider(:eos) do
  # Puppet RAL memoized methods
  let(:resource) do
    resource_hash = {
      name: 'Ethernet1',
      portfast: :true,
      portfast_type: :network,
      bpduguard: :true,
      provider: described_class.name
    }
    Puppet::Type.type(:eos_stp_interface).new(resource_hash)
  end

  let(:provider) { resource.provider }

  let(:api) { double('stp') }
  let(:interfaces) { double('stp.interfaces') }

  def stp
    stp = Fixtures[:stp]
    return stp if stp
    fixture('stp')
  end

  before :each do
    allow(described_class.node).to receive(:api).with('stp').and_return(api)
    allow(provider.node).to receive(:api).with('stp').and_return(api)
    allow(api).to receive(:interfaces).and_return(interfaces)
  end

  context 'class methods' do
    before { allow(api).to receive(:get).and_return(stp) }

    describe '.instances' do
      subject { described_class.instances }

      it { is_expected.to be_an Array }

      it 'has two entries' do
        expect(subject.size).to eq(2)
      end

      %w(Ethernet1 Ethernet2).each do |name|
        it "has an instance for interface #{name}" do
          instance = subject.find { |p| p.name == name }
          expect(instance).to be_a described_class
        end
      end

      context 'eos_stp_interface { Ethernet1: }' do
        subject { described_class.instances.find { |p| p.name == 'Ethernet1' } }

        include_examples 'provider resource methods',
                         name: 'Ethernet1',
                         portfast: :true,
                         portfast_type: :network,
                         bpduguard: :true
      end
    end

    describe '.prefetch' do
      let :resources do
        {
          'Ethernet1' => Puppet::Type.type(:eos_stp_interface)
                                     .new(name: 'Ethernet1'),
          'Ethernet2' => Puppet::Type.type(:eos_stp_interface)
                                     .new(name: 'Ethernet2'),
          'Ethernet3' => Puppet::Type.type(:eos_stp_interface)
                                     .new(name: 'Ethernet3')
        }
      end
      subject { described_class.prefetch(resources) }

      it 'resource providers are absent prior to calling .prefetch' do
        resources.values.each do |rsrc|
          expect(rsrc.provider.portfast).to eq(:absent)
          expect(rsrc.provider.portfast_type).to eq(:absent)
          expect(rsrc.provider.bpduguard).to eq(:absent)
        end
      end

      it 'sets the provider instance of the managed resource' do
        subject
        res = resources['Ethernet1']
        expect(res.provider.portfast).to eq(:true)
        expect(res.provider.portfast_type).to eq(:network)
        expect(res.provider.bpduguard).to eq(:true)

        res = resources['Ethernet2']
        expect(res.provider.portfast).to eq(:true)
        expect(res.provider.portfast_type).to eq(:normal)
        expect(res.provider.bpduguard).to eq(:false)
      end

      it 'does not set the provider instance of the unmanaged resource' do
        subject
        res = resources['Ethernet3']
        expect(res.provider.portfast).to eq :absent
        expect(res.provider.portfast_type).to eq :absent
        expect(res.provider.bpduguard).to eq :absent
      end
    end
  end

  context 'resource (instance) methods' do
    describe '#portfast=(value)' do
      it 'enables portfast in the provider' do
        expect(interfaces).to receive(:set_portfast)
          .with(resource[:name], enable: true)
        provider.portfast = :true
        expect(provider.portfast).to be_truthy
      end
    end

    describe '#portfast_type=(value)' do
      it 'sets portfast type in the provider' do
        expect(interfaces).to receive(:set_portfast_type)
          .with(resource[:name], value: 'network')
        provider.portfast_type = :network
        expect(provider.portfast_type).to eq(:network)
      end
    end

    describe '#bpduguard=(value)' do
      it 'enable bpduguard in the provider' do
        expect(interfaces).to receive(:set_bpduguard)
          .with(resource[:name], enable: true)
        provider.bpduguard = :true
        expect(provider.bpduguard).to be_truthy
      end
    end
  end
end
