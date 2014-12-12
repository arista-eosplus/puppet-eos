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

describe Puppet::Type.type(:eos_logging_host).provider(:eos) do

  # Puppet RAL memoized methods
  let(:resource) do
    resource_hash = {
      name: '1.2.3.4',
      provider: described_class.name
    }
    Puppet::Type.type(:eos_logging_host).new(resource_hash)
  end

  let(:provider) { resource.provider }

  def logging
    logging = Fixtures[:logging]
    return logging if logging
    file = File.join(File.dirname(__FILE__), 'fixtures/logging.json')
    Fixtures[:logging] = JSON.load(File.read(file))
  end

  # Stub the Api method class to obtain all logging instances
  before :each do
    allow_message_expectations_on_nil
    allow(described_class).to receive(:eapi)
    allow(described_class.eapi).to receive(:Logging)
    allow(described_class.eapi.Logging).to receive(:get)
      .and_return(logging)
  end

  context 'class methods' do

    describe '.instances' do
      subject { described_class.instances }

      it { is_expected.to be_an Array }

      it 'has one instance' do
        expect(subject.size).to eq(1)
      end

      it 'has an instance for 1.2.3.4' do
        instance = subject.find { |p| p.name == '1.2.3.4' }
        expect(instance).to be_a described_class
      end

      context 'eos_logging_host { 1.2.3.4: }' do
        subject do
          described_class.instances.find do |p|
            p.name == '1.2.3.4'
          end
        end

        include_examples 'provider resource methods',
                         name: '1.2.3.4',
                         ensure: :present
      end
    end

    describe '.prefetch' do
      let :resources do
        {
          '1.2.3.4' => Puppet::Type.type(:eos_logging_host)
            .new(name: '1.2.3.4'),
          '5.6.7.8' => Puppet::Type.type(:eos_logging_host)
            .new(name: '5.6.7.8')
        }
      end
      subject { described_class.prefetch(resources) }

      it 'resource providers are absent prior to calling .prefetch' do
        resources.values.each do |rsrc|
          expect(rsrc.provider.ensure).to eq(:absent)
        end
      end

      it 'sets the provider instance of the managed resource' do
        subject
        expect(resources['1.2.3.4'].provider.name).to eq('1.2.3.4')
        expect(resources['1.2.3.4'].provider.exists?).to be_truthy
      end

      it 'does not set the provider instance of the unmanaged resource' do
        subject
        expect(resources['5.6.7.8'].provider.name).to eq('5.6.7.8')
        expect(resources['5.6.7.8'].provider.exists?).to be_falsey
      end
    end
  end

  context 'resource (instance) methods' do

    let(:name) { provider.resource[:name] }
    let(:eapi) { double }

    before :each do
      allow(provider).to receive(:eapi)
      allow(provider.eapi).to receive(:Logging).and_return(eapi)
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
      before :each do
        allow(eapi).to receive(:hosts)
        allow(eapi.hosts).to receive(:create)
      end

      it 'calls Logging.hosts#create(name) with the resource id' do
        expect(provider.eapi.Logging.hosts).to receive(:create)
          .with(provider.resource[:name])
        provider.create
      end

      it 'sets ensure to :present' do
        provider.create
        expect(provider.ensure).to eq(:present)
      end
    end

    describe '#destroy' do

      before :each do
        allow(eapi).to receive(:hosts)
        allow(eapi.hosts).to receive(:create)
        allow(eapi.hosts).to receive(:delete)
      end

      it 'calls Logging.hosts#delete(id)' do
        expect(eapi.hosts).to receive(:delete)
          .with(provider.resource[:name])
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
            .to eq(name: provider.resource[:name], ensure: :absent)
        end
      end
    end
  end
end
