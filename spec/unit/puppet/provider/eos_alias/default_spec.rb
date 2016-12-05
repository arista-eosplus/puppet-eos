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

describe Puppet::Type.type(:eos_alias).provider(:eos) do
  # rubocop:disable Metrics/MethodLength
  def load_default_settings
    @name = 'Alias'
    @command = 'a command'
    @ensure = :present
  end

  # Puppet RAL memoized methods
  let(:resource) do
    load_default_settings
    resource_hash = {
      name: @name,
      command: @command,
      ensure: :present,
      provider: described_class.name
    }
    Puppet::Type.type(:eos_alias).new(resource_hash)
  end

  let(:provider) { resource.provider }

  let(:api) { double('alias') }

  def alia
    alia = Fixtures[:alias]
    return alia if alia
    fixture('alias', dir: File.dirname(__FILE__))
  end

  before :each do
    allow(described_class.node).to receive(:api).with('alias').and_return(api)
    allow(provider.node).to receive(:api).with('alias').and_return(api)
    load_default_settings
  end

  context 'class methods' do
    before { allow(api).to receive(:getall).and_return(alia) }

    describe '.instances' do
      subject { described_class.instances }

      it { is_expected.to be_an Array }

      it 'has two entry' do
        expect(subject.size).to eq(2)
      end

      context 'eos_alias { Alias }' do
        subject { described_class.instances.find { |p| p.name == @name } }
      end
    end

    describe '.prefetch' do
      let :resources do
        {
          'Alias' => Puppet::Type.type(:eos_alias).new(name: @name),
          'Alias2' => Puppet::Type.type(:eos_alias).new(name: 'Alias2')
        }
      end

      subject { described_class.prefetch(resources) }

      it 'resource providers are absent prior to calling .prefetch' do
        resources.values.each do |rsrc|
          expect(rsrc.provider.command).to eq(:absent)
        end
      end

      it 'sets the provider instance of the managed resource Alias' do
        subject
        expect(resources['Alias'].provider.name).to eq(@name)
      end

      it 'does not set the provider instance of the unmanaged resource' do
        subject
        expect(resources['Alias2'].provider.command).to eq(:absent)
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
          allow(api).to receive(:getall).and_return(alia)
          described_class.instances.first
        end
        it { is_expected.to be_truthy }
      end
    end
  end

  context 'resource (instance) methods' do
    describe '#create' do
      it 'sets ensure on the resource' do
        expect(api).to receive(:create).with(resource[:name],
                                             name: @name,
                                             command: @command)
        provider.create
        provider.command = @command
        provider.flush
        expect(provider.command).to eq(@command)
      end
    end

    describe '#command=(value)' do
      it 'sets command on the resource' do
        expect(api).to receive(:create).with(resource[:name],
                                             name: @name,
                                             command: @command)
        provider.create
        provider.command = 'a command'
        provider.flush
        expect(provider.command).to eq('a command')
      end
    end

    describe '#destroy' do
      it 'sets ensure to :absent' do
        resource[:ensure] = :absent
        expect(api).to receive(:delete)
        provider.destroy
        provider.flush
        expect(provider.ensure).to eq(:absent)
      end
    end
  end
end
