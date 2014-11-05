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
      name: 'configuration',
      source_interface: 'Loopback0'
    }
    type.new(resource_hash)
  end

  let(:provider) { resource.provider }

  def ntp
    ntp = Fixtures[:ntp]
    return ntp if ntp
    file = File.join(File.dirname(__FILE__), 'fixtures/ntp.json')
    Fixtures[:ntp] = JSON.load(File.read(file))
  end

  before :each do
    allow_message_expectations_on_nil
    allow(described_class).to receive(:eapi)
    allow(described_class.eapi).to receive(:Ntp)
    allow(described_class.eapi.Ntp).to receive(:get)
      .and_return(ntp)
  end

  context 'class methods' do
    describe '.instances' do
      subject { described_class.instances }

      it { is_expected.to be_an Array }

      it 'has one instance' do
        expect(subject.size).to eq(1)
      end

      it 'contains Eos_ntp_config[configuration]' do
        instance = subject.find { |p| p.name == 'configuration' }
        expect(instance).to be_a described_class
      end

      describe 'Eos_ntp_config[configuration]' do
        subject do
          described_class.instances.find { |p| p.name == 'configuration' }
        end

        include_examples 'provider resource methods',
                         name: 'configuration',
                         source_interface: 'Loopback0'
      end
    end

    describe '.prefetch' do
      let(:resources) { { 'configuration' => type.new(name: 'configuration') } }
      subject { described_class.prefetch(resources) }

      it 'updates the provider instance of managed resources' do
        expect(resources['configuration'].provider.source_interface).to eq(:absent)
        subject
        expect(resources['configuration'].provider.source_interface).to eq('Loopback0')
      end
    end
  end

  context 'resource (instance) methods' do

    let(:eapi) { double }

    before do
      allow(provider).to receive(:eapi)
      allow(provider.eapi).to receive(:Ntp)
    end

    describe '#source_interface=(val)' do
      subject { provider.source_interface = 'Loopback0' }

      before :each do
        allow(provider.eapi.Ntp).to receive(:set_source_interface)
          .with('Loopback0')
      end

      it 'calls Ntp.set_source_interface = "Loopback0"' do
        expect(provider.eapi.Ntp).to receive(:set_source_interface)
          .with('Loopback0')
        subject
      end

      it 'sets source_interface to "Loopback0" in the provider' do
        expect(provider.source_interface).not_to eq('Loopback0')
        subject
        expect(provider.source_interface).to eq('Loopback0')
      end
    end
  end
end
