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
require 'puppet_x/eos/modules/switchport'

describe PuppetX::Eos::Switchport do
  let(:eapi) { double }
  let(:instance) { PuppetX::Eos::Switchport.new eapi }

  context 'when initializing a new Switchport instance' do
    subject { instance }
    it { is_expected.to be_a_kind_of PuppetX::Eos::Switchport }
  end

  context 'with Eapi#enable' do
    before :each do
      allow(eapi).to receive(:enable)
        .with(commands, format: 'text')
        .and_return(api_response)
    end

    context '#get' do
      subject { instance.get(name) }

      let(:name) { 'Ethernet1' }
      let(:commands) { 'show interfaces Ethernet1 switchport' }

      let :api_response do
        dir = File.dirname(__FILE__)
        file = File.join(dir, 'fixture_switchport_get.json')
        JSON.load(File.read(file))
      end

      describe 'a switchport from the running-config' do
        it { is_expected.to be_a_kind_of Hash }
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

      let(:commands) { ["interface #{name}", "no ip address", "switchport"] }

      describe 'a new switchport in the running-config' do
        let(:name) { "Ethernet1" }
        let(:api_response) { [{}, {}, {}] }
        it { is_expected.to be_truthy }
      end
    end

    context '#delete' do
      subject { instance.delete(name) }

      let(:commands) { ["interface #{name}", "no switchport"] }

      describe 'an existing switchport from the running-config' do
        let(:name) { 'Ethernet1' }
        let(:api_response) { [{}, {}] }

        it { is_expected.to be_truthy }
      end
    end

    context '#default' do
      subject { instance.default(name) }

      let(:commands) { ["interface #{name}", "default switchport"] }

      describe 'a logical switchport interface' do
        let(:name) { 'Ethernet1' }
        let(:api_response) { [{}, {}] }

        it { is_expected.to be_truthy }
      end
    end

    context '#set_mode' do
      subject { instance.set_mode(name, opts) }

      let(:opts) { {value: value, default: default} }
      let(:default) { false }
      let(:value) { nil }

      %w(access trunk).each do |mode|
        describe "configure switchport mode=#{mode}" do
          let(:name) { 'Ethernet1' }
          let(:value) { mode }
          let(:commands) { ["interface #{name}", "switchport mode #{mode}"] }
          let(:api_response) { [{}, {}] }

          it {is_expected.to be_truthy }
        end
      end

      describe "negate switchport mode" do
        let(:name) { 'Ethernet1' }
        let(:commands) { ["interface Ethernet1",
                          "no switchport mode"] }
        let(:api_response) { [{}, {}] }

        it {is_expected.to be_truthy }
      end

      describe "default switchport mode" do
        let(:name) { 'Ethernet1' }
        let(:default) { true }
        let(:commands) { ["interface Ethernet1",
                          "default switchport mode"] }
        let(:api_response) { [{}, {}] }

        it {is_expected.to be_truthy }
      end
    end

    context '#set_trunk_allowed_vlans' do
      subject { instance.set_trunk_allowed_vlans(name, opts) }

      let(:opts) { {value: value, default: default} }
      let(:default) { false }
      let(:value) { nil }

      describe "configure trunk allowed vlans" do
        let(:name) { 'Ethernet1' }
        let(:value) { "1,10-20,30" }
        let(:commands) { ["interface #{name}",
                          "switchport trunk allowed vlan #{value}"] }
        let(:api_response) { [{}, {}] }

        it {is_expected.to be_truthy }
      end

      describe "negate switchport trunk allowed vlans" do
        let(:name) { 'Ethernet1' }
        let(:commands) { ["interface #{name}",
                          "no switchport trunk allowed vlan"] }
        let(:api_response) { [{}, {}] }

        it {is_expected.to be_truthy }
      end

      describe "default switchport trunk allowed vlans" do
        let(:name) { 'Ethernet1' }
        let(:default) { true }
        let(:commands) { ["interface #{name}",
                          "default switchport trunk allowed vlan"] }
        let(:api_response) { [{}, {}] }

        it {is_expected.to be_truthy }
      end
    end

    context '#set_trunk_native_vlan' do
      subject { instance.set_trunk_native_vlan(name, opts) }

      let(:opts) { {value: value, default: default} }
      let(:default) { false }
      let(:value) { nil }

      describe "configure trunk native vlan" do
        let(:name) { 'Ethernet1' }
        let(:value) { "10" }
        let(:commands) { ["interface #{name}",
                          "switchport trunk native vlan #{value}"] }
        let(:api_response) { [{}, {}] }

        it {is_expected.to be_truthy }
      end

      describe "negate switchport trunk native vlan" do
        let(:name) { 'Ethernet1' }
        let(:commands) { ["interface #{name}",
                          "no switchport trunk native vlan"] }
        let(:api_response) { [{}, {}] }

        it {is_expected.to be_truthy }
      end

      describe "default switchport trunk native vlan" do
        let(:name) { 'Ethernet1' }
        let(:default) { true }
        let(:commands) { ["interface #{name}",
                          "default switchport trunk native vlan"] }
        let(:api_response) { [{}, {}] }

        it {is_expected.to be_truthy }
      end
    end

    context '#set_access_vlan' do
      subject { instance.set_access_vlan(name, opts) }

      let(:opts) { {value: value, default: default} }
      let(:default) { false }
      let(:value) { nil }

      describe "configure access vlan" do
        let(:name) { 'Ethernet1' }
        let(:value) { "10" }
        let(:commands) { ["interface #{name}",
                          "switchport access vlan #{value}"] }
        let(:api_response) { [{}, {}] }

        it {is_expected.to be_truthy }
      end

      describe "negate switchport access vlan" do
        let(:name) { 'Ethernet1' }
        let(:commands) { ["interface #{name}",
                          "no switchport access vlan"] }
        let(:api_response) { [{}, {}] }

        it {is_expected.to be_truthy }
      end

      describe "default switchport access vlan" do
        let(:name) { 'Ethernet1' }
        let(:default) { true }
        let(:commands) { ["interface #{name}",
                          "default switchport access vlan"] }
        let(:api_response) { [{}, {}] }

        it {is_expected.to be_truthy }
      end
    end
  end
end
