RSpec.shared_examples 'provider resource methods' do |opts = {}|
  opts.each_pair do |method, value|
    it "#{method} is #{value}" do
      expect(subject.send(method)).to eq(value)
    end
  end
end

RSpec.shared_examples 'provider resource properties' do |opts = {}|
  namevar = opts[:name]
  opts.each_pair do |property, value|
    it "#{property} is #{value}" do
      expect(rules[namevar].provider.get(property)).to eq(value)
    end
  end
end
