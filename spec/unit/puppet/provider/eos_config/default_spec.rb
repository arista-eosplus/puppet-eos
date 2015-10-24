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

# Minimal unit test, mocking is a challenge, relying on the system test.
describe Puppet::Type.type(:eos_config).provider(:eos) do
  def load_default_settings
    @name = 'This is just a description'
    @command = 'ip virtual-router mac-address aabb.ccdd.eeff'
    @regexp = 'ip virtual-router mac-address aa:bb:cc:dd:ee:ff'
  end

  # Puppet RAL memoized methods
  let(:resource) do
    load_default_settings
    resource_hash = {
      name: @name,
      command: @command,
      regexp: @regexp,
      provider: described_class.name
    }
    Puppet::Type.type(:eos_config).new(resource_hash)
  end

  let(:provider) { resource.provider }

  let(:api) { double('config') }

  def config
    config = Fixtures[:config]
    return config if config
    fixture('config', dir: File.dirname(__FILE__))
  end

  before :each do
    allow(described_class.node).to receive(:api).and_return(api)
    allow(provider.node).to receive(:api).and_return(api)
  end

  context 'class methods' do
    # Note for eos_config it is not possible to get the current state of
    # the resource without having the properties defined.

    describe '.instances' do
      subject { described_class.instances }

      it { is_expected.to be_an Array }

      it 'has zero entry' do
        expect(subject.size).to eq(0)
      end
    end

    describe '.prefetch' do
      subject { described_class.prefetch(resources) }

      let :resources do
        {
          'cfg' => Puppet::Type.type(:eos_config).new(name: @name)
        }
      end

      it 'resource providers are absent prior to calling .prefetch' do
        resources.values.each do |rsrc|
          expect(rsrc.provider.command).to eq(:absent)
          expect(rsrc.provider.regexp).to eq(:absent)
        end
      end

      it 'resource providers are still absent after calling .prefetch' do
        resources.values.each do |rsrc|
          subject
          expect(rsrc.provider.command).to eq(:absent)
          expect(rsrc.provider.regexp).to eq(:absent)
        end
      end
    end
  end
end
