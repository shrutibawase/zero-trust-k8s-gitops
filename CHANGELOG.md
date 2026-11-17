# Changelog

All notable changes to the **Zero-Trust Kubernetes GitOps & Supply Chain Security (SLSA Level 3)** project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

---

## [1.0.0] - 2026-11-17

### Added
#### Day 1: Hardened Kubernetes Workload Architecture
- Production-grade Helm chart `charts/secure-microservice` complying with Kubernetes **Pod Security Standard (PSS) Restricted** profile.
- Hardened container securityContext: `runAsNonRoot: true`, `runAsUser: 10001`, `readOnlyRootFilesystem: true`, `allowPrivilegeEscalation: false`, and `capabilities.drop: [ALL]`.
- ServiceAccount token protection: `automountServiceAccountToken: false` by default.
- Horizontal Pod Autoscaling (HPA) using `autoscaling/v2` with CPU and Memory utilization scaling.
- Automated TLS Ingress integration via cert-manager annotations.
- Namespace governance: `ResourceQuota` and container `LimitRange` guardrails.
- Cross-platform chart linting test suite (`scripts/test-charts.sh` and `scripts/test-charts.ps1`).

#### Day 2: Declarative GitOps with ArgoCD
- Root App-of-Apps pattern (`gitops/root-app.yaml`) orchestrating networking, security policies, and microservice workloads.
- Dynamic multi-environment `ApplicationSet` generating `dev`, `staging`, and `prod` targets.
- Environment value overrides: `values-dev.yaml`, `values-staging.yaml`, and `values-prod.yaml`.
- GitOps lifecycle hooks: `pre-sync-db-migration.yaml` and `post-sync-smoke-test.yaml`.
- Custom Lua health checks (`gitops/health-checks/`) for CiliumNetworkPolicies and Kyverno ClusterPolicies.
- Production `AppProject` access controls with change-freeze sync windows.

#### Day 3: Policy-as-Code Governance with Kyverno
- ClusterPolicy enforcing Pod Security Standard Restricted baseline (`policies/kyverno/enforce-pod-security-restricted.yaml`).
- Disallow privileged containers policy with zero capability escalation.
- Read-only root filesystem enforcement policy.
- Container registry whitelisting policy rejecting `:latest` and unauthorized registries.
- Mutating ClusterPolicy automatically injecting hardened securityContext defaults.
- Kyverno CLI validation test matrix (`policies/tests/kyverno-test.yaml`).
- Automated policy test runner scripts (`scripts/test-policies.sh` and `scripts/test-policies.ps1`).

#### Day 4: Zero-Trust eBPF Networking with Cilium & Hubble
- Default-deny all ingress and egress traffic baseline (`networking/cilium/default-deny-all.yaml`).
- Layer-7 DNS-aware egress proxy filtering restricting outbound access strictly to authorized domains (`*.github.com`, `ghcr.io`, `*.azure.com`).
- Sidecar-free wire mutual TLS (mTLS) encryption via eBPF kernel sockets.
- Layer-7 HTTP method and path authorization rules (`GET /healthz`, `GET/POST /api/v1/*`).
- Hubble telemetry exporter service on port 9965 exposing DNS, drop, TCP, and HTTP metrics.
- Automated connectivity assertion suite (`scripts/test-networking.sh` and `scripts/test-networking.ps1`).

#### Day 5: SLSA Level 3 Supply Chain Security
- Keyless container signing using Sigstore Cosign with ephemeral Fulcio X.509 certs and Rekor transparency log recording.
- Dual-standard Software Bill of Materials (SBOM) generation via Anchore Syft producing both **SPDX 2.3** and **CycloneDX 1.5** JSON.
- Dual-engine vulnerability gating with Aqua Trivy and Anchore Grype failing on `CRITICAL` or `HIGH` CVEs with SARIF upload to GitHub Security.
- In-toto SLSA Level 3 build provenance attestation (`https://slsa.dev/provenance/v0.2`).
- Cross-platform verification CLI tools (`scripts/verify-image.sh` and `scripts/verify-image.ps1`).
- Automated supply chain test suite (`scripts/test-supply-chain.ps1`) verifying all invariants.

#### Day 6: CI/CD Automation & End-to-End Testing
- GitHub Actions workflow for Helm linting and `kubeconform` schema validation across K8s versions 1.28, 1.29, and 1.30.
- Checkov static analysis and Kyverno CLI unit testing workflow with SARIF code-scanning uploads.
- Local multi-node Kind cluster configuration with eBPF mounts and `kubeProxyMode: "none"`.
- One-click cluster bootstrap scripts (`scripts/setup-kind-cluster.sh` and `scripts/setup-kind-cluster.ps1`).
- End-to-end smoke testing suite asserting negative security controls (`scripts/e2e-smoke-test.sh` and `scripts/e2e-smoke-test.ps1`).
- ArgoCD real-time notifications ConfigMap (`gitops/argocd-notifications-cm.yaml`).

#### Day 7: Production Release & Operations
- Automated Kind cluster teardown and cleanup scripts (`scripts/teardown-kind-cluster.sh` and `scripts/teardown-kind-cluster.ps1`).
- Incident response runbook (`docs/incident-response-runbook.md`) covering Kyverno admission troubleshooting and Cilium packet drop triage.
- Industry compliance matrix (`docs/compliance-matrix.md`) mapping to CIS K8s, NIST SP 800-207 Zero Trust, and SLSA Level 3.
- Open source MIT License.
- Production release `v1.0.0`.
