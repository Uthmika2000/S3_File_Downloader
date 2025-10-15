#!/usr/bin/env pwsh

<#
.SYNOPSIS
    AWS S3 File Download Manager
.NOTES
    Requires: Install-Module -Name AWS.Tools.S3 -Scope CurrentUser
#>

if (-not (Get-Module -ListAvailable -Name AWS.Tools.S3)) {
    Write-Host "ERROR: AWS.Tools.S3 module not found!" -ForegroundColor Red
    Write-Host "Run: Install-Module -Name AWS.Tools.S3 -Scope CurrentUser" -ForegroundColor Yellow
    exit 1
}

Import-Module AWS.Tools.S3 -ErrorAction Stop

function Format-FileSize {
    param([long]$Size)
    $units = @('B', 'KB', 'MB', 'GB', 'TB')
    $i = 0
    $s = [double]$Size
    while ($s -ge 1024 -and $i -lt 4) { $s /= 1024; $i++ }
    return "{0:N2} {1}" -f $s, $units[$i]
}

function Initialize-S3 {
    param([string]$Bucket, [ref]$Region)
    try {
        $Region.Value = (Get-S3BucketLocation -BucketName $Bucket -ErrorAction Stop).Value
        if ([string]::IsNullOrWhiteSpace($Region.Value)) { $Region.Value = 'us-east-1' }
        Write-Host "[OK] Connected to: $Bucket (Region: $($Region.Value))`n" -ForegroundColor Green
        return $true
    }
    catch {
        Write-Host "ERROR: $($_.Exception.Message)" -ForegroundColor Red
        return $false
    }
}

function Get-S3Files {
    param([string]$Bucket, [string]$Region)
    try {
        Write-Host "Listing files..." -ForegroundColor Cyan
        Write-Host ("-" * 60)
        $objects = Get-S3Object -BucketName $Bucket -Region $Region
        if (-not $objects) {
            Write-Host "No files found.`n" -ForegroundColor Yellow
            return @()
        }
        $files = @()
        $i = 1
        foreach ($obj in $objects) {
            $files += $obj.Key
            Write-Host "$i. $($obj.Key)" -ForegroundColor White
            Write-Host "   $(Format-FileSize $obj.Size) | $($obj.LastModified.ToString('yyyy-MM-dd HH:mm:ss'))" -ForegroundColor Gray
            $i++
        }
        Write-Host ("-" * 60)
        Write-Host "Total: $($files.Count) files`n" -ForegroundColor Cyan
        return $files
    }
    catch {
        Write-Host "ERROR: $($_.Exception.Message)" -ForegroundColor Red
        return @()
    }
}

function Get-Selection {
    param([int]$Max)
    while ($true) {
        $sel = Read-Host "`nEnter file numbers (e.g., 1,3,5 or 1-3)"
        if ([string]::IsNullOrWhiteSpace($sel)) { continue }
        try {
            $indices = New-Object System.Collections.Generic.HashSet[int]
            foreach ($p in ($sel -split ',')) {
                if ($p -match '^(\d+)-(\d+)$') {
                    $s = [int]$Matches[1]; $e = [int]$Matches[2]
                    if ($s -lt 1 -or $e -gt $Max -or $s -gt $e) { throw }
                    for ($i = $s; $i -le $e; $i++) { [void]$indices.Add($i) }
                } else {
                    $n = [int]$p
                    if ($n -lt 1 -or $n -gt $Max) { throw }
                    [void]$indices.Add($n)
                }
            }
            return ($indices | Sort-Object)
        }
        catch {
            Write-Host "Invalid! Use numbers 1-$Max (e.g., '1,2,3' or '1-3')" -ForegroundColor Red
        }
    }
}

function Save-S3File {
    param([string]$Bucket, [string]$File, [string]$Region, [string]$Path = './downloads')
    try {
        if (-not (Test-Path $Path)) { New-Item -ItemType Directory -Path $Path -Force | Out-Null }
        $local = Join-Path $Path (Split-Path $File -Leaf)
        Write-Host "Downloading: $File..." -NoNewline -ForegroundColor Yellow
        Read-S3Object -BucketName $Bucket -Key $File -File $local -Region $Region -ErrorAction Stop
        Write-Host " [OK]" -ForegroundColor Green
        Write-Host "   -> $local" -ForegroundColor Gray
        return $true
    }
    catch {
        Write-Host " [FAILED]" -ForegroundColor Red
        return $false
    }
}

# Main
Write-Host ("=" * 60) -ForegroundColor Cyan
Write-Host "        AWS S3 File Download Manager" -ForegroundColor White
Write-Host ("=" * 60) -ForegroundColor Cyan
Write-Host ""

$bucket = (Read-Host "Enter S3 bucket name").Trim()
if ([string]::IsNullOrWhiteSpace($bucket)) {
    Write-Host "ERROR: Bucket name required!" -ForegroundColor Red
    exit 1
}

Write-Host ""
$region = $null
if (-not (Initialize-S3 -Bucket $bucket -Region ([ref]$region))) { exit 1 }

while ($true) {
    $files = Get-S3Files -Bucket $bucket -Region $region
    if ($files.Count -eq 0) { break }
    
    $selected = Get-Selection -Max $files.Count
    Write-Host "`nDownloading $($selected.Count) file(s)..." -ForegroundColor Cyan
    Write-Host ("-" * 60)
    
    $success = 0
    foreach ($idx in $selected) {
        if (Save-S3File -Bucket $bucket -File $files[$idx - 1] -Region $region) { $success++ }
    }
    
    Write-Host ("-" * 60)
    Write-Host "Complete: $success/$($selected.Count) downloaded`n" -ForegroundColor Cyan
    
    $continue = Read-Host "Download more? (yes/no)"
    if ($continue -notmatch '^y') {
        Write-Host "`nGoodbye!" -ForegroundColor Green
        break
    }
    Write-Host ""
}