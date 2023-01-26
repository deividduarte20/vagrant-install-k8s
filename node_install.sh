#!/bin/bash

# Desativa Swap
swapoff -a

# Comenta entradas do arquivo fstab
sed -i 's/UUID=/#UUID=/g' /etc/fstab

####---------------------instalação do ContainerD-------------------###

# Atualiza lista de repositório
apt-get update

# Instala dependências do containerD
apt-get install \
    ca-certificates \
    curl \
    gnupg \
    lsb-release -y

# cria diretório para adição de chave GPG
mkdir -p /etc/apt/keyrings

# Adiciona chave GPG
curl -fsSL https://download.docker.com/linux/ubuntu/gpg | gpg --dearmor -o /etc/apt/keyrings/docker.gpg

# Definindo repo
echo \
  "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/docker.gpg] https://download.docker.com/linux/ubuntu \
  $(lsb_release -cs) stable" | tee /etc/apt/sources.list.d/docker.list > /dev/null

# Atualiza lista de repositório
apt-get update

# Instala última versão do containerD
apt-get install containerd.io -y

####---------------------Instalação CNI---------------------------------###

# Baixa repo cni plugin
wget https://github.com/containernetworking/plugins/releases/download/v1.2.0/cni-plugins-linux-amd64-v1.2.0.tgz

# Cria diretório
mkdir -p /opt/cni/bin

# Descompacta cni plugin
tar Cxzvf /opt/cni/bin cni-plugins-linux-amd64-v1.2.0.tgz

# Comenta parâmetro que desabilita cni
sed -i 's/disabled_plugins/#disabled_plugins/g' /etc/containerd/config.toml

# Adiciona parâmetro no final do arquivo
echo "[plugins."io.containerd.grpc.v1.cri".containerd.runtimes.runc.options]
SystemdCgroup = true" >> /etc/containerd/config.toml

####---------------------Instalação do Kubeadm--------------------------###

# Atualiza lista de repositório
apt-get update

# Instala dependencias do Kubernetes
apt-get install -y apt-transport-https ca-certificates curl

# Adiciona chave publica do repo do google
curl -fsSLo /etc/apt/keyrings/kubernetes-archive-keyring.gpg https://packages.cloud.google.com/apt/doc/apt-key.gpg

# Adiciona repositório no apt
echo "deb [signed-by=/etc/apt/keyrings/kubernetes-archive-keyring.gpg] https://apt.kubernetes.io/ kubernetes-xenial main" | tee /etc/apt/sources.list.d/kubernetes.list

# Atualiza lista de repositórios
apt-get update

# Instala Kubelet, kubeadm e kubectl
apt-get install -y kubeadm=1.26.0-00 kubelet=1.26.0-00 kubectl=1.26.0-00

# Fixa a versão dos pacotes instalados
apt-mark hold kubelet kubeadm 

# Cria modulos iptables
cat <<EOF | tee /etc/modules-load.d/k8s.conf
overlay
br_netfilter
EOF
modprobe overlay
modprobe br_netfilter

# Adiciona modulos do iptables no systemctl
cat <<EOF | tee /etc/sysctl.d/k8s.conf
net.bridge.bridge-nf-call-iptables  = 1
net.bridge.bridge-nf-call-ip6tables = 1
net.ipv4.ip_forward                 = 1
EOF

# Reinicia systemctl
sysctl --system

# Remove conf
rm /etc/containerd/config.toml

# Reinicia serviço do containerd
systemctl restart containerd

echo "Fim da instalação"
