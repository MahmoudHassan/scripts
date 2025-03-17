#!/usr/bin/env bash
#
# install_docker_and_k8s.sh
#
# This script performs:
#   1. System update & upgrade
#   2. Docker installation and startup
#   3. Configuration of the new Kubernetes apt repo at pkgs.k8s.io
#   4. Installation of kubelet, kubeadm, and kubectl
#
# Tested on Ubuntu 24.04 (codename Noble), where apt.kubernetes.io is not supported.
#
# Usage:
#   chmod +x install_docker_and_k8s.sh
#   sudo ./install_docker_and_k8s.sh

set -e

echo "=== [1/4] Updating and upgrading Ubuntu packages... ==="
sudo apt update
sudo apt -y upgrade

echo "=== [2/4] Installing Docker... ==="
sudo apt -y install docker.io

echo "=== Enabling and starting Docker... ==="
sudo systemctl enable docker
sudo systemctl start docker

# Optional: Verify Docker status
echo "=== Docker status ==="
sudo systemctl status docker --no-pager

echo "=== Docker version ==="
docker --version

echo "=== [3/4] Adding the official Kubernetes repository from pkgs.k8s.io... ==="
# Create the directory for apt keyrings if it doesn't exist
sudo mkdir -p /etc/apt/keyrings

# Add the Kubernetes repository line (example: v1.32 channel)
echo "deb [signed-by=/etc/apt/keyrings/kubernetes-apt-keyring.gpg] \
https://pkgs.k8s.io/core:/stable:/v1.32/deb/ /" | sudo tee /etc/apt/sources.list.d/kubernetes.list

# Import the Kubernetes GPG key
curl -fsSL https://pkgs.k8s.io/core:/stable:/v1.32/deb/Release.key \
  | sudo gpg --dearmor -o /etc/apt/keyrings/kubernetes-apt-keyring.gpg

echo "=== [4/4] Installing kubeadm, kubelet, and kubectl... ==="
sudo apt-get update
sudo apt-get install -y kubelet kubeadm kubectl

# Hold the Kubernetes packages to avoid accidental upgrades
sudo apt-mark hold kubelet kubeadm kubectl

echo "=== Kubernetes tools installed ==="
echo "Kubeadm version: $(kubeadm version -o short || true)"
echo "Kubelet version: $(kubelet --version || true)"
echo "Kubectl version: $(kubectl version --client --short || true)"

echo "=== All steps completed successfully! ==="
