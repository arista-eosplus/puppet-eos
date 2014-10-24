require 'spec_helper'
require 'puppet_x/eos/eapi/vlan'

describe PuppetX::Eos::Vlan do
  let(:eapi) { double }
  let(:instance) { PuppetX::Eos::Vlan.new eapi }

  context 'when initializing a new Vlans instance' do
    subject { instance }

    it { is_expected.to be_a_kind_of PuppetX::Eos::Vlan }
  end

  context 'with #enable or #config eapi' do

    before :each do
      allow(eapi).to receive(:enable)
        .with(commands)
        .and_return(response)
    end

    before :each do
      allow(eapi).to receive(:config)
        .with(commands)
        .and_return(response)
    end

    context '#get' do
      subject { instance.get(vlanid) }

      describe 'retrieving specific vlan id' do
        let(:vlanid) { '1' }
        let(:commands) { ['show vlan 1', 'show vlan 1 trunk group'] }

        let :response do
          dir = File.dirname(__FILE__)
          file = File.join(dir, 'fixture_show_vlan_1.json')
          JSON.load(File.read(file))
        end

        it 'has only two entries' do
          expect(subject.size).to eq 1
        end

        it { is_expected.to be_a_kind_of Hash }
        it { is_expected.to have_key '1' }
        it { is_expected.not_to have_key 'results' }
        it 'includes trunkGroups' do
          expect(subject['1']).to have_key 'trunkGroups'
        end
      end

      describe 'retreiving all vlans' do
        let(:vlanid) { nil }
        let(:commands) { ['show vlan', 'show vlan trunk group'] }

        let :response do
          dir = File.dirname(__FILE__)
          file = File.join(dir, 'fixture_show_vlan.json')
          JSON.load(File.read(file))
        end

        it 'has only one entry' do
          expect(subject.size).to eq 3
        end

        it { is_expected.to be_a_kind_of Hash }
        it { is_expected.to have_key '1' }
        it { is_expected.not_to have_key 'results' }
        it 'includes trunkGroups' do
          expect(subject.values[0]).to have_key 'trunkGroups'
        end
      end
    end

    context '#add' do
      subject { instance.add(vlanid) }

      describe 'successfully add a new vlan id' do
        let(:vlanid) { '1234' }
        let(:commands) { 'vlan 1234' }
        let(:response) { [{}] }

        it { is_expected.to be_truthy }
      end

      describe 'failed to add new vlan id' do
        let(:vlanid) { '6789' }
        let(:commands) { 'vlan 6789' }
        let(:response) { nil }

        it { is_expected.to be_falsey }
      end
    end

    context '#delete' do
      subject { instance.delete(vlanid) }
      let(:vlanid) { '1234' }
      let(:commands) { 'no vlan 1234' }

      describe 'successfully delete a vlan' do
        let(:response) { [{}] }
        it { is_expected.to be_truthy }
      end

      describe 'failed to delete vlan id' do
        let(:response) { nil }
        it { is_expected.to be_falsey }
      end
    end

    context '#default' do
      subject { instance.default(vlanid) }
      let(:vlanid) { '1234' }
      let(:commands) { 'default vlan 1234' }

      describe 'successfully default vlan' do
        let(:response) { [{}] }
        it { is_expected.to be_truthy }
      end

      describe 'failed to default vlan' do
        let(:response) { nil }
        it { is_expected.to be_falsey }
      end
    end

    context '#set_name' do
      subject { instance.set_name(opts) }

      describe 'successfully set vlan name' do
        let(:opts) { { id: '1234', value: 'foo' } }
        let(:commands) { ['vlan 1234', 'name foo'] }
        let(:response) { [{}, {}] }
        it { is_expected.to be_truthy }
      end

      describe 'failed to set vlan name' do
        let(:opts) { { id: '6789', value: 'foo' } }
        let(:commands) { ['vlan 6789', 'name foo'] }
        let(:response) { nil }
        it { is_expected.to be_falsey }
      end

      describe 'default the vlan name' do
        let(:opts) { { id: '1234', default: true } }
        let(:commands) { ['vlan 1234', 'default name'] }
        let(:response) { [{}, {}] }
        it { is_expected.to be_truthy }
      end
    end

    context '#set_state' do
      subject { instance.set_state(opts) }

      describe 'successfully set vlan state to "active"' do
        let(:opts) { { id: '1234', value: 'active' } }
        let(:commands) { ['vlan 1234', 'state active'] }
        let(:response) { [{}, {}] }
        it { is_expected.to be_truthy }
      end

      describe 'failed to set vlan state to "active"' do
        let(:opts) { { id: '6789', value: 'active' } }
        let(:commands) { ['vlan 6789', 'state active'] }
        let(:response) { nil }
        it { is_expected.to be_falsey }
      end

      describe 'default the vlan state' do
        let(:opts) { { id: '1234', default: true } }
        let(:commands) { ['vlan 1234', 'default state'] }
        let(:response) { [{}, {}] }
        it { is_expected.to be_truthy }
      end

    end

    context '#set_trunk_group' do
      subject { instance.set_trunk_group(opts) }

      describe 'successfully set vlan trunk group' do
        let(:opts) { { id: '1234', value: 'foo' } }
        let(:commands) { ['vlan 1234', 'trunk group foo'] }
        let(:response) { [{}, {}] }
        it { is_expected.to be_truthy }
      end

      describe 'failed to set vlan trunk group' do
        let(:opts) { { id: '6789', value: 'foo' } }
        let(:commands) { ['vlan 6789', 'trunk group foo'] }
        let(:response) { nil }
        it { is_expected.to be_falsey }
      end

      describe 'default the vlan trunk group' do
        let(:opts) { { id: '1234', default: true } }
        let(:commands) { ['vlan 1234', 'default trunk group'] }
        let(:response) { [{}, {}] }
        it { is_expected.to be_truthy }
      end
    end

  end
end
