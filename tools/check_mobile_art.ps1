$ErrorActionPreference = 'Stop'
Add-Type -AssemblyName System.Drawing
$projectDirectory = [IO.Path]::GetFullPath((Join-Path $PSScriptRoot '..'))
$specs = @(
    @('assets/ui/arrow.png',128,'ui','Up arrow; rotate about center for other directions'),
    @('assets/ui/star_on.png',128,'ui','Earned star'),
    @('assets/ui/star_off.png',128,'ui','Unearned star'),
    @('assets/ui/lock.png',128,'ui','Locked stage, replaces emoji'),
    @('assets/sprites/player_happy.png',256,'character','Stage clear expression'),
    @('assets/sprites/player_bump.png',256,'character','Temporary blocked-move expression'),
    @('assets/fx/sparkle.png',64,'fx','Pumpkin reaches goal'),
    @('assets/fx/dust.png',64,'fx','Push dust'),
    @('assets/fx/leaf.png',48,'fx','Clear celebration leaf'),
    @('assets/ui/tier_easy.png',128,'ui','Easy: sprout'),
    @('assets/ui/tier_normal.png',128,'ui','Normal: one pumpkin'),
    @('assets/ui/tier_hard.png',128,'ui','Hard: three pumpkins'),
    @('assets/ui/tier_expert.png',128,'ui','Expert: crowned pumpkin')
)
$manifest = foreach($spec in $specs) {
    $path = Join-Path $projectDirectory $spec[0]
    $b = [Drawing.Bitmap]::FromFile($path)
    try {
        if($b.RawFormat.Guid -ne [Drawing.Imaging.ImageFormat]::Png.Guid){throw "Not PNG: $path"}
        if($b.Width -ne $spec[1] -or $b.Height -ne $spec[1]){throw "Wrong dimensions: $path"}
        if(($b.PixelFormat -band [Drawing.Imaging.PixelFormat]::Alpha) -eq 0){throw "No alpha: $path"}
        $transparent=0; $partial=0; $opaque=0; $maximum=0
        $x0=$b.Width; $y0=$b.Height; $x1=-1; $y1=-1
        for($y=0;$y -lt $b.Height;$y++){
            for($x=0;$x -lt $b.Width;$x++){
                $a=[int]$b.GetPixel($x,$y).A
                $maximum=[Math]::Max($maximum,$a)
                if($a -eq 0){$transparent++}elseif($a -eq 255){$opaque++}else{$partial++}
                if($a -gt 16){$x0=[Math]::Min($x0,$x);$x1=[Math]::Max($x1,$x);$y0=[Math]::Min($y0,$y);$y1=[Math]::Max($y1,$y)}
            }
        }
        $corners=@($b.GetPixel(0,0).A,$b.GetPixel(($b.Width-1),0).A,$b.GetPixel(0,($b.Height-1)).A,$b.GetPixel(($b.Width-1),($b.Height-1)).A)
        if(($corners | Where-Object{$_ -ne 0}).Count -gt 0 -or $transparent -eq 0 -or $maximum -lt 32){throw "Invalid transparent cutout: $path"}
        if($x0 -lt 2 -or $y0 -lt 2 -or $x1 -gt ($b.Width-3) -or $y1 -gt ($b.Height-3)){throw "Insufficient clear padding: $path"}
        [pscustomobject]@{
            path=$spec[0]; resource=('res://'+$spec[0]); width=$b.Width; height=$b.Height; category=$spec[2]; usage=$spec[3];
            pixelFormat=$b.PixelFormat.ToString(); cornerAlpha=$corners; transparentPixels=$transparent; partialAlphaPixels=$partial; opaquePixels=$opaque; maxAlpha=$maximum;
            visibleBounds=@($x0,$y0,$x1,$y1);bytes=(Get-Item -LiteralPath $path).Length;
            sha256=(Get-FileHash -LiteralPath $path -Algorithm SHA256).Hash.ToLowerInvariant()
        }
    } finally {$b.Dispose()}
}
$on=$manifest | Where-Object{$_.path -eq 'assets/ui/star_on.png'}
$off=$manifest | Where-Object{$_.path -eq 'assets/ui/star_off.png'}
for($i=0;$i -lt 4;$i++){if([Math]::Abs($on.visibleBounds[$i]-$off.visibleBounds[$i]) -gt 3){throw 'Star pair alignment differs by more than 3 pixels'}}
$manifest | ConvertTo-Json -Depth 5 | Set-Content -LiteralPath (Join-Path $projectDirectory 'docs/art/mobile-manifest.json') -Encoding utf8
Write-Output 'PASS: all 13 mobile assets; exact sizes, RGBA, genuine transparent pixels, clear margins and aligned star pair.'
$manifest | Select-Object path,width,height,bytes

