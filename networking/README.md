# 🌐 Cilium eBPF Zero-Trust Networking

This directory contains the declarative `CiliumNetworkPolicy` manifests, DNS proxy rules, sidecar-free mutual TLS configurations, and Hubble telemetry exporters.

---

## 🗂 Directory Map

- `cilium/default-deny-all.yaml`: Baseline default-deny policy for all ingress and egress.
- `cilium/dns-aware-egress.yaml`: Strict FQDN egress filter restricting outbound calls to whitelisted enterprise endpoints.
- `cilium/ebpf-mutual-tls.yaml`: Kernel-level pod-to-pod mutual TLS authentication with zero sidecar latency.
- `cilium/l7-http-rules.yaml`: Deep packet inspection matching authorized HTTP verbs and URI paths.
- `cilium/hubble-telemetry.yaml`: Hubble metrics exporter and Prometheus scrape endpoints.

---

## 🚀 Testing Policies

```bash
# Validate policy syntax and zero-trust invariants
./scripts/test-networking.sh
```
