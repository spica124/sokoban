param([string]$FileName = 'sokoban_mobile_assets_20260918.zip')
$ErrorActionPreference = 'Stop'
Add-Type -AssemblyName System.IO.Compression.FileSystem
$rootDirectory = [IO.Path]::GetFullPath((Join-Path $PSScriptRoot '..'))
if([IO.Path]::GetFileName($FileName) -ne $FileName){throw 'Use a filename without a directory'}
$zipPath=Join-Path $rootDirectory $FileName
if(Test-Path -LiteralPath $zipPath){throw 'Archive already exists; select a new filename'}
$manifest=Get-Content -LiteralPath (Join-Path $rootDirectory 'docs/art/mobile-manifest.json') -Raw | ConvertFrom-Json
$paths=@($manifest | ForEach-Object{$_.path})+@('MOBILE_ASSETS.md','ASSETS.md','docs/art/mobile-manifest.json','docs/art/mobile-generation-log.json','docs/art/mobile-prompts.md','docs/art/mobile-preview.html','tools/package_cutout.ps1','tools/check_mobile_art.ps1','tools/bundle_mobile_art.ps1')
$z=[IO.Compression.ZipFile]::Open($zipPath,[IO.Compression.ZipArchiveMode]::Create)
try{foreach($path in $paths){[IO.Compression.ZipFileExtensions]::CreateEntryFromFile($z,(Join-Path $rootDirectory $path),$path,[IO.Compression.CompressionLevel]::Optimal) | Out-Null}}finally{$z.Dispose()}
$z=[IO.Compression.ZipFile]::OpenRead($zipPath)
try{
    foreach($item in $manifest){
        $entry=$z.GetEntry($item.path)
        if($null -eq $entry -or $entry.Length -ne $item.bytes){throw "Archive size mismatch: $($item.path)"}
        $stream=$entry.Open();$sha=[Security.Cryptography.SHA256]::Create()
        try{$hash=[BitConverter]::ToString($sha.ComputeHash($stream)).Replace('-','').ToLowerInvariant()}finally{$stream.Dispose();$sha.Dispose()}
        if($hash -ne $item.sha256){throw "Archive hash mismatch: $($item.path)"}
    }
    Write-Output "PASS: $($z.Entries.Count) archive entries; all $($manifest.Count) PNG hashes verified"
}finally{$z.Dispose()}
Get-Item -LiteralPath $zipPath | Select-Object FullName,Length

