#!/bin/bash

sudo apt update -y && sudo apt upgrade -y

sudo apt install -y curl apt-transport-https ca-certificates software-properties-common

sudo swapoff -a
sudo sed -i '/ swap / s/^/#/' /etc/fstab

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
echo "deb [signed-by=/etc/apt/keyrings/kubernetes-apt-keyring.gpg] https://pkgs.k8s.io/core:/stable:/v${K8S_VERSION>sudo apt update -y
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

sudo kubeadm init --pod-network-cidr=10.244.0.0/16 --apiserver-advertise-address=192.168.1.21

mkdir -p $HOME/.kube
sudo cp -i /etc/kubernetes/admin.conf $HOME/.kube/config
sudo chown $(id -u):$(id -g) $HOME/.kube/config
echo 'export KUBECONFIG=$HOME/.kube/config' >> $HOME/.bashrc
source ~/.bashrc

kubectl get nodes -o wide
kubectl get pods -A -o wide
kubectl apply -f https://docs.projectcalico.org/manifests/calico.yaml
kubectl get pods -n kube-system -o wide

sudo kubeadm token create --print-join-command

kubectl get nodes -o wide
kubectl run my-pod --image=nginx --port=80
kubectl get pods -o wide
