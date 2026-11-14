#!/usr/bin/env bash
# ==============================================================================
# Script: verify-image.sh
# Purpose: Comprehensive Sigstore Cosign Verification Suite
#          Verifies container signature, SPDX SBOM attestation, and SLSA provenance
# ==============================================================================
set -euo pipefail

RED='\033[0;31m'
GREEN='\033[0;32m'
BLUE='\033[0;34m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

IMAGE_REF="${1:-ghcr.io/shrutibawase/zero-trust-k8s-gitops:latest}"
CERT_IDENTITY_REGEXP="${2:-^https://github.com/shrutibawase/.*}"
CERT_OIDC_ISSUER="${3:-https://token.actions.githubusercontent.com}"

echo -e "${BLUE}================================================================${NC}"
echo -e "${BLUE}  Sigstore Cosign Multi-Tier Supply Chain Verifier               ${NC}"
echo -e "${BLUE}================================================================${NC}"
echo -e "Target Image:               ${YELLOW}${IMAGE_REF}${NC}"
echo -e "Expected Certificate Regex: ${YELLOW}${CERT_IDENTITY_REGEXP}${NC}"
echo -e "Expected OIDC Issuer:       ${YELLOW}${CERT_OIDC_ISSUER}${NC}"
echo ""

# 1. Check if cosign CLI is installed
if ! command -v cosign &>/dev/null; then
  echo -e "${RED}[-] Error: 'cosign' CLI is not installed.${NC}"
  echo -e "    Install via: brew install cosign  or  go install github.com/sigstore/cosign/v2/cmd/cosign@latest"
  exit 1
fi

export COSIGN_EXPERIMENTAL=1

# 2. Verify Keyless Image Signature
echo -e "${BLUE}[1/3] Verifying Container Cryptographic Signature...${NC}"
if cosign verify \
  --certificate-identity-regexp "${CERT_IDENTITY_REGEXP}" \
  --certificate-oidc-issuer "${CERT_OIDC_ISSUER}" \
  "${IMAGE_REF}" > /dev/null 2>&1; then
  echo -e "${GREEN}[+] PASS: Container image signature is valid and logged in Rekor!${NC}"
else
  echo -e "${RED}[-] FAIL: Image signature verification failed or image unsigned.${NC}"
  echo -e "    Run manual debug: cosign verify --certificate-identity-regexp \"${CERT_IDENTITY_REGEXP}\" --certificate-oidc-issuer \"${CERT_OIDC_ISSUER}\" \"${IMAGE_REF}\""
fi

# 3. Verify SPDX SBOM Attestation
echo -e "\n${BLUE}[2/3] Verifying Software Bill of Materials (SPDX SBOM) Attestation...${NC}"
if cosign verify-attestation \
  --type spdxjson \
  --certificate-identity-regexp "${CERT_IDENTITY_REGEXP}" \
  --certificate-oidc-issuer "${CERT_OIDC_ISSUER}" \
  "${IMAGE_REF}" > /dev/null 2>&1; then
  echo -e "${GREEN}[+] PASS: SPDX SBOM attestation verified successfully!${NC}"
else
  echo -e "${YELLOW}[!] WARNING: SPDX SBOM attestation could not be verified.${NC}"
fi

# 4. Verify SLSA Level 3 Provenance Attestation
echo -e "\n${BLUE}[3/3] Verifying SLSA Level 3 Build Provenance Attestation...${NC}"
if cosign verify-attestation \
  --type "https://slsa.dev/provenance/v0.2" \
  --certificate-identity-regexp "${CERT_IDENTITY_REGEXP}" \
  --certificate-oidc-issuer "${CERT_OIDC_ISSUER}" \
  "${IMAGE_REF}" > /dev/null 2>&1; then
  echo -e "${GREEN}[+] PASS: SLSA Level 3 build provenance verified successfully!${NC}"
else
  echo -e "${YELLOW}[!] WARNING: SLSA provenance attestation could not be verified.${NC}"
fi

echo -e "\n${BLUE}================================================================${NC}"
echo -e "${GREEN}Verification workflow evaluation complete.${NC}"
echo -e "${BLUE}================================================================${NC}"
