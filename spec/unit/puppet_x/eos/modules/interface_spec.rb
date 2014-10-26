require 'spec_helper'
require 'puppet_x/eos/eapi/interface'

describe PuppetX::Eos::Interface do
  let(:eapi) { double }
  let(:instance) { PuppetX::Eos::Interface.new eapi }

  context 'when initializing a new Interface instance' do
    subject { instance }
    it { is_expected.to be_a_kind_of PuppetX::Eos::Interface }
  end

  context 'with Eapi#enable' do
    before :each do
      allow(eapi).to receive(:enable)
        .with(commands)
        .and_return(response)
    end
    context '#get' do
      subject { instance.get }

      describe 'retrieve all interfaces' do
        let(:commands) { ['show interfaces', 'show interfaces flowcontrol'] }

        let :response do
          dir = File.dirname(__FILE__)
          file = File.join(dir, 'fixture_show_interfaces.json')
          JSON.load(File.read(file))
        end

        it { is_expected.to be_a_kind_of Hash }
        it { is_expected.to have_key 'interfaces' }
        it { is_expected.to have_key 'interfaceFlowControls'}
      end
    end
  end

  context 'with Eapi#config' do
    before :each do
      allow(eapi).to receive(:config)
        .with(commands)
        .and_return(response)
    end

    context '#default' do
      subject { instance.default(name) }
      let(:name) { "Ethernet1" }

      describe 'when the interface exists' do
        let(:commands) { "default interface #{name}" }
        let(:response) { [{}] }
        it { is_expected.to be_truthy }
      end

      describe 'when the interface does not exist' do
        let(:name) { "Vlan1234" }
        let(:commands) { "default interface #{name}" }
        let(:response) { nil }
        it { is_expected.to be_falsey }
      end
    end

    context '#create' do
      subject { instance.create(name) }

      context 'when the interface is physical' do
        let(:name) { 'Ethernet1' }
        let(:commands) { "interface #{name}" }
        let(:response) { nil }

        describe 'the interface already exists' do
          it { is_expected.to be_falsey }
        end
      end

      context 'when the interface is logical' do
        let(:name) { 'Vlan1234' }
        let(:commands) { "interface #{name}" }
        let(:response) { [{}] }

        describe 'the interface does not exist' do
          it { is_expected.to be_truthy }
        end
      end
    end

    context '#delete' do
      subject { instance.delete(name) }

      describe 'try to delete physical interface' do
        let(:name) { 'Ethernet1' }
        let(:commands) { "no interface #{name}" }
        let(:response) { nil }

        it { is_expected.to be_falsey }
      end

      describe 'delete logical interface' do
        let(:name) { 'Vlan1234' }
        let(:commands) { "no interface #{name}" }
        let(:response) { [{}] }
        it { is_expected.to be_truthy }
      end
    end

    context '#set_description' do
      subject { instance.set_description(name, opts) }
      let(:name) { 'Ethernet1' }

      describe 'configure interface description' do
        let(:value) { "this is a test" }
        let(:opts) { {value: value} }
        let(:commands) { ["interface #{name}", "description #{value}"]}
        let(:response) { [{}, {}] }
        it { is_expected.to be_truthy }
      end

      describe 'configure default interface description' do
        let(:opts) { {default: true} }
        let(:commands) { ["interface #{name}", "default description"]}
        let(:response) { [{}, {}] }
        it { is_expected.to be_truthy }
      end

      describe 'configure no interface description' do
        let(:opts) { {} }
        let(:commands) { ["interface #{name}", "no description"] }
        let(:response) { [{}, {}] }
        it { is_expected.to be_truthy }
      end
    end

    context '#set_shutdown' do
      subject { instance.set_shutdown(name, opts) }
      let(:name) { 'Ethernet1' }

      describe 'configure interface enabled' do
        let(:value) { true }
        let(:opts) { {value: value} }
        let(:commands) { ["interface #{name}", "no shutdown"]}
        let(:response) { [{}, {}] }
        it { is_expected.to be_truthy }
      end

      describe 'configure default interface enabled' do
        let(:opts) { {default: true} }
        let(:commands) { ["interface #{name}", "default shutdown"]}
        let(:response) { [{}, {}] }
        it { is_expected.to be_truthy }
      end

      describe 'configure interface disabled' do
        let(:opts) { { value: false } }
        let(:commands) { ["interface #{name}", "shutdown"] }
        let(:response) { [{}, {}] }
        it { is_expected.to be_truthy }
      end
    end

    context '#set_flowcontrol' do
      subject { instance.set_flowcontrol(name, direction, opts) }
      let(:name) { 'Ethernet1' }

      context 'when configuring flowcontrol tx options' do
        let(:direction) { 'send' }

        describe 'configure flowcontrol values' do
          ['on', 'off', 'desired'].each do |value|
            let(:opts) { {value: value} }
            let(:commands) { ["interface #{name}",
                              "flowcontrol send #{value}"]}
            let(:response) { [{}, {}] }
            it { is_expected.to be_truthy }
          end
        end

        describe 'configure flowcontrol as default' do
          let(:opts) { {default: true} }
          let(:commands) { ["interface #{name}", "default flowcontrol send"]}
          let(:response) { [{}, {}] }
          it { is_expected.to be_truthy }
        end
      end

      context 'when configuring flowcontrol rx options' do
        let(:direction) { 'receive' }

        describe 'configure flowcontrol values' do
          ['on', 'off', 'desired'].each do |value|
            let(:opts) { {value: value} }
            let(:commands) { ["interface #{name}",
                              "flowcontrol receive #{value}"]}
            let(:response) { [{}, {}] }
            it { is_expected.to be_truthy }
          end
        end

        describe 'configure flowcontrol as default' do
          let(:opts) { {default: true} }
          let(:commands) { ["interface #{name}", "default flowcontrol receive"]}
          let(:response) { [{}, {}] }
          it { is_expected.to be_truthy }
        end
      end
    end
  end
end
