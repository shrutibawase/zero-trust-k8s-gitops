<#
.SYNOPSIS
    End-to-End Security & Functional Invariant Smoke Tests for Windows/PowerShell.
.DESCRIPTION
    Validates cluster health, deploys the secure-microservice chart, and tests negative security
    controls (privileged pod rejection, root user blocking, writable rootfs rejection).
#>
[CmdletBinding()]
param(
    [Parameter(Mandatory = $false)]
    [string]$Namespace = "dev"
)

$ErrorActionPreference = "Continue"

Write-Host "================================================================" -ForegroundColor Cyan
Write-Host "  Zero-Trust Kubernetes E2E Verification Suite (PowerShell)     " -ForegroundColor Cyan
Write-Host "================================================================" -ForegroundColor Cyan

$FailedTests = 0
$TotalTests = 0

function Assert-Test {
    param(
        [string]$Name,
        [scriptblock]$Action,
        [bool]$ExpectSuccess = $true
    )

    $script:TotalTests++
    Write-Host "`n[Test $script:TotalTests] $Name..." -ForegroundColor Cyan

    try {
        & $Action *>$null
        $success = ($LASTEXITCODE -eq 0)
    } catch {
        $success = $false
    }

    if ($ExpectSuccess -and $success) {
        Write-Host "[+] PASS: Test succeeded as expected." -ForegroundColor Green
    } elseif ((-not $ExpectSuccess) -and (-not $success)) {
        Write-Host "[+] PASS: Security gate successfully blocked unauthorized action!" -ForegroundColor Green
    } else {
        Write-Host "[-] FAIL: Test outcome did not match expected expectation." -ForegroundColor Red
        $script:FailedTests++
    }
}

# Test 1: Node status
Assert-Test -Name "Kubernetes API Server Reachability" -Action { kubectl get nodes } -ExpectSuccess $true

# Test 2: Kyverno controller status
Assert-Test -Name "Kyverno Admission Webhook Deployment Status" -Action { kubectl get deployment -n kyverno -l app.kubernetes.io/part-of=kyverno } -ExpectSuccess $true

# Test 3: Deploy compliant Helm chart
Assert-Test -Name "Deploy Hardened Microservice into Dev Namespace" -Action {
    helm upgrade --install secure-microservice ./charts/secure-microservice -f ./charts/secure-microservice/values-dev.yaml -n $Namespace --create-namespace --wait --timeout=120s
} -ExpectSuccess $true

# Test 4: Block Privileged Pod
Assert-Test -Name "Kyverno Blocks Privileged Container" -Action {
    kubectl run test-privileged --image=busybox --privileged -n $Namespace --restart=Never
} -ExpectSuccess $false

# Test 5: Block Root User Container
Assert-Test -Name "Kyverno Blocks Container Running as Root" -Action {
    kubectl run test-root --image=busybox --overrides='{"spec":{"containers":[{"name":"test","image":"busybox","securityContext":{"runAsNonRoot":false,"runAsUser":0}}]}}' -n $Namespace --restart=Never
} -ExpectSuccess $false

# Test 6: Block Writable Root FS
Assert-Test -Name "Kyverno Blocks Container with Writable Root Filesystem" -Action {
    kubectl run test-rw-rootfs --image=busybox --overrides='{"spec":{"containers":[{"name":"test","image":"busybox","securityContext":{"readOnlyRootFilesystem":false}}]}}' -n $Namespace --restart=Never
} -ExpectSuccess $false

# Test 7: Cilium Network Policy Default-Deny
Assert-Test -Name "Apply Cilium Default-Deny Baseline" -Action {
    kubectl apply -f ./networking/cilium/default-deny-all.yaml -n $Namespace
} -ExpectSuccess $true

# Clean up test pods
kubectl delete pod test-privileged test-root test-rw-rootfs -n $Namespace --ignore-not-found *>$null

Write-Host "`n================================================================" -ForegroundColor Cyan
if ($FailedTests -eq 0) {
    Write-Host "ALL $TotalTests E2E SECURITY & COMPLIANCE TESTS PASSED! (0 failures)" -ForegroundColor Green
} else {
    Write-Host "$FailedTests OUT OF $TotalTests E2E TESTS FAILED!" -ForegroundColor Red
    exit 1
}
Write-Host "================================================================" -ForegroundColor Cyan
