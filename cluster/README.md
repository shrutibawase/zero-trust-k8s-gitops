# Local Kind Cluster Architecture (Cilium & eBPF)

This directory defines the **declarative topology** for bootstrapping a local production-parity Kubernetes test environment using **Kind (Kubernetes in Docker)**.

---

## 1. Cluster Topology

- **1 Control Plane Node:** Labels `ingress-ready=true`, port forwards `80`, `443`, and `9965` (Hubble Relay).
- **2 Worker Nodes:** Isolated workload runtimes.
- **eBPF Filesystem Mounts:** All nodes mount `/sys/fs/bpf` to enable Cilium kernel program attachment.

```
       Host Machine (localhost:80, 443, 9965)
                         │
                         ▼
        ┌───────────────────────────────────┐
        │       Control-Plane Node          │
        │   (API Server, Ingress, Hubble)   │
        └─────────────────┬─────────────────┘
                          │
          ┌───────────────┴───────────────┐
          ▼                               ▼
  ┌───────────────┐               ┌───────────────┐
  │ Worker Node 1 │               │ Worker Node 2 │
  │ (Cilium eBPF) │               │ (Cilium eBPF) │
  └───────────────┘               └───────────────┘
```

---

## 2. Key Zero-Trust Configuration Invariants

1. **`disableDefaultCNI: true`:** Kind does not install `kindnet`, permitting Cilium to manage the entire pod networking lifecycle.
2. **`kubeProxyMode: "none"`:** Disables standard iptables-based `kube-proxy`. Cilium replaces `kube-proxy` via eBPF socket load balancing, delivering superior performance, lower latency, and deep observability.
3. **eBPF Host Routing:** Kernel bypass via BPF programs attached to network device queues (tc/xdp).
