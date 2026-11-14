# SLSA Level 3 Provenance & Attestation Architecture

This repository enforces **Supply-chain Levels for Software Artifacts (SLSA) Level 3** by capturing verifiable, non-forgeable build provenance metadata for every container artifact.

---

## 1. What is SLSA Level 3?

SLSA (pronounced *salsa*) is an open-source security framework spearheaded by OpenSSF and Google to prevent supply chain tampering. Level 3 guarantees:

- **Isolated Build Environment:** Builds occur on dedicated, ephemeral GitHub Actions runners.
- **Auditable History:** Source code, configuration, and build parameters are immutably tied to a Git commit SHA.
- **Cryptographic Provenance:** An in-toto statement attesting to the exact source commit, build platform, dependencies, and builder identity is signed via Sigstore Cosign.
- **Non-Forgeability:** Ephemeral OIDC identity guarantees only the genuine GitHub repository workflow can generate valid signatures and attestations.

---

## 2. In-Toto Predicate Format

Our attestation produces an in-toto predicate conforming to `https://slsa.dev/provenance/v0.2`:

```json
{
  "_type": "https://in-toto.io/Statement/v0.1",
  "predicateType": "https://slsa.dev/provenance/v0.2",
  "subject": [
    {
      "name": "ghcr.io/shrutibawase/zero-trust-k8s-gitops",
      "digest": { "sha256": "..." }
    }
  ],
  "predicate": {
    "builder": { "id": "https://github.com/shrutibawase/zero-trust-k8s-gitops/.github/workflows/supply-chain-security.yml@refs/heads/main" },
    "buildType": "https://github.com/slsa-framework/slsa-github-generator/container@v1",
    "invocation": { ... },
    "materials": [ ... ]
  }
}
```

---

## 3. Verifying SLSA Attestation

To cryptographically inspect the provenance attestation of an image:

```bash
cosign verify-attestation \
  --type https://slsa.dev/provenance/v0.2 \
  --certificate-identity-regexp "^https://github.com/shrutibawase/.*" \
  --certificate-oidc-issuer "https://token.actions.githubusercontent.com" \
  ghcr.io/shrutibawase/zero-trust-k8s-gitops:<TAG>
```
