#requires -Version 5.1
Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'
$sourceRoot = Split-Path -Parent $PSScriptRoot
$testRoot = Join-Path $PSScriptRoot ('setup-test-' + [guid]::NewGuid().ToString('N'))
New-Item -ItemType Directory -Path $testRoot | Out-Null
foreach ($directory in @('scripts', 'compatibility', 'originalgame')) {
    Copy-Item -LiteralPath (Join-Path $sourceRoot $directory) -Destination $testRoot -Recurse
}
$testCache = Join-Path $testRoot '.cache'
New-Item -ItemType Directory -Path $testCache | Out-Null
foreach ($archive in @('DDrawCompat-v0.7.1.zip', 'cnc-ddraw-v7.1.0.0.zip')) {
    Copy-Item -LiteralPath (Join-Path $PSScriptRoot $archive) -Destination $testCache
}
$prepare = Join-Path $testRoot 'scripts\Prepare-Game.ps1'
function Snapshot([string] $Directory) {
    @(Get-ChildItem -LiteralPath $Directory -File -Recurse | ForEach-Object {
        '{0}:{1}' -f $_.FullName.Substring($Directory.Length), (Get-FileHash -LiteralPath $_.FullName).Hash
    })
}
function Assert-Same($Before, $After, [string] $Description) {
    if (Compare-Object @($Before) @($After)) { throw "FAIL: $Description" }
    Write-Host "PASS: $Description"
}
function Assert-Refused([scriptblock] $Action, [string] $Description) {
    $refused = $false
    try { & $Action } catch {
        if ($_.Exception.Message -notmatch 'Unexpected SHA-256') { throw }
        $refused = $true
    }
    if (-not $refused) { throw "FAIL: $Description" }
    Write-Host "PASS: $Description"
}
$original = Join-Path $testRoot 'originalgame'
$originalBefore = Snapshot $original
& $prepare
$fullscreen = Join-Path $testRoot 'game'
# Distinct fixture bytes stand in for changed user settings and a saved game.
Copy-Item -LiteralPath (Join-Path $original 'readme.txt') -Destination (Join-Path $fullscreen 'config.cfg')
Copy-Item -LiteralPath (Join-Path $original 'readme.txt') -Destination (Join-Path $fullscreen 'save\fixture.lod0')
$fullscreenBefore = Snapshot $fullscreen
& $prepare -Mode Windowed
$windowed = Join-Path $testRoot 'game-windowed'
foreach ($name in @('config.cfg', 'save\fixture.lod0')) {
    Assert-Same (Get-FileHash -LiteralPath (Join-Path $fullscreen $name)).Hash `
        (Get-FileHash -LiteralPath (Join-Path $windowed $name)).Hash "first-run seed $name"
}
Assert-Same $fullscreenBefore (Snapshot $fullscreen) 'fullscreen copy unchanged by windowed setup'
# Simulate progress made only in the windowed copy, then prepare it again.
Copy-Item -LiteralPath (Join-Path $original 'config2.cfg') -Destination (Join-Path $windowed 'save\fixture.lod0')
$windowedBefore = Snapshot $windowed
& $prepare -Mode Windowed
Assert-Same $windowedBefore (Snapshot $windowed) 'repeat windowed setup preserves personal progress and settings'
& $prepare
Assert-Same $fullscreenBefore (Snapshot $fullscreen) 'repeat fullscreen setup preserves personal progress and settings'
Assert-Same $originalBefore (Snapshot $original) 'original files unchanged'
# Refuse unknown binaries without silently replacing them.
Copy-Item -LiteralPath (Join-Path $original 'readme.txt') -Destination (Join-Path $windowed 'ddraw.dll')
$unknownWrapper = (Get-FileHash -LiteralPath (Join-Path $windowed 'ddraw.dll')).Hash
Assert-Refused { & $prepare -Mode Windowed } 'unknown wrapper rejected'
Assert-Same $unknownWrapper (Get-FileHash -LiteralPath (Join-Path $windowed 'ddraw.dll')).Hash 'unknown wrapper not overwritten'
Copy-Item -LiteralPath (Join-Path $original 'readme.txt') -Destination (Join-Path $fullscreen 'stilbomber2v103.exe')
Assert-Refused { & $prepare } 'unknown executable rejected'
Write-Host "All setup checks passed. Isolated fixtures retained at $testRoot"
