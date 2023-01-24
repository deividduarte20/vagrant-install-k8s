# -*- mode: ruby -*-
# vi: set ft=ruby :

# Configurações SO, nome, rede, memória e vcpu e libera porta 8080
Vagrant.configure("2") do |config|
  config.vm.box = "ubuntu/bionic64"
  config.vm.hostname = "master"
   config.vm.network "public_network"
   config.vm.network :forwarded_port, guest: 8080, host: 8000
   config.vm.provider "virtualbox" do |v|
    v.memory = 4098
    v.cpus = 2
  end
  # Executa shellscript para instalação do kubernetes
  config.vm.provision :shell, path: "k8s_install.sh"
  end
# wlp18s0 conf de rede para teste
 