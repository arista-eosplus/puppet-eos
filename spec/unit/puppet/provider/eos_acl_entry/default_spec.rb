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

describe Puppet::Type.type(:eos_acl_entry).provider(:eos) do
  # Puppet RAL memoized methods
  let(:resource) do
    resource_hash = {
      name: 'test1:10',
      ensure: :present,
      acltype: :standard,
      action: :permit,
      srcaddr: '1.2.3.0',
      srcprefixlen: 8,
      log: :true,
      provider: described_class.name
    }
    Puppet::Type.type(:eos_acl_entry).new(resource_hash)
  end

  let(:provider) { resource.provider }

  let(:api) { double('acl_entry') }

  def acl_entry
    acl_entry = Fixtures[:acl_entry]
    return acl_entry if acl_entry
    fixture('acl_entry', dir: File.dirname(__FILE__))
  end

  before :each do
    allow(described_class.node).to receive(:api).with('acl').and_return(api)
    allow(provider.node).to receive(:api).with('acl').and_return(api)
  end

  context 'class methods' do
    before { allow(api).to receive(:getall).and_return(acl_entry) }

    describe '.instances' do
      subject { described_class.instances }

      it { is_expected.to be_an Array }

      it 'has four entries' do
        expect(subject.size).to eq 4
      end

      it 'has an instance for test1 and test2 entries' do
        %w(test1:10 test1:20 test2:10 test2:20 ).each do |name|
          instance = subject.find { |p| p.name == name }
          expect(instance).to be_a described_class
        end
      end

      context 'eos_acl_entry { test1:10 }' do
        subject { described_class.instances.find { |p| p.name == 'test1:10' } }

        include_examples 'provider resource methods',
                         acltype: :standard,
                         action: :permit,
                         srcaddr: 'host 1.2.3.4',
                         srcprefixlen: :absent,
                         log: :true
      end
    end

    describe '.prefetch' do
      let :resources do
        {
          'test1:10' => Puppet::Type.type(:eos_acl_entry).new(name: 'test1:10'),
          'test2:10' => Puppet::Type.type(:eos_acl_entry).new(name: 'test2:10'),
          'test3:10' => Puppet::Type.type(:eos_acl_entry).new(name: 'test3:10')
        }
      end

      subject { described_class.prefetch(resources) }

      it 'resource providers are absent prior to calling .prefetch' do
        resources.values.each do |rsrc|
          expect(rsrc.provider.acltype).to eq(:absent)
          expect(rsrc.provider.action).to eq(:absent)
          expect(rsrc.provider.srcaddr).to eq(:absent)
          expect(rsrc.provider.srcprefixlen).to eq(:absent)
          expect(rsrc.provider.log).to eq(:absent)
        end
      end

      it 'sets the provider instance of the managed resource test1' do
        subject
        expect(resources['test1:10'].provider.acltype).to eq(:standard)
        expect(resources['test1:10'].provider.action).to eq(:permit)
        expect(resources['test1:10'].provider.srcaddr).to eq('host 1.2.3.4')
        expect(resources['test1:10'].provider.srcprefixlen).to be_truthy
        expect(resources['test1:10'].provider.log).to be_truthy
      end

      it 'sets the provider instance of the managed resource test2' do
        subject
        expect(resources['test2:10'].provider.acltype).to eq(:standard)
        expect(resources['test2:10'].provider.action).to eq(:deny)
        expect(resources['test2:10'].provider.srcaddr).to eq('1.2.3.0')
        expect(resources['test2:10'].provider.srcprefixlen).to eq(8)
        expect(resources['test2:10'].provider.log).to eq(:false)
      end

      it 'does not set the provider instance of the unmanaged resource' do
        subject
        expect(resources['test3:10'].provider.acltype).to eq(:absent)
        expect(resources['test3:10'].provider.action).to eq(:absent)
        expect(resources['test3:10'].provider.srcaddr).to eq(:absent)
        expect(resources['test3:10'].provider.srcprefixlen).to eq(:absent)
        expect(resources['test3:10'].provider.log).to eq(:absent)
      end
    end
  end

  context 'resource (instance) methods' do
    describe '#exists?' do
      subject { provider.exists? }

      context 'when the resource does not exist on the system' do
        it { is_expected.to be_falsey }
      end

      context 'when the resource exists on the system' do
        let(:provider) do
          allow(api).to receive(:getall).and_return(acl_entry)
          described_class.instances.first
        end
        it { is_expected.to be_truthy }
      end
    end

    describe '#create' do
      before do
        update_values = resource.to_hash
        update_values[:seqno] = 10
        expect(api).to receive(:update_entry).with('test1', update_values)
        allow(api).to receive_messages(
          acltype: true,
          action: true,
          srcaddr: true,
          srcprefixlen: true,
          log: true
        )
      end

      it 'sets ensure on the resource' do
        provider.create
        provider.flush
        expect(provider.ensure).to eq(:present)
      end

      it 'sets acltype on the resource' do
        provider.create
        provider.flush
        expect(provider.acltype).to eq(:standard)
      end

      it 'sets action on the resource' do
        provider.create
        provider.flush
        expect(provider.action).to eq(:permit)
      end

      it 'sets srcaddr on the resource' do
        provider.create
        provider.flush
        expect(provider.srcaddr).to eq('1.2.3.0')
      end

      it 'sets srcprefixlen on the resource' do
        provider.create
        provider.flush
        expect(provider.srcprefixlen).to eq(8)
      end

      it 'sets log on the resource' do
        provider.create
        provider.flush
        expect(provider.log).to eq(:true)
      end
    end

    describe '#destroy' do
      it 'sets ensure to :absent' do
        resource[:ensure] = :absent
        expect(api).to receive(:remove_entry).with('test1', 10)
        provider.destroy
        provider.flush
        expect(provider.ensure).to eq(:absent)
      end
    end
  end
end
