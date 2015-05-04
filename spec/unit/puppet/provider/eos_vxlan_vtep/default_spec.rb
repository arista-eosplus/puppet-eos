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

describe Puppet::Type.type(:eos_vxlan_vtep).provider(:eos) do
  # Puppet RAL memoized methods
  let(:resource) do
    resource_hash = {
      name: '1.1.1.1',
      provider: described_class.name
    }
    Puppet::Type.type(:eos_vxlan_vtep).new(resource_hash)
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
    before { allow(api).to receive(:get).and_return(vxlan) }

    describe '.instances' do
      subject { described_class.instances }

      it { is_expected.to be_an Array }

      it 'has two entries' do
        expect(subject.size).to eq(2)
      end

      it 'has an instance for 1.1.1.1' do
        instance = subject.find { |p| p.name == '1.1.1.1' }
        expect(instance).to be_a described_class
      end

      context 'eos_vxlan_vtep { 1.1.1.1: }' do
        subject { described_class.instances.find { |p| p.name == '1.1.1.1' } }

        include_examples 'provider resource methods',
                         name: '1.1.1.1',
                         ensure: :present
      end
    end

    describe '.prefetch' do
      let :resources do
        {
          '1.1.1.1' => Puppet::Type.type(:eos_vxlan_vtep).new(name: '1.1.1.1'),
          '2.2.2.2' => Puppet::Type.type(:eos_vxlan_vtep).new(name: '2.2.2.2')
        }
      end
      subject { described_class.prefetch(resources) }

      it 'resource providers are absent prior to calling .prefetch' do
        resources.values.each do |rsrc|
          expect(rsrc.provider.exists?).to be_falsey
        end
      end

      it 'sets the provider instance of the managed resource' do
        subject
        expect(resources['1.1.1.1'].provider.name).to eq '1.1.1.1'
        expect(resources['1.1.1.1'].provider.exists?).to be_truthy
      end

      it 'does not set the provider instance of the unmanaged resource' do
        subject
        expect(resources['2.2.2.2'].provider.name).to eq '2.2.2.2'
        expect(resources['2.2.2.2'].provider.exists?).to be_falsey
      end
    end
  end

  context 'resource (instance) methods' do
    describe '#create' do
      before do
        expect(api).to receive(:add_vtep)
          .with('Vxlan1', resource[:name])
      end

      it 'sets ensure to :present' do
        provider.create
        expect(provider.ensure).to eq(:present)
      end
    end

    describe '#destroy' do
      it 'sets ensure to :absent' do
        resource[:ensure] = :absent
        expect(api).to receive(:remove_vtep).with('Vxlan1', resource[:name])
        provider.destroy
        expect(provider.ensure).to eq(:absent)
      end
    end
  end
end
