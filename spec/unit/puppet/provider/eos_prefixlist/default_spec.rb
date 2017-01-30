#
# Copyright (c) 2016, Arista Networks, Inc.
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

describe Puppet::Type.type(:eos_prefixlist).provider(:eos) do
  def load_default_settings
    @name = 'test:10'
    @prefix_list = 'test'
    @seqno = 10
    @action = :permit
    @prefix = '10.10.0.0'
    @masklen = 16
  end

  let(:resource) do
    load_default_settings
    resource_hash = {
      name: @name,
      prefix_list: @prefix_list,
      # seqno: @seqno,
      action: @action,
      prefix: @prefix,
      masklen: @masklen,
      provider: described_class.name
    }
    Puppet::Type.type(:eos_prefixlist).new(resource_hash)
  end

  let(:provider) { resource.provider }

  let(:api) { double('prefixlists') }

  def prefixlists
    prefixlists = Fixtures[:prefixlist]
    return prefixlists if prefixlists
    fixture('prefixlist', dir: File.dirname(__FILE__))
  end

  before :each do
    allow(described_class.node).to receive(:api).with('prefixlists')
      .and_return(api)
    allow(provider.node).to receive(:api).with('prefixlists')
      .and_return(api)
    load_default_settings
  end

  context 'class methods' do
    before { allow(api).to receive(:getall).and_return(prefixlists) }

    describe '.instances' do
      subject { described_class.instances }

      it { is_expected.to be_an Array }

      it 'has five entries' do
        expect(subject.size).to eq(5)
      end

      it 'has an instance test:10' do
        instance = subject.find { |p| p.name == @name }
        expect(instance).to be_a described_class
      end

      context 'eos_prefixlist { test }' do
        subject { described_class.instances.find { |p| p.name == @name } }

        include_examples 'provider resource methods',
                         seqno: 10,
                         action: 'permit',
                         prefix: '10.10.0.0',
                         masklen: 16
      end
    end

    describe '.prefetch' do
      let(:resources) do
        {
          'test:10' => Puppet::Type.type(:eos_prefixlist).new(name: 'test:10'),
          'test:20' => Puppet::Type.type(:eos_prefixlist).new(name: 'test:20'),
          'test:30' => Puppet::Type.type(:eos_prefixlist).new(name: 'test:30'),
          'test:40' => Puppet::Type.type(:eos_prefixlist).new(name: 'test:40'),
          'test1:10' => Puppet::Type.type(:eos_prefixlist).new(name: 'test1:10')
        }
      end

      it 'resource providers are absent prior to calling .prefetch' do
        resources.values.each do |rsrc|
          expect(rsrc.provider.seqno).to eq(:absent)
          expect(rsrc.provider.action).to eq(:absent)
          expect(rsrc.provider.prefix).to eq(:absent)
        end
      end

      context 'provider instance managed resources' do
        subject(:rules) { described_class.prefetch(resources) }

        include_examples 'provider resource properties',
                         name: 'test:10', seqno: 10, action: 'permit',
                         prefix: '10.10.0.0', masklen: 16,
                         eq: :absent, ge: :absent, le: :absent

        include_examples 'provider resource properties',
                         name: 'test:20', seqno: 20, action: 'deny',
                         prefix: '10.20.0.0', masklen: 16,
                         eq: :absent, ge: :absent, le: :absent

        include_examples 'provider resource properties',
                         name: 'test:30', seqno: 30, action: 'permit',
                         prefix: '10.30.0.0', masklen: 24,
                         eq: 26, ge: :absent, le: :absent

        include_examples 'provider resource properties',
                         name: 'test:40', seqno: 40, action: 'permit',
                         prefix: '10.40.0.0', masklen: 16,
                         eq: :absent, ge: 18, le: 28

        include_examples 'provider resource properties',
                         name: 'test1:10', seqno: 10, action: 'permit',
                         prefix: '1.10.10.0', masklen: 24,
                         eq: :absent, ge: :absent, le: :absent
      end
    end

    it 'fails namevar check when no seqno' do
      expect { Puppet::Type.type(:eos_prefixlist).new(name: 'testx') }
        .to raise_error(Puppet::ResourceError)
    end

    it 'fails namevar check when seqno not integer' do
      expect { Puppet::Type.type(:eos_prefixlist).new(name: 'testx:10O') }
        .to raise_error(Puppet::ResourceError)
    end
  end

  context 'resource method exists' do
    describe '#exists?' do
      subject { provider.exists? }

      it 'is false when the resource does not exist' do
        expect(subject).to be_falsey
      end

      context 'when the resource exists' do
        let(:provider) do
          allow(api).to receive(:getall).and_return(prefixlists)
          described_class.instances.first
        end
        it { is_expected.to be_truthy }
      end
    end
  end

  context 'instance methods' do
    describe '#create' do
      it 'creates a new rule when ensure :present' do
        resource[:ensure] = :present
        expect(api).to receive(:add_rule).with(@prefix_list,
                                               @action,
                                               "#{@prefix}/#{@masklen}",
                                               @seqno)
        provider.create
        provider.flush
        expect(provider.name).to eq(@name)
        expect(provider.seqno).to eq(@seqno)
        expect(provider.action).to eq(@action)
        expect(provider.prefix_list).to eq(@prefix_list)
        expect(provider.prefix).to eq(@prefix)
        expect(provider.ensure).to eq(:present)
      end

      let(:new_resource) do
        resource_hash = {
          name: 'test99:99',
          ensure: :present,
          action: :permit,
          prefix: '99.99.0.0',
          masklen: 16
        }
        Puppet::Type.type(:eos_prefixlist).new(resource_hash)
      end

      it 'extracts seqno and prefix_list from name' do
        allow(new_resource.provider.node).to receive(:api).with('prefixlists')
          .and_return(api)
        expect(api).to receive(:add_rule).with('test99', :permit,
                                               '99.99.0.0/16', 99)
        new_resource.provider.create
        new_resource.provider.flush
        expect(new_resource.provider.seqno).to eq(99)
        expect(new_resource.provider.prefix_list).to eq('test99')
      end
    end

    describe '#destroy' do
      it 'deletes a rule when ensure :absent' do
        resource[:ensure] = :absent
        expect(api).to receive(:delete).with('test', 10)
        provider.destroy
        provider.flush
        expect(provider.ensure).to eq(:absent)
      end
    end

    describe '#*=(val)' do
      it 'sets resource attributes' do
        expect(api).to receive(:add_rule).with('testme', :permit,
                                               '10.10.0.0/16', 99)
        provider.create
        provider.prefix_list = 'testme'
        provider.seqno = 99
        provider.action = :deny
        provider.prefix = '10.255.0.0'
        provider.masklen = 20
        provider.eq = 22
        provider.ge = 24
        provider.le = 28
        provider.flush
        expect(provider.prefix_list).to eq('testme')
        expect(provider.seqno).to eq(99)
        expect(provider.action).to eq(:deny)
        expect(provider.prefix).to eq('10.255.0.0')
        expect(provider.masklen).to eq(20)
        expect(provider.eq).to eq(22)
        expect(provider.ge).to eq(24)
        expect(provider.le).to eq(28)
      end
    end
  end
end
