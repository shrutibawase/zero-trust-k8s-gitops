#!/usr/bin/env bash
set -euo pipefail

# ==============================================================================
# Script: Automated Helm Chart Linting & Zero-Trust Manifest Validation
# ==============================================================================

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ROOT_DIR="$SCRIPT_DIR/.."
CHART_DIR="$ROOT_DIR/charts/secure-microservice"

echo "================================================="
echo "🔍 Validating Helm Chart & Security Manifests"
echo "Target Chart: $CHART_DIR"
echo "Timestamp: $(date -u)"
echo "================================================="

if ! command -v helm &> /dev/null; then
    echo "⚠️ Warning: 'helm' CLI is not installed locally. Skipping dynamic lint."
    exit 0
fi

# 1. Run Helm Lint
echo "1. Running helm lint..."
helm lint "$CHART_DIR"

# 2. Render Helm Templates Dry-Run
echo "2. Rendering Helm templates in dry-run mode..."
RENDERED=$(helm template test-release "$CHART_DIR")

# 3. Assert Zero-Trust Security Baselines in Manifests
echo "3. Verifying zero-trust security invariants in rendered manifests..."

# Check non-root
echo "$RENDERED" | grep -q "runAsNonRoot: true" && echo "  ✅ Invariant passed: runAsNonRoot is enforced" || {
    echo "  ❌ Invariant failed: runAsNonRoot missing!"
    exit 1
}

# Check read-only rootfs
echo "$RENDERED" | grep -q "readOnlyRootFilesystem: true" && echo "  ✅ Invariant passed: readOnlyRootFilesystem is enforced" || {
    echo "  ❌ Invariant failed: readOnlyRootFilesystem missing!"
    exit 1
}

# Check automount token restriction
echo "$RENDERED" | grep -q "automountServiceAccountToken: false" && echo "  ✅ Invariant passed: automountServiceAccountToken is false" || {
    echo "  ❌ Invariant failed: automountServiceAccountToken is not disabled!"
    exit 1
}

# Check ResourceQuota presence
echo "$RENDERED" | grep -q "kind: ResourceQuota" && echo "  ✅ Invariant passed: ResourceQuota is configured" || {
    echo "  ❌ Invariant failed: ResourceQuota missing!"
    exit 1
}

# Check HorizontalPodAutoscaler
echo "$RENDERED" | grep -q "kind: HorizontalPodAutoscaler" && echo "  ✅ Invariant passed: HPA is configured" || {
    echo "  ❌ Invariant failed: HPA missing!"
    exit 1
}

echo "================================================="
echo "🎉 All Helm Chart & Security Invariants Passed!"
echo "================================================="
