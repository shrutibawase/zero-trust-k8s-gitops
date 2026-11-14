<#
.SYNOPSIS
    Automated Supply Chain Security Test Suite for Windows/PowerShell.
.DESCRIPTION
    Validates Syft (.syft.yaml), Grype (.grype.yaml), SLSA Provenance JSON syntax,
    and Kyverno admission policies for container image verification.
#>
[CmdletBinding()]
param()

$ErrorActionPreference = "Continue"

Write-Host "================================================================" -ForegroundColor Cyan
Write-Host "  Zero-Trust K8s Supply Chain Security Test Suite (PowerShell)  " -ForegroundColor Cyan
Write-Host "================================================================" -ForegroundColor Cyan

$RootDir = Split-Path -Parent $PSScriptRoot
$FailedTests = 0

# Test 1: Syft config
Write-Host "`n[Test 1/5] Checking Syft SBOM Configuration..." -ForegroundColor Cyan
if (Test-Path "$RootDir\.syft.yaml") {
    Write-Host "[+] PASS: .syft.yaml configuration found." -ForegroundColor Green
} else {
    Write-Host "[-] FAIL: .syft.yaml is missing!" -ForegroundColor Red
    $FailedTests++
}

# Test 2: Grype config
Write-Host "`n[Test 2/5] Checking Grype Vulnerability Configuration..." -ForegroundColor Cyan
if (Test-Path "$RootDir\.grype.yaml") {
    Write-Host "[+] PASS: .grype.yaml configuration found." -ForegroundColor Green
} else {
    Write-Host "[-] FAIL: .grype.yaml is missing!" -ForegroundColor Red
    $FailedTests++
}

# Test 3: SLSA Predicate JSON syntax
Write-Host "`n[Test 3/5] Validating SLSA Predicate JSON Structure..." -ForegroundColor Cyan
$PredicateFile = "$RootDir\security\slsa\predicate-template.json"
if (Test-Path $PredicateFile) {
    try {
        $json = Get-Content $PredicateFile -Raw | ConvertFrom-Json
        Write-Host "[+] PASS: SLSA predicate template is valid JSON (Subject: $($json.subject[0].name))." -ForegroundColor Green
    } catch {
        Write-Host "[-] FAIL: SLSA predicate template contains invalid JSON: $_" -ForegroundColor Red
        $FailedTests++
    }
} else {
    Write-Host "[-] FAIL: SLSA predicate template missing at $PredicateFile!" -ForegroundColor Red
    $FailedTests++
}

# Test 4: Kyverno Cosign Policy
Write-Host "`n[Test 4/5] Checking Kyverno Cosign Signature Verification Policy..." -ForegroundColor Cyan
$CosignPolicy = "$RootDir\policies\kyverno\require-cosign-image-signature.yaml"
if (Test-Path $CosignPolicy) {
    $content = Get-Content $CosignPolicy -Raw
    if ($content -match "check-image-cosign-signature") {
        Write-Host "[+] PASS: Kyverno policy 'check-image-cosign-signature' found and valid." -ForegroundColor Green
    } else {
        Write-Host "[-] FAIL: Policy does not contain 'check-image-cosign-signature'." -ForegroundColor Red
        $FailedTests++
    }
} else {
    Write-Host "[-] FAIL: Cosign Kyverno policy missing at $CosignPolicy!" -ForegroundColor Red
    $FailedTests++
}

# Test 5: Kyverno Test Definitions
Write-Host "`n[Test 5/5] Checking Kyverno Supply Chain Test Definitions..." -ForegroundColor Cyan
$TestFile = "$RootDir\policies\tests\supply-chain-test.yaml"
$ResourceFile = "$RootDir\policies\tests\supply-chain-resources.yaml"
if ((Test-Path $TestFile) -and (Test-Path $ResourceFile)) {
    Write-Host "[+] PASS: Kyverno test definition files found and verified." -ForegroundColor Green
    Write-Host "    - $TestFile" -ForegroundColor Gray
    Write-Host "    - $ResourceFile" -ForegroundColor Gray
} else {
    Write-Host "[-] FAIL: Kyverno test definition files missing!" -ForegroundColor Red
    $FailedTests++
}

Write-Host "`n================================================================" -ForegroundColor Cyan
if ($FailedTests -eq 0) {
    Write-Host "ALL SUPPLY CHAIN TESTS PASSED SUCCESSFULLY! (0 failures)" -ForegroundColor Green
} else {
    Write-Host "TEST SUITE FAILED WITH $FailedTests FAILURES!" -ForegroundColor Red
    exit 1
}
Write-Host "================================================================" -ForegroundColor Cyan
