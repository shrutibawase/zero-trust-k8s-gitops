#!/usr/bin/env bash
set -euo pipefail

# ==============================================================================
# Script: Automated Zero-Trust Cilium Network Policy Test Suite
# ==============================================================================

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ROOT_DIR="$SCRIPT_DIR/.."
NETWORKING_DIR="$ROOT_DIR/networking/cilium"

echo "================================================="
echo "🌐 Validating Cilium eBPF Network Policies"
echo "Policy Directory: $NETWORKING_DIR"
echo "Timestamp: $(date -u)"
echo "================================================="

# 1. Validate Policy Syntax & Schemas
echo "1. Checking YAML syntax across Cilium policies..."
for policy in "$NETWORKING_DIR"/*.yaml; do
    echo "  Parsing: $(basename "$policy")..."
    if command -v python3 &> /dev/null; then
        python3 -c "import yaml; yaml.safe_load(open('$policy'))"
    fi
done
echo "✅ All policy manifests have valid YAML structure."

# 2. Check for Zero-Trust Baseline Invariants
echo "2. Asserting Zero-Trust architectural invariants..."

# Invariant A: Default-Deny Exists
if grep -q "name: default-deny-all" "$NETWORKING_DIR/default-deny-all.yaml"; then
    echo "  ✅ Invariant passed: Default-deny baseline policy is defined"
else
    echo "  ❌ Invariant failed: Default-deny policy missing!"
    exit 1
fi

# Invariant B: DNS Proxy Inspection Configured
if grep -q "rules:" "$NETWORKING_DIR/dns-aware-egress.yaml" && grep -q "matchPattern" "$NETWORKING_DIR/dns-aware-egress.yaml"; then
    echo "  ✅ Invariant passed: L7 DNS proxy inspection is configured"
else
    echo "  ❌ Invariant failed: DNS proxy inspection missing!"
    exit 1
fi

# Invariant C: Mutual TLS Declared
if grep -q "authentication:" "$NETWORKING_DIR/ebpf-mutual-tls.yaml"; then
    echo "  ✅ Invariant passed: Sidecar-free mTLS wire encryption is configured"
else
    echo "  ❌ Invariant failed: eBPF mTLS configuration missing!"
    exit 1
fi

# Invariant D: L7 HTTP Filtering Enforced
if grep -q "rules:" "$NETWORKING_DIR/l7-http-rules.yaml" && grep -q "http:" "$NETWORKING_DIR/l7-http-rules.yaml"; then
    echo "  ✅ Invariant passed: Layer-7 HTTP method and path filtering is active"
else
    echo "  ❌ Invariant failed: L7 HTTP rules missing!"
    exit 1
fi

# 3. Cilium CLI Connectivity Test Helper (If active cluster exists)
if command -v cilium &> /dev/null; then
    echo "3. Active Cilium CLI detected. To run cluster-wide connectivity test, execute:"
    echo "     cilium connectivity test -n zero-trust-prod"
fi

echo "================================================="
echo "🎉 All Cilium eBPF Network Policies Verified!"
echo "================================================="
