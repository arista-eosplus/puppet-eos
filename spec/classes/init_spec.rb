require 'spec_helper'
describe 'eos' do

  context 'with defaults for all parameters' do
    it { should contain_class('eos') }
  end
end
