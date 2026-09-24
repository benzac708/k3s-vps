# k3s-vps

Reproducible single-node K3s platform for the AskVault AI service on an
Oracle Cloud Ampere ARM VM (4 OCPU / 24 GB RAM).

This repository owns the **node and platform bootstrap**. Application and
monitoring configuration lives in the separate
[`askvault-gitops`](https://github.com/benzac708/askvault-gitops) repository.

## Install

The install script is for a fresh Ubuntu 22.04/24.04 node. It pins K3s to
`v1.36.4+k3s1` and exposes only HTTP/HTTPS publicly. SSH and the Kubernetes API
are restricted to the private admin CIDR (`100.64.0.0/10` by default).

```bash
K3S_VERSION=v1.36.4+k3s1 ADMIN_CIDR=100.64.0.0/10 ./install.sh
export KUBECONFIG=/etc/rancher/k3s/k3s.yaml
sudo k3s kubectl get nodes -o wide
```

Do not open 6443 or 22 to `0.0.0.0/0` in the OCI Security List. If the node
must be reachable outside Tailscale, replace the default CIDR with a specific
administrator network.

## Bootstrap

After the node is healthy:

```bash
./platform/bootstrap.sh
```

The bootstrap boundary installs pinned ingress-nginx, cert-manager, Argo CD,
the ApplicationSet CRD, Argo CD Image Updater, Ollama, the AI namespace quota,
and the default-deny network policy. It is intentionally not GitOps-managed:
the platform must exist before Argo CD can reconcile applications.

The live monitoring stack and AskVault application are applied from
`askvault-gitops`, not from this repository.

## Architecture

```text
Oracle ARM VM
  └─ K3s v1.36.4
      ├─ ingress-nginx + cert-manager
      ├─ Argo CD + Image Updater
      ├─ ai-platform: Ollama + PVC
      ├─ monitoring: Prometheus + Grafana (askvault-gitops)
      └─ askvault: RAG API + ServiceMonitor (askvault-gitops)
```

## Operations

```bash
sudo k3s kubectl get pods -A
sudo k3s kubectl get ingress -A
sudo k3s kubectl get certificate -A
sudo k3s kubectl -n argocd get applications
sudo k3s kubectl -n argocd get imageupdaters
sudo k3s kubectl -n askvault get pods
sudo k3s kubectl -n monitoring get pods
journalctl -u k3s -f
```

## Security decisions

- The Kubernetes API is private/admin-only; public ingress is 80/443 only.

- Ollama's image is digest-pinned and its ingress is limited to AskVault pods.

- AskVault runs as UID 10001 with a read-only root filesystem, no API token, a
  NetworkPolicy and no public metrics path.

- The `ai-platform` namespace has a default-deny ingress policy and a resource
  quota.

- Grafana credentials are supplied through a Kubernetes Secret, never Git.

## Incidents

`notes/break-fix.md` records real failures and their verified fixes, including
RWO/PVC scheduling, namespace quota, missing ApplicationSet CRD, Helm readiness
timeouts, and mutable image delivery.
