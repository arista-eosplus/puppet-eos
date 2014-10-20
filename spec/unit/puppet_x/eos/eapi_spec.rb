require 'spec_helper'

describe PuppetX::Eos::Eapi do
  let(:hostname) { 'localhost' }
  let(:port) { 80 }
  let(:username) { 'admin' }
  let(:password) { 'puppet' }
  let(:enable_pwd) { 'puppet' }
  let(:config) do
    {
      hostname: hostname,
      port: 80,
      username: 'admin',
      password: 'puppet'
    }
  end
  let(:api) { PuppetX::Eos::Eapi.new(config) }

  context 'when initializing a new EAPI instance' do
    [:hostname, :port, :username, :password, :enable_pwd].each do |option|
      it "initializes with #{option}" do
        api = described_class.new(option => send(option))
        expect(api.send(option)).to eq(send(option))
      end
    end

    it 'defaults hostname to localhost' do
      expect(subject.hostname).to eq('localhost')
    end

    it 'uses a non-ssl connnection' do
      api = described_class.new(use_ssl: false)
      expect(api.uri.to_s).to eq('http://localhost')
    end
  end

  describe '#uri' do
    it 'returns a default uri string' do
      expect(subject.uri.to_s).to eq('https://localhost')
    end
  end

  describe '#http' do
    it 'returns an instance of Net::HTTP' do
      expect(subject.http).to be_a Net::HTTP
    end
  end

  context '#request' do
    subject { api.request(commands, format: format) }
    let(:format) { 'json' }

    describe 'request a single command' do
      let(:commands) { 'foo' }

      it 'returns a request object of len 1' do
        expect(subject['params']['cmds']).to be_a Array
        expect(subject['params']['cmds'].length).to eq 1
        expect(subject).to be_a Hash
      end
    end

    describe 'request a commands array' do
      let(:commands) { %w(foo bar) }

      it 'returns a request object hash of len 2' do
        expect(subject['params']['cmds']).to be_a Array
        expect(subject['params']['cmds'].length).to eq 2
        expect(subject).to be_a Hash
      end
    end

    describe 'request a commands array with text' do
      let(:commands) { 'foo' }
      let(:format) { 'text' }
      it 'requets a reqest objct of format text' do
        expect(subject['params']['format']).to eq 'text'
      end
    end
  end

  describe '#enable' do
    context 'when sending a single command' do
      subject { api.enable('foo') }

      before do
        allow(api).to receive(:execute)
          .with(['foo'], {})
          .and_return([{}])
      end

      it { is_expected.to be_a_kind_of Array }
    end

    context 'when sending a commands with format = "text"' do
      subject { api.enable('foo', format: 'text') }

      before do
        allow(api).to receive(:execute)
          .with(['foo'], format: 'text')
          .and_return([{}])
      end

      it { is_expected.to be_a_kind_of Array }
    end

    context 'when sending an array of commands' do
      subject { api.enable(%w(foo bar)) }

      before do
        allow(api).to receive(:execute)
          .with(%w(foo bar), {})
          .and_return([{}, {}])
      end

      it { is_expected.to be_a_kind_of Array }
    end
  end

  describe '#config' do

    context 'when sending a command' do
      subject { api.config('foo') }

      before do
        allow(api).to receive(:enable)
          .with(%w(configure foo))
          .and_return([{}, {}])
      end

      it { is_expected.to be_a_kind_of Array }
    end

    context 'when sending an array of commands' do
      subject { api.config(%w(foo bar)) }

      before do
        allow(api).to receive(:enable)
          .with(%w(configure foo bar))
          .and_return([{}, {}, {}])
      end

      it { is_expected.to be_a_kind_of Array }
    end
  end

  describe '#execute' do
  end

  describe '#invoke' do
  end

end
