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
require 'puppet_x/eos/modules/portchannel'

describe PuppetX::Eos::Portchannel do
  let(:eapi) { double }
  let(:instance) { PuppetX::Eos::Portchannel.new eapi }

  context 'when initializing a new Portchannel instance' do
    subject { instance }
    it { is_expected.to be_a_kind_of PuppetX::Eos::Portchannel }
  end

  context 'with Eapi#enable' do
    context '#get' do
      subject { instance.get(name) }

      let(:name) { 'Port-Channel1' }
      let(:dir) { File.dirname(__FILE__) }

      let :response_portchannel_get do
        file = File.join(dir, 'fixtures/portchannel_get.json')
        JSON.load(File.read(file))
      end

      let :response_portchannel_getmembers do
        file = File.join(dir, 'fixtures/portchannel_getmembers.json')
        JSON.load(File.read(file))
      end

      let :response_portchannel_getlacpmode do
        file = File.join(dir, 'fixtures/portchannel_getlacpmode.json')
        JSON.load(File.read(file))
      end

      before :each do
        allow(eapi).to receive(:enable)
          .with("show interfaces #{name}")
          .and_return(response_portchannel_get)

        allow(eapi).to receive(:enable)
          .with("show #{name} all-ports", format: 'text')
          .and_return(response_portchannel_getmembers)

        allow(eapi).to receive(:enable)
          .with('show running-config interfaces Ethernet1', format: 'text')
          .and_return(response_portchannel_getlacpmode)
      end

      it { is_expected.to be_a_kind_of Hash }
    end

    context '#getall' do
      subject { instance.getall }

      let :interfaces do
        dir = File.dirname(__FILE__)
        file = File.join(dir, 'fixtures/portchannel_get.json')
        JSON.load(File.read(file))
      end

      let :portchannel_po1 do
        dir = File.dirname(__FILE__)
        file = File.join(dir, 'fixtures/portchannel_po1.json')
        JSON.load(File.read(file))
      end

      before :each do
        allow(eapi).to receive(:enable).and_return(interfaces)

        allow(instance).to receive(:get)
          .with('Port-Channel1')
          .and_return(portchannel_po1)
      end

      it { is_expected.to be_a_kind_of Array }

      it 'has only one entry' do
        expect(subject.size).to eq 1
      end

      it 'contains Port-Channel1' do
        expect(subject[0]['name']).to eq 'Port-Channel1'
      end
    end

    context '#get_members' do
      subject { instance.get_members(name) }

      let(:name) { 'Port-Channel1' }

      let :api_response do
        dir = File.dirname(__FILE__)
        file = File.join(dir, 'fixtures/portchannel_getmembers.json')
        JSON.load(File.read(file))
      end

      before :each do
        allow(eapi).to receive(:enable)
          .with("show #{name} all-ports", format: 'text')
          .and_return(api_response)
      end

      it { is_expected.to be_a_kind_of Array }
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

      let(:commands) { "interface #{name}" }

      describe 'a new portchannel in the running-config' do
        let(:name) { 'Port-Channel1' }
        let(:api_response) { [{}] }
        it { is_expected.to be_truthy }
      end
    end

    context '#delete' do
      subject { instance.delete(name) }

      let(:commands) { "no interface #{name}" }

      describe 'an existing portchannel from the running-config' do
        let(:name) { 'Port-Channel1' }
        let(:api_response) { [{}] }

        it { is_expected.to be_truthy }
      end
    end

    context '#default' do
      subject { instance.default(name) }

      let(:commands) { "default interface #{name}" }

      describe 'a logical switchport interface' do
        let(:name) { 'Ethernet1' }
        let(:api_response) { [{}] }

        it { is_expected.to be_truthy }
      end
    end

    context '#add_member' do
      subject { instance.add_member(name, member) }

      describe 'to portchannel interface' do
        let(:name) { 'Port-Channel1' }
        let(:member) { 'Ethernet1' }
        let(:commands) { ['interface Ethernet1', 'channel-group 1 mode on'] }

        let(:api_response) { [{}, {}] }

        it { is_expected.to be_truthy }
      end
    end

    context '#remove_member' do
      subject { instance.remove_member(name, member) }

      let(:name) { 'Port-Channel1' }
      let(:member) { 'Ethernet2' }
      let(:commands) { ['interface Ethernet2', 'no channel-group'] }
      let(:api_response) { [{}, {}] }

      it { is_expected.to be_truthy }
    end

    context '#set_lacp_mode' do
      subject { instance.set_lacp_mode(name, mode) }

      let(:api_response) { nil }

      let :enable_response do
        dir = File.dirname(__FILE__)
        file = File.join(dir, 'fixtures/portchannel_getmembers.json')
        JSON.load(File.read(file))
      end

      before :each do
        allow(eapi).to receive(:enable)
          .with("show #{name} all-ports", format: 'text')
          .and_return(enable_response)

        allow(eapi).to receive(:config)
          .with(commands)
          .and_return(config_response)
      end

      %w(active passive on).each do |mode|
        describe "configure lacp mode=#{mode}" do
          let(:name) { 'Port-Channel1' }
          let(:mode) { mode }
          let(:commands) do
            ['interface Ethernet1', 'no channel-group',
             'interface Ethernet2', 'no channel-group',
             'interface Ethernet1', "channel-group 1 mode #{mode}",
             'interface Ethernet2', "channel-group 1 mode #{mode}"]
          end
          let(:config_response) { [{}, {}, {}, {}, {}, {}, {}, {}] }

          it { is_expected.to be_truthy }
        end
      end
    end

    context '#set_lacp_fallback' do
      subject { instance.set_lacp_fallback(name, opts) }

      let(:opts) { { value: value, default: default } }
      let(:default) { false }
      let(:value) { nil }

      %w(static individual).each do |mode|
        describe "configure port-channel lacp fallback #{mode}" do
          let(:name) { 'Port-Channel1' }
          let(:value) { mode }
          let(:commands) do
            ["interface #{name}", "port-channel lacp fallback #{value}"]
          end
          let(:api_response) { [{}, {}] }

          it { is_expected.to be_truthy }
        end

        describe "negate port-channel lacp fallback #{mode}" do
          let(:name) { 'Port-Channel1' }
          let(:commands) do
            ["interface #{name}", "no port-channel lacp fallback #{value}"]
          end
          let(:api_response) { [{}, {}] }

          it { is_expected.to be_truthy }
        end

        describe "default port-channel lacp fallback #{mode}" do
          let(:name) { 'Port-Channel1' }
          let(:default) { true }
          let(:commands) do
            ["interface #{name}", 'default port-channel lacp fallback']
          end
          let(:api_response) { [{}, {}] }

          it { is_expected.to be_truthy }
        end
      end
    end

    context '#set_lacp_timeout' do
      subject { instance.set_lacp_timeout(name, opts) }

      let(:opts) { { value: value, default: default } }
      let(:default) { false }
      let(:value) { nil }

      describe 'configure portchannel lacp timeout' do
        let(:name) { 'Port-Channel1' }
        let(:value) { '100' }
        let(:commands) do
          ["interface #{name}", "port-channel lacp fallback timeout #{value}"]
        end
        let(:api_response) { [{}, {}] }

        it { is_expected.to be_truthy }
      end

      describe 'negate portchannel lacp timeout' do
        let(:name) { 'Port-Channel1' }
        let(:commands) do
          ["interface #{name}", 'no port-channel lacp fallback timeout']
        end
        let(:api_response) { [{}, {}] }

        it { is_expected.to be_truthy }
      end

      describe 'default portchannel lacp timeout' do
        let(:name) { 'Port-Channel1' }
        let(:default) { true }
        let(:commands) do
          ["interface #{name}", 'default port-channel lacp fallback timeout']
        end
        let(:api_response) { [{}, {}] }

        it { is_expected.to be_truthy }
      end
    end
  end

  context 'with instance' do

    describe '#set_members' do
      subject { instance.set_members(intf, members) }

      let(:intf) { 'Port-Channel1' }
      let(:members) { %w(Ethernet1 Ethernet3) }

      before :each do
        allow(instance).to receive(:get_members)
          .and_return(%w(Ethernet1 Ethernet2))
        allow(instance).to receive(:add_member)
        allow(instance).to receive(:remove_member)
      end

      it 'should call #remove_member' do
        expect(instance).to receive(:add_member)
          .with('Port-Channel1', 'Ethernet3')
        subject
      end

      it 'should call #add_member' do
        expect(instance).to receive(:add_member)
          .with('Port-Channel1', 'Ethernet3')
        subject
      end
    end
  end
end
