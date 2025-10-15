try {
    Import-Module AWS.Tools.S3 -ErrorAction Stop
} catch {
    Write-Host "ERROR: AWS.Tools.S3 module not found!" -ForegroundColor Red
    Write-Host "Please install it using: Install-Module -Name AWS.Tools.S3 -Scope CurrentUser"
    exit 1
}

class S3DownloadManager {
    [string]$BucketName
    [string]$ProfileName
    
    S3DownloadManager([string]$bucketName, [string]$profileName) {
        $this.BucketName = $bucketName
        $this.ProfileName = $profileName
        $this.TestConnection()
    }
    
    [void]TestConnection() {
        try {
            $params = @{
                BucketName = $this.BucketName
            }
            
            if ($this.ProfileName) {
                $params['ProfileName'] = $this.ProfileName
                Write-Host " Using AWS profile: $($this.ProfileName)" -ForegroundColor Green
            }
            
            $null = Get-S3Bucket -BucketName $this.BucketName @params -ErrorAction Stop
            Write-Host " Successfully connected to bucket: $($this.BucketName)`n" -ForegroundColor Green
        }
        catch {
            if ($_.Exception.Message -match "not found|does not exist") {
                Write-Host "ERROR: Bucket '$($this.BucketName)' does not exist" -ForegroundColor Red
            }
            elseif ($_.Exception.Message -match "Access Denied|403") {
                Write-Host "ERROR: Access denied to bucket '$($this.BucketName)'" -ForegroundColor Red
                if ($this.ProfileName) {
                    Write-Host "Your SSO session may have expired. Try running:" -ForegroundColor Yellow
                    Write-Host "  aws sso login --profile $($this.ProfileName)" -ForegroundColor Yellow
                }
            }
            elseif ($_.Exception.Message -match "No credentials") {
                Write-Host "ERROR: AWS credentials not found!" -ForegroundColor Red
                Write-Host "Please run 'aws configure sso' to set up your SSO credentials." -ForegroundColor Yellow
                Write-Host "Then run 'aws sso login --profile <profile-name>' to authenticate." -ForegroundColor Yellow
            }
            else {
                Write-Host "ERROR: $($_.Exception.Message)" -ForegroundColor Red
            }
            exit 1
        }
    }
    
    [array]ListFiles() {
        try {
            Write-Host "Listing files in bucket: $($this.BucketName)"
            Write-Host ("-" * 60)
            
            $params = @{
                BucketName = $this.BucketName
            }
            
            if ($this.ProfileName) {
                $params['ProfileName'] = $this.ProfileName
            }
            
            $objects = Get-S3Object @params
            
            if (-not $objects) {
                Write-Host "No files found in the bucket."
                return @()
            }
            
            $files = @()
            $idx = 1
            
            foreach ($obj in $objects) {
                $fileName = $obj.Key
                $fileSize = $obj.Size
                $lastModified = $obj.LastModified.ToString("yyyy-MM-dd HH:mm:ss")
                
                $files += $fileName
                
                Write-Host "$idx. $fileName"
                Write-Host "   Size: $($this.FormatSize($fileSize)) | Last Modified: $lastModified"
                $idx++
            }
            
            Write-Host ("-" * 60)
            Write-Host "Total files: $($files.Count)`n"
            
            return $files
        }
        catch {
            Write-Host "ERROR listing files: $($_.Exception.Message)" -ForegroundColor Red
            return @()
        }
    }
    
    [string]FormatSize([long]$sizeBytes) {
        $units = @('B', 'KB', 'MB', 'GB', 'TB')
        $size = [double]$sizeBytes
        $unitIndex = 0
        
        while ($size -ge 1024 -and $unitIndex -lt ($units.Count - 1)) {
            $size = $size / 1024
            $unitIndex++
        }
        
        return "{0:N2} {1}" -f $size, $units[$unitIndex]
    }
    
    [bool]DownloadFile([string]$fileName, [string]$downloadPath) {
        try {
            if (-not (Test-Path $downloadPath)) {
                New-Item -ItemType Directory -Path $downloadPath -Force | Out-Null
            }
            
            $localFilePath = Join-Path $downloadPath (Split-Path $fileName -Leaf)
            
            Write-Host "Downloading: $fileName..." -NoNewline
            
            $params = @{
                BucketName = $this.BucketName
                Key = $fileName
                File = $localFilePath
            }
            
            if ($this.ProfileName) {
                $params['ProfileName'] = $this.ProfileName
            }
            
            Copy-S3Object @params
            
            Write-Host "  Success" -ForegroundColor Green
            Write-Host "   Saved to: $localFilePath"
            
            return $true
        }
        catch {
            Write-Host "  Failed: $($_.Exception.Message)" -ForegroundColor Red
            return $false
        }
    }
    
