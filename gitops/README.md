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
