# -*- mode: ruby -*-
# # vi: set ft=ruby :

Vagrant.configure(2) do |config|
  # Ethernet1
  config.vm.network 'private_network', virtualbox__intnet: true,
                                       ip: '169.254.1.11', auto_config: false
  # Ethernet2
  config.vm.network 'private_network', virtualbox__intnet: true,
                                       ip: '169.254.1.11', auto_config: false

  config.vm.provision 'shell', inline: <<-SHELL
    sleep 30
    FastCli -p 15 -c 'configure
    ip route 0.0.0.0/0 10.0.2.2
    end'
    SHELL

  config.vm.provision 'shell', inline: <<-SHELL
    sleep 30
    FastCli -p 15 -c 'configure
    ip route 0.0.0.0/0 10.0.2.2
    end'
    SHELL
  config.vm.provider :virtualbox do |v|
    # Networking:
    #  nic1 is always Management1 which is set to dhcp in the basebox.

    # Patch Ethernet1 to a particular internal network
    v.customize ['modifyvm', :id, '--nic2', 'intnet',
                 '--intnet2', 'vEOS-intnet1']
    # Patch Ethernet2 to a particular internal network
    v.customize ['modifyvm', :id, '--nic3', 'intnet',
                 '--intnet3', 'vEOS-intnet2']
  end
end
