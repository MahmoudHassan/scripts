#!/usr/bin/env bash
#
# install_docker_k8s_flannel.sh
#
# Steps:
#   1. Update & upgrade the system
#   2. Disable swap
#   3. Install Docker & enable the service
#   4. Add the official Kubernetes apt repo from pkgs.k8s.io
#   5. Install kubeadm, kubelet, and kubectl
#   6. Initialize the cluster (control-plane node) with kubeadm
#   7. Copy kubeconfig to your home directory for kubectl usage
#   8. (Optional) Ask if you want to install Flannel CNI
#
# Usage:
#   chmod +x install_docker_k8s_flannel.sh
#   sudo ./install_docker_k8s_flannel.sh
#

set -e

echo "=== [1/8] Updating and upgrading Ubuntu packages... ==="
sudo apt update
sudo apt -y upgrade

echo "=== [2/8] Disabling swap... ==="
sudo swapoff -a
sudo sed -i '/ swap / s/^\(.*\)$/#\1/g' /etc/fstab

echo "=== [3/8] Installing Docker... ==="
sudo apt -y install docker.io

echo "=== Enabling and starting Docker... ==="
sudo systemctl enable docker
sudo systemctl start docker

echo "=== Docker status ==="
sudo systemctl status docker --no-pager || true
echo "=== Docker version ==="
docker --version || true

echo "=== [4/8] Adding the official Kubernetes repository from pkgs.k8s.io... ==="
sudo mkdir -p /etc/apt/keyrings

# Example: v1.32 channel (change as desired)
sudo tee /etc/apt/sources.list.d/kubernetes.list >/dev/null <<EOF
deb [signed-by=/etc/apt/keyrings/kubernetes-apt-keyring.gpg] https://pkgs.k8s.io/core:/stable:/v1.32/deb/ /
EOF

# Import the GPG key
curl -fsSL https://pkgs.k8s.io/core:/stable:/v1.32/deb/Release.key \
  | sudo gpg --dearmor -o /etc/apt/keyrings/kubernetes-apt-keyring.gpg

echo "=== [5/8] Installing kubeadm, kubelet, and kubectl... ==="
sudo apt-get update
sudo apt-get install -y kubelet kubeadm kubectl
sudo apt-mark hold kubelet kubeadm kubectl

echo "kubeadm:  $(kubeadm version -o short || true)"
echo "kubelet:  $(kubelet --version || true)"
echo "kubectl:  $(kubectl version --client --short || true)"

echo "=== [6/8] Initializing the cluster with kubeadm init ==="
# Adjust the --pod-network-cidr if you want a different subnet for Flannel or another CNI
sudo kubeadm init --pod-network-cidr=10.244.0.0/16

echo "=== [7/8] Setting up kubeconfig for your user ==="
mkdir -p $HOME/.kube
sudo cp -i /etc/kubernetes/admin.conf $HOME/.kube/config
sudo chown $(id -u):$(id -g) $HOME/.kube/config

echo "=== [8/8] (Optional) Installing Flannel CNI ==="
read -rp "Do you want to install Flannel CNI now? [y/N]: " INSTALL_FLANNEL

if [[ "$INSTALL_FLANNEL" =~ ^[Yy]$ ]]; then
  echo "=== Installing Flannel CNI plugin... ==="
  kubectl apply -f https://raw.githubusercontent.com/coreos/flannel/master/Documentation/kube-flannel.yml
  echo "Flannel installation command has been applied."
else
  echo "Skipping Flannel installation. You can manually install it later with:"
  echo "  kubectl apply -f https://raw.githubusercontent.com/coreos/flannel/master/Documentation/kube-flannel.yml"
fi

echo "=== Script completed successfully! ==="
echo "If you installed Flannel, you can check node status with 'kubectl get nodes -o wide'."
echo "Otherwise, remember to install a CNI plugin before scheduling pods."
