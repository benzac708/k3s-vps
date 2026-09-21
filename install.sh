#!/bin/bash
# k3s single-node install. Tested on Ubuntu 22.04.
set -euo pipefail

sudo apt update && sudo apt upgrade -y
sudo hostnamectl set-hostname k3s-01 || true

sudo ufw allow 22/tcp || true
sudo ufw allow 6443/tcp || true
sudo ufw allow 80/tcp || true
sudo ufw allow 443/tcp || true
sudo ufw --force enable

curl -sfL https://get.k3s.io | sh -
sudo systemctl enable k3s
sudo k3s kubectl get nodes
