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

describe Puppet::Type.type(:eos_system).provider(:eos) do

  # Puppet RAL memoized methods
  let(:resource) do
    resource_hash = {
      name: 'localhost',
      provider: described_class.name
    }
    Puppet::Type.type(:eos_system).new(resource_hash)
  end

  let(:provider) { resource.provider }

  def system
    system = Fixtures[:system]
    return system if system
    file = File.join(File.dirname(__FILE__), 'fixtures/system.json')
    Fixtures[:system] = JSON.load(File.read(file))
  end

  # Stub the Api method class to obtain all vlans.
  before :each do
    allow_message_expectations_on_nil
    allow(described_class).to receive(:eapi)
    allow(described_class.eapi).to receive(:System)
    allow(described_class.eapi.System).to receive(:get)
      .and_return(system)
  end

  context 'class methods' do

    describe '.instances' do
      subject { described_class.instances }

      it { is_expected.to be_an Array }

      it 'has an instance for hostname=localhost' do
        instance = subject.find { |p| p.name == 'localhost' }
        expect(instance).to be_a described_class
      end

      context "eos_system { 'localhost': }" do
        subject do
          described_class.instances.find do |p|
            p.name == 'localhost'
          end
        end

        include_examples 'provider resource methods',
                         name: 'localhost'
      end
    end

    describe '.prefetch' do
      let :resources do
        {
          'localhost' => Puppet::Type.type(:eos_system)
            .new(name: 'localhost'),
          'alternative' => Puppet::Type.type(:eos_system)
            .new(name: 'alternative')
        }
      end

      subject { described_class.prefetch(resources) }

      it 'sets the provider instance of the managed resource' do
        subject
        expect(resources['localhost'].provider.name).to eq('localhost')
        expect(resources['localhost'].provider.exists?).to be_truthy
      end

      it 'does not set the provider instance of the unmanaged resource' do
        subject
        expect(resources['alternative'].provider.name).to eq('alternative')
        expect(resources['alternative'].provider.exists?).to be_falsey
      end
    end
  end
end
