#!/usr/bin/env bash
# One-time platform bootstrap. Run ONCE on a fresh node, in order.
# Re-runs are safe (kubectl apply), but this is not GitOps-synced on
# purpose: ArgoCD, ingress and cert-manager must exist before anything
# can sync through them. Everything after this file lives in git.
#
# Pinned versions, verified 2026-09-23. Bump deliberately, not by latest.
set -euo pipefail

INGRESS_NGINX=controller-v1.15.1
CERT_MANAGER=v1.21.2
ARGOCD=v3.5.3

kubectl apply -f "https://raw.githubusercontent.com/kubernetes/ingress-nginx/${INGRESS_NGINX}/deploy/static/provider/cloud/deploy.yaml"
kubectl apply -f "https://github.com/cert-manager/cert-manager/releases/download/${CERT_MANAGER}/cert-manager.yaml"
kubectl create namespace argocd --dry-run=client -o yaml | kubectl apply -f -
kubectl apply -n argocd -f "https://raw.githubusercontent.com/argoproj/argo-cd/${ARGOCD}/manifests/install.yaml"

kubectl -n ingress-nginx wait --for=condition=available deploy/ingress-nginx-controller --timeout=300s
kubectl -n cert-manager wait --for=condition=available deploy/cert-manager --timeout=300s
kubectl -n argocd wait --for=condition=available deploy/argocd-server --timeout=300s
kubectl apply -f ../tls/cluster-issuer.yaml
kubectl apply -f platform/ollama.yaml
kubectl get pods -A
