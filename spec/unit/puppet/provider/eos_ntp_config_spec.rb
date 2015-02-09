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

describe Puppet::Type.type(:eos_ntp_config).provider(:eos) do
  let(:type) { Puppet::Type.type(:eos_ntp_config) }

  let :resource do
    resource_hash = {
      name: 'settings',
      source_interface: 'Loopback0'
    }
    type.new(resource_hash)
  end

  let(:provider) { resource.provider }

  let(:api) { double('ntp') }

  def ntp
    ntp = Fixtures[:ntp]
    return ntp if ntp
    file = get_fixture('ntp.json')
    Fixtures[:ntp] = JSON.load(File.read(file))
  end

  before :each do
    allow(described_class.node).to receive(:api).with('ntp').and_return(api)
    allow(provider.node).to receive(:api).with('ntp').and_return(api)
  end

  context 'class methods' do

    before { allow(api).to receive(:get).and_return(ntp) }

    describe '.instances' do
      subject { described_class.instances }

      it { is_expected.to be_an Array }

      it 'has one instance' do
        expect(subject.size).to eq(1)
      end

      it 'contains Eos_ntp_config[settings]' do
        instance = subject.find { |p| p.name == 'settings' }
        expect(instance).to be_a described_class
      end

      describe 'Eos_ntp_config[settings]' do
        subject do
          described_class.instances.find { |p| p.name == 'settings' }
        end

        include_examples 'provider resource methods',
                         name: 'settings',
                         source_interface: 'Loopback0'
      end
    end

    describe '.prefetch' do
      let(:resources) do
        {
          'settings' => Puppet::Type.type(:eos_ntp_config).new(name: 'settings'),
          'alternative' => Puppet::Type.type(:eos_ntp_config).new(name: 'alternative')
        }
      end

      subject { described_class.prefetch(resources) }

      it 'resource providers are absent prior to calling .prefetch' do
        resources.values.each do |rsrc|
          expect(rsrc.provider.source_interface).to eq(:absent)
        end
      end

      it 'sets the provider instane of the managed resource' do
        subject
        expect(resources['settings'].provider.name).to eq 'settings'
        expect(resources['settings'].provider.exists?).to be_truthy
        expect(resources['settings'].provider.source_interface).to eq 'Loopback0'
      end

      it 'does not set the provider instance of the unmanaged resource' do
        subject
        expect(resources['alternative'].provider.name).to eq 'alternative'
        expect(resources['alternative'].provider.exists?).to be_falsy
        expect(resources['alternative'].provider.source_interface).to eq :absent
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
          allow(api).to receive(:get).and_return(ntp)
          described_class.instances.first
        end
        it { is_expected.to be_truthy }
      end
    end

    describe '#source_interface=(val)' do
      it 'updates source_interace with value "Loopback1"' do
        expect(api).to receive(:set_source_interface).with(value: 'Loopback1')
        provider.source_interface = 'Loopback1'
        expect(provider.source_interface).to eq('Loopback1')
      end
    end
  end
end
