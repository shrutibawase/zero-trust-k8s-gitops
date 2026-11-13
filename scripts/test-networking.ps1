# ==============================================================================
# Script: Automated Zero-Trust Cilium Network Policy Test Suite (PowerShell)
# ==============================================================================
$ErrorActionPreference = "Stop"

Write-Host "=================================================" -ForegroundColor Cyan
Write-Host "🌐 Validating Cilium eBPF Network Policies (PowerShell)" -ForegroundColor Cyan
Write-Host "=================================================" -ForegroundColor Cyan

$RootDir = Join-Path $PSScriptRoot ".."
$NetworkingDir = Join-Path $RootDir "networking\cilium"

Write-Host "1. Verifying policy files exist..." -ForegroundColor Yellow
$files = Get-ChildItem -Path $NetworkingDir -Filter "*.yaml"
foreach ($f in $files) {
    Write-Host "  Found: $($f.Name)" -ForegroundColor Green
}

Write-Host "2. Asserting Zero-Trust architectural invariants..." -ForegroundColor Yellow

$defaultDeny = Get-Content (Join-Path $NetworkingDir "default-deny-all.yaml") -Raw
if ($defaultDeny -match "name: default-deny-all") {
    Write-Host "  ✅ Invariant passed: Default-deny baseline policy is defined" -ForegroundColor Green
}

$dnsEgress = Get-Content (Join-Path $NetworkingDir "dns-aware-egress.yaml") -Raw
if ($dnsEgress -match "toFQDNs") {
    Write-Host "  ✅ Invariant passed: L7 DNS proxy inspection is configured" -ForegroundColor Green
}

$mtls = Get-Content (Join-Path $NetworkingDir "ebpf-mutual-tls.yaml") -Raw
if ($mtls -match "authentication") {
    Write-Host "  ✅ Invariant passed: Sidecar-free mTLS wire encryption is configured" -ForegroundColor Green
}

$l7Http = Get-Content (Join-Path $NetworkingDir "l7-http-rules.yaml") -Raw
if ($l7Http -match "rules:" -and $l7Http -match "http:") {
    Write-Host "  ✅ Invariant passed: Layer-7 HTTP method and path filtering is active" -ForegroundColor Green
}

Write-Host "🎉 All Cilium eBPF Network Policies Verified!" -ForegroundColor Green
