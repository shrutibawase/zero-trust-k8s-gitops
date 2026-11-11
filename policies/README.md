# 🛡️ Kyverno Policy-as-Code Directory

This directory contains the Kubernetes admission control policies enforcing zero-trust standards, Pod Security Standards (Restricted), image provenance verification, and automated mutation rules.

---

## 🗂 Policy Catalogue

- `kyverno/enforce-pod-security-restricted.yaml`: Blocks host namespaces (`hostNetwork`, `hostPID`, `hostIPC`) and requires default seccomp profiles.
- `kyverno/disallow-privileged-containers.yaml`: Forbids `privileged: true`, blocks privilege escalation, and enforces `capabilities.drop: [ALL]`.
- `kyverno/require-ro-rootfs.yaml`: Enforces immutable `readOnlyRootFilesystem: true` and non-root UID execution.
- `kyverno/disallow-latest-and-untrusted-registries.yaml`: Blocks mutable `:latest` tags and restricts registries to authorized enterprise endpoints.
- `kyverno/require-cosign-image-signature.yaml`: Rejects unsigned OCI container images via Sigstore Cosign verification.
- `kyverno/mutate-default-security-context.yaml`: Mutating admission policy injecting secure defaults automatically.
- `tests/`: Automated unit test matrix for the Kyverno CLI (`kyverno test`).

---

## 🚀 Running Policy Tests

```bash
# Bash
./scripts/test-policies.sh

# PowerShell
.\scripts\test-policies.ps1
```
