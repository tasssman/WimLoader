#Requires -Version 5.1
[CmdletBinding()]
param(
    [string]$CompilerPath,

    [string]$AutoHotkeyBasePath,

    [string]$ImagePath,
    [string]$Destination = '\\ntshare\helpdesk\scripts\WinPE_HW\media\sources'
)

$ErrorActionPreference = 'Stop'
$localRoot = Join-Path $PSScriptRoot 'local'
if (-not $CompilerPath) {
    $CompilerPath = Join-Path $localRoot 'Ahk2Exe.exe'
}
if (-not $AutoHotkeyBasePath) {
    $AutoHotkeyBasePath = Join-Path $localRoot 'AutoHotkey64.exe'
}
if (-not $ImagePath) {
    $ImagePath = Join-Path $localRoot 'WinPE_HW\media\sources\boot.wim'
}
if (-not (Test-Path -LiteralPath $CompilerPath -PathType Leaf)) {
    throw "Ahk2Exe compiler not found: $CompilerPath. Place Ahk2Exe.exe in $localRoot or specify -CompilerPath."
}
if (-not (Test-Path -LiteralPath $AutoHotkeyBasePath -PathType Leaf)) {
    throw "AutoHotkey v2 base executable not found: $AutoHotkeyBasePath. Place AutoHotkey64.exe in $localRoot or specify -AutoHotkeyBasePath."
}

$principal = New-Object Security.Principal.WindowsPrincipal([Security.Principal.WindowsIdentity]::GetCurrent())
if (-not $principal.IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)) {
    throw 'Run this script from an elevated PowerShell session.'
}

$sourcePath = Join-Path $PSScriptRoot 'WimLoader.ahk'
$workRoot = Join-Path $localRoot 'WinPE_HW'
foreach ($file in @($ImagePath, $sourcePath)) {
    if (-not (Test-Path -LiteralPath $file -PathType Leaf)) {
        throw "Required file not found: $file"
    }
}
if (-not (Test-Path -LiteralPath $workRoot -PathType Container)) {
    throw "WinPE working directory not found: $workRoot"
}
if (-not (Test-Path -LiteralPath $Destination -PathType Container)) {
    throw "Destination directory is not accessible: $Destination"
}

$imageFile = (Resolve-Path -LiteralPath $ImagePath).ProviderPath
$destinationPath = (Resolve-Path -LiteralPath $Destination).ProviderPath
$publishedImage = Join-Path $destinationPath 'boot.wim'
$publishedManifest = Join-Path $destinationPath 'winpe-update.ini'
if ([string]::Equals($imageFile, $publishedImage, [StringComparison]::OrdinalIgnoreCase)) {
    throw 'The source image and published image must be different files.'
}

$versionMatches = @([regex]::Matches(
    (Get-Content -LiteralPath $sourcePath -Raw),
    '(?m)^\s*version\s*:=\s*"(\d+\.\d+\.\d+(?:\.\d+)?)"\s*$'
))
if ($versionMatches.Count -ne 1) {
    throw 'Expected exactly one valid version assignment in WimLoader.ahk.'
}
$version = $versionMatches[0].Groups[1].Value
$dism = (Get-Command dism.exe -ErrorAction Stop).Source
$id = [guid]::NewGuid().ToString('N')
$workDir = Join-Path $workRoot ".deploy-$id"
$mountDir = Join-Path $workDir 'mount'
$workingImage = Join-Path $workDir 'boot.wim'
$executable = Join-Path $workDir 'WimLoader.exe'
$publishDir = Join-Path $destinationPath "wimloader-deploy-$id"
$lock = $null
$mountMayExist = $false
$failure = $null
$cleanupFailures = @()

