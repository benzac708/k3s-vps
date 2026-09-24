#!/usr/bin/env bash
set -euo pipefail

K3S_VERSION="${K3S_VERSION:-v1.36.4+k3s1}"
ADMIN_CIDR="${ADMIN_CIDR:-100.64.0.0/10}"

# Public ingress is limited to HTTP/HTTPS. SSH and the Kubernetes API are
# reachable through the private admin CIDR (Tailscale by default).
sudo apt-get update
sudo apt-get upgrade -y
sudo hostnamectl set-hostname k3s-01 || true

sudo ufw allow from "$ADMIN_CIDR" to any port 22 proto tcp || true
sudo ufw allow from "$ADMIN_CIDR" to any port 6443 proto tcp || true
sudo ufw allow 80/tcp || true
sudo ufw allow 443/tcp || true
sudo ufw --force enable

curl --proto '=https' --tlsv1.2 --fail --silent --show-error --location \
  https://get.k3s.io -o /tmp/k3s-install.sh
INSTALL_K3S_VERSION="$K3S_VERSION" sh /tmp/k3s-install.sh
sudo systemctl enable --now k3s
sudo k3s kubectl get nodes -o wide
