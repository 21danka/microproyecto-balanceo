# -*- mode: ruby -*-
# vi: set ft=ruby :
Vagrant.configure("2") do |config|
  if Vagrant.has_plugin?("vagrant-vbguest")
    config.vbguest.no_install = true
    config.vbguest.auto_update = false
    config.vbguest.no_remote  = true
  end
  config.vm.box_check_update = false

  # LB: Consul server + HAProxy
  config.vm.define "lb" do |lb|
    lb.vm.box = "bento/ubuntu-22.04"
    lb.vm.hostname = "lb"
    lb.vm.network :private_network, ip: "192.168.100.10"
    lb.vm.provider :virtualbox do |vb|
      vb.memory = 1024
      vb.cpus = 1
    end
    lb.vm.provision "shell", path: "provision/00_common.sh"
    lb.vm.provision "shell", path: "provision/10_consul_server_haproxy.sh"
  end

  # WEB1: Consulclient+Node
  config.vm.define "web1" do |web|
    web.vm.box = "bento/ubuntu-22.04"
    web.vm.hostname = "web1"
    web.vm.network :private_network, ip: "192.168.100.11"
    web.vm.provider :virtualbox do |vb|
      vb.memory = 1024
      vb.cpus = 1
    end
    web.vm.provision "shell", path: "provision/00_common.sh"
    web.vm.provision "shell", path: "provision/20_consul_client_node.sh"
  end

  # WEB2:Consulclient+Node
  config.vm.define "web2" do |web|
    web.vm.box = "bento/ubuntu-22.04"
    web.vm.hostname = "web2"
    web.vm.network :private_network, ip: "192.168.100.12"
    web.vm.provider :virtualbox do |vb|
      vb.memory = 1024
      vb.cpus = 1
    end
    web.vm.provision "shell", path: "provision/00_common.sh"
    web.vm.provision "shell", path: "provision/20_consul_client_node.sh"
  end
end