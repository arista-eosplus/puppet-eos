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
require 'puppet_x/eos/modules/extension'

describe PuppetX::Eos::Extension do
  let(:eapi) { double }
  let(:instance) { PuppetX::Eos::Extension.new eapi }

  context 'when initializing a new Extension instance' do
    subject { instance }
    it { is_expected.to be_a_kind_of PuppetX::Eos::Extension }
  end

  context '#getall' do
    subject { instance.getall }

    let(:commands) { 'show extensions' }

    let :api_response do
      dir = File.dirname(__FILE__)
      file = File.join(dir, 'fixtures/extensions.json')
      JSON.load(File.read(file))
    end

    before :each do
      allow(eapi).to receive(:enable)
        .with(commands)
        .and_return(api_response)
    end

    describe 'retreiving extensions from eAPI' do
      it { is_expected.to be_a_kind_of Array }

      it 'has only one entry' do
        expect(subject.size).to eq 1
      end

      it 'has entry for extensions' do
        expect(subject[0]).to have_key 'extensions'
      end
    end
  end

  context '#load' do
    subject { instance.load(name, force) }

    let(:name) { 'foo' }
    let(:api_response) { [{}] }

    before :each do
      allow(eapi).to receive(:enable)
        .with(commands)
        .and_return(api_response)
    end

    describe 'load an extension with force=false (default)' do
      let(:force) { false }
      let(:commands) { "extension #{name}" }
      it { is_expected.to be_truthy }
    end

    describe 'load an extension with force=true' do
      let(:force) { true }
      let(:commands) { "extension #{name} force" }
      it { is_expected.to be_truthy }
    end
  end

  context '#delete' do
    subject { instance.delete(name) }
    let(:name) { 'foo' }

    before :each do
      allow(instance).to receive(:set_autoload).and_return(true)

      allow(eapi).to receive(:enable)
        .once
        .with('no extension foo')
        .and_return([{}])

      allow(eapi).to receive(:enable)
        .once
        .with('delete extension:foo')
        .and_return([{}])
    end

    describe 'delete an existing extension' do
      it { is_expected.to be_truthy }
    end
  end

  context '#install' do
    subject { instance.install(name, force) }
    let(:name) { 'dummy.rpm' }
    let(:force) { false }

    before :each do
      allow(eapi).to receive(:enable)
        .once
        .with("copy #{name} extension:")
        .and_return([{}])

      allow(eapi).to receive(:enable)
        .once
        .with("extension #{name}")
        .and_return([{}])

      allow(eapi).to receive(:enable)
        .once
        .with("extension #{name} force")
        .and_return([{}])
    end

    describe 'install a new extension with force=false (default)' do
      it { is_expected.to be_truthy }
    end

    describe 'install a new extension with force=true' do
      let(:force) { true }
      it { is_expected.to be_truthy }
    end
  end

  context '#autoload?' do
    subject { instance.autoload?(name) }
    let(:name) { 'dummy.rpm' }
    let(:file) { double }

    before :each do
      allow(File).to receive(:open).and_return(file)
      allow(file).to receive(:read).and_return(contents)
    end

    describe "extension #{name} already configured" do
      let(:contents) { "#{name}\n" }
      it { is_expected.to be_truthy }
    end

    describe "extension #{name} not yet configured" do
      let(:contents) { '' }
      it { is_expected.to be_falsey }
    end
  end

  context '#set_autoload' do
    subject { instance.set_autoload(enabled, name, force) }
    let(:enabled) { :true }
    let(:name) { 'dummy.rpm' }
    let(:force) { nil }
    let(:file) { double }

    before :each do
      allow(File).to receive(:open).and_return(file)
      allow(file).to receive(:read).and_return(contents)
    end

    describe 'extension is not yet configured' do
      let(:contents) { '' }
      it { is_expected.to be_truthy }
    end

    describe 'extension is already configured' do
      let(:contents) { "#{name}\n" }
      it { is_expected.to be_falsy }
    end
  end
end
