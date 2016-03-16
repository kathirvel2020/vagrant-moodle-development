# -*- mode: ruby -*-
# vi: set ft=ruby :

# All Vagrant configuration is done below. The "2" in Vagrant.configure
# configures the configuration version (we support older styles for
# backwards compatibility). Please don't change it unless you know what
# you're doing.
#
# For a complete reference, please see the online documentation at
# https://docs.vagrantup.com.
#
# Every Vagrant development environment requires a box. You can search for
# boxes at https://atlas.hashicorp.com/search.
#
VAGRANTFILE_API_VERSION = "2"

Vagrant.configure(VAGRANTFILE_API_VERSION) do |config|
  config.vm.box = "ubuntu/trusty64"
  config.vm.hostname = 'dev.local'
  config.vm.network "private_network", ip: "192.168.33.33"
  config.vm.synced_folder "./", "/var/www", create: true, owner: 'www-data', group: 'www-data'
  config.ssh.forward_agent = true

  config.vm.provider "virtualbox" do |vb|
      vb.name = "dev"
      vb.memory = 1024
      vb.cpus = 1
  end

  config.vm.provision :shell, path: "provision.sh"
end
