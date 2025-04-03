#!/bin/bash

sudo apt update -y && sudo apt upgrade -y

sudo apt install -y curl apt-transport-https ca-certificates software-properties-common

sudo swapoff -a
#Supprimer la ligne du SWAP dans /etc/fstab

sudo modprobe overlay
sudo modprobe br_netfilter

cat <<EOF | sudo tee /etc/modules-load.d/k8s.conf
overlay
br_netfilter
EOF

cat <<EOF | sudo tee /etc/sysctl.d/k8s.conf
net.bridge.bridge-nf-call-iptables  = 1
net.bridge.bridge-nf-call-ip6tables = 1
net.ipv4.ip_forward                 = 1
EOF

sudo sysctl --system
sudo apt update -y
sudo apt install -y containerd
sudo mkdir -p /etc/containerd
containerd config default | sudo tee /etc/containerd/config.toml

sudo sed -i 's/SystemdCgroup = false/SystemdCgroup = true/' /etc/containerd/config.toml

sudo systemctl restart containerd
sudo systemctl enable containerd

K8S_VERSION="1.32"
sudo mkdir -p -m 755 /etc/apt/keyrings
curl -fsSL https://pkgs.k8s.io/core:/stable:/v${K8S_VERSION}/deb/Release.key | sudo gpg --dearmor -o /etc/apt/keyrings/kubernetes-apt-keyring.gpg
K8S_VERSION="1.32"
echo "deb [signed-by=/etc/apt/keyrings/kubernetes-apt-keyring.gpg] https://pkgs.k8s.io/core:/stable:/v${K8S_VERSION}/deb/ /" | sudo tee /etc/apt/sources.list.d/kubernetes.list

sudo apt update -y
sudo apt install -y kubelet kubeadm kubectl
sudo apt-mark hold kubelet kubeadm kubectl

# Pour l'utilisateur en cours uniquement
echo "source <(kubectl completion bash)" >> ~/.bashrc
source ~/.bashrc

# Pour tous les utilisateurs
#kubectl completion bash | sudo tee /etc/bash_completion.d/kubectl > /dev/null

#source /etc/bash_completion
# Pour un utilisateur spécifique uniquement
# echo "source <(kubectl completion bash)" >> /home/user/.bashrc

sudo systemctl start kubelet
sudo systemctl enable kubelet

# Mettre l'ip du serveur
sudo kubeadm init --pod-network-cidr=10.244.0.0/16 --apiserver-advertise-address=192.168.1.21

mkdir -p $HOME/.kube
sudo cp -i /etc/kubernetes/admin.conf $HOME/.kube/config
sudo chown $(id -u):$(id -g) $HOME/.kube/config
echo 'export KUBECONFIG=$HOME/.kube/config' >> $HOME/.bashrc
source ~/.bashrc
