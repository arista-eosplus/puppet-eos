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

describe Puppet::Type.type(:eos_varp).provider(:eos) do
  let(:type) { Puppet::Type.type(:eos_varp) }

  let :resource do
    resource_hash = {
      name: 'settings',
      mac_address: 'aaaa.bbbb.cccc'
    }
    type.new(resource_hash)
  end

  let(:provider) { resource.provider }

  def varp
    varp = Fixtures[:varp]
    return varp if varp
    file = File.join(File.dirname(__FILE__), 'fixtures/varp.json')
    Fixtures[:varp] = JSON.load(File.read(file))
  end

  before :each do
    allow_message_expectations_on_nil
    allow(described_class).to receive(:eapi)
    allow(described_class.eapi).to receive(:Varp)
    allow(described_class.eapi.Varp).to receive(:get)
      .and_return(varp)
  end

  context 'class methods' do
    describe '.instances' do
      subject { described_class.instances }

      it { is_expected.to be_an Array }

      it 'has one instance' do
        expect(subject.size).to eq(1)
      end

      it 'contains eos_varp[settings]' do
        instance = subject.find { |p| p.name == 'settings' }
        expect(instance).to be_a described_class
      end

      describe 'eos_varp[settings]' do
        subject do
          described_class.instances.find { |p| p.name == 'settings' }
        end

        include_examples 'provider resource methods',
                         name: 'settings',
                         mac_address: 'aaaa.bbbb.cccc'
      end
    end

    describe '.prefetch' do
      let(:resources) { { 'settings' => type.new(name: 'settings') } }
      subject { described_class.prefetch(resources) }

      it 'updates the provider instance of managed resources' do
        expect(resources['settings'].provider.mac_address).to eq(:absent)
        subject
        expect(resources['settings'].provider.mac_address).to \
          eq('aaaa.bbbb.cccc')
      end
    end
  end

  context 'resource (instance) methods' do

    let(:eapi) { double }

    before do
      allow(provider).to receive(:eapi)
      allow(provider.eapi).to receive(:Varp)
    end

    describe '#mac_address=(val)' do
      subject { provider.mac_address = 'aaaa.bbbb.cccc' }

      before :each do
        allow(provider.eapi.Varp).to receive(:set_mac_address)
          .with(value: 'aaaa.bbbb.cccc')
      end

      it 'calls Varp.set_mac_address = "aaaa.bbbb.cccc"' do
        expect(provider.eapi.Varp).to receive(:set_mac_address)
          .with(value: 'aaaa.bbbb.cccc')
        subject
      end

      it 'sets mac_address to "aaaa.bbbb.cccc" in the provider' do
        expect(provider.mac_address).not_to eq('aaaa.bbbb.cccc')
        subject
        expect(provider.mac_address).to eq('aaaa.bbbb.cccc')
      end
    end
  end
end
