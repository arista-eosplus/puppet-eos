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
require 'puppet_x/eos/modules/ipinterface'

describe PuppetX::Eos::Ipinterface do
  let(:eapi) { double }
  let(:instance) { PuppetX::Eos::Ipinterface.new eapi }

  context 'when initializing a new Ipinterface instance' do
    subject { instance }
    it { is_expected.to be_a_kind_of PuppetX::Eos::Ipinterface }
  end

  context 'with Eapi#enable' do
    before :each do
      allow(eapi).to receive(:enable)
        .with(commands)
        .and_return(api_response)
    end

    context '#getall' do
      subject { instance.getall }

      let(:commands) { 'show ip interface' }

      let :api_response do
        dir = File.dirname(__FILE__)
        file = File.join(dir, 'fixtures/ipinterface_getall.json')
        JSON.load(File.read(file))
      end

      describe 'retrieve ip interfaces' do
        it { is_expected.to be_a_kind_of Array }

        it 'has one entry' do
          expect(subject.size).to eq 1
        end

        it 'includes interfaces' do
          expect(subject[0]).to have_key 'interfaces'
        end
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

      let(:commands) { ["interface #{name}", 'no switchport'] }

      describe 'logical ip interface' do
        let(:name) { 'Ethernet1' }
        let(:api_response) { [{}, {}] }

        it { is_expected.to be_truthy }
      end
    end

    context '#delete' do
      subject { instance.delete(name) }

      let(:commands) { ["interface #{name}", 'no ip address'] }

      describe 'logical ip address' do
        let(:name) { 'Ethernet1' }
        let(:api_response) { [{}, {}] }

        it { is_expected.to be_truthy }
      end
    end

    context '#set_address' do
      subject { instance.set_address(name, opts) }

      let(:opts) { { value: value, default: default } }
      let(:default) { false }
      let(:value) { nil }

      describe 'with valid address and mask' do
        let(:name) { 'Ethernet1' }
        let(:value) { '10.10.10.10/24' }
        let(:commands) { ["interface #{name}", "ip address #{value}"] }
        let(:api_response) { [{}, {}] }

        it { is_expected.to be_truthy }
      end

      describe 'negate address for interface' do
        let(:name) { 'Ethernet1' }
        let(:commands) { ["interface #{name}", 'no ip address'] }
        let(:api_response) { [{}, {}] }

        it { is_expected.to be_truthy }
      end

      describe 'default address for interface' do
        let(:name) { 'Ethernet1' }
        let(:default) { true }
        let(:commands) { ["interface #{name}", 'default ip address'] }
        let(:api_response) { [{}, {}] }

        it { is_expected.to be_truthy }
      end
    end
  end
end
