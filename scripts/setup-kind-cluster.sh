#!/usr/bin/env bash
# ==============================================================================
# Script: setup-kind-cluster.sh
# Purpose: One-click local bootstrap of Zero-Trust Kubernetes Cluster
#          Installs Kind, Cilium (eBPF + kube-proxy replacement), Kyverno & ArgoCD
# ==============================================================================
set -euo pipefail

RED='\033[0;31m'
GREEN='\033[0;32m'
BLUE='\033[0;34m'
YELLOW='\033[1;33m'
NC='\033[0m'

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
CLUSTER_NAME="zero-trust-cluster"

echo -e "${BLUE}================================================================${NC}"
echo -e "${BLUE}  Bootstrapping Zero-Trust Kubernetes Local Cluster             ${NC}"
echo -e "${BLUE}================================================================${NC}"

# 1. Prerequisite checks
for cmd in docker kind kubectl helm; do
  if ! command -v "$cmd" &>/dev/null; then
    echo -e "${RED}[-] Error: Required tool '$cmd' is not installed or not in PATH.${NC}"
    exit 1
  fi
done
echo -e "${GREEN}[+] Prerequisites verified: docker, kind, kubectl, helm.${NC}"

# 2. Check if Docker daemon is running
if ! docker info > /dev/null 2>&1; then
  echo -e "${RED}[-] Error: Docker daemon is not running.${NC}"
  exit 1
fi

# 3. Create Kind cluster if not already present
if kind get clusters | grep -q "^${CLUSTER_NAME}$"; then
  echo -e "${YELLOW}[!] Kind cluster '${CLUSTER_NAME}' already exists. Reusing.${NC}"
else
  echo -e "${BLUE}[Step 1/4] Creating Kind Cluster with eBPF support...${NC}"
  kind create cluster --config "$ROOT_DIR/cluster/kind-config.yaml"
fi

kubectl cluster-info --context "kind-${CLUSTER_NAME}"

# 4. Install Cilium CNI with eBPF Kube-Proxy Replacement
echo -e "\n${BLUE}[Step 2/4] Installing Cilium CNI with eBPF Kube-Proxy Replacement...${NC}"
helm repo add cilium https://helm.cilium.io/ --force-update > /dev/null
helm upgrade --install cilium cilium/cilium \
  --namespace kube-system \
  --version 1.15.4 \
  --set kubeProxyReplacement=true \
  --set k8sServiceHost="${CLUSTER_NAME}-control-plane" \
  --set k8sServicePort=6443 \
  --set hubble.enabled=true \
  --set hubble.relay.enabled=true \
  --set hubble.ui.enabled=true \
  --set hubble.metrics.enabled="{dns,drop,tcp,flow,port-distribution,icmp,http}" \
  --wait

echo -e "${GREEN}[+] Cilium eBPF CNI and Hubble successfully deployed.${NC}"

# 5. Install Kyverno Policy Engine
echo -e "\n${BLUE}[Step 3/4] Installing Kyverno Admission Controller...${NC}"
helm repo add kyverno https://kyverno.github.io/kyverno/ --force-update > /dev/null
helm upgrade --install kyverno kyverno/kyverno \
  --namespace kyverno \
  --create-namespace \
  --version 3.1.4 \
  --set admissionController.replicas=1 \
  --set backgroundController.replicas=1 \
  --set cleanupController.replicas=1 \
  --set reportsController.replicas=1 \
  --wait

echo -e "${GREEN}[+] Kyverno Admission Engine successfully deployed.${NC}"

# 6. Install ArgoCD & Apply Root App-of-Apps
echo -e "\n${BLUE}[Step 4/4] Installing ArgoCD GitOps Engine...${NC}"
kubectl create namespace argocd --dry-run=client -o yaml | kubectl apply -f -
kubectl apply -n argocd -f https://raw.githubusercontent.com/argoproj/argo-cd/v2.10.4/manifests/install.yaml

echo -e "Waiting for ArgoCD Server to become ready..."
kubectl rollout status deployment/argocd-server -n argocd --timeout=180s

echo -e "\n${BLUE}[Deploying GitOps Root Application]...${NC}"
kubectl apply -f "$ROOT_DIR/gitops/root-app.yaml"

echo -e "\n${BLUE}================================================================${NC}"
echo -e "${GREEN}  Zero-Trust Cluster Bootstrap Successfully Completed!          ${NC}"
echo -e "${BLUE}================================================================${NC}"
echo -e "To access ArgoCD UI: kubectl port-forward svc/argocd-server -n argocd 8080:443"
echo -e "To access Hubble UI: kubectl port-forward svc/hubble-ui -n kube-system 12000:80"
