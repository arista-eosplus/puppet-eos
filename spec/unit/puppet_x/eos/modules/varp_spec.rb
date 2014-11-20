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
require 'puppet_x/eos/modules/varp'

describe PuppetX::Eos::Varp do
  let(:eapi) { double }
  let(:instance) { PuppetX::Eos::Varp.new eapi }

  context 'when initializing a new Varp instance' do
    subject { instance }
    it { is_expected.to be_a_kind_of PuppetX::Eos::Varp }
  end

  context 'with Eapi#enable' do
    before :each do
      allow(eapi).to receive(:enable)
        .with(commands)
        .and_return(api_response)
    end

    context '#get' do
      subject { instance.get }

      let(:commands) { 'show ip virtual-router' }

      let :api_response do
        dir = File.dirname(__FILE__)
        file = File.join(dir, 'fixtures/varp_get.json')
        JSON.load(File.read(file))
      end

      it { is_expected.to be_a_kind_of Hash }
      it { is_expected.to have_key 'macaddress' }
      it { is_expected.to have_key 'interfaces' }

      it 'should return interfaces as a hash' do
        expect(subject['interfaces']).to be_a_kind_of Hash
      end
    end
  end

  context 'with Eapi#config' do
    before :each do
      allow(eapi).to receive(:config)
        .with(commands)
        .and_return(api_response)
    end

    context '#set_macaddress' do
      subject { instance.set_macaddress(opts) }

      let(:opts) { { value: value, default: default } }
      let(:default) { false }
      let(:value) { nil }

      describe 'to aaaa.bbbb.cccc' do
        let(:value) { 'aaaa.bbbb.cccc' }
        let(:commands) { "ip virtual-router mac-address #{value}" }
        let(:api_response) { [{}] }

        it { is_expected.to be_truthy }
      end

      describe 'to negate the current value' do
        let(:commands) { 'no ip virtual-router mac-address' }
        let(:api_response) { [{}] }

        it { is_expected.to be_truthy }
      end

      describe 'to default the current value' do
        let(:default) { true }
        let(:commands) { 'default ip virtual-router mac-address' }
        let(:api_response) { [{}] }

        it { is_expected.to be_truthy }
      end
    end
  end
end
