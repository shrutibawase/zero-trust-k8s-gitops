#!/usr/bin/env bash
# ==============================================================================
# Script: generate-slsa-predicate.sh
# Purpose: Generates an in-toto SLSA Provenance v0.2 Predicate JSON for Cosign Attestation
# ==============================================================================
set -euo pipefail

IMAGE_DIGEST="${1:-}"
OUTPUT_FILE="${2:-provenance-predicate.json}"

if [[ -z "$IMAGE_DIGEST" ]]; then
  echo "[-] Error: Image digest (sha256:...) required as argument 1" >&2
  exit 1
fi

# Clean digest prefix if present
DIGEST_HEX="${IMAGE_DIGEST#sha256:}"
REPO="${GITHUB_REPOSITORY:-shrutibawase/zero-trust-k8s-gitops}"
COMMIT_SHA="${GITHUB_SHA:-$(git rev-parse HEAD 2>/dev/null || echo "unknown")}"
RUN_ID="${GITHUB_RUN_ID:-manual-build}"
NOW_ISO="$(date -u +"%Y-%m-%dT%H:%M:%SZ")"

cat <<EOF > "$OUTPUT_FILE"
{
  "_type": "https://in-toto.io/Statement/v0.1",
  "predicateType": "https://slsa.dev/provenance/v0.2",
  "subject": [
    {
      "name": "ghcr.io/${REPO}",
      "digest": {
        "sha256": "${DIGEST_HEX}"
      }
    }
  ],
  "predicate": {
    "builder": {
      "id": "https://github.com/${REPO}/.github/workflows/supply-chain-security.yml@refs/heads/main"
    },
    "buildType": "https://github.com/slsa-framework/slsa-github-generator/container@v1",
    "invocation": {
      "configSource": {
        "uri": "git+https://github.com/${REPO}",
        "digest": {
          "sha1": "${COMMIT_SHA}"
        },
        "entryPoint": ".github/workflows/supply-chain-security.yml"
      },
      "parameters": {
        "event_name": "${GITHUB_EVENT_NAME:-push}",
        "ref": "${GITHUB_REF:-refs/heads/main}"
      },
      "environment": {
        "github_run_id": "${RUN_ID}",
        "runner_os": "Linux"
      }
    },
    "metadata": {
      "buildStartedOn": "${NOW_ISO}",
      "buildFinishedOn": "${NOW_ISO}",
      "completeness": {
        "parameters": true,
        "environment": true,
        "materials": true
      },
      "reproducible": false
    },
    "materials": [
      {
        "uri": "git+https://github.com/${REPO}",
        "digest": {
          "sha1": "${COMMIT_SHA}"
        }
      }
    ]
  }
}
EOF

echo "[+] Successfully generated SLSA Provenance Predicate at: $OUTPUT_FILE"
