# Supply Chain Security & SLSA Level 3 Framework

This directory houses the configurations, templates, and specifications for **Zero-Trust Supply Chain Security** across the SDLC.

---

## Directory Layout

```
security/
├── cosign/
│   └── README.md                       # Sigstore Cosign keyless signing architecture
├── sbom/
│   └── README.md                       # SPDX 2.3 & CycloneDX 1.5 SBOM design
├── slsa/
│   ├── README.md                       # SLSA Level 3 provenance specification
│   └── predicate-template.json         # In-toto SLSA provenance predicate template
└── vulnerability-management/
    └── README.md                       # Dual-scanner (Trivy & Grype) policy & runbook
```

---

## Key Features

1. **Keyless Signing:** OIDC-based container signing via Sigstore Cosign without long-lived private keys.
2. **Dual SBOM Generation:** Anchore Syft generates both SPDX 2.3 and CycloneDX 1.5 machine-readable inventories.
3. **Automated Vulnerability Gating:** Aqua Trivy and Anchore Grype enforce zero-tolerance for `CRITICAL` or `HIGH` CVEs.
4. **SLSA Level 3 Provenance:** Non-forgeable build metadata attested using in-toto specifications.
5. **Runtime Cluster Admission:** Kyverno ClusterPolicy verifies signatures before admitting Pods into the cluster.
