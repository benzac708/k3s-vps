# k3s-homelab

Single-node k3s on Oracle free tier. My K8s playground.

Node: Ubuntu 22.04, 1 vCPU / 1GB RAM, k3s v1.31.

## Setup

```bash
./install.sh
export KUBECONFIG=~/.kube/config-k3s
kubectl get nodes
```

OCI console: open 6443, 80, 443 in the security list. `ufw` alone is not enough.

## What's running

- `demo` deployment (nginx, 2 replicas)
- ingress-nginx, host `demo.<IP>.nip.io`
- cert-manager + Let's Encrypt (optional)

## Useful

```bash
kubectl get pods,svc,ingress
kubectl logs -l app=demo
kubectl describe pod -l app=demo
journalctl -u k3s -f
```

See `notes/break-fix.md` for what broke.
