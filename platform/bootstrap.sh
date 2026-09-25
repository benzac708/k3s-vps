#!/usr/bin/env bash
set -euo pipefail

INGRESS_NGINX=controller-v1.15.1
CERT_MANAGER=v1.21.2
ARGOCD=v3.5.3

# This is the bootstrap boundary: platform components must exist before Argo CD
# can own application configuration. Everything after this script is in Git.
kubectl apply -f "https://raw.githubusercontent.com/kubernetes/ingress-nginx/${INGRESS_NGINX}/deploy/static/provider/cloud/deploy.yaml"
kubectl apply -f "https://github.com/cert-manager/cert-manager/releases/download/${CERT_MANAGER}/cert-manager.yaml"
kubectl create namespace argocd --dry-run=client -o yaml | kubectl apply -f -
kubectl apply -n argocd -f "https://raw.githubusercontent.com/argoproj/argo-cd/${ARGOCD}/manifests/install.yaml"
# The full Argo CD install includes the ApplicationSet controller but not this
# CRD in v3.5.3. Applying it prevents the controller restart loop.
kubectl apply --server-side --force-conflicts -f "https://raw.githubusercontent.com/argoproj/argo-cd/${ARGOCD}/manifests/crds/applicationset-crd.yaml"
kubectl apply -n argocd -f platform/argocd-image-updater-install.yaml

kubectl -n ingress-nginx wait --for=condition=available deploy/ingress-nginx-controller --timeout=300s
kubectl -n cert-manager wait --for=condition=available deploy/cert-manager --timeout=300s
kubectl -n argocd wait --for=condition=available deploy/argocd-server --timeout=300s
kubectl -n argocd wait --for=condition=available deploy/argocd-image-updater-controller --timeout=300s

kubectl apply -f tls/cluster-issuer.yaml
kubectl apply -f platform/ai-platform.yaml
kubectl apply -f platform/ollama.yaml
kubectl apply -f platform/ai-platform-default-deny.yaml
kubectl apply -f platform/ollama-access.yaml
kubectl get pods -A
