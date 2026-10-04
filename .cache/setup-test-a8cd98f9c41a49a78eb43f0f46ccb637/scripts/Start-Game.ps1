#requires -Version 5.1
[CmdletBinding()]
param(
    [switch] $PrepareOnly,
    [switch] $PassThru
)

Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

$projectRoot = Split-Path -Parent $PSScriptRoot
$gameDir = Join-Path $projectRoot 'game'
$gameExe = Join-Path $gameDir 'stilbomber2v103.exe'
$runningGame = Get-Process -Name 'stilbomber2v103' -ErrorAction SilentlyContinue |
    Where-Object { $_.Path -eq $gameExe }
if ($runningGame) {
    throw 'Stilbomber is already running. Close it before launching another copy.'
}

& (Join-Path $PSScriptRoot 'Prepare-Game.ps1')
$desktop = & (Join-Path $PSScriptRoot 'Get-DesktopMode.ps1')
$resolution = '{0}x{1}' -f $desktop.Width, $desktop.Height
# Windows uses 0/1 for an unspecified/default refresh rate. Do not force those.
$refreshRate = if ($desktop.RefreshRate -gt 1) { [string] $desktop.RefreshRate } else { 'desktop' }

# Scale only the DirectDraw game surface. Ordinary Delphi forms must keep the
# desktop and DPI context they used before the wrapper was loaded dynamically.
# Use 'desktop', not 'initial': the latter emulates physical pixels even for
# DPI-unaware forms, which use logical desktop coordinates when centering.
$settings = [ordered]@{
    FullscreenMode = 'borderless'
    DesktopResolution = 'desktop'
    DesktopColorDepth = 'initial'
    DpiAwareness = 'app'
    DisplayResolution = $resolution
    DisplayRefreshRate = $refreshRate
    DisplayAspectRatio = 'app'
    RenderColorDepth = '32'
}
$configPath = Join-Path $gameDir 'DDrawCompat-stilbomber2v103.ini'
$header = '; Desktop scaling settings refreshed by Play-Stilbomber.cmd on every launch.'
$managedKeys = ($settings.Keys | ForEach-Object { [regex]::Escape($_) }) -join '|'
$managedLine = '^\s*(' + $managedKeys + ')\s*='
$otherLines = @()
if (Test-Path -LiteralPath $configPath) {
    $otherLines = @(Get-Content -LiteralPath $configPath | Where-Object {
        $_ -ne $header -and $_ -notmatch $managedLine
    })
}
$configLines = @($header) + $otherLines + @($settings.GetEnumerator() | ForEach-Object {
    '{0} = {1}' -f $_.Key, $_.Value
})
[IO.File]::WriteAllLines($configPath, [string[]] $configLines, [Text.UTF8Encoding]::new($false))

Write-Host "Keeping desktop at $resolution, $refreshRate Hz; scaling the game to fit."
if (-not $PrepareOnly) {
    $gameProcess = Start-Process -FilePath $gameExe -WorkingDirectory $gameDir -PassThru
    if ($PassThru) { $gameProcess }
}
