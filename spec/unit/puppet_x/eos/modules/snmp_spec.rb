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
require 'puppet_x/eos/modules/snmp'

describe PuppetX::Eos::Snmp do
  let(:eapi) { double }
  let(:instance) { PuppetX::Eos::Snmp.new eapi }

  context 'when initializing a new Snmp instance' do
    subject { instance }
    it { is_expected.to be_a_kind_of PuppetX::Eos::Snmp }
  end

  context 'with Eapi#enable' do
    before :each do
      allow(eapi).to receive(:enable)
        .with(commands, format: 'text')
        .and_return(api_response)
    end

    context '#get' do
      subject { instance.get }

      let(:commands) { ['show snmp contact',
                        'show snmp location',
                        'show snmp chassis',
                        'show snmp source-interface'] }

      let :api_response do
        dir = File.dirname(__FILE__)
        file = File.join(dir, 'fixture_snmp_get.json')
        JSON.load(File.read(file))
      end

      describe 'snmp configuration' do
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

    context '#set_contact' do
      subject { instance.set_contact(opts) }

      let(:opts) { {value: value, default: default} }
      let(:default) { false }
      let(:value) { nil }

      describe "configure snmp contact" do
        let(:value) { 'foo' }
        let(:commands) { "snmp contact #{value}" }
        let(:api_response) { [{}] }

        it {is_expected.to be_truthy }
      end

      describe "negate snmp contact" do
        let(:commands) { 'no snmp contact' }
        let(:api_response) { [{}] }

        it {is_expected.to be_truthy }
      end

      describe "default snmp contact" do
        let(:default) { true }
        let(:commands) { 'default snmp contact' }
        let(:api_response) { [{}] }

        it {is_expected.to be_truthy }
      end
    end

    context '#set_location' do
      subject { instance.set_location(opts) }

      let(:opts) { {value: value, default: default} }
      let(:default) { false }
      let(:value) { nil }

      describe "configure snmp location" do
        let(:value) { 'foo' }
        let(:commands) { "snmp location #{value}" }
        let(:api_response) { [{}] }

        it {is_expected.to be_truthy }
      end

      describe "negate snmp location" do
        let(:commands) { 'no snmp location' }
        let(:api_response) { [{}] }

        it {is_expected.to be_truthy }
      end

      describe "default snmp location" do
        let(:default) { true }
        let(:commands) { 'default snmp location' }
        let(:api_response) { [{}] }

        it {is_expected.to be_truthy }
      end
    end

    context '#set_chassis_id' do
      subject { instance.set_chassis_id(opts) }

      let(:opts) { {value: value, default: default} }
      let(:default) { false }
      let(:value) { nil }

      describe "configure snmp chassis id" do
        let(:value) { 'foo' }
        let(:commands) { "snmp chassis #{value}" }
        let(:api_response) { [{}] }

        it {is_expected.to be_truthy }
      end

      describe "negate snmp chassis id" do
        let(:commands) { 'no snmp chassis' }
        let(:api_response) { [{}] }

        it {is_expected.to be_truthy }
      end

      describe "default snmp chassis id" do
        let(:default) { true }
        let(:commands) { 'default snmp chassis' }
        let(:api_response) { [{}] }

        it {is_expected.to be_truthy }
      end
    end

    context '#set_source_interface' do
      subject { instance.set_source_interface(opts) }

      let(:opts) { {value: value, default: default} }
      let(:default) { false }
      let(:value) { nil }

      describe "configure snmp source-interface" do
        let(:value) { 'Loopback0' }
        let(:commands) { "snmp source-interface #{value}" }
        let(:api_response) { [{}] }

        it {is_expected.to be_truthy }
      end

      describe "negate snmp source-interface" do
        let(:commands) { 'no snmp source-interface' }
        let(:api_response) { [{}] }

        it {is_expected.to be_truthy }
      end

      describe "default snmp source-interface" do
        let(:default) { true }
        let(:commands) { 'default snmp source-interface' }
        let(:api_response) { [{}] }

        it {is_expected.to be_truthy }
      end
    end
  end
end
