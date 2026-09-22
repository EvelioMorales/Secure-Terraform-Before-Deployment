$ErrorActionPreference = "Stop"
$blockingFindings = 0

Write-Host "`nTerraform Security Review" -ForegroundColor Cyan
Write-Host "=========================" -ForegroundColor Cyan

Write-Host "`n[1/4] Checking for possible hard-coded secrets..."

$terraformFiles = Get-ChildItem -Path . -Recurse -File |
    Where-Object {
        $_.FullName -notmatch '\\.terraform\\' -and
        $_.Extension -in ".tf", ".tfvars"
    }

$secretMatches = $terraformFiles |
    Select-String -Pattern '(password|secret|token|access_key)\s*='

if ($secretMatches) {
    $secretMatches
    $blockingFindings++
}
else {
    Write-Host "PASS: No basic hard-coded secret patterns found." -ForegroundColor Green
}

Write-Host "`n[2/4] Checking tracked sensitive files..."

$trackedFiles = git ls-files

$sensitiveTrackedFiles = $trackedFiles |
    Where-Object {
        $_ -match '\.tfstate(\..*)?$' -or
        $_ -match '\.tfvars$' -or
        $_ -match '(^|/)\.env$'
    }

if ($sensitiveTrackedFiles) {
    $sensitiveTrackedFiles
    $blockingFindings++
}
else {
    Write-Host "PASS: No state, private tfvars, or .env files are tracked." -ForegroundColor Green
}

Write-Host "`n[3/4] Reviewing public 0.0.0.0/0 entries..."

$publicMatches = $terraformFiles |
    Select-String -SimpleMatch '0.0.0.0/0'

if ($publicMatches) {
    $publicMatches
    Write-Host "REVIEW: Public CIDRs were found. Check their purpose and direction." -ForegroundColor Yellow
}
else {
    Write-Host "PASS: No public IPv4 CIDRs found." -ForegroundColor Green
}

Write-Host "`n[4/4] Checking the SSH rule..."

$securityContent = Get-Content ".\security.tf" -Raw
$ingressBlocks = [regex]::Matches(
    $securityContent,
    'ingress\s*\{[\s\S]*?\}'
)

$publicSshFound = $false
$restrictedSshFound = $false

foreach ($block in $ingressBlocks) {
    if ($block.Value -match 'from_port\s*=\s*22') {
        if ($block.Value -match '0\.0\.0\.0/0') {
            $publicSshFound = $true
        }

        if ($block.Value -match 'var\.admin_cidr') {
            $restrictedSshFound = $true
        }
    }
}

if ($publicSshFound) {
    Write-Host "FAIL: SSH port 22 is open to 0.0.0.0/0." -ForegroundColor Red
    $blockingFindings++
}
elseif ($restrictedSshFound) {
    Write-Host "PASS: SSH uses var.admin_cidr." -ForegroundColor Green
}
else {
    Write-Host "FAIL: A restricted SSH rule was not found." -ForegroundColor Red
    $blockingFindings++
}

Write-Host ""

if ($blockingFindings -gt 0) {
    Write-Host "Security review failed with $blockingFindings blocking finding(s)." -ForegroundColor Red
    exit 1
}

Write-Host "Security review passed. Public CIDRs still require manual context review." -ForegroundColor Green
exit 0