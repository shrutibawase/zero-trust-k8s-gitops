# Software Bill of Materials (SBOM) Generation Architecture

This repository automates the creation, validation, and attestation of machine-readable Software Bill of Materials (SBOM) for every container build using **Anchore Syft**.

---

## 1. Dual-Standard Architecture (SPDX + CycloneDX)

To satisfy both regulatory compliance and modern vulnerability scanning tooling, the CI pipeline emits two standardized formats:

| Standard | Version | Primary Purpose | Standard Body |
|---|---|---|---|
| **SPDX (Software Package Data Exchange)** | 2.3 | Legal compliance, software license auditing, ISO/IEC 5230 conformity | Linux Foundation |
| **CycloneDX** | 1.5 | Application security, CVE vulnerability correlation, component dependency graph | OWASP Foundation |

---

## 2. Syft Pipeline Workflow

The build workflow adheres to the following sequence:

1. **Squashed Layer Inspection:** Syft catalogs packages across all filesystem layers, inspecting installed OS packages (Alpine `apk`, Debian `dpkg`), language dependencies (Python, Go, Node.js), and static binaries.
2. **Digest Matching:** Syft scans against the immutable image digest (`@sha256:...`) rather than mutable tags to prevent race conditions or poisoning.
3. **Artifact Retention:** Both `sbom-spdx.json` and `sbom-cyclonedx.json` are retained in GitHub Actions for 90 days for audit trails.
4. **Cosign Attestation:** The SPDX SBOM is cryptographically attached to the OCI image artifact in GHCR using `cosign attest`.

---

## 3. Local SBOM Generation

To generate an SBOM locally from a built container image:

```bash
# Generate SPDX 2.3 JSON
syft ghcr.io/shrutibawase/zero-trust-k8s-gitops:latest -o spdx-json > sbom-spdx.json

# Generate CycloneDX 1.5 JSON
syft ghcr.io/shrutibawase/zero-trust-k8s-gitops:latest -o cyclonedx-json > sbom-cyclonedx.json

# Tabular terminal view
syft ghcr.io/shrutibawase/zero-trust-k8s-gitops:latest
```
