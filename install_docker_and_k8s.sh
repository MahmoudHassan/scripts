#!/usr/bin/env bash
#
# install_docker_k8s.sh
#
# Steps:
#   1. Update & upgrade the system
#   2. Disable swap
#   3. Install Docker & enable it
#   4. Add new K8s apt repo from pkgs.k8s.io
#   5. Install kubeadm, kubelet, kubectl
#   6. Ask if this node is master:
#      - If yes, kubeadm init
#      - If no, skip
#   7. Ask to install Flannel
#
# Usage:
#   chmod +x install_docker_k8s.sh
#   sudo ./install_docker_k8s.sh
#

set -e

echo "=== [1/7] Updating and upgrading Ubuntu packages... ==="
sudo apt update
sudo apt -y upgrade

echo "=== [2/7] Disabling swap... ==="
sudo swapoff -a
sudo sed -i '/ swap / s/^\(.*\)$/#\1/g' /etc/fstab

echo "=== [3/7] Installing Docker... ==="
sudo apt -y install docker.io
sudo systemctl enable docker
sudo systemctl start docker
echo "=== Docker version ==="
docker --version || true

echo "=== [4/7] Adding the official Kubernetes repository from pkgs.k8s.io... ==="
sudo mkdir -p /etc/apt/keyrings

sudo tee /etc/apt/sources.list.d/kubernetes.list >/dev/null <<EOF
deb [signed-by=/etc/apt/keyrings/kubernetes-apt-keyring.gpg] https://pkgs.k8s.io/core:/stable:/v1.32/deb/ /
EOF

curl -fsSL https://pkgs.k8s.io/core:/stable:/v1.32/deb/Release.key \
  | sudo gpg --dearmor -o /etc/apt/keyrings/kubernetes-apt-keyring.gpg

echo "=== [5/7] Installing kubeadm, kubelet, kubectl... ==="
sudo apt-get update
sudo apt-get install -y kubelet kubeadm kubectl
sudo apt-mark hold kubelet kubeadm kubectl

echo "kubeadm:  $(kubeadm version -o short || true)"
echo "kubelet:  $(kubelet --version || true)"
echo "kubectl:  $(kubectl version --client --short || true)"

echo "=== [6/7] Checking if this is the Master node... ==="
read -rp "Is this the master (control-plane) node? [y/N]: " IS_MASTER

if [[ "$IS_MASTER" =~ ^[Yy]$ ]]; then
  echo "=== Initializing the cluster with kubeadm init ==="
  sudo kubeadm init --pod-network-cidr=10.244.0.0/16

  echo "=== Setting up kubeconfig for your user ==="
  mkdir -p $HOME/.kube
  sudo cp -i /etc/kubernetes/admin.conf $HOME/.kube/config
  sudo chown $(id -u):$(id -g) $HOME/.kube/config

  # Optionally install Flannel
  echo "=== [7/7] Do you want to install Flannel CNI on the master node now? ==="
  read -rp "Install Flannel CNI? [y/N]: " INSTALL_FLANNEL
  if [[ "$INSTALL_FLANNEL" =~ ^[Yy]$ ]]; then
    kubectl apply -f https://raw.githubusercontent.com/coreos/flannel/master/Documentation/kube-flannel.yml
    echo "Flannel installed. Check with: kubectl get pods -n kube-system"
  else
    echo "Skipping Flannel installation. You can install any CNI later."
  fi

else
  echo "=== Skipping kubeadm init. This node can join the cluster with a 'kubeadm join' command. ==="
  echo "=== [7/7] Script completed. ==="
fi

echo "=== Done! ==="
