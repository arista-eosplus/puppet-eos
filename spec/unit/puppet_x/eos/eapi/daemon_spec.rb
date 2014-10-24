require 'spec_helper'
require 'puppet_x/eos/eapi/daemon'

describe PuppetX::Eos::Daemon do
  let(:eapi) { double }
  let(:instance) { PuppetX::Eos::Daemon.new eapi }

  context 'when initializing a new Daemon instance' do
    subject { instance }
    it { is_expected.to be_a_kind_of PuppetX::Eos::Daemon }
  end

  context 'with Eapi#enable' do
    before :each do
      allow(eapi).to receive(:enable).and_return(nil)
    end

    context '#get' do
      subject { instance.get }

      before :each do
        allow(eapi).to receive(:enable)
          .with(commands, format: 'text')
          .and_return(response)
      end

      describe 'retreiving extensions from eAPI' do
        let(:commands) { 'show running-config section daemon' }

        let :response do
          dir = File.dirname(__FILE__)
          file = File.join(dir, 'fixture_show_rc_daemon.json')
          JSON.load(File.read(file))
        end

        it 'has only one entry' do
          expect(subject.size).to eq 2
        end

        it { is_expected.to be_a_kind_of Hash }
        it { is_expected.not_to have_key 'results' }
      end
    end
  end

  context 'with Eapi#config' do
    context '#create' do
      subject { instance.create(name, command) }
      let(:name) { 'myagent' }
      let(:command) { '/usr/bin/dummy' }

      before :each do
        allow(eapi).to receive(:config)
          .with(["daemon #{name}", "command #{command}"])
          .and_return([{}, {}])
      end

      context 'when command is valid and executable' do
        before :each do
          allow(File).to receive(:executable?)
            .and_return(true)
        end

        describe 'configures a new agent' do
          it { is_expected.to be_truthy }
        end
      end

      context 'when command is valid and executable' do
        before :each do
          allow(File).to receive(:executable?)
            .and_return(false)
        end

        describe 'fails to configure a new agent' do
          it { is_expected.to be_falsey }
        end
      end
    end

    context '#delete' do
      subject { instance.delete(name) }
      let(:name) { 'myagent' }

      before :each do
        allow(eapi).to receive(:config)
          .with("no daemon #{name}")
          .and_return([{}])
      end

      describe 'delete an existing agent' do
        it { is_expected.to be_truthy }
      end

      describe 'try to delete a non-existent agent' do
        it { is_expected.to be_truthy }
      end
    end
  end
end
