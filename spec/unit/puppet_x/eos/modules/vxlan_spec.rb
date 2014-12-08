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
require 'puppet_x/eos/modules/vxlan'

describe PuppetX::Eos::Vxlan do
  let(:eapi) { double }
  let(:instance) { PuppetX::Eos::Vxlan.new eapi }

  context 'when initializing a new Vxlan instance' do
    subject { instance }
    it { is_expected.to be_a_kind_of PuppetX::Eos::Vxlan }
  end

  context 'with Eapi#enable' do
    before :each do
      allow(eapi).to receive(:enable)
        .with(commands)
        .and_return(api_response)
    end

    context '#getall' do
      subject { instance.getall }

      let(:commands) { 'show interfaces' }

      let :api_response do
        dir = File.dirname(__FILE__)
        file = File.join(dir, 'fixtures/vxlan_get.json')
        JSON.load(File.read(file))
      end

      describe 'vxlan interfaces configuration' do
        it { is_expected.to be_a_kind_of Hash }
        it { is_expected.to have_key 'Vxlan1' }

        it 'has one entry' do
          expect(subject.size).to eq(1)
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
      subject { instance.create }

      let(:commands) { 'interface Vxlan1' }

      describe 'a new instance of vxlan' do
        let(:api_response) { [{}] }

        it { is_expected.to be_truthy }
      end
    end

    context '#delete' do
      subject { instance.delete }

      let(:commands) { 'no interface Vxlan1' }

      describe 'a configured instance of vxlan' do
        let(:api_response) { [{}] }

        it { is_expected.to be_truthy }
      end
    end

    context '#default' do
      subject { instance.default }

      let(:commands) { 'default interface Vxlan1' }

      describe 'a configured instance of vxlan' do
        let(:api_response) { [{}] }

        it { is_expected.to be_truthy }
      end
    end

    context '#set_source_interface' do
      subject { instance.set_source_interface(opts) }

      let(:opts) { { value: value, default: default } }
      let(:default) { false }
      let(:value) { nil }

      describe 'to interface loopback 0' do
        let(:value) { 'loopback 0' }
        let(:commands) do
          ['interface Vxlan1', 'vxlan source-interface loopback 0']
        end
        let(:api_response) { [{}, {}] }

        it { is_expected.to be_truthy }
      end

      describe 'to negate vxlan source-interface' do
        let(:commands) { ['interface Vxlan1', 'no vxlan source-interface'] }
        let(:api_response) { [{}, {}] }

        it { is_expected.to be_truthy }
      end

      describe 'default state vxlan source-interface' do
        let(:default) { true }
        let(:commands) do
          ['interface Vxlan1', 'default vxlan source-interface']
        end
        let(:api_response) { [{}, {}] }

        it { is_expected.to be_truthy }
      end
    end

    context '#set_multicast_group' do
      subject { instance.set_multicast_group(opts) }

      let(:opts) { { value: value, default: default } }
      let(:default) { false }
      let(:value) { nil }

      describe 'to mulitcast address 239.10.10.10' do
        let(:value) { '239.10.10.10' }
        let(:commands) do
          ['interface Vxlan1', 'vxlan multicast-group 239.10.10.10']
        end
        let(:api_response) { [{}, {}] }

        it { is_expected.to be_truthy }
      end

      describe 'to negate vxlan multicast-group' do
        let(:commands) { ['interface Vxlan1', 'no vxlan multicast-group'] }
        let(:api_response) { [{}, {}] }

        it { is_expected.to be_truthy }
      end

      describe 'default state vxlan multicast-group' do
        let(:default) { true }
        let(:commands) do
          ['interface Vxlan1', 'default vxlan multicast-group']
        end
        let(:api_response) { [{}, {}] }

        it { is_expected.to be_truthy }
      end
    end
  end
end
