require 'spec_helper'
require 'puppet_x/eos/eapi/extension'

describe PuppetX::Eos::Extension do
  let(:eapi) { double }
  let(:instance) { PuppetX::Eos::Extension.new eapi }

  context 'when initializing a new Extension instance' do
    subject { instance }

    it { is_expected.to be_a_kind_of PuppetX::Eos::Extension }
  end

  context 'with Eapi#enable' do
    before :each do
      allow(eapi).to receive(:enable).and_return(nil)
    end

    context '#get' do
      subject { instance.get }

      before :each do
        allow(eapi).to receive(:enable).with(commands).and_return(response)
      end

      describe 'retreiving extensions from eAPI' do
        let(:commands) { 'show extensions' }

        let :response do
          dir = File.dirname(__FILE__)
          file = File.join(dir, 'fixture_show_extensions.json')
          JSON.load(File.read(file))
        end

        it 'has only three entries' do
          expect(subject.size).to eq 3
        end

        it { is_expected.to be_a_kind_of Hash }
        it { is_expected.not_to have_key 'results' }
      end
    end

    context '#load' do
      subject { instance.load(name, force) }
      let(:name) { 'dummy.rpm' }
      let(:force) { false }
      let(:response) { [{}] }

      before :each do
        allow(eapi).to receive(:enable).with(commands).and_return(response)
      end

      describe 'load an extension with force=false (default)' do
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
      let(:name) { 'dummy.rpm' }

      before :each do
        allow(instance).to receive(:set_autoload).and_return(true)

        allow(eapi).to receive(:enable)
          .once
          .with('no extension dummy.rpm')
          .and_return([{}])

        allow(eapi).to receive(:enable)
          .once
          .with('delete extension:dummy.rpm')
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
end
