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
require 'puppet_x/eos/modules/vlan'

describe PuppetX::Eos::Vlan do
  let(:eapi) { double }
  let(:instance) { PuppetX::Eos::Vlan.new eapi }

context 'when initializing a new Vlan instance' do
    subject { instance }
    it { is_expected.to be_a_kind_of PuppetX::Eos::Vlan }
  end

  context 'with Eapi#enable' do
    before :each do
      allow(eapi).to receive(:enable)
        .with(commands)
        .and_return(api_response)
    end

    context '#getall' do
      subject { instance.getall }

      let(:commands) { ['show vlan', 'show vlan trunk group']}

      let :api_response do
        dir = File.dirname(__FILE__)
        file = File.join(dir, 'fixtures/vlan_getall.json')
        JSON.load(File.read(file))
      end

      describe 'retrieve vlans' do
        it { is_expected.to be_a_kind_of Array }

        it 'has two entries' do
          expect(subject.size).to eq 2
        end

        it 'includes vlans' do
          expect(subject[0]).to have_key 'vlans'
        end

        it 'includes trunkGroups' do
          expect(subject[1]).to have_key 'trunkGroups'
        end

        it 'vlans to have a 1 to 1 mapping to trunkGroups' do
          subject[0].keys do |vid|
            expect(subject[1]['trunkGroups']).to have_key vid
          end
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
      subject { instance.create(vlanid) }

      let(:commands) { "vlan #{vlanid}" }

      describe 'vlan 1234 success' do
        let(:vlanid) { '1234' }
        let(:api_response) { [{}] }

        it { is_expected.to be_truthy }
      end
    end

    context '#delete' do
      subject { instance.delete(vlanid) }

      let(:commands) { "no vlan #{vlanid}" }

      describe 'vlan 1234 success' do
        let(:vlanid) { '1234' }
        let(:api_response) { [{}] }

        it { is_expected.to be_truthy }
      end
    end

    context '#default' do
      subject { instance.default(vlanid) }

      let(:commands) { "default vlan #{vlanid}" }

      describe 'vlan 1234 success' do
        let(:vlanid) { '1234' }
        let(:api_response) { [{}] }

        it { is_expected.to be_truthy }
      end
    end

    context '#set_name' do
      subject { instance.set_name(vlanid, opts) }

      let(:opts) { {value: value, default: default} }
      let(:default) { false }
      let(:value) { nil }

      %w(10, 100, 1000).each do |vlanid|
        vlan_name = (0...50).map { ('a'..'z').to_a[rand(26)] }.join
        describe "configure name=#{vlan_name} for vlan #{vlanid}" do
          let(:vlanid) { vlanid }
          let(:value) { vlan_name }
          let(:commands) { ["vlan #{vlanid}", "name #{value}"] }
          let(:api_response) { [{}, {}] }

          it { is_expected.to be_truthy }
        end

        describe "negate name for vlan #{vlanid}" do
          let(:vlanid) { vlanid }
          let(:commands) { ["vlan #{vlanid}", 'no name'] }
          let(:api_response) { [{}, {}] }

          it { is_expected.to be_truthy }
        end

        describe "default name for vlan #{vlanid}" do
          let(:vlanid) { vlanid }
          let(:default) { true }
          let(:commands) { ["vlan #{vlanid}", 'default name'] }
          let(:api_response) { [{}, {}] }

          it { is_expected.to be_truthy }
        end
      end
    end

    context '#set_state' do
      subject { instance.set_state(vlanid, opts) }

      let(:opts) { {value: value, default: default} }
      let(:default) { false }
      let(:value) { nil }

      %w(10, 100, 1000).each do |vlanid|
        %w(active suspect).each do |value|
          describe "configure state=#{value} for vlan #{vlanid}" do
            let(:vlanid) { vlanid }
            let(:value) { value }
            let(:commands) { ["vlan #{vlanid}", "state #{value}"] }
            let(:api_response) { [{}, {}] }

            it { is_expected.to be_truthy }
          end
        end

        describe "negate state for vlan #{vlanid}" do
          let(:vlanid) { vlanid }
          let(:commands) { ["vlan #{vlanid}", 'no state'] }
          let(:api_response) { [{}, {}] }

          it { is_expected.to be_truthy }
        end

        describe "default state for vlan #{vlanid}" do
          let(:vlanid) { vlanid }
          let(:default) { true }
          let(:commands) { ["vlan #{vlanid}", 'default state'] }
          let(:api_response) { [{}, {}] }

          it { is_expected.to be_truthy }
        end
      end
    end

    context '#set_trunk_group' do
      subject { instance.set_trunk_group(vlanid, opts) }

      let(:opts) { { value: value, default: default } }
      let(:default) { false }
      let(:value) { nil }

      %w(10, 100, 1000).each do |vlanid|
        value = (0...10).map { ('a'..'z').to_a[rand(26)] }.join
        describe "configure trunk_group=#{value} for vlan #{vlanid}" do
          let(:vlanid) { vlanid }
          let(:value) { value }
          let(:commands) { ["vlan #{vlanid}", "trunk group #{value}"] }
          let(:api_response) { [{}, {}] }

          it { is_expected.to be_truthy }
        end

        describe "negate trunk group for vlan #{vlanid}" do
          let(:vlanid) { vlanid }
          let(:commands) { ["vlan #{vlanid}", 'no trunk group'] }
          let(:api_response) { [{}, {}] }

          it { is_expected.to be_truthy }
        end

        describe "default trunk group for vlan #{vlanid}" do
          let(:vlanid) { vlanid }
          let(:default) { true }
          let(:commands) { ["vlan #{vlanid}", 'default trunk group'] }
          let(:api_response) { [{}, {}] }

          it { is_expected.to be_truthy }
        end
      end
    end
  end
end
