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

describe Puppet::Type.type(:eos_switchconfig).provider(:eos) do
  # Puppet RAL memoized methods
  let(:resource) do
    resource_hash = {
      name: 'running-config',
      content: switchconfig,
      provider: described_class.name
    }
    Puppet::Type.type(:eos_switchconfig).new(resource_hash)
  end

  let(:provider) { resource.provider }

  let(:switchconfig) { double('switchconfig') }

  def switchconfig
    switchconfig = Fixtures[:switchconfig]
    return switchconfig if switchconfig
    fixture('switchconfig', dir: File.dirname(__FILE__))
  end

  before :each do
    allow(described_class.node).to receive(:get_config).and_return(switchconfig)
    allow(provider.node).to receive(:get_config).and_return(switchconfig)
  end

  context 'class methods' do
    describe '.instances' do
      subject { described_class.instances }

      it { is_expected.to be_an Array }

      it 'has one entry' do
        expect(subject.size).to eq 1
      end

      it 'has an instance for running-config' do
        instance = subject.find { |p| p.name == 'running-config' }
        expect(instance).to be_a described_class
      end

      context 'eos_switchconfig { "running-config": }' do
        subject do
          described_class.instances.find { |p| p.name == 'running-config' }
        end

        include_examples 'provider resource methods',
                         exists?: true,
                         staging_file: 'puppet-config'
      end
    end

    describe '.prefetch' do
      let :resources do
        {
          'running-config' => Puppet::Type.type(:eos_switchconfig)
                                          .new(name: 'running-config')
        }
      end

      subject { described_class.prefetch(resources) }

      it 'resource providers are absent prior to calling .prefetch' do
        resources.values.each do |rsrc|
          expect(rsrc.provider.content).to eq(:absent)
        end
      end

      it 'sets the provider instance of the managed resource' do
        subject
        expect(resources['running-config'].provider.name).to eq 'running-config'
        expect(resources['running-config'].provider.content).to eq switchconfig
        expect(resources['running-config'].provider.content).to be_truthy
      end
    end
  end
end
