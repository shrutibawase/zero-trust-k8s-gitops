# Zero-Trust Architecture Security & Compliance Matrix

This document provides a formal cross-reference between this repository's implementation and major enterprise security benchmarks:
- **NIST SP 800-207**: Zero Trust Architecture
- **CIS Kubernetes Benchmark v1.8**: Workload and Cluster Hardening
- **OpenSSF SLSA v0.2 / v1.0**: Supply-chain Levels for Software Artifacts (Level 3)
- **OWASP Kubernetes Top 10**: Cloud-Native Risk Mitigation

---

## 1. NIST SP 800-207 Zero Trust Tenet Mapping

| NIST SP 800-207 Tenet | Technical Implementation in This Repo | Enforcing Component | Artifact Link |
|---|---|---|---|
| **Tenet 1: All data sources and computing services are considered resources** | Granular microsegmentation of all services via CiliumNetworkPolicies | Cilium eBPF | [`networking/cilium/default-deny-all.yaml`](file:///D:/project/antigravity/zero-trust-k8s-gitops/networking/cilium/default-deny-all.yaml) |
| **Tenet 2: All communication is secured regardless of network location** | Kernel-level sidecar-free mutual TLS (mTLS) wire encryption between all pods | Cilium eBPF | [`networking/cilium/ebpf-mutual-tls.yaml`](file:///D:/project/antigravity/zero-trust-k8s-gitops/networking/cilium/ebpf-mutual-tls.yaml) |
| **Tenet 3: Access to individual enterprise resources is granted per session** | L7 HTTP method (`GET`, `POST`) and path authorization checks per request | Cilium L7 Proxy | [`networking/cilium/l7-http-rules.yaml`](file:///D:/project/antigravity/zero-trust-k8s-gitops/networking/cilium/l7-http-rules.yaml) |
| **Tenet 4: Resource access is determined by dynamic policy** | Admission webhooks dynamically evaluate image signatures and PSS profile | Kyverno | [`policies/kyverno/require-cosign-image-signature.yaml`](file:///D:/project/antigravity/zero-trust-k8s-gitops/policies/kyverno/require-cosign-image-signature.yaml) |
| **Tenet 5: Integrity and security posture of all owned assets is monitored** | Hubble flow exporter streams DNS, TCP, and drop metrics to Prometheus | Hubble Telemetry | [`networking/cilium/hubble-telemetry.yaml`](file:///D:/project/antigravity/zero-trust-k8s-gitops/networking/cilium/hubble-telemetry.yaml) |
| **Tenet 6: All resource authentication and authorization are dynamic and enforced** | GitOps continuous drift reconciliation resets manual tampering within seconds | ArgoCD | [`gitops/root-app.yaml`](file:///D:/project/antigravity/zero-trust-k8s-gitops/gitops/root-app.yaml) |

---

## 2. CIS Kubernetes Benchmark v1.8 Control Mapping

| CIS Control ID | Description | Enforcing Manifest | Status |
|---|---|---|---|
| **5.2.1** | Minimize the admission of privileged containers | `policies/kyverno/disallow-privileged-containers.yaml` | **ENFORCED** |
| **5.2.2** | Minimize the admission of containers wishing to share the host process ID namespace | `policies/kyverno/enforce-pod-security-restricted.yaml` | **ENFORCED** |
| **5.2.4** | Minimize the admission of containers with `allowPrivilegeEscalation: true` | `charts/secure-microservice/templates/deployment.yaml` | **ENFORCED** |
| **5.2.5** | Minimize the admission of root containers (`runAsNonRoot: true`) | `policies/kyverno/disallow-root-user.yaml` | **ENFORCED** |
| **5.2.6** | Minimize the admission of containers with NET_RAW capability | `charts/secure-microservice/templates/deployment.yaml` (`drop: [ALL]`) | **ENFORCED** |
| **5.2.7** | Minimize the admission of containers with added capabilities | `charts/secure-microservice/templates/deployment.yaml` | **ENFORCED** |
| **5.2.8** | Minimize the admission of containers with writable root filesystem | `policies/kyverno/require-ro-rootfs.yaml` | **ENFORCED** |
| **5.7.4** | The default namespace should not be used | `gitops/applicationset.yaml` (`dev`, `staging`, `prod` namespaces) | **ENFORCED** |

---

## 3. OpenSSF SLSA Level 3 Supply Chain Compliance

| SLSA Requirement | Verification Mechanism | Implementation File | Status |
|---|---|---|---|
| **Build Service** | Hosted, ephemeral GitHub Actions runners | `.github/workflows/supply-chain-security.yml` | **COMPLIANT** |
| **Build as Code** | Build definition checked into Git repository | `.github/workflows/supply-chain-security.yml` | **COMPLIANT** |
| **Ephemeral Environment**| Isolated virtual machine per build run | GitHub Actions Runner (`ubuntu-latest`) | **COMPLIANT** |
| **Non-Forgeable Provenance**| Signed in-toto statement via Sigstore Cosign | `security/slsa/predicate-template.json` | **COMPLIANT** |
| **Verified Inputs (Git SHA)**| Cryptographically pinned Git commit SHA in predicate | `scripts/generate-slsa-predicate.sh` | **COMPLIANT** |
| **Dependency Analysis**| Dual SBOM generation (SPDX 2.3 & CycloneDX 1.5) | `.syft.yaml` | **COMPLIANT** |
| **Vulnerability Gate** | Builds fail on CVE severity `HIGH` or `CRITICAL` | `.grype.yaml`, `.trivyignore` | **COMPLIANT** |
| **Immutable Audit Log** | Append-only public transparency log | Sigstore Rekor (`rekor.sigstore.dev`) | **COMPLIANT** |

---

## 4. OWASP Kubernetes Top 10 Mitigations

1. **K01 (Insecure Workload Configurations):** Enforced by Kyverno Restricted Pod Security Standards (`policies/kyverno/`).
2. **K02 (Supply Chain Vulnerabilities):** Mitigated via Syft SBOM, Trivy/Grype gates, and Cosign keyless signing (`security/`).
3. **K03 (Overly Permissive Network Policies):** Mitigated via Cilium default-deny and L7 DNS-restricted egress (`networking/cilium/`).
4. **K04 (Lack of Centralized Policy Enforcement):** Managed by Kyverno ClusterPolicies with `validationFailureAction: Enforce`.
5. **K05 (Inadequate Logging and Observability):** Real-time network telemetry provided by Cilium Hubble (`networking/cilium/hubble-telemetry.yaml`).
