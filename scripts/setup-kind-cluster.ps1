<#
.SYNOPSIS
    Automated Local Kind Cluster Bootstrap for Windows PowerShell.
.DESCRIPTION
    Creates a Kind cluster with eBPF filesystem mounts, installs Cilium (kube-proxy replacement),
    installs Kyverno admission controller, and installs ArgoCD GitOps engine.
#>
[CmdletBinding()]
param(
    [Parameter(Mandatory = $false)]
    [string]$ClusterName = "zero-trust-cluster"
)

$ErrorActionPreference = "Stop"

Write-Host "================================================================" -ForegroundColor Cyan
Write-Host "  Bootstrapping Zero-Trust Kubernetes Local Cluster (PowerShell)" -ForegroundColor Cyan
Write-Host "================================================================" -ForegroundColor Cyan

$RootDir = Split-Path -Parent $PSScriptRoot

# 1. Prerequisite checks
$RequiredTools = @("docker", "kind", "kubectl", "helm")
foreach ($tool in $RequiredTools) {
    if (-not (Get-Command $tool -ErrorAction SilentlyContinue)) {
        Write-Host "[-] Error: Required tool '$tool' is not installed or not in PATH." -ForegroundColor Red
        exit 1
    }
}
Write-Host "[+] Prerequisites verified: docker, kind, kubectl, helm." -ForegroundColor Green

# 2. Check Docker daemon
docker info *>$null
if ($LASTEXITCODE -ne 0) {
    Write-Host "[-] Error: Docker daemon is not running." -ForegroundColor Red
    exit 1
}

# 3. Create Kind cluster
$existingClusters = kind get clusters 2>$null
if ($existingClusters -contains $ClusterName) {
    Write-Host "[!] Kind cluster '$ClusterName' already exists. Reusing." -ForegroundColor Yellow
} else {
    Write-Host "`n[Step 1/4] Creating Kind Cluster with eBPF support..." -ForegroundColor Cyan
    kind create cluster --config "$RootDir\cluster\kind-config.yaml"
}

# 4. Install Cilium
Write-Host "`n[Step 2/4] Installing Cilium CNI with eBPF Kube-Proxy Replacement..." -ForegroundColor Cyan
helm repo add cilium https://helm.cilium.io/ --force-update *>$null
helm upgrade --install cilium cilium/cilium `
  --namespace kube-system `
  --version 1.15.4 `
  --set kubeProxyReplacement=true `
  --set k8sServiceHost="$ClusterName-control-plane" `
  --set k8sServicePort=6443 `
  --set hubble.enabled=true `
  --set hubble.relay.enabled=true `
  --set hubble.ui.enabled=true `
  --set hubble.metrics.enabled="{dns,drop,tcp,flow,port-distribution,icmp,http}" `
  --wait

Write-Host "[+] Cilium eBPF CNI and Hubble successfully deployed." -ForegroundColor Green

# 5. Install Kyverno
Write-Host "`n[Step 3/4] Installing Kyverno Admission Controller..." -ForegroundColor Cyan
helm repo add kyverno https://kyverno.github.io/kyverno/ --force-update *>$null
helm upgrade --install kyverno kyverno/kyverno `
  --namespace kyverno `
  --create-namespace `
  --version 3.1.4 `
  --set admissionController.replicas=1 `
  --set backgroundController.replicas=1 `
  --set cleanupController.replicas=1 `
  --set reportsController.replicas=1 `
  --wait

Write-Host "[+] Kyverno Admission Engine successfully deployed." -ForegroundColor Green

# 6. Install ArgoCD
Write-Host "`n[Step 4/4] Installing ArgoCD GitOps Engine..." -ForegroundColor Cyan
kubectl create namespace argocd --dry-run=client -o yaml | kubectl apply -f -
kubectl apply -n argocd -f https://raw.githubusercontent.com/argoproj/argo-cd/v2.10.4/manifests/install.yaml

Write-Host "Waiting for ArgoCD Server to become ready..." -ForegroundColor Yellow
kubectl rollout status deployment/argocd-server -n argocd --timeout=180s

Write-Host "`n[Deploying GitOps Root Application]..." -ForegroundColor Cyan
kubectl apply -f "$RootDir\gitops\root-app.yaml"

Write-Host "`n================================================================" -ForegroundColor Cyan
Write-Host "  Zero-Trust Cluster Bootstrap Successfully Completed!          " -ForegroundColor Green
Write-Host "================================================================" -ForegroundColor Cyan
Write-Host "To access ArgoCD UI: kubectl port-forward svc/argocd-server -n argocd 8080:443" -ForegroundColor Yellow
Write-Host "To access Hubble UI: kubectl port-forward svc/hubble-ui -n kube-system 12000:80" -ForegroundColor Yellow
