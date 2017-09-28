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

include FixtureHelpers

describe Puppet::Type.type(:eos_logging_host).provider(:eos) do
  # Puppet RAL memoized methods
  let(:resource) do
    resource_hash = {
      :name => '192.0.2.4',
      :provider => described_class.name
    }
    Puppet::Type.type(:eos_logging_host).new(resource_hash)
  end

  let(:provider) { resource.provider }

  let(:api) { double('logging') }

  def logging
    logging = Fixtures[:logging]
    return logging if logging
    fixture('logging', dir: File.dirname(__FILE__))
  end

  before :each do
    allow(described_class.node).to receive(:api).with('logging')
      .and_return(api)
    allow(provider.node).to receive(:api).with('logging').and_return(api)
  end

  context 'class methods' do
    before { allow(api).to receive(:get).and_return(logging) }

    describe '.instances' do
      subject { described_class.instances }

      it { is_expected.to be_an Array }

      it 'has five instances' do
        expect(subject.size).to eq(5)
      end

      it 'has an instance for 192.0.2.4' do
        instance = subject.find { |p| p.name == '192.0.2.4' }
        expect(instance).to be_a described_class
      end

      context 'eos_logging_host { 192.0.2.4: }' do
        subject do
          described_class.instances.find do |p|
            p.name == '192.0.2.4'
          end
        end

        include_examples 'provider resource methods',
                         :name => '192.0.2.4',
                         :ensure => :present
      end
    end

    describe '.prefetch' do
      let :resources do
        {
          '192.0.2.4' => Puppet::Type.type(:eos_logging_host)
                                   .new(:name => '192.0.2.4'),
          '10.0.0.99' => Puppet::Type.type(:eos_logging_host)
                                   .new(:name => '10.0.0.99')
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
        expect(resources['192.0.2.4'].provider.name).to eq('192.0.2.4')
        expect(resources['192.0.2.4'].provider.exists?).to be_truthy
      end

      it 'does not set the provider instance of the unmanaged resource' do
        subject
        expect(resources['10.0.0.99'].provider.name).to eq('10.0.0.99')
        expect(resources['10.0.0.99'].provider.exists?).to be_falsey
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
          allow(api).to receive(:get).and_return(logging)
          described_class.instances.first
        end
        it { is_expected.to be_truthy }
      end
    end

    describe '#create' do
      let(:name) { resource[:name] }

      #before do
      #  expect(api).to receive(:add_host).with(name)
      #end

      it 'sets ensure to :present' do
        expect(api).to receive(:add_host).with(resource[:name],
                                               :port => 514,
                                               :protocol => :udp)
        provider.create
        provider.flush
        expect(provider.ensure).to eq(:present)
      end
    end

    describe '#port' do
      it 'sets the port' do
        expect(api).to receive(:add_host).with(resource[:name],
                                               :port => 555,
                                               :protocol => :udp)
        provider.port = 555
        provider.flush
        expect(provider.port).to eq(555)
      end
    end

    describe '#protocol' do
      it 'sets the protocol' do
        expect(api).to receive(:add_host).with(resource[:name],
                                               :port => 514,
                                               :protocol => 'tcp')
        provider.protocol = 'tcp'
        provider.flush
        expect(provider.protocol).to eq('tcp')
      end
    end

    describe '#vrf' do
      it 'sets the VRF' do
        expect(api).to receive(:add_host).with(resource[:name],
                                               :port => 514,
                                               :protocol => :udp,
                                               :vrf => 'blue')
        provider.vrf = 'blue'
        provider.flush
        expect(provider.vrf).to eq('blue')
      end
    end

    describe '#destroy' do
      it 'sets ensure to :absent' do
        expect(api).to receive(:remove_host).with(resource[:name],
                                                 :port => 514,
                                                 :protocol => :udp)
        provider.destroy
        provider.flush
        expect(provider.ensure).to eq(:absent)
      end
    end
  end
end
