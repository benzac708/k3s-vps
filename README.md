# k3s-vps

Single-node K3s on Oracle Cloud free tier (Ampere ARM: 4 OCPU / 24 GB RAM).
The floor AskVault stands on. One `install.sh` from bare Ubuntu 22.04 to a
TLS-terminated cluster; everything above the node lives in git.

## Setup (fresh node only)

```bash
./install.sh
export KUBECONFIG=~/.kube/config-k3s
kubectl get nodes
```

OCI console: open 6443, 80, 443 in the security list. `ufw` alone is not enough.

Then, once per cluster:

```bash
./platform/bootstrap.sh   # ingress-nginx + cert-manager + ArgoCD (pinned) + ollama
```

## What's running

- `askvault` namespace: AskVault RAG API (GitOps-synced, `askvault.zachara.dev`)
- `ai-platform` namespace: Ollama (shared LLM/embeddings for the box)
- `monitoring` namespace: Prometheus + Grafana (deploy via askvault-gitops)
- `demo` namespace: nginx demo (first-deploy smoke test)
- ingress-nginx + cert-manager (Let's Encrypt prod)

Retired 2026-09-23: the old `ai-demo/ai-app` deployment and the hand-applied
`ai-platform/llm-api` stack were deleted, absorbed into AskVault + Ollama above.

## Useful

```bash
kubectl get pods -A
kubectl get ingress -A
kubectl get certificate -A
kubectl logs -l app=askvault -n askvault --tail=50
journalctl -u k3s -f
```

See `notes/break-fix.md` for what broke.
