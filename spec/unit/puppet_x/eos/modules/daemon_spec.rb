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
require 'puppet_x/eos/modules/daemon'

describe PuppetX::Eos::Daemon do
  let(:eapi) { double }
  let(:instance) { PuppetX::Eos::Daemon.new eapi }

  context 'when initializing a new Daemon instance' do
    subject { instance }
    it { is_expected.to be_a_kind_of PuppetX::Eos::Daemon }
  end

  context 'with Eapi#enable' do
    before :each do
      allow(eapi).to receive(:enable)
        .with(commands, format: 'text')
        .and_return(api_response)
    end

    context '#getall' do
      subject { instance.getall }

      let(:commands) { 'show running-config section daemon' }

      let :api_response do
        dir = File.dirname(__FILE__)
        file = File.join(dir, 'fixtures/daemon_getall.json')
        JSON.load(File.read(file))
      end

      describe 'retreiving daemons from running-config' do
        it { is_expected.to be_a_kind_of Hash }

        it 'has two entries' do
          expect(subject.size).to eq 2
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
      subject { instance.create(name, command) }

      let(:commands) { ["daemon #{name}", "command #{command}"] }
      let(:api_response) { [{}, {}] }

      describe 'configure agent=foo with command=/path/to/foo' do
        before :each do
          allow(File).to receive(:executable?)
            .and_return(true)
        end

        let(:name) { 'foo' }
        let(:command) { '/path/to/foo' }

        it { is_expected.to be_truthy }
      end
    end

    context '#delete' do
      subject { instance.delete(name) }

      let(:commands) { "no daemon #{name}" }
      let(:api_response) { [{}] }

      describe 'delete agent foo from the running-config' do
        let(:name) { 'foo' }
        it { is_expected.to be_truthy }
      end
    end
  end
end
