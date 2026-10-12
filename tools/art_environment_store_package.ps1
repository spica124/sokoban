param([string]$ProjectRoot = 'C:\Users\limji\Desktop\game\sokoban')
$ErrorActionPreference = 'Stop'
Add-Type -AssemblyName System.Drawing
$sources = @(
    @{Name='library_hero.png'; Width=3840; Height=1240; Source='C:\Users\limji\.codex\generated_images\01a07604-9dbf-7dd0-a447-72320a6e556b\exec-57f83668-2032-419a-a426-d09d06054404.png'},
    @{Name='icon.png'; Width=512; Height=512; Source='C:\Users\limji\.codex\generated_images\01a07604-9dbf-7dd0-a447-72320a6e556b\exec-f8e3ae7d-1fa9-4376-b443-f26054dcef69.png'}
)
$destination = Join-Path $ProjectRoot 'assets\store'
[System.IO.Directory]::CreateDirectory($destination) | Out-Null
foreach ($item in $sources) {
    $path = Join-Path $destination $item.Name
    if (Test-Path -LiteralPath $path) { throw "Refusing to overwrite existing asset: $path" }
    $source = [System.Drawing.Bitmap]::new($item.Source)
    $output = [System.Drawing.Bitmap]::new($item.Width, $item.Height, [System.Drawing.Imaging.PixelFormat]::Format32bppArgb)
    $graphics = [System.Drawing.Graphics]::FromImage($output)
    try {
        $graphics.CompositingMode = [System.Drawing.Drawing2D.CompositingMode]::SourceCopy
        $graphics.CompositingQuality = [System.Drawing.Drawing2D.CompositingQuality]::HighQuality
        $graphics.InterpolationMode = [System.Drawing.Drawing2D.InterpolationMode]::HighQualityBicubic
        $graphics.PixelOffsetMode = [System.Drawing.Drawing2D.PixelOffsetMode]::HighQuality
        $attributes = [System.Drawing.Imaging.ImageAttributes]::new()
        $attributes.SetWrapMode([System.Drawing.Drawing2D.WrapMode]::TileFlipXY)
        try { $graphics.DrawImage($source, [System.Drawing.Rectangle]::new(0, 0, $item.Width, $item.Height), 0, 0, $source.Width, $source.Height, [System.Drawing.GraphicsUnit]::Pixel, $attributes) }
        finally { $attributes.Dispose() }
        $output.Save($path, [System.Drawing.Imaging.ImageFormat]::Png)
    } finally { $graphics.Dispose(); $output.Dispose(); $source.Dispose() }
    $verified = [System.Drawing.Bitmap]::new($path)
    try {
        $transparent=0; $partial=0; $opaque=0
        for ($y=0; $y -lt $verified.Height; $y++) {
            for ($x=0; $x -lt $verified.Width; $x++) {
                $a=$verified.GetPixel($x,$y).A
                if ($a -eq 0) {$transparent++} elseif ($a -eq 255) {$opaque++} else {$partial++}
            }
        }
        [pscustomobject]@{File=$path;Width=$verified.Width;Height=$verified.Height;PixelFormat=$verified.PixelFormat.ToString();TransparentPixels=$transparent;PartialAlphaPixels=$partial;OpaquePixels=$opaque;Bytes=(Get-Item -LiteralPath $path).Length}
    } finally { $verified.Dispose() }
}
