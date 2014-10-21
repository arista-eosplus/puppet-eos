RSpec.shared_examples 'provider resource methods' do |opts = {}|
  opts.each_pair do |method, value|
    it "#{method} is #{value}" do
      expect(subject.send(method)).to eq(value)
    end
  end
end
