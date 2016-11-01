require 'spec_helper'
# Serverspec examples can be found at
# http://serverspec.org/resource_types.html

## checking successfull puppet run
describe command('grep fail /var/lib/puppet/state/last_run_summary.yaml |grep -v "fail.*:\ 0”') do
  its(:exit_status) { should eq 1 }
end

describe package('puppet-agent') do
  it { should be_installed.by('rpm') }
end

cmd = 'show running-config section management api http-commands'
describe command("/usr/bin/FastCli -p 15 -c \"#{cmd}\"") do
  its(:stdout) { should contain('protocol unix-socket') }
  its(:stdout) { should contain('no shutdown') }
end
