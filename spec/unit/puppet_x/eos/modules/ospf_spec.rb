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
require 'puppet_x/eos/modules/ospf'

describe PuppetX::Eos::Ospf do
  let(:eapi) { double }
  let(:instance) { PuppetX::Eos::Ospf.new eapi }

  context 'when initializing a new Ospf instance' do
    subject { instance }
    it { is_expected.to be_a_kind_of PuppetX::Eos::Ospf }
  end

  context 'with Eapi#enable' do
    before :each do
      allow(eapi).to receive(:enable)
        .with(commands)
        .and_return(api_response)
    end

    context '#getall' do
      subject { instance.getall }

      describe 'retrieve all instances of ospf' do
        let(:commands) { 'show ip ospf' }

        let :api_response do
          dir = File.dirname(__FILE__)
          file = File.join(dir, 'fixtures/ospf_instance_getall.json')
          JSON.load(File.read(file))
        end

        it { is_expected.to be_a_kind_of Hash}
        it { is_expected.to have_key :instances }
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

      describe 'configure ospf instance id 1' do
        let(:name) { '1' }
        let(:commands) { "router ospf #{name}" }
        let(:api_response) { [{}] }

        it { is_expected.to be_truthy }
      end
    end

    context '#delete' do
      subject { instance.delete(name) }

      describe "negate ospf instance id 1" do
        let(:name) { '1' }
        let(:commands) { "no router ospf #{name}" }
        let(:api_response) { [{}] }

        it { is_expected.to be_truthy }
      end
    end

    context '#default' do
      subject { instance.default(name) }

      describe 'default ospf instance 1' do
        let(:name) { '1' }
        let(:commands) { "default router ospf #{name}" }
        let(:api_response) { [{}] }

        it { is_expected.to be_truthy }
      end
    end

    context '#set_router_id' do
      subject { instance.set_router_id(name, opts) }

      let(:opts) { {value: value, default: default} }
      let(:default) { false }
      let(:value) { nil }

      describe "configure router id for ospf instance 1" do
        let(:name) { '1' }
        let(:value) { '1.1.1.1' }
        let(:commands) { ["router ospf #{name}", "router-id #{value}"] }
        let(:api_response) { [{}, {}] }
        it { is_expected.to be_truthy }
      end

      describe "default router id for ospf instance 1" do
        let(:name) { '1' }
        let(:default) { true }
        let(:commands) { ["router ospf #{name}", "default router-id"] }
        let(:api_response) { [{}, {}] }
        it { is_expected.to be_truthy }
      end

      describe "negate router id for ospf instance 1" do
        let(:name) { '1' }
        let(:commands) { ["router ospf #{name}", "no router-id"] }
        let(:api_response) { [{}, {}] }
        it { is_expected.to be_truthy }
      end
    end
  end
end
