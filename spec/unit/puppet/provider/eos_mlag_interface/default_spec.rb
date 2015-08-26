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

describe Puppet::Type.type(:eos_mlag_interface).provider(:eos) do
  # Puppet RAL memoized methods
  let(:resource) do
    resource_hash = {
      ensure: :present,
      name: 'Port-Channel1',
      mlag_id: 1,
      provider: described_class.name
    }
    Puppet::Type.type(:eos_mlag_interface).new(resource_hash)
  end

  let(:provider) { resource.provider }

  let(:api) { double('mlag') }

  def mlag
    mlag = Fixtures[:mlag]
    return mlag if mlag
    fixture('mlag', dir: File.dirname(__FILE__))
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

      it 'has one entry' do
        expect(subject.size).to eq 1
      end

      it 'has an instance for interface Port-Channel1' do
        instance = subject.find { |p| p.name == 'Port-Channel1' }
        expect(instance).to be_a described_class
      end

      context "eos_mlag_interface { 'Port-Channel1': }" do
        subject do
          described_class.instances.find { |p| p.name == 'Port-Channel1' }
        end

        include_examples 'provider resource methods',
                         ensure: :present,
                         name: 'Port-Channel1',
                         mlag_id: 1
      end
    end

    describe '.prefetch' do
      let :resources do
        {
          'Port-Channel1' => Puppet::Type.type(:eos_mlag_interface)
            .new(name: 'Port-Channel1'),
          'Port-Channel3' => Puppet::Type.type(:eos_mlag_interface)
            .new(name: 'Port-Channel3')
        }
      end

      subject { described_class.prefetch(resources) }

      it 'resource providers are absent prior to calling .prefetch' do
        resources.values.each do |rsrc|
          expect(rsrc.provider.mlag_id).to eq(:absent)
        end
      end

      it 'sets the provider instance of the managed resource' do
        subject
        expect(resources['Port-Channel1'].provider.name).to eq 'Port-Channel1'
        expect(resources['Port-Channel1'].provider.exists?).to be_truthy
        expect(resources['Port-Channel1'].provider.mlag_id).to eq(1)
      end

      it 'does not set the provider instance of the unmanaged resource' do
        subject
        expect(resources['Port-Channel3'].provider.name).to eq('Port-Channel3')
        expect(resources['Port-Channel3'].provider.exists?).to be_falsey
        expect(resources['Port-Channel3'].provider.mlag_id).to eq(:absent)
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

    describe '#create' do
      let(:name) { resource[:name] }

      it 'sets ensure to :present' do
        expect(api).to receive(:set_mlag_id).with(name, value: 1)
        provider.create
        provider.flush
        expect(provider.ensure).to eq(:present)
      end
    end

    describe '#destroy' do
      let(:name) { resource[:name] }

      it 'sets ensure to :absent' do
        expect(api).to receive(:set_mlag_id).with(name, enable: false)
        resource[:ensure] = :absent
        provider.destroy
        provider.flush
        expect(provider.ensure).to eq(:absent)
      end
    end

    describe '#mlag_id=(val)' do
      let(:name) { resource[:name] }

      it 'sets mlag_id to value 100' do
        expect(api).to receive(:set_mlag_id).with(name, value: 100)
        provider.mlag_id = 100
        provider.flush
        expect(provider.mlag_id).to eq(100)
      end
    end
  end
end