try {
    # Keep the lock file in place: deleting it can race with another publisher.
    $lockPath = Join-Path $destinationPath '.wimloader-deploy.lock'
    $lock = [System.IO.File]::Open($lockPath, [System.IO.FileMode]::OpenOrCreate,
        [System.IO.FileAccess]::ReadWrite, [System.IO.FileShare]::None)

    New-Item -ItemType Directory -Path $workDir, $mountDir | Out-Null
    Write-Host "Compiling WimLoader $version..."
    $compilerArguments = '/in "{0}" /out "{1}" /base "{2}"' -f $sourcePath, $executable, $AutoHotkeyBasePath
    $compilerProcess = Start-Process -FilePath $CompilerPath -ArgumentList $compilerArguments -Wait -PassThru
    if ($compilerProcess.ExitCode -ne 0) {
        throw "AutoHotkey compilation failed (exit code $($compilerProcess.ExitCode))."
    }
    if (-not (Test-Path -LiteralPath $executable -PathType Leaf)) {
        throw "AutoHotkey compilation did not produce the executable: $executable"
    }
    Write-Host "Compilation completed: WimLoader $version."

    Write-Host 'Copying the source image to the working directory...'
    Copy-Item -LiteralPath $imageFile -Destination $workingImage
    Write-Host 'Mounting the working image...'
    $mountMayExist = $true
    & $dism /Mount-Image "/ImageFile:$workingImage" /Index:1 "/MountDir:$mountDir"
    if ($LASTEXITCODE -ne 0) {
        throw "DISM mount failed (exit code $LASTEXITCODE)."
    }

    Write-Host 'Copying WimLoader.exe to Windows\System32 in the mounted image...'
    Copy-Item -LiteralPath $executable -Destination (Join-Path $mountDir 'Windows\System32\WimLoader.exe') -Force
    Write-Host 'WimLoader.exe copied to the mounted image.'
    Write-Host 'Saving and unmounting the image...'
    & $dism /Unmount-Image "/MountDir:$mountDir" /Commit
    if ($LASTEXITCODE -ne 0) {
        throw "DISM commit failed (exit code $LASTEXITCODE)."
    }
    $mountMayExist = $false

    $hash = (Get-FileHash -LiteralPath $workingImage -Algorithm SHA256).Hash
    New-Item -ItemType Directory -Path $publishDir | Out-Null
    $stagedImage = Join-Path $publishDir 'boot.wim.new'
    $stagedManifest = Join-Path $publishDir 'winpe-update.ini.new'
    Write-Host 'Staging and verifying the image on the destination...'
    Copy-Item -LiteralPath $workingImage -Destination $stagedImage
    if ((Get-FileHash -LiteralPath $stagedImage -Algorithm SHA256).Hash -ne $hash) {
        throw 'The staged image hash does not match the local image.'
    }
    [System.IO.File]::WriteAllText($stagedManifest,
        "[WinPE]`r`nVersion=$version`r`nSHA256=$hash`r`n", [System.Text.Encoding]::ASCII)

    # Remove the old manifest first so new update checks cannot see a mismatched pair.
    if (Test-Path -LiteralPath $publishedManifest) {
        Remove-Item -LiteralPath $publishedManifest
    }
    Move-Item -LiteralPath $stagedImage -Destination $publishedImage -Force
    Move-Item -LiteralPath $stagedManifest -Destination $publishedManifest
    Write-Host "Published WimLoader $version to $destinationPath."
    Remove-Item -LiteralPath $publishDir
} catch {
    $failure = $_
} finally {
    if ($mountMayExist) {
        Write-Warning "Attempting to discard the mounted image at $mountDir."
        & $dism /Unmount-Image "/MountDir:$mountDir" /Discard
        if ($LASTEXITCODE -eq 0) {
            $mountMayExist = $false
        } else {
            $cleanupFailures += "DISM discard failed (exit code $LASTEXITCODE); preserve and inspect $workDir."
        }
    }
    if (-not $mountMayExist -and (Test-Path -LiteralPath $workDir)) {
        try {
            Remove-Item -LiteralPath $workDir -Recurse -Force
        } catch {
            $cleanupFailures += "Could not remove working directory ${workDir}: $($_.Exception.Message)"
        }
    }
    if ($null -ne $lock) {
        $lock.Dispose()
    }
}

if ($null -ne $failure) {
    Write-Warning "Deployment failed. If publication started, inspect $publishDir and $destinationPath before retrying."
    foreach ($cleanupFailure in $cleanupFailures) {
        Write-Warning $cleanupFailure
    }
    throw $failure
}
if ($cleanupFailures.Count -gt 0) {
    throw ($cleanupFailures -join ' ')
}
