#!/bin/bash
set -x
PUPPET='puppet-agent-1.5.2-1.eos4.i386.swix'
PUPPET_URL="http://pm.puppetlabs.com/puppet-agent/2016.2.0/1.5.2/repos/eos/4/PC1/i386/${PUPPET}"
RBEAPI='rbeapi-puppet-aio-1.0-1.swix'
RBEAPI_URL="https://github.com/arista-eosplus/rbeapi/releases/download/v1.0/${RBEAPI}"

WGET_OPTS="--progress=dot:binary"

# Ensure the puppet agent is installed
puppet_exists=`ls -l /mnt/flash/.extensions/${PUPPET}`
if [ $? -ne 0 ]; then
  wget ${WGET_OPTS} -O /mnt/flash/${PUPPET} ${PUPPET_URL}
  cmds="copy flash:${PUPPET} extension:
extension ${PUPPET}"
  FastCli -p 15 -c "${cmds}"
fi

# Ensure rbeapi is installed
rbeapi_exists=`ls -l /mnt/flash/.extensions/${RBEAPI}`
if [ $? -ne 0 ]; then
  wget ${WGET_OPTS} -O /mnt/flash/${RBEAPI} ${RBEAPI_URL}
  cmds="copy flash:${RBEAPI} extension:
extension ${RBEAPI}"
  FastCli -p 15 -c "${cmds}"
fi

puppet="/opt/puppetlabs/bin/puppet"

sudo ${puppet} config set user root
sudo ${puppet} config set group root

# Show the installed packages and ensure eAPI is enabled
cmds="show extension
configure
management api http-commands
   protocol unix-socket"
FastCli -p 15 -c "${cmds}"

# EOS 4.17 includes the redhat-release file which confuses some os-detection systems.
# https://github.com/chef/mixlib-install/pull/158
if [ -f /etc/redhat-release ]; then
  rm -f /etc/redhat-release
fi

${puppet} describe --modulepath=/tmp/kitchen/data eos_switchconfig
${puppet} resource --modulepath=/tmp/kitchen/data eos_switchconfig
${puppet} apply --modulepath=/tmp/kitchen/data -e "eos_switchconfig{'running-config': content => template('eos/tmp_config'), staging_file => 'puppet-config', }"
