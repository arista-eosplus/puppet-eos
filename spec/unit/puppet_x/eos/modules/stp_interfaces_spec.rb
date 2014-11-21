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
require 'puppet_x/eos/modules/stp'

describe PuppetX::Eos::StpInterfaces do
  let(:eapi) { double }
  let(:instance) { PuppetX::Eos::StpInterfaces.new eapi }

  context 'when initializing a new StpInterfaces instance' do
    subject { instance }
    it { is_expected.to be_a_kind_of PuppetX::Eos::StpInterfaces }
  end

  context 'with Eapi#enable' do
    before :each do
      allow(eapi).to receive(:enable)
    end

    context '#getall' do
      subject { instance.getall }

      before :each do
        allow(eapi).to receive(:enable).with('show interfaces')
          .and_return(show_interfaces)
        allow(eapi).to receive(:enable)
          .with('show running-config interfaces Ethernet1', format: 'text')
          .and_return(show_interfaces_et1)
      end

      let :show_interfaces do
        dir = File.dirname(__FILE__)
        file = File.join(dir, 'fixtures/stp_interfaces_getall.json')
        JSON.load(File.read(file))
      end

      let :show_interfaces_et1 do
        dir = File.dirname(__FILE__)
        file = File.join(dir, 'fixtures/stp_interfaces_et1.json')
        JSON.load(File.read(file))
      end

      it { is_expected.to be_a_kind_of Hash }
      it { is_expected.to have_key 'Ethernet1' }

      it 'has only one entry' do
        expect(subject.size).to eq(1)
      end
    end
  end

  context 'with Eapi#config' do
    before :each do
      allow(eapi).to receive(:config)
        .with(commands)
        .and_return(api_response)
    end

    context '#set_portfast' do
      subject { instance.set_portfast('Ethernet1', opts) }

      let(:opts) { { value: value, default: default } }
      let(:default) { false }
      let(:value) { nil }

      describe 'for Ethernet1 to "enable"' do
        let(:value) { 'enable' }
        let(:commands) { ['interface Ethernet1', 'spanning-tree portfast'] }
        let(:api_response) { [{}, {}] }

        it { is_expected.to be_truthy }
      end

      describe 'for Ethernet1 to "disable"' do
        let(:value) { 'disable' }
        let(:commands) { ['interface Ethernet1', 'no spanning-tree portfast'] }
        let(:api_response) { [{}, {}] }

        it { is_expected.to be_truthy }
      end

      describe 'to negate portfast for Ethernet1' do
        let(:commands) { ['interface Ethernet1', 'no spanning-tree portfast'] }
        let(:api_response) { [{}, {}] }

        it { is_expected.to be_truthy }
      end

      describe 'to default portfast for Ethernet1' do
        let(:default) { true }
        let(:commands) do
          ['interface Ethernet1', 'default spanning-tree portfast']
        end
        let(:api_response) { [{}, {}] }

        it { is_expected.to be_truthy }
      end
    end
  end
end
