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

describe Puppet::Type.type(:eos_extension).provider(:eos) do
  # Puppet RAL memoized methods
  let(:resource) do
    resource_hash = {
      ensure: :present,
      name: 'puppet.rpm',
      provider: described_class.name
    }
    Puppet::Type.type(:eos_extension).new(resource_hash)
  end

  let(:provider) { resource.provider }
  let(:eapi) { double }

  def extensions
    extensions = Fixtures[:all_extensions]
    return extensions if extensions
    file = File.join(File.dirname(__FILE__), 'fixtures/extensions.json')
    Fixtures[:extensions] = JSON.load(File.read(file))
  end

  # Stub the Api method class to obtain all vlans.
  before :each do
    allow_message_expectations_on_nil
    allow(described_class).to receive(:eapi)
    allow(described_class.eapi).to receive(:Extension).and_return(eapi)
    allow(eapi).to receive(:getall)
      .and_return(extensions)
    allow(eapi).to receive(:autoload?)
      .and_return(true)
  end

  context 'class methods' do
    describe '.instances' do
      subject { described_class.instances }

      it { is_expected.to be_an Array }

      it 'has two entries' do
        expect(subject.size).to eq(2)
      end

      %w(ruby-1.9.3-1.swix puppet-3.7.1-2-ruby1.swix).each do |name|
        it "has an instance for extension #{name}" do
          instance = subject.find { |p| p.name == name }
          expect(instance).to be_a described_class
        end
      end

      context 'eos_extension { ruby-1.9.3-1.swix: }' do
        subject do
          described_class.instances.find do |p|
            p.name == 'ruby-1.9.3-1.swix'
          end
        end

        include_examples 'provider resource methods',
                         ensure: :present,
                         autoload: :true
      end

      context 'eos_extension { puppet-3.7.1-2-ruby1.swix: }' do
        subject do
          described_class.instances.find do |p|
            p.name == 'puppet-3.7.1-2-ruby1.swix'
          end
        end

        include_examples 'provider resource methods',
                         ensure: :present,
                         autoload: :true
      end
    end

    describe '.prefetch' do
      let :resources do
        {
          'ruby-1.9.3-1.swix' => Puppet::Type.type(:eos_extension)
            .new(name: 'ruby-1.9.3-1.swix'),
          'puppet-3.7.1-2-ruby1.swix' => Puppet::Type.type(:eos_extension)
            .new(name: 'puppet-3.7.1-2-ruby1.swix'),
          'dummy.rpm' => Puppet::Type.type(:eos_extension)
            .new(name: 'dummy.rpm')
        }
      end
      subject { described_class.prefetch(resources) }

      it 'sets the provider instance of the managed resource' do
        subject
        %w(ruby-1.9.3-1.swix puppet-3.7.1-2-ruby1.swix).each do |ext|
          expect(resources[ext].provider.name).to eq(ext)
          expect(resources[ext].provider.autoload).to eq(:true)
          expect(resources[ext].provider.exists?).to eq(true)
        end
      end

      it 'does not set the provider instance of the unmanaged resource' do
        subject
        expect(resources['dummy.rpm'].provider.autoload).to eq(:absent)
        expect(resources['dummy.rpm'].provider.force).to eq(:absent)
        expect(resources['dummy.rpm'].provider.exists?).to eq(false)
      end
    end
  end

  context 'resource (instance) methods' do
    let(:eapi) { double }

    before do
      allow(provider).to receive(:eapi)
      allow(provider.eapi).to receive(:Extension).and_return(eapi)
      allow(eapi).to receive(:autoload?).and_return(true)
    end

    describe '#exists?' do
      subject { provider.exists? }

      context 'when the resource does not exist on the system' do
        it { is_expected.to be_falsey }
      end

      context 'when the resource exists on the system' do
        let(:provider) { described_class.instances.first }
        it { is_expected.to be_truthy }
      end
    end

    describe '#create' do
      let(:name) { provider.resource[:name] }

      before :each do
        allow(eapi).to receive(:install)
      end

      it 'calls Extension#install(name) with the extensions name' do
        expect(provider.eapi.Extension).to receive(:install)
          .with(name, nil)
        provider.create
      end

      it 'sets ensure to :present' do
        provider.create
        expect(provider.ensure).to eq(:present)
      end

      it 'sets autoload to the resource value' do
        provider.create
        expect(provider.autoload).to eq(:absent)
      end
    end

    describe '#destroy' do
      let(:name) { 'puppet.rpm' }

      before :each do
        allow(eapi).to receive(:delete)
        allow(eapi).to receive(:install)
      end

      it 'calls Extension#delete(name)' do
        expect(provider.eapi.Extension).to receive(:delete)
          .with(name)
        provider.destroy
      end

      context 'when the resource has been created' do
        subject do
          provider.create
          provider.destroy
        end

        it 'sets ensure to :absent' do
          subject
          expect(provider.ensure).to eq(:absent)
        end

        it 'clears the property hash' do
          subject
          expect(provider.instance_variable_get(:@property_hash))
            .to eq(name: name, ensure: :absent)
        end
      end
    end
  end
end
