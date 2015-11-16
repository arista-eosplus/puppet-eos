#
# Copyright (c) 2015, Arista Networks, Inc.
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

include FixtureHelpers

describe Puppet::Type.type(:eos_vrrp).provider(:eos) do
  def load_default_settings
    @secondary_ip = ['1.2.3.4', '40.10.5.42']
    @track = [{ name: 'Ethernet3', action: 'decrement', amount: 33 },
              { name: 'Ethernet2', action: 'decrement', amount: 22 },
              { name: 'Ethernet2', action: 'shutdown' }]
    @track_string_keys = []
    @track.each do |hash|
      hash_string_keys = {}
      hash.each { |k, v| hash_string_keys[k.to_s] = v }
      @track_string_keys << hash_string_keys
    end
  end
  before(:all) { load_default_settings }

  # Puppet RAL memoized methods
  let(:resource) do
    resource_hash = {
      name: 'Vlan150:40',
      preempt: :false,
      enable: :true,
      primary_ip: '40.10.5.32',
      priority: 200,
      description: 'The description',
      secondary_ip: @secondary_ip,
      ip_version: 2,
      timers_advertise: 100,
      mac_addr_adv_interval: 101,
      preempt_delay_min: 102,
      preempt_delay_reload: 103,
      delay_reload: 104,
      track: @track_string_keys,
      ensure: :present,
      provider: described_class.name
    }
    Puppet::Type.type(:eos_vrrp).new(resource_hash)
  end

  let(:provider) { resource.provider }

  let(:api) { double('vrrp') }

  def vrrp
    vrrp = Fixtures[:vrrp]
    return vrrp if vrrp
    fixture('vrrp', dir: File.dirname(__FILE__))
  end

  before :each do
    allow(described_class.node).to receive(:api).with('vrrp').and_return(api)
    allow(provider.node).to receive(:api).with('vrrp').and_return(api)
  end

  context 'class methods' do
    before { allow(api).to receive(:getall).and_return(vrrp) }

    describe '.instances' do
      subject { described_class.instances }

      it { is_expected.to be_an Array }

      it 'has one entry' do
        expect(subject.size).to eq(5)
      end

      it 'has an instance Vlan150:40' do
        instance = subject.find { |p| p.name == 'Vlan150:40' }
        expect(instance).to be_a described_class
      end

      context 'eos_vrrp { Vlan150:40 }' do
        subject do
          described_class.instances.find { |p| p.name == 'Vlan150:40' }
        end

        # Note that track is not checked here because passing in
        # @track_string_keys as a value was not working.
        include_examples 'provider resource methods',
                         name: 'Vlan150:40',
                         preempt: :false,
                         enable: :true,
                         primary_ip: '40.10.5.32',
                         priority: '200',
                         description: 'The description',
                         secondary_ip: ['1.2.3.4', '40.10.5.42'],
                         ip_version: '2',
                         timers_advertise: '100',
                         mac_addr_adv_interval: '101',
                         preempt_delay_min: '102',
                         preempt_delay_reload: '103',
                         delay_reload: '104'
      end
    end

    describe '.prefetch' do
      let :resources do
        {
          'Vlan150:40' => Puppet::Type.type(:eos_vrrp).new(name: 'Vlan150:40'),
          'Vlan150:90' => Puppet::Type.type(:eos_vrrp).new(name: 'Vlan150:90')
        }
      end

      subject { described_class.prefetch(resources) }

      it 'resource providers are absent prior to calling .prefetch' do
        resources.values.each do |rsrc|
          expect(rsrc.provider.primary_ip).to eq(:absent)
          expect(rsrc.provider.priority).to eq(:absent)
          expect(rsrc.provider.timers_advertise).to eq(:absent)
          expect(rsrc.provider.preempt).to eq(:absent)
          expect(rsrc.provider.enable).to eq(:absent)
          expect(rsrc.provider.secondary_ip).to eq(:absent)
          expect(rsrc.provider.description).to eq(:absent)
          expect(rsrc.provider.track).to eq(:absent)
          expect(rsrc.provider.ip_version).to eq(:absent)
          expect(rsrc.provider.mac_addr_adv_interval).to eq(:absent)
          expect(rsrc.provider.preempt_delay_min).to eq(:absent)
          expect(rsrc.provider.preempt_delay_reload).to eq(:absent)
          expect(rsrc.provider.delay_reload).to eq(:absent)
        end
      end

      it 'sets the provider instance of the managed resource Vlan150:40' do
        subject
        expect(resources['Vlan150:40'].provider.name).to eq('Vlan150:40')
        expect(resources['Vlan150:40'].provider.primary_ip).to eq('40.10.5.32')
        expect(resources['Vlan150:40'].provider.priority).to eq('200')
        expect(resources['Vlan150:40'].provider.timers_advertise).to eq('100')
        expect(resources['Vlan150:40'].provider.preempt).to eq(:false)
        expect(resources['Vlan150:40'].provider.enable).to eq(:true)
        expect(resources['Vlan150:40'].provider.secondary_ip)
          .to eq(@secondary_ip)
        expect(resources['Vlan150:40'].provider.description)
          .to eq('The description')
        expect(resources['Vlan150:40'].provider.track).to eq(@track_string_keys)
        expect(resources['Vlan150:40'].provider.ip_version).to eq('2')
        expect(resources['Vlan150:40'].provider.mac_addr_adv_interval)
          .to eq('101')
        expect(resources['Vlan150:40'].provider.preempt_delay_min)
          .to eq('102')
        expect(resources['Vlan150:40'].provider.preempt_delay_reload)
          .to eq('103')
        expect(resources['Vlan150:40'].provider.delay_reload).to eq('104')
      end

      it 'does not set the provider instance of the unmanaged resource' do
        subject
        expect(resources['Vlan150:90'].provider.primary_ip).to eq(:absent)
        expect(resources['Vlan150:90'].provider.priority).to eq(:absent)
        expect(resources['Vlan150:90'].provider.timers_advertise).to eq(:absent)
        expect(resources['Vlan150:90'].provider.preempt).to eq(:absent)
        expect(resources['Vlan150:90'].provider.enable).to eq(:absent)
        expect(resources['Vlan150:90'].provider.secondary_ip).to eq(:absent)
        expect(resources['Vlan150:90'].provider.description).to eq(:absent)
        expect(resources['Vlan150:90'].provider.track).to eq(:absent)
        expect(resources['Vlan150:90'].provider.ip_version).to eq(:absent)
        expect(resources['Vlan150:90'].provider.mac_addr_adv_interval)
          .to eq(:absent)
        expect(resources['Vlan150:90'].provider.preempt_delay_min)
          .to eq(:absent)
        expect(resources['Vlan150:90'].provider.preempt_delay_reload)
          .to eq(:absent)
        expect(resources['Vlan150:90'].provider.delay_reload).to eq(:absent)
      end
    end
  end

  context 'resource exists method' do
    describe '#exists?' do
      subject { provider.exists? }

      context 'when the resource does not exist on the system' do
        it { is_expected.to be_falsey }
      end

      context 'when the resource exists on the system' do
        let(:provider) do
          allow(api).to receive(:getall).and_return(vrrp)
          described_class.instances.first
        end
        it { is_expected.to be_truthy }
      end
    end
  end

  context 'resource (instance) methods' do
    describe '#create with all options set' do
      it 'sets ensure on the resource' do
        expect(api).to receive(:create).with('Vlan150', 40,
                                             preempt: false,
                                             enable: true,
                                             primary_ip: '40.10.5.32',
                                             priority: 200,
                                             description: 'The description',
                                             secondary_ip: @secondary_ip,
                                             ip_version: 2,
                                             timers_advertise: 100,
                                             mac_addr_adv_interval: 101,
                                             preempt_delay_min: 102,
                                             preempt_delay_reload: 103,
                                             delay_reload: 104,
                                             track: @track)
        provider.create
        provider.preempt = :false
        provider.enable = :true
        provider.primary_ip = '40.10.5.32'
        provider.priority = 200
        provider.description = 'The description'
        provider.secondary_ip = @secondary_ip
        provider.ip_version = 2
        provider.timers_advertise = 100
        provider.mac_addr_adv_interval = 101
        provider.preempt_delay_min = 102
        provider.preempt_delay_reload = 103
        provider.delay_reload = 104
        provider.track = @track
        provider.flush
        expect(provider.preempt).to eq(:false)
        expect(provider.enable).to eq(:true)
        expect(provider.primary_ip).to eq('40.10.5.32')
        expect(provider.priority).to eq(200)
        expect(provider.description).to eq('The description')
        expect(provider.secondary_ip).to eq(@secondary_ip)
        expect(provider.ip_version).to eq(2)
        expect(provider.timers_advertise).to eq(100)
        expect(provider.mac_addr_adv_interval).to eq(101)
        expect(provider.preempt_delay_min).to eq(102)
        expect(provider.preempt_delay_reload).to eq(103)
        expect(provider.delay_reload).to eq(104)
        expect(provider.track).to eq(@track)
      end
    end

    describe '#destroy' do
      it 'sets ensure to :absent' do
        resource[:ensure] = :absent
        expect(api).to receive(:delete).with('Vlan150', 40)
        provider.destroy
        provider.flush
        expect(provider.ensure).to eq(:absent)
      end
    end
  end
end
