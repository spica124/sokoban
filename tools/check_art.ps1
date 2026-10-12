$ErrorActionPreference = 'Stop'
Add-Type -AssemblyName System.Drawing
$projectDirectory = [System.IO.Path]::GetFullPath((Join-Path $PSScriptRoot '..'))
$expected = @(
    @('assets/sprites/floor.png',256,256,'opaque'),
    @('assets/sprites/wall.png',256,256,'opaque'),
    @('assets/sprites/goal.png',256,256,'alpha'),
    @('assets/sprites/goal_tile.png',256,256,'opaque'),
    @('assets/sprites/box.png',256,256,'alpha'),
    @('assets/sprites/box_on_goal.png',256,256,'alpha'),
    @('assets/sprites/player.png',256,256,'alpha'),
    @('assets/sprites/player_down.png',256,256,'alpha'),
    @('assets/sprites/player_up.png',256,256,'alpha'),
    @('assets/sprites/player_left.png',256,256,'alpha'),
    @('assets/sprites/player_right.png',256,256,'alpha'),
    @('assets/sprites/bg.png',1920,1080,'opaque'),
    @('assets/sprites/logo.png',1040,400,'alpha'),
    @('assets/ui/panel.png',96,96,'alpha'),
    @('assets/ui/button.png',96,96,'alpha'),
    @('assets/ui/button_hover.png',96,96,'alpha'),
    @('assets/ui/button_pressed.png',96,96,'alpha'),
    @('assets/ui/button_disabled.png',96,96,'alpha'),
    @('assets/icon.png',512,512,'opaque'),
    @('assets/store/capsule_header.png',460,215,'opaque'),
    @('assets/store/capsule_small.png',231,87,'opaque'),
    @('assets/store/capsule_main.png',616,353,'opaque'),
    @('assets/store/capsule_vertical.png',374,448,'opaque'),
    @('assets/store/library_hero.png',3840,1240,'opaque'),
    @('assets/store/library_logo.png',1280,720,'alpha'),
    @('assets/store/icon.png',512,512,'opaque'),
    @('assets/store/screenshots/stage1.png',1920,1080,'opaque'),
    @('assets/store/screenshots/stage9.png',1920,1080,'opaque'),
    @('assets/store/screenshots/stage24.png',1920,1080,'opaque')
)
$manifest = foreach ($spec in $expected) {
    $assetPath = Join-Path $projectDirectory $spec[0]
    if (-not (Test-Path -LiteralPath $assetPath)) { throw "Missing asset: $($spec[0])" }
    $bitmap = [System.Drawing.Bitmap]::FromFile($assetPath)
    try {
        if ($bitmap.RawFormat.Guid -ne [System.Drawing.Imaging.ImageFormat]::Png.Guid) { throw "Not PNG: $($spec[0])" }
        if ($bitmap.Width -ne $spec[1] -or $bitmap.Height -ne $spec[2]) { throw "Wrong size: $($spec[0])" }
        $alphaChannel = ($bitmap.PixelFormat -band [System.Drawing.Imaging.PixelFormat]::Alpha) -ne 0
        $cornerAlpha = @(
            $bitmap.GetPixel(0,0).A,
            $bitmap.GetPixel(($bitmap.Width-1),0).A,
            $bitmap.GetPixel(0,($bitmap.Height-1)).A,
            $bitmap.GetPixel(($bitmap.Width-1),($bitmap.Height-1)).A
        )
        $minSampleAlpha = 255
        $maxSampleAlpha = 0
        for ($sampleY=0; $sampleY -lt $bitmap.Height; $sampleY+=8) {
            for ($sampleX=0; $sampleX -lt $bitmap.Width; $sampleX+=8) {
                $sampleAlpha = [int]$bitmap.GetPixel($sampleX,$sampleY).A
                $minSampleAlpha = [Math]::Min($minSampleAlpha,$sampleAlpha)
                $maxSampleAlpha = [Math]::Max($maxSampleAlpha,$sampleAlpha)
            }
        }
        if ($spec[3] -eq 'alpha' -and (-not $alphaChannel -or ($cornerAlpha | Where-Object { $_ -ne 0 }).Count -gt 0 -or $maxSampleAlpha -lt 240)) { throw "Invalid transparency: $($spec[0])" }
        if ($spec[3] -eq 'opaque' -and $minSampleAlpha -ne 255) { throw "Unexpected transparent pixel sample: $($spec[0])" }
        if ($spec[0] -eq 'assets/sprites/goal.png' -and $bitmap.GetPixel(128,128).A -ne 0) { throw 'Goal center must be transparent.' }
        [pscustomobject]@{
            path=$spec[0]; width=$bitmap.Width; height=$bitmap.Height;
            expectedBackground=$spec[3]; pixelFormat=$bitmap.PixelFormat.ToString(); alphaChannel=$alphaChannel;
            cornerAlpha=$cornerAlpha; alphaSampleStride=8; minSampleAlpha=$minSampleAlpha; maxSampleAlpha=$maxSampleAlpha;
            bytes=(Get-Item -LiteralPath $assetPath).Length;
            sha256=(Get-FileHash -Algorithm SHA256 -LiteralPath $assetPath).Hash.ToLowerInvariant()
        }
    } finally { $bitmap.Dispose() }
}
$defaultPlayerHash = ($manifest | Where-Object { $_.path -eq 'assets/sprites/player.png' }).sha256
$downPlayerHash = ($manifest | Where-Object { $_.path -eq 'assets/sprites/player_down.png' }).sha256
if ($defaultPlayerHash -ne $downPlayerHash) { throw 'Default and down player must match.' }
$runtimeIconHash = ($manifest | Where-Object { $_.path -eq 'assets/icon.png' }).sha256
$storeIconHash = ($manifest | Where-Object { $_.path -eq 'assets/store/icon.png' }).sha256
if ($runtimeIconHash -ne $storeIconHash) { throw 'Runtime and store icon must match.' }
$manifest | ConvertTo-Json -Depth 4 | Set-Content -LiteralPath (Join-Path $projectDirectory 'docs/art/manifest.json') -Encoding utf8
Write-Output "PASS: $($manifest.Count) PNG deliverables; requested sizes, alpha samples, transparent corners and matching default/down player."
