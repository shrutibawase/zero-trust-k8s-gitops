<#
.SYNOPSIS
    Gracefully destroys local Kind cluster and cleans up resources on Windows.
.PARAMETER ClusterName
    Name of the Kind cluster to destroy (defaults to zero-trust-cluster).
#>
[CmdletBinding()]
param(
    [Parameter(Mandatory = $false)]
    [string]$ClusterName = "zero-trust-cluster"
)

$ErrorActionPreference = "Continue"

Write-Host "================================================================" -ForegroundColor Cyan
Write-Host "  Teardown & Cleanup: Zero-Trust Local Cluster (PowerShell)     " -ForegroundColor Cyan
Write-Host "================================================================" -ForegroundColor Cyan

if (-not (Get-Command kind -ErrorAction SilentlyContinue)) {
    Write-Host "[-] Error: 'kind' CLI is not found in PATH." -ForegroundColor Red
    exit 1
}

$existing = kind get clusters 2>$null
if ($existing -contains $ClusterName) {
    Write-Host "`n[Step 1/3] Deleting Kind cluster '$ClusterName'..." -ForegroundColor Yellow
    kind delete cluster --name $ClusterName
    Write-Host "[+] Cluster '$ClusterName' successfully deleted." -ForegroundColor Green
} else {
    Write-Host "[!] Cluster '$ClusterName' does not exist. Skipping deletion." -ForegroundColor Yellow
}

Write-Host "`n[Step 2/3] Cleaning up lingering kubeconfig contexts..." -ForegroundColor Cyan
kubectl config delete-context "kind-$ClusterName" *>$null
kubectl config delete-cluster "kind-$ClusterName" *>$null
Write-Host "[+] Kubeconfig context purged." -ForegroundColor Green

Write-Host "`n[Step 3/3] Pruning orphaned docker volumes..." -ForegroundColor Cyan
docker volume prune -f --filter "label=io.x-k8s.kind.cluster=$ClusterName" *>$null
Write-Host "[+] Orphaned volumes pruned." -ForegroundColor Green

Write-Host "`n================================================================" -ForegroundColor Cyan
Write-Host "  Teardown and cleanup completed successfully!                   " -ForegroundColor Green
Write-Host "================================================================" -ForegroundColor Cyan
