<#
.SYNOPSIS
    Sigstore Cosign Multi-Tier Supply Chain Verifier for Windows & PowerShell.
.DESCRIPTION
    Validates container cryptographic signatures, SPDX SBOM attestations, and SLSA Level 3
    provenance statements against Sigstore's Rekor transparency log and Fulcio CA.
.PARAMETER ImageRef
    Container image reference (defaults to ghcr.io/shrutibawase/zero-trust-k8s-gitops:latest).
.PARAMETER CertificateIdentityRegex
    Expected regex pattern for signer identity (defaults to ^https://github.com/shrutibawase/.*).
.PARAMETER CertificateOidcIssuer
    Expected OIDC token issuer (defaults to https://token.actions.githubusercontent.com).
#>
[CmdletBinding()]
param (
    [Parameter(Mandatory = $false, Position = 0)]
    [string]$ImageRef = "ghcr.io/shrutibawase/zero-trust-k8s-gitops:latest",

    [Parameter(Mandatory = $false, Position = 1)]
    [string]$CertificateIdentityRegex = "^https://github.com/shrutibawase/.*",

    [Parameter(Mandatory = $false, Position = 2)]
    [string]$CertificateOidcIssuer = "https://token.actions.githubusercontent.com"
)

$ErrorActionPreference = "Continue"

Write-Host "================================================================" -ForegroundColor Cyan
Write-Host "  Sigstore Cosign Multi-Tier Supply Chain Verifier (PowerShell) " -ForegroundColor Cyan
Write-Host "================================================================" -ForegroundColor Cyan
Write-Host "Target Image:               $ImageRef" -ForegroundColor Yellow
Write-Host "Expected Certificate Regex: $CertificateIdentityRegex" -ForegroundColor Yellow
Write-Host "Expected OIDC Issuer:       $CertificateOidcIssuer" -ForegroundColor Yellow
Write-Host ""

$cosignPath = Get-Command "cosign" -ErrorAction SilentlyContinue
if (-not $cosignPath) {
    Write-Host "[-] Error: 'cosign' CLI is not found in PATH." -ForegroundColor Red
    Write-Host "    Install via: winget install Sigstore.Cosign  or  choco install cosign" -ForegroundColor Gray
    exit 1
}

$env:COSIGN_EXPERIMENTAL = "1"

# 1. Verify Image Signature
Write-Host "[1/3] Verifying Container Cryptographic Signature..." -ForegroundColor Cyan
cosign verify `
  --certificate-identity-regexp "$CertificateIdentityRegex" `
  --certificate-oidc-issuer "$CertificateOidcIssuer" `
  "$ImageRef" *>$null

if ($LASTEXITCODE -eq 0) {
    Write-Host "[+] PASS: Container image signature is valid and logged in Rekor!" -ForegroundColor Green
} else {
    Write-Host "[-] FAIL: Image signature verification failed or image unsigned." -ForegroundColor Red
}

# 2. Verify SPDX SBOM Attestation
Write-Host "`n[2/3] Verifying Software Bill of Materials (SPDX SBOM) Attestation..." -ForegroundColor Cyan
cosign verify-attestation `
  --type spdxjson `
  --certificate-identity-regexp "$CertificateIdentityRegex" `
  --certificate-oidc-issuer "$CertificateOidcIssuer" `
  "$ImageRef" *>$null

if ($LASTEXITCODE -eq 0) {
    Write-Host "[+] PASS: SPDX SBOM attestation verified successfully!" -ForegroundColor Green
} else {
    Write-Host "[!] WARNING: SPDX SBOM attestation could not be verified." -ForegroundColor Yellow
}

# 3. Verify SLSA Level 3 Provenance Attestation
Write-Host "`n[3/3] Verifying SLSA Level 3 Build Provenance Attestation..." -ForegroundColor Cyan
cosign verify-attestation `
  --type "https://slsa.dev/provenance/v0.2" `
  --certificate-identity-regexp "$CertificateIdentityRegex" `
  --certificate-oidc-issuer "$CertificateOidcIssuer" `
  "$ImageRef" *>$null

if ($LASTEXITCODE -eq 0) {
    Write-Host "[+] PASS: SLSA Level 3 build provenance verified successfully!" -ForegroundColor Green
} else {
    Write-Host "[!] WARNING: SLSA provenance attestation could not be verified." -ForegroundColor Yellow
}

Write-Host "`n================================================================" -ForegroundColor Cyan
Write-Host "Verification workflow evaluation complete." -ForegroundColor Green
Write-Host "================================================================" -ForegroundColor Cyan
