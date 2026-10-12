param([string]$FileName = 'sokoban_assets_farm_v2_20260907.zip')
$ErrorActionPreference = 'Stop'
Add-Type -AssemblyName System.IO.Compression.FileSystem
$projectDirectory = [System.IO.Path]::GetFullPath((Join-Path $PSScriptRoot '..'))
if ([System.IO.Path]::GetFileName($FileName) -ne $FileName) { throw 'Use an archive filename without a directory.' }
$archivePath = Join-Path $projectDirectory $FileName
if (Test-Path -LiteralPath $archivePath) { throw 'Archive already exists; use a new filename.' }
$manifest = Get-Content -Raw -LiteralPath (Join-Path $projectDirectory 'docs/art/manifest.json') | ConvertFrom-Json
$filesToArchive = @($manifest | ForEach-Object { Get-Item -LiteralPath (Join-Path $projectDirectory $_.path) })
$filesToArchive += @(Get-Item -LiteralPath (Join-Path $projectDirectory 'ART_ASSETS.md'), (Join-Path $projectDirectory 'ASSETS.md'), (Join-Path $projectDirectory 'docs/art/manifest.json'), (Join-Path $projectDirectory 'docs/screenshots/assets_menu.png'))
$filesToArchive += @(Get-ChildItem -LiteralPath (Join-Path $projectDirectory 'docs/art') -File -Filter '*prompts.md')
foreach ($toolFile in @('tools/art_player_pack.ps1','tools/art_ui_farm_store.ps1','tools/art_environment_farm_package.ps1','tools/package_sprite.ps1','tools/package_art.ps1','tools/check_art.ps1','tools/capture_assets.gd','tools/verify_farm_art.ps1','tools/bundle_art.ps1')) {
    $filesToArchive += Get-Item -LiteralPath (Join-Path $projectDirectory $toolFile)
}
$archive = [System.IO.Compression.ZipFile]::Open($archivePath, [System.IO.Compression.ZipArchiveMode]::Create)
try {
    foreach ($file in $filesToArchive) {
        $entryName = $file.FullName.Substring($projectDirectory.Length + 1).Replace('\','/')
        [System.IO.Compression.ZipFileExtensions]::CreateEntryFromFile($archive, $file.FullName, $entryName, [System.IO.Compression.CompressionLevel]::Optimal) | Out-Null
    }
} finally { $archive.Dispose() }
$verificationArchive = [System.IO.Compression.ZipFile]::OpenRead($archivePath)
try {
    foreach ($asset in $manifest) {
        $entry = $verificationArchive.GetEntry($asset.path)
        if ($null -eq $entry -or $entry.Length -ne $asset.bytes) { throw "Archive entry mismatch: $($asset.path)" }
        $stream = $entry.Open()
        $sha = [System.Security.Cryptography.SHA256]::Create()
        try { $entryHash = [BitConverter]::ToString($sha.ComputeHash($stream)).Replace('-','').ToLowerInvariant() }
        finally { $stream.Dispose(); $sha.Dispose() }
        if ($entryHash -ne $asset.sha256) { throw "Archive hash mismatch: $($asset.path)" }
    }
    Write-Output "Archive verified: $($verificationArchive.Entries.Count) files; all $($manifest.Count) PNG hashes match manifest."
} finally { $verificationArchive.Dispose() }
Get-Item -LiteralPath $archivePath | Select-Object FullName,Length
