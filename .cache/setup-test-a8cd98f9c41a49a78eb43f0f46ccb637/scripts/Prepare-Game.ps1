#requires -Version 5.1
<#
Creates a playable copy without changing originalgame or existing game saves/settings.
Downloads a pinned official wrapper release only when needed.
#>
[CmdletBinding()]
param(
    [ValidateSet('Fullscreen', 'Windowed')]
    [string] $Mode = 'Fullscreen'
)

Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

$projectRoot = Split-Path -Parent $PSScriptRoot
$originalDir = Join-Path $projectRoot 'originalgame'
$windowed = $Mode -eq 'Windowed'
$directoryName = if ($windowed) { 'game-windowed' } else { 'game' }
$gameDir = Join-Path $projectRoot $directoryName
$seedExistingProgress = $windowed -and -not (Test-Path -LiteralPath $gameDir)
$cacheDir = Join-Path $projectRoot '.cache'
$exeName = 'stilbomber2v103.exe'
$originalExe = Join-Path $originalDir $exeName
$gameExe = Join-Path $gameDir $exeName
$originalExeHash = 'F29BCD2DD0893F25F9CEAB7F38C6E26BF407D97350251B47F1B4ED308215A35F'
$wrapperName = 'DDrawCompat'
$wrapperVersion = 'v0.7.1'
$archiveHash = '0C33ECB1C01C1C779063B490A2E818F6D9227B3B4EE827C51790FB0FD59B17C5'
$wrapperHash = 'F75F0AC48D2782F225C483DC2F1142303A513E8DD8A60793891ADE89F64755EA'
$archiveName = "DDrawCompat-$wrapperVersion.zip"
$downloadUrl = "https://github.com/narzoul/DDrawCompat/releases/download/$wrapperVersion/$archiveName"
$configName = 'DDrawCompat.ini'
if ($windowed) {
    $wrapperName = 'cnc-ddraw'
    $wrapperVersion = 'v7.1.0.0'
    $archiveHash = '0B13AB89A64C9918189B1DADD449EF6ED3CB3B7B19CABD96D8ADBD95505BB908'
    $wrapperHash = '85E0F7D530DFDA134793A57CB3E76B0287DCC96892EE57162DD68F47283B03A9'
    $archiveName = "cnc-ddraw-$wrapperVersion.zip"
    $downloadUrl = "https://github.com/FunkyFr3sh/cnc-ddraw/releases/download/$wrapperVersion/cnc-ddraw.zip"
    $configName = 'ddraw.ini'
}
$wrapperDll = Join-Path $gameDir 'ddraw.dll'
$configSource = Join-Path (Join-Path $projectRoot 'compatibility') $configName

# Do not copy progress or replace files while either playable copy is running.
$playablePaths = @(
    (Join-Path $projectRoot "game\$exeName"),
    (Join-Path $projectRoot "game-windowed\$exeName")
)
if (Get-Process -Name 'stilbomber2v103' -ErrorAction SilentlyContinue |
        Where-Object { $_.Path -in $playablePaths }) {
    throw 'Close Stilbomber before preparing or launching either version.'
}

function Assert-FileHash([string] $Path, [string] $Expected) {
    if (-not (Test-Path -LiteralPath $Path -PathType Leaf)) {
        throw "Required file not found: $Path"
    }
    if ((Get-FileHash -LiteralPath $Path -Algorithm SHA256).Hash -ne $Expected) {
        throw "Unexpected SHA-256 for $Path. The file has been left untouched."
    }
}

Assert-FileHash $originalExe $originalExeHash
if (Test-Path -LiteralPath $gameExe) {
    Assert-FileHash $gameExe $originalExeHash
}
if (Test-Path -LiteralPath $wrapperDll) {
    Assert-FileHash $wrapperDll $wrapperHash
}
if (-not (Test-Path -LiteralPath $configSource -PathType Leaf)) {
    throw "Compatibility configuration not found: $configSource"
}

if (-not (Test-Path -LiteralPath $wrapperDll)) {
    New-Item -ItemType Directory -Path $cacheDir -Force | Out-Null
    $archivePath = Join-Path $cacheDir $archiveName
    $extractDir = Join-Path $cacheDir "$wrapperName-$wrapperVersion"
    if (-not (Test-Path -LiteralPath $archivePath)) {
        Write-Host "Downloading official $wrapperName $wrapperVersion..."
        Invoke-WebRequest -Uri $downloadUrl -OutFile $archivePath -UseBasicParsing
    }
    Assert-FileHash $archivePath $archiveHash
    Expand-Archive -LiteralPath $archivePath -DestinationPath $extractDir -Force
    $extractedDll = Join-Path $extractDir 'ddraw.dll'
    Assert-FileHash $extractedDll $wrapperHash
}

# Copy only missing files: repeated setup must preserve personal settings and saves.
New-Item -ItemType Directory -Path $gameDir -Force | Out-Null
foreach ($originalFile in Get-ChildItem -LiteralPath $originalDir -File -Recurse) {
    $relativeName = $originalFile.FullName.Substring($originalDir.Length + 1)
    $destination = Join-Path $gameDir $relativeName
    if (-not (Test-Path -LiteralPath $destination)) {
        New-Item -ItemType Directory -Path (Split-Path -Parent $destination) -Force | Out-Null
        Copy-Item -LiteralPath $originalFile.FullName -Destination $destination
    }
}
New-Item -ItemType Directory -Path (Join-Path $gameDir 'save') -Force | Out-Null

# Only on the first creation of the isolated windowed copy, seed current progress.
# Do not copy the other wrapper, logs or INIs; the two renderers cannot be stacked.
# Subsequent launches leave the two copies' saves/settings independent.
if ($seedExistingProgress) {
    $previousGameDir = Join-Path $projectRoot 'game'
    foreach ($name in @('config.cfg', 'config2.cfg', 'rozlisenie', 'default.sbmx')) {
        $source = Join-Path $previousGameDir $name
        if (Test-Path -LiteralPath $source -PathType Leaf) {
            Copy-Item -LiteralPath $source -Destination (Join-Path $gameDir $name)
        }
    }
    $previousSaveDir = Join-Path $previousGameDir 'save'
    if (Test-Path -LiteralPath $previousSaveDir -PathType Container) {
        foreach ($saveFile in Get-ChildItem -LiteralPath $previousSaveDir -File -Recurse) {
            $relativeName = $saveFile.FullName.Substring($previousGameDir.Length + 1)
            $destination = Join-Path $gameDir $relativeName
            New-Item -ItemType Directory -Path (Split-Path -Parent $destination) -Force | Out-Null
            Copy-Item -LiteralPath $saveFile.FullName -Destination $destination
        }
    }
}
if (-not (Test-Path -LiteralPath $wrapperDll)) {
    Copy-Item -LiteralPath $extractedDll -Destination $wrapperDll
}
$gameConfig = Join-Path $gameDir $configName
if (-not (Test-Path -LiteralPath $gameConfig)) {
    Copy-Item -LiteralPath $configSource -Destination $gameConfig
}
if ($windowed) {
    Copy-Item -LiteralPath (Join-Path $projectRoot 'compatibility\cnc-ddraw-LICENSE.txt') `
        -Destination (Join-Path $gameDir 'cnc-ddraw-LICENSE.txt')
}

Assert-FileHash $gameExe $originalExeHash
Assert-FileHash $wrapperDll $wrapperHash
Assert-FileHash $originalExe $originalExeHash
Write-Host "Ready: $gameExe"
Write-Host 'Existing game settings and saves were preserved.'
