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

describe Puppet::Type.type(:eos_interface).provider(:eos) do

  # Puppet RAL memoized methods
  let(:resource) do
    resource_hash = {
      name: 'Ethernet1',
      description: 'test interface',
      enable: :true,
      provider: described_class.name
    }
    Puppet::Type.type(:eos_interface).new(resource_hash)
  end

  let(:provider) { resource.provider }

  let(:api) { double('rbeapi').as_null_object }

  def interfaces
    interfaces = Fixtures[:interfaces]
    return interfaces if interfaces
    file = get_fixture('interfaces.json')
    Fixtures[:interfaces] = JSON.load(File.read(file))
  end

  before :each do
    allow(described_class.node).to receive(:api).with('interfaces')
      .and_return(api)

    allow(provider.node).to receive(:api).with('interfaces').and_return(api)
  end

  context 'class methods' do

    before { allow(api).to receive(:getall).and_return(interfaces) }

    describe '.instances' do
      subject { described_class.instances }

      it { is_expected.to be_an Array }

      it 'has one entry' do
        expect(subject.size).to eq(1)
      end

      it "has an instance for interface Ethernet1" do
        instance = subject.find { |p| p.name == 'Ethernet1' }
        expect(instance).to be_a described_class
      end

      context 'eos_interface { Ethernet1: }' do
        subject { described_class.instances.find { |p| p.name == 'Ethernet1' } }

        include_examples 'provider resource methods',
                         name: 'Ethernet1',
                         description: 'test interface',
                         enable: :true
      end

    end

    describe '.prefetch' do
      let :resources do
        {
          'Ethernet1' => Puppet::Type.type(:eos_interface)
            .new(name: 'Ethernet1'),
          'Ethernet2' => Puppet::Type.type(:eos_interface)
            .new(name: 'Ethernet2')
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
        expect(resources['Ethernet1'].provider.description).to eq('test interface')
        expect(resources['Ethernet1'].provider.enable).to eq :true
      end

      it 'does not set the provider instance of the unmanaged resource' do
        subject
        expect(resources['Ethernet2'].provider.description).to eq :absent
        expect(resources['Ethernet2'].provider.enable).to eq :absent
      end
    end
  end

  context 'resource (instance) methods' do

    describe '#create' do
      let(:name) { 'Ethernet1' }

      it 'sets ensure to :present' do
        expect(api).to receive(:create).with(resource[:name])
        provider.create
      end

      it 'sets enable on the resource' do
        expect(api).to receive(:set_shutdown).with(name, value: false)
        provider.create
        expect(provider.enable).to be_truthy
      end

      it 'sets description on the resource' do
        expect(api).to receive(:set_description).with(name, value: 'test interface')
        provider.create
        expect(provider.description).to eq('test interface')
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
        let(:name) { 'Ethernet1' }

        it "updates enable in the provider" do
          expect(api).to receive(:set_shutdown).with(name, value: !val)
          provider.enable = val
          expect(provider.enable).to eq(val)
        end
      end
    end
  end
end
