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

describe Puppet::Type.type(:eos_interface).provider(:eos) do

  # Puppet RAL memoized methods
  let(:resource) do
    resource_hash = {
      name: 'Ethernet1',
      description: 'test interface',
      enable: :true,
      flowcontrol_send: :on,
      flowcontrol_receive: :off,
      provider: described_class.name
    }
    Puppet::Type.type(:eos_interface).new(resource_hash)
  end

  let(:provider) { resource.provider }

  def all_interfaces
    all_interfaces = Fixtures[:all_interfaces]
    return all_interfaces if all_interfaces
    file = File.join(File.dirname(__FILE__), 'fixtures/interface_get.json')
    Fixtures[:all_interfaces] = JSON.load(File.read(file))
  end

  # Stub the Api method class to obtain all interfaces.
  before :each do
    allow_message_expectations_on_nil
    allow(described_class).to receive(:eapi)
    allow(described_class.eapi).to receive(:Interface)
    allow(described_class.eapi.Interface).to receive(:get)
      .and_return(all_interfaces)
  end

  context 'class methods' do

    describe '.instances' do
      subject { described_class.instances }

      it { is_expected.to be_an Array }

      it 'has two entries' do
        expect(subject.size).to eq(2)
      end

      %w(Ethernet1 Management1).each do |name|
        it "has an instance for interface #{name}" do
          instance = subject.find { |p| p.name == name }
          expect(instance).to be_a described_class
        end
      end

      context 'eos_interface { Ethernet1: }' do
        subject { described_class.instances.find { |p| p.name == 'Ethernet1' } }

        include_examples 'provider resource methods',
                         name: 'Ethernet1',
                         description: '',
                         enable: :true,
                         flowcontrol_receive: :off,
                         flowcontrol_send: :off
      end

      context 'eos_interface { Management1: }' do
        subject { described_class.instances.find { |p| p.name == 'Management1' } }

        include_examples 'provider resource methods',
                         name: 'Management1',
                         description: '',
                         enable: :true,
                         flowcontrol_receive: :desired,
                         flowcontrol_send: :desired
      end
    end

    describe '.prefetch' do
      let :resources do
        {
          'Ethernet1' => Puppet::Type.type(:eos_interface).new(name: 'Ethernet1'),
          'Ethernet2' => Puppet::Type.type(:eos_interface).new(name: 'Ethernet2'),
          'Management1' => Puppet::Type.type(:eos_interface).new(name: 'Management1')
        }
      end
      subject { described_class.prefetch(resources) }

      it 'resource providers are absent prior to calling .prefetch' do
        resources.values.each do |rsrc|
          expect(rsrc.provider.description).to eq(:absent)
          expect(rsrc.provider.enable).to eq(:absent)
        end
      end

      it 'sets the provider instance of the managed resource' do
        subject
        %w(Ethernet1 Management1).each do |intf|
          expect(resources[intf].provider.name).to eq(intf)
        end
      end
    end
  end

  context 'resource (instance) methods' do

    let(:name) { provider.resource[:name] }
    let(:eapi) { double }

    before :each do
      allow(provider).to receive(:eapi)
      allow(provider.eapi).to receive(:Interface).and_return(eapi)
    end

    describe '#create' do
      before :each do
        allow(eapi).to receive(:create).with(name).and_return(true)
        allow(eapi).to receive(:set_shutdown).and_return(true)
        allow(eapi).to receive(:set_description).and_return(true)
        allow(eapi).to receive(:set_flowcontrol).and_return(true)
      end

      it 'calls Interface#create(name) with the resource name' do
        expect(eapi).to receive(:create).with(name)
        provider.create
      end

      it 'sets enable to the resource value' do
        provider.create
        expect(provider.enable).to eq(provider.resource[:enable])
      end

      it 'sets description to the resource value' do
        provider.create
        expect(provider.description).to eq(provider.resource[:description])
      end

      it 'sets flowcontrol_send to the resource value' do
        provider.create
        expect(provider.flowcontrol_send).to eq(provider.resource[:flowcontrol_send])
      end

      it 'sets flowcontrol_receive to the resource value' do
        provider.create
        expect(provider.flowcontrol_receive).to eq(provider.resource[:flowcontrol_receive])
      end
    end

    describe '#destroy' do
      before :each do
        allow(eapi).to receive(:create).with(name)
        allow(eapi).to receive(:set_shutdown).and_return(true)
        allow(eapi).to receive(:set_description).and_return(true)
        allow(eapi).to receive(:set_flowcontrol).and_return(true)
        allow(eapi).to receive(:delete).with(name).and_return(true)
      end

      it 'calls Interface#delete(name)' do
        expect(eapi).to receive(:delete).with(name)
        provider.destroy
      end

      context 'when the resource has been created' do
        subject do
          provider.create
          provider.destroy
        end

        it 'clears the property hash' do
          subject
          expect(provider.instance_variable_get(:@property_hash))
            .to eq(name: name, ensure: :absent)
        end
      end
    end

    describe '#description=(value)' do
      before :each do
        allow(eapi).to receive(:set_description)
          .with(name, value: 'foo')
      end

      it "calls Interface#set_description(#{name}, 'foo')" do
        expect(eapi).to receive(:set_description)
          .with(name, value: 'foo')
        provider.description = 'foo'
      end

      it 'updates description in the provider' do
        expect(provider.description).not_to eq('foo')
        provider.description = 'foo'
        expect(provider.description).to eq('foo')
      end
    end

    describe '#enable=(value)' do
      before :each do
        allow(eapi).to receive(:set_shutdown)
          .with(name, value: value)
      end

      %w(true, false).each do |val|
        let(:value) { !val }
        it "calls Interface#set_shutdown(#{name}, #{val})" do
          expect(eapi).to receive(:set_shutdown)
            .with(name, value: !val)
          provider.enable = val
        end
      end
    end

    %w(:on :off :desired).each do |val|
      describe '#flowcontrol_send=(value)' do
        before :each do
          allow(eapi).to receive(:set_flowcontrol)
            .with(name, 'send', value: val)
        end

        it "calls Interface#set_flowcontrol(#{name}, 'send', #{val})" do
          expect(eapi).to receive(:set_flowcontrol)
            .with(name, 'send', value: val)
          provider.flowcontrol_send = val
        end

        it 'updates flowcontrol_receive in the provider' do
          expect(provider.flowcontrol_receive).not_to eq(val)
          provider.flowcontrol_send = val
          expect(provider.flowcontrol_send).to eq(val)
        end
      end

      describe '#flowcontrol_receive=(value)' do
        before :each do
          allow(eapi).to receive(:set_flowcontrol)
            .with(name, 'receive', value: val)
        end

        it "calls Interface#set_flowcontrol(#{name}, 'receive', #{val})" do
          expect(eapi).to receive(:set_flowcontrol)
            .with(name, 'receive', value: val)
          provider.flowcontrol_receive = val
        end

        it 'updates flowcontrol_receive in the provider' do
          expect(provider.flowcontrol_receive).not_to eq(val)
          provider.flowcontrol_receive = val
          expect(provider.flowcontrol_receive).to eq(val)
        end
      end
    end
  end
end
