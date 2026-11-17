# Zero-Trust Kubernetes Incident Response & Policy Violation Runbook

## 1. Incident Severity Matrix

| Severity | Definition | Target MTTR | Examples |
|---|---|---|---|
| **SEV-1 (Critical)** | Active security control failure or zero-trust boundary breach | < 30 mins | Kyverno webhook offline in fail-open mode; unsigned image scheduled in cluster |
| **SEV-2 (High)** | Valid production workload blocked from admission or network-partitioned | < 1 hour | Workload denied admission due to signature verification timeout; Cilium dropping valid traffic |
| **SEV-3 (Medium)** | GitOps reconciliation drift or non-blocking policy warning | < 4 hours | ArgoCD out-of-sync; Kyverno mutating policy warning; minor Hubble drop spikes |

---

## 2. Standard Triage Playbooks

### Playbook A: Kyverno Blocks Workload Admission (`check-image-cosign-signature`)

**Symptom:** `Error from server (Forbidden): admission webhook "validate.kyverno.svc" denied the request: check-image-cosign-signature failed`.

**Diagnostic Steps:**
1. Inspect the admission event:
   ```bash
   kubectl get events -n <namespace> --sort-by='.metadata.creationTimestamp' | grep -i kyverno
   ```
2. Check Kyverno controller logs:
   ```bash
   kubectl logs -n kyverno -l app.kubernetes.io/component=admission-controller --tail=100
   ```
3. Test manual Cosign verification from an operator terminal:
   ```bash
   cosign verify \
     --certificate-identity-regexp "^https://github.com/shrutibawase/.*" \
     --certificate-oidc-issuer "https://token.actions.githubusercontent.com" \
     <image-uri>
   ```
4. **Resolution:**
   - If image is legitimate but unsigned: Re-trigger GitHub Actions workflow (`supply-chain-security.yml`).
   - If Rekor was temporarily unreachable: Ensure cluster egress allows port 443 to `rekor.sigstore.dev`.

---

### Playbook B: Cilium eBPF Drops Legitimate Workload Traffic

**Symptom:** Workload reports connection timeouts or `503 Service Unavailable`.

**Diagnostic Steps:**
1. Query Hubble live flow drops in real-time:
   ```bash
   hubble observe --verdict DROPPED --namespace <namespace> --follow
   ```
2. Inspect Cilium endpoint security identity:
   ```bash
   cilium endpoint list
   cilium monitor --type drop
   ```
3. Check active CiliumNetworkPolicies:
   ```bash
   kubectl get cnp,ccnp -A
   ```
4. **Resolution:**
   - If legitimate DNS egress is blocked: Update `networking/cilium/dns-aware-egress.yaml` to include the target FQDN.
   - If internal service-to-service communication is blocked: Verify pod labels match `endpointSelector.matchLabels`.

---

### Playbook C: Emergency Admission Webhook Bypass (Break-Glass Only)

> [!CAUTION]
> Use this procedure ONLY during SEV-1 production outages where Kyverno is deadlocked and preventing critical cluster remediation.

1. Switch Kyverno policy to `Audit` mode instead of `Enforce`:
   ```bash
   kubectl patch clusterpolicy check-image-cosign-signature --type=json \
     -p='[{"op": "replace", "path": "/spec/validationFailureAction", "value": "Audit"}]'
   ```
2. If the API server is completely unresponsive due to webhook timeouts:
   ```bash
   kubectl delete validatingwebhookconfiguration kyverno-policy-validating-webhook-cfg
   ```
3. Once the root cause is resolved, immediately restore the webhook and revert `validationFailureAction: Enforce`.

---

## 3. Post-Incident Review (PIR) Checklist

- [ ] Timeline of events documented with exact timestamps (UTC).
- [ ] Root cause categorized (Supply chain, Policy regression, eBPF drop, Certificate expiry).
- [ ] Any emergency bypasses reverted and verified active in `Enforce` mode.
- [ ] Kyverno unit test added to `policies/tests/` to prevent recurrence.
- [ ] Runbook updated with new troubleshooting patterns.
