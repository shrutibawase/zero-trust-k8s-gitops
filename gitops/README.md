# 🐙 Declarative GitOps with ArgoCD

This directory contains the declarative GitOps definitions, App-of-Apps root manifests, multi-environment ApplicationSets, lifecycle hooks, and project access rules.

---

## 🗂 Directory Map

- `root-app.yaml`: Root ArgoCD Application pointing to the `apps/` directory.
- `applicationset.yaml`: Dynamic multi-environment generator for `dev`, `staging`, and `production`.
- `project-production.yaml`: AppProject specification with strict sync windows and change freeze rules.
- `argocd-cm.yaml`: ConfigMap registering custom Lua health checks for Cilium and Kyverno CRDs.
- `apps/`: Directory of child applications (`networking.yaml`, `security-policies.yaml`, `workloads.yaml`).
- `hooks/`: Lifecycle jobs (`pre-sync-db-migration.yaml`, `post-sync-smoke-test.yaml`).
- `health-checks/`: Standalone Lua scripts for custom resource health checks.

---

## 🚀 Bootstrap Command

```bash
kubectl apply -f root-app.yaml
```
ArgoCD will automatically discover all child applications and begin reconciling the target cluster to the desired Git state.

- `argocd-notifications-cm.yaml`: Real-time notification templates and triggers for Slack, Teams, and Webhooks.

---

## 🔔 Real-Time Notifications & Alerting

The `argocd-notifications-cm.yaml` manifest defines automated event triggers:

- **`on-sync-failed`:** Emitted when sync operations fail due to manifest errors or admission webhook rejections (e.g., Kyverno blocking an unsigned image).
- **`on-health-degraded`:** Emitted when workloads enter `CrashLoopBackOff`, fail liveness probes, or are partitioned by Cilium network policies.
- **`on-deployed`:** Emitted upon successful verification and rollout of new Git revisions.
