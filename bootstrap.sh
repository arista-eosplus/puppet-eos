#!/bin/bash
export TERM=vt100
set -x
PUPPET='puppet-agent-1.5.2-1.eos4.i386.swix'
PUPPET_URL="http://pm.puppetlabs.com/puppet-agent/2016.2.0/1.5.2/repos/eos/4/PC1/i386/${PUPPET}"
RBEAPI='rbeapi-puppet-aio-1.0-1.swix'
RBEAPI_URL="https://github.com/arista-eosplus/rbeapi/releases/download/v1.0/${RBEAPI}"

WGET_OPTS="--progress=dot:binary"

# Ensure the puppet agent is installed
if ! [ -f /mnt/flash/.extensions/${PUPPET} ]; then
  wget ${WGET_OPTS} -O /mnt/flash/${PUPPET} ${PUPPET_URL}
  cmds="copy flash:${PUPPET} extension:
extension ${PUPPET}"
  FastCli -p 15 -c "${cmds}"
fi

# Ensure rbeapi is installed
if ! [ -f /mnt/flash/.extensions/${RBEAPI} ]; then
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
   protocol unix-socket
   no shutdown"
FastCli -p 15 -c "${cmds}"

# EOS 4.17 includes the redhat-release file which confuses some os-detection systems.
# https://github.com/chef/mixlib-install/pull/158
if [ -f /etc/redhat-release ]; then
  rm -f /etc/redhat-release
fi

module_path="--modulepath=/tmp/kitchen/data"
puppet_opts="${module_path} --detailed-exitcodes"
/opt/puppetlabs/puppet/bin/gem install pry
/opt/puppetlabs/puppet/bin/gem install pry-nav

${puppet} describe ${module_path} eos_switchconfig
${puppet} resource ${module_path} eos_switchconfig
resource="eos_switchconfig{'running-config': \
            content => template('eos/tmp_config'), \
            staging_file => 'puppet-config', \
          }"
${puppet} apply ${puppet_opts} -e "${resource}"
if [ $? == 2 ]; then
    echo "SUCCESSFULLY applied the first time"
else
    echo "FAILED to apply the first time"
fi

${puppet} apply ${puppet_opts} -e "${resource}"
if [ $? == 0 ]; then
    echo "SUCCESSFULLY applied the second time with no changes (Idempotent)"
else
    echo "FAILED idempotency check"
fi
