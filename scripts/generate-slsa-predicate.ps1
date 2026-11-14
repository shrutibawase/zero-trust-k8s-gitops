<#
.SYNOPSIS
    Generates an in-toto SLSA Provenance v0.2 Predicate JSON for Cosign Attestation on Windows/PowerShell.
.PARAMETER ImageDigest
    The sha256 digest of the container image.
.PARAMETER OutputFile
    Output JSON path (defaults to provenance-predicate.json).
#>
[CmdletBinding()]
param (
    [Parameter(Mandatory = $true, Position = 0)]
    [string]$ImageDigest,

    [Parameter(Mandatory = $false, Position = 1)]
    [string]$OutputFile = "provenance-predicate.json"
)

$ErrorActionPreference = "Stop"

$DigestHex = $ImageDigest -replace "^sha256:", ""
$Repo = if ($env:GITHUB_REPOSITORY) { $env:GITHUB_REPOSITORY } else { "shrutibawase/zero-trust-k8s-gitops" }
$CommitSha = if ($env:GITHUB_SHA) { $env:GITHUB_SHA } else { (git rev-parse HEAD 2>$null) }
if (-not $CommitSha) { $CommitSha = "local-developer-build" }
$RunId = if ($env:GITHUB_RUN_ID) { $env:GITHUB_RUN_ID } else { "manual-powershell-run" }
$NowIso = (Get-Date).ToUniversalTime().ToString("yyyy-MM-ddTHH:mm:ssZ")
$EventName = if ($env:GITHUB_EVENT_NAME) { $env:GITHUB_EVENT_NAME } else { "push" }
$Ref = if ($env:GITHUB_REF) { $env:GITHUB_REF } else { "refs/heads/main" }

$Predicate = [ordered]@{
    "_type" = "https://in-toto.io/Statement/v0.1"
    "predicateType" = "https://slsa.dev/provenance/v0.2"
    "subject" = @(
        [ordered]@{
            "name" = "ghcr.io/$Repo"
            "digest" = [ordered]@{
                "sha256" = $DigestHex
            }
        }
    )
    "predicate" = [ordered]@{
        "builder" = [ordered]@{
            "id" = "https://github.com/$Repo/.github/workflows/supply-chain-security.yml@refs/heads/main"
        }
        "buildType" = "https://github.com/slsa-framework/slsa-github-generator/container@v1"
        "invocation" = [ordered]@{
            "configSource" = [ordered]@{
                "uri" = "git+https://github.com/$Repo"
                "digest" = [ordered]@{
                    "sha1" = $CommitSha
                }
                "entryPoint" = ".github/workflows/supply-chain-security.yml"
            }
            "parameters" = [ordered]@{
                "event_name" = $EventName
                "ref" = $Ref
            }
            "environment" = [ordered]@{
                "github_run_id" = $RunId
                "runner_os" = "Windows/PowerShell"
            }
        }
        "metadata" = [ordered]@{
            "buildStartedOn" = $NowIso
            "buildFinishedOn" = $NowIso
            "completeness" = [ordered]@{
                "parameters" = $true
                "environment" = $true
                "materials" = $true
            }
            "reproducible" = $false
        }
        "materials" = @(
            [ordered]@{
                "uri" = "git+https://github.com/$Repo"
                "digest" = [ordered]@{
                    "sha1" = $CommitSha
                }
            }
        )
    }
}

$Predicate | ConvertTo-Json -Depth 10 | Set-Content -Path $OutputFile -Encoding UTF8
Write-Host "[+] Successfully generated SLSA Provenance Predicate at: $OutputFile" -ForegroundColor Green
