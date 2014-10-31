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
require 'puppet_x/eos/modules/interface'

describe PuppetX::Eos::Interface do
  let(:eapi) { double }
  let(:instance) { PuppetX::Eos::Interface.new eapi }

  context 'when initializing a new Interface instance' do
    subject { instance }
    it { is_expected.to be_a_kind_of PuppetX::Eos::Interface }
  end

  context 'with Eapi#enable' do
    before :each do
      allow(eapi).to receive(:enable)
        .with(commands)
        .and_return(api_response)
    end

    context '#getall' do
      subject { instance.getall }

      describe 'retrieve all interfaces' do
        let(:commands) { ['show interfaces', 'show interfaces flowcontrol'] }

        let :api_response do
          dir = File.dirname(__FILE__)
          file = File.join(dir, 'fixtures/interface_getall.json')
          JSON.load(File.read(file))
        end

        it { is_expected.to be_a_kind_of Array }

        it 'should contain one entry' do
          expect(subject.size).to eq 1
        end

        it 'should have an entry for interfaces' do
          expect(subject[0]).to have_key 'interfaces'
        end

        it 'should have an entry for interfaceFlowControls' do
          expect(subject[0]).to have_key 'interfaceFlowControls'
        end

        it 'has interfaces with a 1:1 mapping to interfaceFlowControls' do
          subject[0]['interfaces'].keys do |intf|
            expect(subject[0]['interfaceFlowControls']).to have_key intf
          end
        end
      end
    end
  end

  context 'with Eapi#config' do
    before :each do
      allow(eapi).to receive(:config)
        .with(commands)
        .and_return(response)
    end

    context '#default' do
      subject { instance.default(name) }

      %w(Ethernet1 Ethernet1/1).each do |intf|
        describe 'default interface #{intf}' do
          let(:name) { intf }
          let(:commands) { "default interface #{name}" }
          let(:response) { [{}] }

          it { is_expected.to be_truthy }
        end
      end
    end

    context '#create' do
      subject { instance.create(name) }

      %w(Ethernet1 Ethernet1/1).each do |intf|
        context 'when the interface is physical' do
          let(:name) { intf }
          let(:commands) { "interface #{name}" }
          let(:response) { nil }

          describe 'the interface already exists' do
            it { is_expected.to be_falsey }
          end
        end
      end

      %w(Vlan124, Port-Channel10).each do |intf|
        context 'when the interface is logical' do
          let(:name) { intf }
          let(:commands) { "interface #{name}" }
          let(:response) { [{}] }

          describe 'the interface does not exist' do
            it { is_expected.to be_truthy }
          end
        end
      end
    end

    context '#delete' do
      subject { instance.delete(name) }

      %w(Ethernet1 Ethernet1/1 Management1).each do |intf|
        describe "try to delete physical interface #{intf}" do
          let(:name) { intf }
          let(:commands) { "no interface #{name}" }
          let(:response) { nil }

          it { is_expected.to be_falsey }
        end
      end

      %w(Vlan124 Port-Channel10).each do |intf|
        describe "delete logical interface #{intf}" do
          let(:name) { intf }
          let(:commands) { "no interface #{name}" }
          let(:response) { [{}] }
          it { is_expected.to be_truthy }
        end
      end
    end

    context '#set_description' do
      subject { instance.set_description(name, opts) }

      let(:opts) { { value: value, default: default } }
      let(:default) { false }
      let(:value) { nil }

      %w(Ethernet1 Ethernet1/1).each do |intf|
        describe "configure interface description for #{intf}" do
          let(:name) { intf }
          let(:value) { 'this is a test' }
          let(:commands) { ["interface #{name}", "description #{value}"] }
          let(:response) { [{}, {}] }
          it { is_expected.to be_truthy }
        end

        describe "configure default interface description #{intf}" do
          let(:name) { intf }
          let(:default) { true }
          let(:commands) { ["interface #{name}", 'default description'] }
          let(:response) { [{}, {}] }
          it { is_expected.to be_truthy }
        end

        describe "configure no interface description for #{intf}" do
          let(:name) { intf }
          let(:commands) { ["interface #{name}", 'no description'] }
          let(:response) { [{}, {}] }
          it { is_expected.to be_truthy }
        end
      end
    end

    context '#set_shutdown' do
      subject { instance.set_shutdown(name, opts) }

      let(:opts) { { value: value, default: default } }
      let(:default) { false }
      let(:value) { nil }

      %w(Ethernet1 Ethernet1/1).each do |intf|
        describe "configure shutdown=false for #{intf}" do
          let(:name) { intf }
          let(:value) { false }
          let(:commands) { ["interface #{name}", 'no shutdown'] }
          let(:response) { [{}, {}] }
          it { is_expected.to be_truthy }
        end

        describe "configure shutdown=true for #{intf}" do
          let(:name) { intf }
          let(:value) { true }
          let(:commands) { ["interface #{name}", 'shutdown'] }
          let(:response) { [{}, {}] }
          it { is_expected.to be_truthy }
        end

        describe 'configure default interface shutdown' do
          let(:name) { intf }
          let(:default) { true }
          let(:commands) { ["interface #{name}", 'default shutdown'] }
          let(:response) { [{}, {}] }
          it { is_expected.to be_truthy }
        end

        describe "negate interface shutdown for #{intf}" do
          let(:name) { intf }
          let(:commands) { ["interface #{name}", 'no shutdown'] }
          let(:response) { [{}, {}] }
          it { is_expected.to be_truthy }
        end
      end
    end

    context '#set_flowcontrol' do
      subject { instance.set_flowcontrol(name, direction, opts) }

      let(:opts) { { value: value, default: default } }
      let(:default) { false }
      let(:value) { nil }

      %w(Ethernet1 Ethernet1/1).each do |intf|
        %w(send receive).each do |direction|
          %w(on off desired).each do |state|
            describe 'configure flowcontrol on interface' do
              let(:name) { intf }
              let(:direction) { direction }
              let(:value) { state }
              let(:commands) do
                ["interface #{name}", "flowcontrol #{direction} #{state}"]
              end
              let(:response) { [{}, {}] }

              it { is_expected.to be_truthy }
            end
          end

          describe 'configuring flowcontrol default' do
            let(:name) { intf }
            let(:direction) { direction }
            let(:default) { true }
            let(:commands) do
              ["interface #{name}", "default flowcontrol #{direction}"]
            end
            let(:response) { [{}, {}] }

            it { is_expected.to be_truthy }
          end

          describe 'negating flowcontrol' do
            let(:name) { intf }
            let(:direction) { direction }
            let(:commands) do
              ["interface #{name}", "no flowcontrol #{direction}"]
            end
            let(:response) { [{}, {}] }

            it { is_expected.to be_truthy }
          end
        end
      end
    end
  end
end
