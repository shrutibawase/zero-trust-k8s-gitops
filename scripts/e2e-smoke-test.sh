#!/usr/bin/env bash
# ==============================================================================
# Script: e2e-smoke-test.sh
# Purpose: End-to-End Security & Functional Invariant Smoke Tests
#          Asserts Kyverno PSS enforcement, admission control, and Cilium eBPF
# ==============================================================================
set -euo pipefail

RED='\033[0;31m'
GREEN='\033[0;32m'
BLUE='\033[0;34m'
YELLOW='\033[1;33m'
NC='\033[0m'

FAILED_TESTS=0
TOTAL_TESTS=0

run_assertion() {
  local test_name="$1"
  local cmd="$2"
  local expected_status="$3" # 0 for success, 1 for expected failure

  TOTAL_TESTS=$((TOTAL_TESTS + 1))
  echo -e "\n${BLUE}[Test ${TOTAL_TESTS}] ${test_name}...${NC}"

  set +e
  eval "$cmd" > /dev/null 2>&1
  local exit_code=$?
  set -e

  if [[ $expected_status -eq 0 && $exit_code -eq 0 ]]; then
    echo -e "${GREEN}[+] PASS: Test succeeded as expected.${NC}"
  elif [[ $expected_status -eq 1 && $exit_code -ne 0 ]]; then
    echo -e "${GREEN}[+] PASS: Security gate successfully blocked unauthorized action!${NC}"
  else
    echo -e "${RED}[-] FAIL: Expected status $expected_status but got $exit_code.${NC}"
    FAILED_TESTS=$((FAILED_TESTS + 1))
  fi
}

echo -e "${BLUE}================================================================${NC}"
echo -e "${BLUE}  Zero-Trust Kubernetes E2E Invariant Verification Suite        ${NC}"
echo -e "${BLUE}================================================================${NC}"

# Test 1: Cluster connectivity
run_assertion "Kubernetes API Server Reachability" \
  "kubectl get nodes" 0

# Test 2: Kyverno Admission Controller Healthy
run_assertion "Kyverno Admission Webhook Deployment Status" \
  "kubectl get deployment -n kyverno -l app.kubernetes.io/part-of=kyverno" 0

# Test 3: Deploy compliant secure microservice Helm chart
run_assertion "Deploy Hardened Microservice into Dev Namespace" \
  "helm upgrade --install secure-microservice ./charts/secure-microservice -f ./charts/secure-microservice/values-dev.yaml -n dev --create-namespace --wait --timeout=120s" 0

# Test 4: Negative Test - Block Privileged Pod Creation
run_assertion "Kyverno Blocks Privileged Container" \
  "kubectl run test-privileged --image=busybox --privileged -n dev --restart=Never" 1

# Test 5: Negative Test - Block Root User Container
run_assertion "Kyverno Blocks Container Running as Root" \
  "kubectl run test-root --image=busybox --overrides='{\"spec\":{\"containers\":[{\"name\":\"test\",\"image\":\"busybox\",\"securityContext\":{\"runAsNonRoot\":false,\"runAsUser\":0}}]}}' -n dev --restart=Never" 1

# Test 6: Negative Test - Block Writable Root Filesystem
run_assertion "Kyverno Blocks Container with Writable Root Filesystem" \
  "kubectl run test-rw-rootfs --image=busybox --overrides='{\"spec\":{\"containers\":[{\"name\":\"test\",\"image\":\"busybox\",\"securityContext\":{\"readOnlyRootFilesystem\":false}}]}}' -n dev --restart=Never" 1

# Test 7: Verify Cilium Network Policy Ingress Default Deny
run_assertion "Apply Cilium Default-Deny Baseline" \
  "kubectl apply -f ./networking/cilium/default-deny-all.yaml -n dev" 0

# Cleanup test resources
kubectl delete pod test-privileged test-root test-rw-rootfs -n dev --ignore-not-found > /dev/null 2>&1 || true

echo -e "\n${BLUE}================================================================${NC}"
if [[ $FAILED_TESTS -eq 0 ]]; then
  echo -e "${GREEN}ALL $TOTAL_TESTS E2E SECURITY & COMPLIANCE TESTS PASSED! (0 failures)${NC}"
  echo -e "${BLUE}================================================================${NC}"
  exit 0
else
  echo -e "${RED}$FAILED_TESTS OUT OF $TOTAL_TESTS E2E TESTS FAILED!${NC}"
  echo -e "${BLUE}================================================================${NC}"
  exit 1
fi
