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
      enable: true,
      flowcontrol_send: on,
      flowcontrol_receive: off,
      provider: described_class.name
    }
    Puppet::Type.type(:eos_interface).new(resource_hash)
  end

  let(:provider) { resource.provider }

  def all_interfaces
    all_interfaces = Fixtures[:all_interfaces]
    return all_interfaces if all_interfaces
    file = File.join(File.dirname(__FILE__), 'fixture_interface_get.json')
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

      %w(Ethernet1, Management1).each do |name|
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
        %w(Ethernet1, Management1).each do |intf|
          expect(resources[intf].provider.name).to eq(intf)
        end
      end

      it 'does not set the provider instance of the unmanaged resource' do
        subject
          expect(resources['Ethernet2'].provider.name).to eq(:absent)
      end
    end
  end

  context 'resource (instance) methods' do
    before do
      allow(provider).to receive(:eapi)
      allow(provider.eapi).to receive(:Interface)
    end

    describe '#create' do
      before :each do
        allow(provider.eapi.Interface).to receive(:create)
      end

      it 'calls Interface#create(name) with the resource name' do
        expect(provider.eapi.Interface).to receive(:create)
          .with(provider.resource[:name])
        provider.create
      end

      it 'sets ensure to :present' do
        provider.create
        expect(provider.ensure).to eq(:present)
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

    # describe '#destroy' do

    #   let(:id) { provider.resource[:vlanid] }

    #   before :each do
    #     allow(provider.eapi.Vlan).to receive(:add).with(id)
    #     allow(provider.eapi.Vlan).to receive(:delete).with(id)
    #     allow(provider.eapi.Vlan).to receive(:set_state)
    #     allow(provider.eapi.Vlan).to receive(:set_name)
    #     allow(provider.eapi.Vlan).to receive(:set_trunk_group)
    #   end

    #   it 'calls Eapi#delete(id)' do
    #     expect(provider.eapi.Vlan).to receive(:delete)
    #       .with(id)
    #     provider.destroy
    #   end

    #   context 'when the resource has been created' do
    #     subject do
    #       provider.create
    #       provider.destroy
    #     end

    #     it 'sets ensure to :absent' do
    #       subject
    #       expect(provider.ensure).to eq(:absent)
    #     end

    #     it 'clears the property hash' do
    #       subject
    #       expect(provider.instance_variable_get(:@property_hash))
    #         .to eq(vlanid: id, ensure: :absent)
    #     end
    #   end
    # end

    # describe '#description=(value)' do
    #   before :each do
    #     allow(provider.eapi.Vlan).to receive(:set_name)
    #       .with(id: provider.resource[:vlanid], value: 'foo')
    #   end

    #   it 'calls Eapi#set_vlan_name("100", "foo")' do
    #     expect(provider.eapi.Vlan).to receive(:set_name)
    #       .with(id: provider.resource[:vlanid], value: 'foo')
    #     provider.vlan_name = 'foo'
    #   end

    #   it 'updates vlan_name in the provider' do
    #     expect(provider.vlan_name).not_to eq('foo')
    #     provider.vlan_name = 'foo'
    #     expect(provider.vlan_name).to eq('foo')
    #   end
    # end

    # describe '#enable=(value)' do
    # end

    # describe '#flowcontrol_send=(value)' do
    #   before :each do
    #     allow(provider.eapi.Vlan).to receive(:set_trunk_group)
    #       .with(id: provider.resource[:vlanid], value: ['foo'])
    #   end

    #   it 'calls Eapi#set_trunk_group("100", ["foo"])' do
    #     expect(provider.eapi.Vlan).to receive(:set_trunk_group)
    #       .with(id: provider.resource[:vlanid], value: ['foo'])
    #     provider.trunk_groups = ['foo']
    #   end

    #   it 'updates trunk_groups in the provider' do
    #     expect(provider.trunk_groups).not_to eq(['foo'])
    #     provider.trunk_groups = ['foo']
    #     expect(provider.trunk_groups).to eq(['foo'])
    #   end
    # end

    # describe '#flowcontrol_receive=(value)' do
    #   context 'when value is :true' do
    #     before :each do
    #       allow(provider.eapi.Vlan).to receive(:set_state)
    #         .with(id: provider.resource[:vlanid], value: 'active')
    #     end

    #     it 'calls Eapi#set_enable("100", "active")' do
    #       expect(provider.eapi.Vlan).to receive(:set_state)
    #         .with(id: provider.resource[:vlanid], value: 'active')
    #       provider.enable = true
    #     end
    #   end

    #   context 'when value is :false' do
    #     before :each do
    #       allow(provider.eapi.Vlan).to receive(:set_state)
    #         .with(id: provider.resource[:vlanid], value: 'suspend')
    #     end

    #     it 'updates enable in the provider' do
    #       expect(provider.enable).not_to be_falsey
    #       provider.enable = false
    #       expect(provider.enable).to be_falsey
    #     end
    #   end
    # end
  end
end
