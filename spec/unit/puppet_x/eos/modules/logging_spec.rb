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
require 'puppet_x/eos/modules/logging'

describe PuppetX::Eos::Logging do
  let(:eapi) { double }
  let(:instance) { PuppetX::Eos::Logging.new eapi }

  context 'when initializing a new Logging instance' do
    subject { instance }
    it { is_expected.to be_a_kind_of PuppetX::Eos::Logging }
  end

  context 'with Eapi#enable' do
    before :each do
      allow(eapi).to receive(:enable)
        .with(commands, format: 'text')
        .and_return(api_response)
    end

    context '#get' do
      subject { instance.get }

      let(:commands) { 'show running-config section ^logging' }

      let :api_response do
        dir = File.dirname(__FILE__)
        file = File.join(dir, 'fixtures/logging_get.json')
        JSON.load(File.read(file))
      end

      describe 'logging settings' do
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

    context '#add_host' do
      subject { instance.add_host(value) }

      let(:commands) { "logging host #{value}" }
      let(:api_response) { [{}] }

      describe 'with ip address' do
        let(:value) { '1.2.3.4' }

        it { is_expected.to be_truthy }
      end

      describe 'with hostname' do
        let(:value) { 'syslog.example.net' }

        it { is_expected.to be_truthy }
      end
    end

    context '#remove_host' do
      subject { instance.remove_host(value) }

      let(:commands) { "no logging host #{value}" }
      let(:api_response) { [{}] }

      describe 'with ip address' do
        let(:value) { '1.2.3.4' }

        it { is_expected.to be_truthy }
      end

      describe 'with hostname' do
        let(:value) { 'syslog.example.net' }

        it { is_expected.to be_truthy }
      end
    end
  end
end
