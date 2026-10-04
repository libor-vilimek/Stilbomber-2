#requires -Version 5.1
[CmdletBinding()]
param(
    [switch] $PrepareOnly,
    [switch] $PassThru
)

Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

$projectRoot = Split-Path -Parent $PSScriptRoot
$gameDir = Join-Path $projectRoot 'game-windowed'
& (Join-Path $PSScriptRoot 'Prepare-Game.ps1') -Mode Windowed

Write-Host 'Borderless window at desktop size; Ctrl+Tab releases the mouse.'
Write-Host 'Progress is stored separately in game-windowed\save.'
if (-not $PrepareOnly) {
    $gameProcess = Start-Process -FilePath (Join-Path $gameDir 'stilbomber2v103.exe') `
        -WorkingDirectory $gameDir -PassThru
    if ($PassThru) { $gameProcess }
}
