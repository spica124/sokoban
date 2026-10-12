param([string]$ManifestPath = '')
$ErrorActionPreference = 'Stop'
# Read-only PNG inspection; this never modifies artwork. Use Windows PowerShell 5.1.
Add-Type -AssemblyName System.Drawing
$projectDirectory = [IO.Path]::GetFullPath((Join-Path $PSScriptRoot '..'))
if (-not $ManifestPath) { $ManifestPath = Join-Path $projectDirectory 'docs/art/new-features-manifest.json' }
$specs = @(
    @('assets/sprites/hat_straw.png',256,'hat','Straw sun hat'),
    @('assets/sprites/hat_mandarin.png',256,'hat','Single mandarin'),
    @('assets/sprites/hat_flower.png',256,'hat','Flower wreath'),
    @('assets/sprites/hat_leaf.png',256,'hat','Leaf hat'),
    @('assets/sprites/hat_chef.png',256,'hat','Chef toque'),
    @('assets/sprites/hat_beanie.png',256,'hat','Red knit beanie'),
    @('assets/sprites/hat_grad.png',256,'hat','Graduation mortarboard'),
    @('assets/sprites/hat_crown.png',256,'hat','Gold crown'),
    @('assets/sprites/box_c1.png',256,'tile','Green kabocha squash'),
    @('assets/sprites/box_on_goal_c1.png',256,'tile','Green squash on goal'),
    @('assets/sprites/ice.png',256,'overlay','Translucent ice floor'),
    @('assets/sprites/oneway.png',256,'tile','Upward painted arrow'),
    @('assets/ui/rule_color.png',128,'ui','Color matching rule'),
    @('assets/ui/rule_ice.png',128,'ui','Ice rule'),
    @('assets/ui/rule_oneway.png',128,'ui','One-way rule'),
    @('assets/ui/rule_mix.png',128,'ui','Mixed rules'),
    @('assets/ui/daily.png',128,'ui','Daily puzzle'),
    @('assets/ui/trophy.png',128,'ui','Achievements'),
    @('assets/ui/hanger.png',128,'ui','Wardrobe')
)
$missing = @($specs | Where-Object { -not (Test-Path -LiteralPath (Join-Path $projectDirectory $_[0])) } | ForEach-Object { $_[0] })
if ($missing.Count) { throw ('Missing new-feature assets: ' + ($missing -join ', ')) }
$manifest = foreach ($spec in $specs) {
    $path = Join-Path $projectDirectory $spec[0]
    $b = [Drawing.Bitmap]::FromFile($path)
    try {
        if ($b.RawFormat.Guid -ne [Drawing.Imaging.ImageFormat]::Png.Guid) { throw "Not PNG: $path" }
        if ($b.Width -ne $spec[1] -or $b.Height -ne $spec[1]) { throw "Wrong dimensions: $path" }
        if (($b.PixelFormat -band [Drawing.Imaging.PixelFormat]::Alpha) -eq 0) { throw "No alpha channel: $path" }
        $zero=0; $partial=0; $opaque=0; $maximum=0; $minimum=255; $interiorPartial=0; $interiorCount=0
        $x0=$b.Width; $y0=$b.Height; $x1=-1; $y1=-1
        for ($y=0; $y -lt $b.Height; $y++) {
            for ($x=0; $x -lt $b.Width; $x++) {
                $a=[int]$b.GetPixel($x,$y).A
                $maximum=[Math]::Max($maximum,$a); $minimum=[Math]::Min($minimum,$a)
                if ($a -eq 0) {$zero++} elseif ($a -eq 255) {$opaque++} else {$partial++}
                if ($a -gt 16) { $x0=[Math]::Min($x0,$x);$x1=[Math]::Max($x1,$x);$y0=[Math]::Min($y0,$y);$y1=[Math]::Max($y1,$y) }
                if ($x -ge $b.Width/4 -and $x -lt 3*$b.Width/4 -and $y -ge $b.Height/4 -and $y -lt 3*$b.Height/4) {
                    $interiorCount++
                    if ($a -ge 16 -and $a -le 240) {$interiorPartial++}
                }
            }
        }
        $corners=@($b.GetPixel(0,0).A,$b.GetPixel(($b.Width-1),0).A,$b.GetPixel(0,($b.Height-1)).A,$b.GetPixel(($b.Width-1),($b.Height-1)).A)
        if ($x1 -lt 0 -or $maximum -lt 32) { throw "No visible artwork: $path" }
        if ($spec[2] -eq 'overlay') {
            # Soft edges alone do not count: the middle half must reveal the floor.
            if ($interiorPartial -lt [Math]::Ceiling($interiorCount*0.25)) { throw "Ice interior needs real partial alpha (16..240), not only antialiased edges: $path" }
        } else {
            if ($zero -eq 0 -or @($corners | Where-Object {$_ -ne 0}).Count -gt 0) { throw "Cutout needs real transparency and clear corners: $path" }
            if ($x0 -lt 2 -or $y0 -lt 2 -or $x1 -gt $b.Width-3 -or $y1 -gt $b.Height-3) { throw "Insufficient clear padding: $path" }
        }
        $visibleWidth=$x1-$x0+1; $visibleHeight=$y1-$y0+1
        if ($spec[2] -eq 'hat') {
            if ($visibleWidth -gt 224 -or $visibleHeight -gt 166) { throw "Hat visible bounds exceed 224x166: $path ($visibleWidth x $visibleHeight)" }
            if ([Math]::Abs(($y1+1)-200) -gt 1) { throw "Hat bottom must align to y=200: $path" }
            if ([Math]::Abs((($x0+$x1+1)/2.0)-128) -gt 2) { throw "Hat must be horizontally centered at x=128: $path" }
        }
        [pscustomobject]@{
            path=$spec[0];resource=('res://'+$spec[0]);width=$b.Width;height=$b.Height;category=$spec[2];usage=$spec[3];
            pixelFormat=$b.PixelFormat.ToString();cornerAlpha=$corners;transparentPixels=$zero;partialAlphaPixels=$partial;opaquePixels=$opaque;minAlpha=$minimum;maxAlpha=$maximum;
            interiorPartialAlphaPixels=$interiorPartial;interiorSamplePixels=$interiorCount;visibleBounds=@($x0,$y0,$x1,$y1);visibleWidth=$visibleWidth;visibleHeight=$visibleHeight;
            bytes=(Get-Item -LiteralPath $path).Length;sha256=(Get-FileHash -LiteralPath $path -Algorithm SHA256).Hash.ToLowerInvariant()
        }
    } finally { $b.Dispose() }
}
$manifest | ConvertTo-Json -Depth 5 | Set-Content -LiteralPath $ManifestPath -Encoding utf8
Write-Output 'PASS: all 19 new-feature PNG assets; exact sizes, actual alpha, hat alignment, translucent ice interior and SHA256 manifest.'
$manifest | Select-Object path,width,height,visibleWidth,visibleHeight,bytes
