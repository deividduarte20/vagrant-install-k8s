#!/bin/bash

####---------------------Configurações de Swap-----------------------###

# Criado por Deivid Duarte

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

# Inicializar master
kubeadm init --kubernetes-version=1.26.0

# Adiciona tempo de espera para executar o proximo comando
sleep 100

# Cria diretório em home do user vagrant
mkdir -p $HOME/.kube

# Copia configurações de atribuição de permissão
sudo cp -i /etc/kubernetes/admin.conf $HOME/.kube/config

# Torna usuário vagrant proprietário do diretório .kube/config
sudo chown $(id -u):$(id -g) $HOME/.kube/config

# Instalação de driver de rede
kubectl apply -f https://github.com/weaveworks/weave/releases/download/v2.8.1/weave-daemonset-k8s.yaml

echo "Fim da instalação"
