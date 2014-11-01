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
require 'puppet_x/eos/modules/mlag'

describe PuppetX::Eos::Mlag do
  let(:eapi) { double }
  let(:instance) { PuppetX::Eos::Mlag.new eapi }

  context 'when initializing a new Mlag instance' do
    subject { instance }
    it { is_expected.to be_a_kind_of PuppetX::Eos::Mlag }
  end

  context 'with Eapi#enable' do
    before :each do
      allow(eapi).to receive(:enable)
        .with(commands)
        .and_return(api_response)
    end

    context '#get' do
      subject { instance.get }

      let(:commands) { 'show mlag' }

      let :api_response do
        dir = File.dirname(__FILE__)
        file = File.join(dir, 'fixtures/mlag_get.json')
        JSON.load(File.read(file))
      end

      describe 'mlag configuration' do
        it { is_expected.to be_a_kind_of Hash }
      end
    end

    context '#get_interfaces' do
      subject { instance.get_interfaces }

      let(:commands) { 'show mlag interfaces' }

      let :api_response do
        dir = File.dirname(__FILE__)
        file = File.join(dir, 'fixtures/mlag_get_interfaces.json')
        JSON.load(File.read(file))
      end

      it { is_expected.to be_a_kind_of Array }

      it 'has only one entry' do
        expect(subject.size).to eq 1
      end

      it 'has includes key interfaces' do
        expect(subject[0]).to have_key 'interfaces'
      end
    end
  end

  context 'with Eapi#config' do
    before :each do
      allow(eapi).to receive(:config)
        .with(commands)
        .and_return(api_response)
    end

    context '#create' do
      subject { instance.create(name) }

      let(:name) { 'mlag-domain' }
      let(:commands) { ['mlag configuration', "domain-id #{name}"] }

      describe 'create mlag instance with domain-id' do
        let(:api_response) { [{}, {}] }
        it { is_expected.to be_truthy }
      end
    end

    context '#delete' do
      subject { instance.delete }

      let(:commands) { 'no mlag configuration' }

      describe 'remove mlag configuration' do
        let(:api_response) { [{}] }
        it { is_expected.to be_truthy }
      end
    end

    context '#default' do
      subject { instance.default }

      let(:commands) { 'default mlag configuration' }

      describe 'default mlag configuration' do
        let(:api_response) { [{}] }
        it { is_expected.to be_truthy }
      end
    end

    context '#add_interface' do
      subject { instance.add_interface(name, mlag_id) }

      let(:name) { 'Port-Channel1' }
      let(:mlag_id) { 1 }
      let(:commands) { ["interface #{name}", "mlag #{mlag_id}"] }

      describe 'using mlag id 1' do
        let(:api_response) { [{}, {}] }

        it { is_expected.to be_truthy }
      end
    end

    context '#remove_interface' do
      subject { instance.remove_interface(name) }

      let(:name) { 'Port-Channel1' }
      let(:commands) { ["interface #{name}", 'no mlag'] }

      describe 'delete from mlag' do
        let(:api_response) { [{}, {}] }

        it { is_expected.to be_truthy }
      end
    end

    context '#set_domain_id' do
      subject { instance.set_domain_id(opts) }

      let(:opts) { { value: value, default: default } }
      let(:default) { false }
      let(:value) { nil }

      describe 'to foo' do
        let(:value) { 'foo' }
        let(:commands) { ['mlag configuration', 'domain-id foo'] }
        let(:api_response) { [{}, {}] }

        it { is_expected.to be_truthy }
      end

      describe 'to negate mlag domain-id' do
        let(:commands) { ['mlag configuration', 'no domain-id'] }
        let(:api_response) { [{}, {}] }

        it { is_expected.to be_truthy }
      end

      describe 'default mlag domain-id' do
        let(:default) { true }
        let(:commands) { ['mlag configuration', 'default domain-id'] }
        let(:api_response) { [{}, {}] }

        it { is_expected.to be_truthy }
      end
    end

    context '#set_local_interface' do
      subject { instance.set_local_interface(opts) }

      let(:opts) { { value: value, default: default } }
      let(:default) { false }
      let(:value) { nil }

      describe 'to value vlan 4094' do
        let(:value) { 'Vlan 4094' }
        let(:commands) { ['mlag configuration', 'local-interface Vlan 4094'] }
        let(:api_response) { [{}, {}] }

        it { is_expected.to be_truthy }
      end

      describe 'to negate mlag local-interface' do
        let(:commands) { ['mlag configuration', 'no local-interface'] }
        let(:api_response) { [{}, {}] }

        it { is_expected.to be_truthy }
      end

      describe 'default mlag local-interface' do
        let(:default) { true }
        let(:commands) { ['mlag configuration', 'default local-interface'] }
        let(:api_response) { [{}, {}] }

        it { is_expected.to be_truthy }
      end
    end

    context '#set_peer_address' do
      subject { instance.set_peer_address(opts) }

      let(:opts) { { value: value, default: default } }
      let(:default) { false }
      let(:value) { nil }

      describe 'to value 10.10.10.10' do
        let(:value) { '10.10.10.10' }
        let(:commands) { ['mlag configuration', 'peer-address 10.10.10.10'] }
        let(:api_response) { [{}, {}] }

        it { is_expected.to be_truthy }
      end

      describe 'to negate mlag peer-address' do
        let(:commands) { ['mlag configuration', 'no peer-address'] }
        let(:api_response) { [{}, {}] }

        it { is_expected.to be_truthy }
      end

      describe 'default mlag peer-address' do
        let(:default) { true }
        let(:commands) { ['mlag configuration', 'default peer-address'] }
        let(:api_response) { [{}, {}] }

        it { is_expected.to be_truthy }
      end
    end

    context '#set_peer_link' do
      subject { instance.set_peer_link(opts) }

      let(:opts) { { value: value, default: default } }
      let(:default) { false }
      let(:value) { nil }

      describe 'to value Port-Channel 100' do
        let(:value) { 'Port-Channel 100' }
        let(:commands) { ['mlag configuration', 'peer-link Port-Channel 100'] }
        let(:api_response) { [{}, {}] }

        it { is_expected.to be_truthy }
      end

      describe 'to negate mlag peer-link' do
        let(:commands) { ['mlag configuration', 'no peer-link'] }
        let(:api_response) { [{}, {}] }

        it { is_expected.to be_truthy }
      end

      describe 'default mlag peer-link' do
        let(:default) { true }
        let(:commands) { ['mlag configuration', 'default peer-link'] }
        let(:api_response) { [{}, {}] }

        it { is_expected.to be_truthy }
      end
    end

    context '#set_shutdown' do
      subject { instance.set_shutdown(opts) }

      let(:opts) { { value: value, default: default } }
      let(:default) { false }
      let(:value) { nil }

      describe 'configure shutdown=false' do
        let(:value) { false }
        let(:commands) { ['mlag configuration', 'no shutdown'] }
        let(:api_response) { [{}, {}] }
        it { is_expected.to be_truthy }
      end

      describe 'configure shutdown=true' do
        let(:value) { true }
        let(:commands) { ['mlag configuration', 'shutdown'] }
        let(:api_response) { [{}, {}] }
        it { is_expected.to be_truthy }
      end

      describe 'configure default interface shutdown' do
        let(:default) { true }
        let(:commands) { ['mlag configuration', 'default shutdown'] }
        let(:api_response) { [{}, {}] }
        it { is_expected.to be_truthy }
      end

      describe 'negate interface shutdown' do
        let(:commands) { ['mlag configuration', 'no shutdown'] }
        let(:api_response) { [{}, {}] }
        it { is_expected.to be_truthy }
      end
    end
  end
end
