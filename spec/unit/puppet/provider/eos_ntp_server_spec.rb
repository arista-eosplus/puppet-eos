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

describe Puppet::Type.type(:eos_ntp_server).provider(:eos) do
  let(:type) { Puppet::Type.type(:eos_ntp_server) }

  let :resource do
    resource_hash = {
      name: '1.2.3.4',
      ensure: :present
    }
    type.new(resource_hash)
  end

  let(:provider) { resource.provider }

  def ntp
    ntp = Fixtures[:ntp]
    return ntp if ntp
    file = File.join(File.dirname(__FILE__), 'fixtures/ntp.json')
    Fixtures[:ntp] = JSON.load(File.read(file))
  end

  before :each do
    allow_message_expectations_on_nil
    allow(described_class).to receive(:eapi)
    allow(described_class.eapi).to receive(:Ntp)
    allow(described_class.eapi.Ntp).to receive(:get)
      .and_return(ntp)
  end

  context 'class methods' do
    describe '.instances' do
      subject { described_class.instances }

      it { is_expected.to be_an Array }

      it 'has two instances' do
        expect(subject.size).to eq(2)
      end

      it 'contains Eos_ntp_server[1.2.3.4]' do
        instance = subject.find { |p| p.name == '1.2.3.4' }
        expect(instance).to be_a described_class
      end

      describe 'Eos_ntp_config[1.2.3.4]' do
        subject do
          described_class.instances.find { |p| p.name == '1.2.3.4' }
        end

        include_examples 'provider resource methods',
                         name: '1.2.3.4',
                         ensure: :present
      end
    end

    describe '.prefetch' do
      let :resources do
        {
          '1.2.3.4' => Puppet::Type.type(:eos_ntp_server)
            .new(name: '1.2.3.4'),
          '11.12.13.14' => Puppet::Type.type(:eos_ntp_server)
            .new(name: '11.12.13.14')
        }
      end

      subject { described_class.prefetch(resources) }

      it 'resource providers are absent prior to calling .prefetch' do
        resources.values.each do |rsrc|
          expect(rsrc.provider.exists?).to be_falsey
        end
      end

      it 'sets the provider instance of the managed resource' do
        subject
        expect(resources['1.2.3.4'].provider.name).to eq '1.2.3.4'
        expect(resources['1.2.3.4'].provider.exists?).to be_truthy
      end

      it 'does not set the provider instance of the unmanaged resource' do
        subject
        expect(resources['11.12.13.14'].provider.name).to eq('11.12.13.14')
        expect(resources['11.12.13.14'].provider.exists?).to be_falsey
      end
    end
  end
end