    [array]GetUserSelection([int]$totalFiles) {
        while ($true) {
            try {
                $selection = Read-Host "`nEnter file numbers to download (e.g., 1,3,5 or 1-3)"
                $selection = $selection.Trim()
                
                if ([string]::IsNullOrEmpty($selection)) {
                    Write-Host "No selection made. Please try again."
                    continue
                }
                
                $selectedIndices = @()
                $parts = $selection -split ','
                
                foreach ($part in $parts) {
                    $part = $part.Trim()
                    
                    if ($part -match '-') {
                        $range = $part -split '-'
                        $start = [int]$range[0].Trim()
                        $end = [int]$range[1].Trim()
                        
                        if ($start -lt 1 -or $end -gt $totalFiles -or $start -gt $end) {
                            throw "Invalid range"
                        }
                        
                        $selectedIndices += $start..$end
                    }
                    else {
                        $num = [int]$part
                        
                        if ($num -lt 1 -or $num -gt $totalFiles) {
                            throw "Invalid number"
                        }
                        
                        $selectedIndices += $num
                    }
                }
                
                $selectedIndices = $selectedIndices | Select-Object -Unique | Sort-Object
                
                return $selectedIndices
            }
            catch {
                Write-Host "Invalid input! Please enter numbers between 1 and $totalFiles" -ForegroundColor Red
                Write-Host "Examples: '1,2,3' or '1-3' or '1,3-5'" -ForegroundColor Yellow
            }
        }
        
        return @()
    }
    
    [void]Run() {
        while ($true) {
            $files = $this.ListFiles()
            
            if ($files.Count -eq 0) {
                break
            }
            
            $selectedIndices = $this.GetUserSelection($files.Count)
            
            Write-Host "`nYou selected $($selectedIndices.Count) file(s)"
            Write-Host ("-" * 60)
            
            $successCount = 0
            foreach ($idx in $selectedIndices) {
                $fileName = $files[$idx - 1]
                if ($this.DownloadFile($fileName, ".\downloads")) {
                    $successCount++
                }
            }
            
            Write-Host ("-" * 60)
            Write-Host "Download complete: $successCount/$($selectedIndices.Count) files downloaded successfully`n"
            
            while ($true) {
                $continueChoice = Read-Host "Do you want to download more files? (yes/no)"
                $continueChoice = $continueChoice.Trim().ToLower()
                
                if ($continueChoice -in @('yes', 'y')) {
                    Write-Host ""
                    break
                }
                elseif ($continueChoice -in @('no', 'n')) {
                    Write-Host "`nExiting... Goodbye!"
                    return
                }
                else {
                    Write-Host "Please enter 'yes' or 'no'" -ForegroundColor Yellow
                }
            }
        }
    }
}

function Get-AvailableProfiles {
    try {
        $configPath = Join-Path $env:USERPROFILE ".aws\config"
        
        if (Test-Path $configPath) {
            $profiles = @()
            $content = Get-Content $configPath
            
            foreach ($line in $content) {
                if ($line -match '^\[profile\s+(.+)\]') {
                    $profiles += $matches[1]
                }
                elseif ($line -match '^\[(.+)\]' -and $line -notmatch 'default') {
                    $profiles += $matches[1]
                }
            }
            
            $credentialsPath = Join-Path $env:USERPROFILE ".aws\credentials"
            if (Test-Path $credentialsPath) {
                $credContent = Get-Content $credentialsPath
                if ($credContent -match '^\[default\]') {
                    $profiles = @('default') + $profiles
                }
            }
            
            return $profiles | Select-Object -Unique
        }
        
        return @()
    }
    catch {
        Write-Host "Warning: Could not list profiles: $($_.Exception.Message)" -ForegroundColor Yellow
        return @()
    }
}

function Main {
    Write-Host ("=" * 60)
    Write-Host "        AWS S3 File Download Manager (SSO)"
    Write-Host ("=" * 60)
    Write-Host ""
    
    $profiles = Get-AvailableProfiles
    
    if ($profiles.Count -gt 0) {
        Write-Host "Available AWS profiles:"
        $idx = 1
        foreach ($awsProfile in $profiles) {
            Write-Host "  $idx. $awsProfile"
            $idx++
        }
        Write-Host ""
    }
    
    $profileName = Read-Host "Enter your AWS profile name (press Enter for default)"
    $profileName = $profileName.Trim()
    
    if ([string]::IsNullOrEmpty($profileName)) {
        $profileName = $null
        Write-Host "Using default profile"
    }
    
    Write-Host ""
    
    $bucketName = Read-Host "Enter your S3 bucket name"
    $bucketName = $bucketName.Trim()
    
    if ([string]::IsNullOrEmpty($bucketName)) {
        Write-Host "ERROR: Bucket name cannot be empty!" -ForegroundColor Red
        return
    }
    
    Write-Host ""
    
    $manager = [S3DownloadManager]::new($bucketName, $profileName)
    $manager.Run()
}

Main