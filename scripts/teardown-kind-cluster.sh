#!/usr/bin/env bash
# ==============================================================================
# Script: teardown-kind-cluster.sh
# Purpose: Gracefully destroys local Kind cluster and cleans up resources
# ==============================================================================
set -euo pipefail

RED='\033[0;31m'
GREEN='\033[0;32m'
BLUE='\033[0;34m'
YELLOW='\033[1;33m'
NC='\033[0m'

CLUSTER_NAME="zero-trust-cluster"

echo -e "${BLUE}================================================================${NC}"
echo -e "${BLUE}  Teardown & Cleanup: Zero-Trust Local Kubernetes Cluster        ${NC}"
echo -e "${BLUE}================================================================${NC}"

if ! command -v kind &>/dev/null; then
  echo -e "${RED}[-] Error: 'kind' CLI is not found in PATH.${NC}"
  exit 1
fi

if kind get clusters | grep -q "^${CLUSTER_NAME}$"; then
  echo -e "${YELLOW}[Step 1/3] Deleting Kind cluster '${CLUSTER_NAME}'...${NC}"
  kind delete cluster --name "${CLUSTER_NAME}"
  echo -e "${GREEN}[+] Cluster '${CLUSTER_NAME}' successfully deleted.${NC}"
else
  echo -e "${YELLOW}[!] Cluster '${CLUSTER_NAME}' does not exist. Skipping deletion.${NC}"
fi

echo -e "\n${BLUE}[Step 2/3] Cleaning up lingering kubeconfig contexts...${NC}"
kubectl config delete-context "kind-${CLUSTER_NAME}" > /dev/null 2>&1 || true
kubectl config delete-cluster "kind-${CLUSTER_NAME}" > /dev/null 2>&1 || true
echo -e "${GREEN}[+] Kubeconfig context purged.${NC}"

echo -e "\n${BLUE}[Step 3/3] Pruning orphaned docker volumes...${NC}"
docker volume prune -f --filter "label=io.x-k8s.kind.cluster=${CLUSTER_NAME}" > /dev/null 2>&1 || true
echo -e "${GREEN}[+] Orphaned volumes pruned.${NC}"

echo -e "\n${BLUE}================================================================${NC}"
echo -e "${GREEN}  Teardown and cleanup completed successfully!                   ${NC}"
echo -e "${BLUE}================================================================${NC}"
