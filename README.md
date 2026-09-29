# k3s-vps

Node bootstrap for the AskVault single-node k3s platform on an Oracle Cloud
Ampere ARM VM (4 OCPU / 24 GB RAM, free tier). Everything after the node is
healthy lives in the application repo
([`askvault`](https://github.com/benzac708/askvault), private) and the
cluster-and-GitOps repo ([`askvault-gitops`](https://github.com/benzac708/askvault-gitops), private).

This repository owns exactly one thing: **bringing a fresh node to the point
where the GitOps flow can take over.**

## Install

`install.sh` is for a fresh Ubuntu 22.04/24.04 node. It pins K3s to
`v1.36.4+k3s1` and exposes only HTTP/HTTPS publicly. SSH and the Kubernetes
API are restricted to the private admin CIDR (Tailscale `100.64.0.0/10` by
default).

```bash
K3S_VERSION=v1.36.4+k3s1 ADMIN_CIDR=100.64.0.0/10 ./install.sh
export KUBECONFIG=/etc/rancher/k3s/k3s.yaml
sudo k3s kubectl get nodes -o wide
```

Do not open 6443 or 22 to `0.0.0.0/0` in the OCI Security List. If the node
must be reachable outside Tailscale, replace the default CIDR with a specific
administrator network.

## After the node is healthy

Everything else is elsewhere, deliberately:

- **Cluster + application GitOps** - `askvault-gitops`, including the
  scripted rebuild (`hack/00…99`), the dev/prod overlays, and the Argo CD
  objects. Argo CD reconciles the `askvault-prod`/`askvault-dev` applications
  from that repository.
- **Ingress is k3s-native Traefik,** deployed as a NodePort behind a host-level
  Caddy on 80/443, with a cloudflared tunnel at the edge. Ingress-nginx is
  deliberately not used: Traefik is the ingress controller k3s ships with, and
  the whole edge chain is documented in `askvault-gitops/hack`.
- **The model is hosted, not local.** Ollama was evaluated and rejected: a
  local model on this box is too slow and too weak for the RAG service. The
  service calls a pinned hosted model (OpenRouter) instead - see the
  `askvault` repo for the provider seam and the rate ceilings that protect its
  quota.
- **cert-manager** is required by the monitoring stack's admission webhooks
  (the live `Certificate` objects are `kube-prometheus-stack-admission` and
  `kube-prometheus-stack-root-cert`); `askvault-gitops/hack/31-monitoring.sh`
  installs it. `tls/cluster-issuer.yaml` here is the Let's Encrypt convention
  only - the public edge terminates TLS at cloudflared, so no public object
  consumes the issuer.

## Verification (CI)

`.github/workflows/verify.yml` runs on push and pull request: actionlint,
`bash -n` + shellcheck on the scripts, yamllint, gitleaks over history,
kubeconform on the manifests, and a Trivy fs/misconfig/secret scan. Tools are
checksum-pinned in `scripts/install-tools.sh`. This is the estate's public,
green CI.

```bash
scripts/verify.sh
```

## Operations

```bash
sudo k3s kubectl get nodes -o wide
journalctl -u k3s -f
```

See `notes/break-fix.md` for what broke.