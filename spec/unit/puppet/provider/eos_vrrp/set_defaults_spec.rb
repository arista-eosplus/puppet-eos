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

# Tests the type with the minimum number of options required for the
# create to validate that the provider is setting the defaults correctly.
describe Puppet::Type.type(:eos_vrrp).provider(:eos) do
  # Puppet RAL memoized methods
  let(:resource) do
    resource_hash = {
      name: 'Vlan150:50',
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

  context 'resource (instance) methods' do
    describe '#create with minimal options set' do
      it 'sets ensure on the resource' do
        expect(api).to receive(:create).with('Vlan150', 50,
                                             preempt: true,
                                             enable: true,
                                             primary_ip: '0.0.0.0',
                                             priority: 100,
                                             ip_version: 2,
                                             timers_advertise: 1,
                                             mac_addr_adv_interval: 30,
                                             preempt_delay_min: 0,
                                             preempt_delay_reload: 0,
                                             delay_reload: 0)
        provider.create
        provider.flush
        # Don't need to check the values since they would need to
        # be set in the resource above. Just needed to validate
        # that the create call to rbeapi had the defaults set.
      end
    end

    describe '#destroy' do
      it 'sets ensure to :absent' do
        resource[:ensure] = :absent
        expect(api).to receive(:delete).with('Vlan150', 50)
        provider.destroy
        provider.flush
        expect(provider.ensure).to eq(:absent)
      end
    end
  end
end
