#!/usr/bin/env bash

# Made by: Arseni Skobelev (gh: https://github.com/ArseniSkobelev)

# This script allows for simple preparation of a single (on-prem) K8s node.
# It installs all of the required packages and adds all of the settings needed for
# (relatively) simple on-prem K8s deployment.

# Exit script on error
set -e

# Define text-log colors
ERROR='\033[0;31m'
INFO='\033[0;33m'
SUCCESS='\033[0;32m'
NC='\033[0m'

# ----------------------
# |    Disable swap    |
# ----------------------
echo $INFO"[Step 1 | Swap] Disabling swap"

sudo swapoff -a >> /dev/null
sudo sed -i '/ swap / s/^\(.*\)$/#\1/g' /etc/fstab >> /dev/null

echo $SUCCESS"[Step 1 | Swap] Swap disabled successfully!"$NC


# --------------------------------------------
# |    Add kernel settings and set params    |
# --------------------------------------------
echo $INFO"[Step 2 | Kernel] Adding kernel settings"$NC

sudo tee /etc/modules-load.d/containerd.conf >> /dev/null <<EOF
overlay
br_netfilter
EOF

sudo modprobe overlay >> /dev/null && sudo modprobe br_netfilter >> /dev/null

sudo tee /etc/sysctl.d/kubernetes.conf >> /dev/null <<EOF
net.bridge.bridge-nf-call-ip6tables = 1
net.bridge.bridge-nf-call-iptables = 1
net.ipv4.ip_forward = 1
EOF

sudo sysctl --ignore --quiet --system >> /dev/null

echo $SUCCESS"[Step 2 | Kernel] Kernel settings added successfully!"$NC


# ----------------------------
# |    Install Containerd    |
# ----------------------------
echo $INFO"[Step 3 | Container runtime] Installing Containerd.."

sudo curl -fsSL https://download.docker.com/linux/ubuntu/gpg | sudo gpg --dearmour -o /etc/apt/trusted.gpg.d/docker.gpg >> /dev/null
sudo add-apt-repository "deb [arch=amd64] https://download.docker.com/linux/ubuntu $(lsb_release -cs) stable" --yes >> /dev/null

asdasdasdasd

sudo apt-get update >> /dev/null
sudo apt-get install -y containerd.io >> /dev/null

containerd config default | sudo tee /etc/containerd/config.toml >/dev/null 2>&1
sudo sed -i 's/SystemdCgroup \= false/SystemdCgroup \= true/g' /etc/containerd/config.toml >> /dev/null
sudo systemctl restart containerd >> /dev/null
sudo systemctl enable containerd >> /dev/null

echo $SUCCESS"[Step 3 | Container runtime] Containerd installed successfully!"$NC


# ---------------------------
# |    Install K8s tools    |
# ---------------------------
echo $INFO"[Step 4 | Kubernetes] Installing K8s tooling"

curl -s https://packages.cloud.google.com/apt/doc/apt-key.gpg | sudo gpg --dearmour -o /etc/apt/trusted.gpg.d/kubernetes-xenial.gpg >> /dev/null
sudo apt-add-repository "deb http://apt.kubernetes.io/ kubernetes-xenial main" --yes >> /dev/null

sudo apt-get update >> /dev/null
sudo apt-get install -y kubelet kubeadm kubectl >> /dev/null
sudo apt-mark hold kubelet kubeadm kubectl >> /dev/null

echo $SUCCESS"[Step 4 | Kubernetes] All of the required K8s tools installed successfully"$NC


# -------------------
# |    Summarize    |
# -------------------

host=$(hostname)

echo -e "\n"$SUCCESS$host "| Node ready for action!"$NC
