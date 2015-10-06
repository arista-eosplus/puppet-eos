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

describe Puppet::Type.type(:eos_user).provider(:eos) do
  def load_default_settings
    @name = 'Username'
    @nopassword = :false
    @secret = 'dc647eb65e6711e155375218212b3964'
    @encryption = 'md5'
    @role = 'network-admin'
    @privilege = 1
    @sshkey = 'ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAABAQDKL1UtBALa4CvFUsHUipN' \
            'ymA04qCXuAtTwNcMj84bTUzUI+q7mdzRCTLkllXeVxKuBnaTm2PW7W67K5C' \
            'Vpl0EVCm6IY7FS7kc4nlnD/tFvTvShy/fzYQRAdM7ZfVtegW8sMSFJzBR/T' \
            '/Y/sxI16Y/dQb8fC3la9T25XOrzsFrQiKRZmJGwg8d+0RLxpfMg0s/9ATwQ' \
            'Kp6tPoLE4f3dKlAgSk5eENyVLA3RsypWADHpenHPcB7sa8D38e1TS+n+EUy' \
            'Adb3Yov+5ESAbgLIJLd52Xv+FyYi0c2L49ByBjcRrupp4zfXn4DNRnEG4K6' \
            'GcmswHuMEGZv5vjJ9OYaaaaaaa'
    @other_key = 'ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAABAQDKL1UtBALa4CvFUsHUipN' \
                 'ymA04qCXuAtTwNcMj84bTUzUI+q7mdzRCTLkllXeVxKuBnaTm2PW7W67K5C' \
                 'Vpl0EVCm6IY7FS7kc4nlnD/tFvTvShy/fzYQRAdM7ZfVtegW8sMSFJzBR/T' \
                 '/Y/sxI16Y/dQb8fC3la9T25XOrzsFrQiKRZmJGwg8d+0RLxpfMg0s/9ATwQ' \
                 'Kp6tPoLE4f3dKlAgSk5eENyVLA3RsypWADHpenHPcB7sa8D38e1TS+n+EUy' \
                 'Adb3Yov+5ESAbgLIJLd52Xv+FyYi0c2L49ByBjcRrupp4zfXn4DNRnEG4K6' \
                 'GcmswHuMEGZv5vjJ9OYaaaaaaa'
    @ensure = :present
  end

  # Puppet RAL memoized methods
  let(:resource) do
    load_default_settings
    resource_hash = {
      name: @name,
      nopassword: @nopassword,
      secret: @secret,
      encryption: @encryption,
      role: @role,
      privilege: @privilege,
      sshkey: @sshkey,
      ensure: :present,
      provider: described_class.name
    }
    Puppet::Type.type(:eos_user).new(resource_hash)
  end

  let(:provider) { resource.provider }

  let(:api) { double('users') }

  def users
    users = Fixtures[:users]
    return users if users
    fixture('users', dir: File.dirname(__FILE__))
  end

  before :each do
    allow(described_class.node).to receive(:api).with('users').and_return(api)
    allow(provider.node).to receive(:api).with('users').and_return(api)
    load_default_settings
  end

  context 'class methods' do
    before { allow(api).to receive(:getall).and_return(users) }

    describe '.instances' do
      subject { described_class.instances }

      it { is_expected.to be_an Array }

      it 'has one entry' do
        expect(subject.size).to eq(1)
      end

      it 'has an instance Username' do
        instance = subject.find { |p| p.name == @name }
        expect(instance).to be_a described_class
      end

      context 'eos_user { Username }' do
        subject { described_class.instances.find { |p| p.name == @name } }
      end
    end

    describe '.prefetch' do
      let :resources do
        {
          'Username' => Puppet::Type.type(:eos_user).new(name: @name),
          'Username2' => Puppet::Type.type(:eos_user).new(name: 'Username2')
        }
      end

      subject { described_class.prefetch(resources) }

      it 'resource providers are absent prior to calling .prefetch' do
        resources.values.each do |rsrc|
          expect(rsrc.provider.nopassword).to eq(:absent)
          expect(rsrc.provider.secret).to eq(:absent)
          expect(rsrc.provider.encryption).to eq(:absent)
          expect(rsrc.provider.role).to eq(:absent)
          expect(rsrc.provider.privilege).to eq(:absent)
          expect(rsrc.provider.sshkey).to eq(:absent)
        end
      end

      it 'sets the provider instance of the managed resource 64600' do
        subject
        expect(resources['Username'].provider.name).to eq(@name)
        expect(resources['Username'].provider.nopassword).to eq(@nopassword)
        expect(resources['Username'].provider.secret).to eq(@secret)
        expect(resources['Username'].provider.encryption).to eq(@encryption)
        expect(resources['Username'].provider.role).to eq(@role)
        expect(resources['Username'].provider.privilege).to eq(@privilege)
        expect(resources['Username'].provider.sshkey).to eq(@sshkey)
      end

      it 'does not set the provider instance of the unmanaged resource' do
        subject
        expect(resources['Username2'].provider.nopassword).to eq(:absent)
        expect(resources['Username2'].provider.secret).to eq(:absent)
        expect(resources['Username2'].provider.encryption).to eq(:absent)
        expect(resources['Username2'].provider.role).to eq(:absent)
        expect(resources['Username2'].provider.privilege).to eq(:absent)
        expect(resources['Username2'].provider.sshkey).to eq(:absent)
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
          allow(api).to receive(:getall).and_return(users)
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
                                             provider: :eos,
                                             ensure: :present,
                                             nopassword: :false,
                                             secret: @secret,
                                             encryption: @encryption,
                                             role: @role,
                                             privilege: @privilege,
                                             sshkey: @sshkey,
                                             loglevel: :notice)
        provider.create
        provider.provider = :eos
        provider.ensure = :present
        provider.nopassword = :false
        provider.secret = @secret
        provider.encryption = @encryption
        provider.role = @role
        provider.privilege = @privilege
        provider.sshkey = @sshkey
        provider.flush
        expect(provider.ensure).to eq(:present)
        expect(provider.nopassword).to eq(@nopassword)
        expect(provider.secret).to eq(@secret)
        expect(provider.encryption).to eq(@encryption)
        expect(provider.role).to eq(@role)
        expect(provider.privilege).to eq(@privilege)
        expect(provider.sshkey).to eq(@sshkey)
      end
    end

    describe '#nopassword=(value)' do
      it 'sets nopassword on the resource' do
        expect(api).to receive(:create).with(resource[:name],
                                             name: @name,
                                             provider: :eos,
                                             ensure: :present,
                                             nopassword: :true,
                                             secret: @secret,
                                             encryption: @encryption,
                                             role: @role,
                                             privilege: @privilege,
                                             sshkey: @sshkey,
                                             loglevel: :notice)
        provider.create
        provider.nopassword = :true
        provider.flush
        expect(provider.nopassword).to eq(:true)
      end
    end

    describe '#secret=(value)' do
      it 'sets secret on the resource' do
        expect(api).to receive(:create).with(resource[:name],
                                             name: @name,
                                             provider: :eos,
                                             ensure: :present,
                                             nopassword: @nopassword,
                                             secret: '%$dc647eb65e6711e',
                                             encryption: @encryption,
                                             role: @role,
                                             privilege: @privilege,
                                             sshkey: @sshkey,
                                             loglevel: :notice)
        provider.create
        provider.secret = '%$dc647eb65e6711e'
        provider.flush
        expect(provider.secret).to eq('%$dc647eb65e6711e')
      end
    end

    describe '#encryption=(value)' do
      it 'sets encryption on the resource' do
        expect(api).to receive(:create).with(resource[:name],
                                             name: @name,
                                             provider: :eos,
                                             ensure: :present,
                                             nopassword: @nopassword,
                                             secret: @secret,
                                             encryption: 'sha512',
                                             role: @role,
                                             privilege: @privilege,
                                             sshkey: @sshkey,
                                             loglevel: :notice)
        provider.create
        provider.encryption = 'sha512'
        provider.flush
        expect(provider.encryption).to eq('sha512')
      end
    end

    describe '#role=(value)' do
      it 'sets role on the resource' do
        expect(api).to receive(:create).with(resource[:name],
                                             name: @name,
                                             provider: :eos,
                                             ensure: :present,
                                             nopassword: @nopassword,
                                             secret: @secret,
                                             encryption: @encryption,
                                             role: 'network-master',
                                             privilege: @privilege,
                                             sshkey: @sshkey,
                                             loglevel: :notice)
        provider.create
        provider.role = 'network-master'
        provider.flush
        expect(provider.role).to eq('network-master')
      end
    end

    describe '#privilege=(value)' do
      it 'sets privilege on the resource' do
        expect(api).to receive(:create).with(resource[:name],
                                             name: @name,
                                             provider: :eos,
                                             ensure: :present,
                                             nopassword: @nopassword,
                                             secret: @secret,
                                             encryption: @encryption,
                                             role: @role,
                                             privilege: 2,
                                             sshkey: @sshkey,
                                             loglevel: :notice)
        provider.create
        provider.privilege = 2
        provider.flush
        expect(provider.privilege).to eq(2)
      end
    end

    describe '#sshkey=(value)' do
      it 'sets sshkey on the resource' do
        expect(api).to receive(:create).with(resource[:name],
                                             name: @name,
                                             provider: :eos,
                                             ensure: :present,
                                             nopassword: @nopassword,
                                             secret: @secret,
                                             encryption: @encryption,
                                             role: @role,
                                             privilege: @privilege,
                                             sshkey: @other_key,
                                             loglevel: :notice)
        provider.create
        provider.sshkey = @other_key
        provider.flush
        expect(provider.sshkey).to eq(@other_key)
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
