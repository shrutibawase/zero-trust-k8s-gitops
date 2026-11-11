# 🛡️ Policy-as-Code Governance & Compliance Runbook

This guide details the admission control security standards, regulatory compliance baselines, and runtime invariants enforced by **Kyverno**.

---

## 🏛️ Policy Compliance Matrix

| Policy Rule | Target Threat / Vector | CIS K8s Benchmark | NIST SP 800-190 | Action |
|---|---|---|---|---|
| `enforce-pod-security-restricted` | Host namespace escape (hostPID, hostIPC, hostNet) | Section 5.2.2, 5.2.3, 5.2.4 | Section 3.3.1 | **Enforce** |
| `disallow-privileged-containers` | Root breakout & kernel hijacking | Section 5.2.1 | Section 3.3.2 | **Enforce** |
| `require-drop-all-capabilities` | Arbitrary Linux capability abuse (`CAP_SYS_ADMIN`) | Section 5.2.7 | Section 3.3.2 | **Enforce** |
| `require-ro-rootfs-and-non-root` | Malware persistence & root execution | Section 5.2.6, 5.2.8 | Section 3.3.3 | **Enforce** |
| `disallow-latest-and-untrusted` | Supply chain drift & unverified registries | Section 5.5.1 | Section 3.1.1 | **Enforce** |
| `require-cosign-image-signature` | Tampered / unsigned malicious images | Supply Chain SLSA L3 | Section 3.1.2 | **Enforce** |
| `mutate-default-security-context` | Uninformed developer friction (Auto-inject safe defaults) | DevSecOps DX | Section 3.3 | **Mutate** |

---

## ⚙️ Operational Modes: Audit vs. Enforce

Kyverno policies can be deployed in two modes controlled by `spec.validationFailureAction`:

1. **`Audit`**:
   - Workloads that violate policy are **admitted** to the cluster.
   - Non-compliance generates a `PolicyReport` CRD without interrupting runtime workloads.
   - Recommended for initial 14-day discovery in staging environments.

2. **`Enforce` (Active Zero-Trust Default)**:
   - Any non-compliant resource is immediately **rejected** at the API server admission webhook.
   - Developers receive descriptive feedback detailing the exact field violation.

---

## 🧪 Automated Testing with Kyverno CLI

Policies are treated as first-class software artifacts and validated before hitting git:

```bash
# Run automated policy assertion suite
./scripts/test-policies.sh
```

Sample Test Execution:
```plaintext
executing zero-trust-kyverno-test-suite...
  checking policy disallow-privileged-and-capabilities... pass
  checking policy require-ro-rootfs-and-non-root... pass
  checking policy disallow-latest-and-untrusted-registries... pass
results: 5 passed, 0 failed, 0 errors
```
