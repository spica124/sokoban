param([string]$ProjectRoot = 'C:\Users\limji\Desktop\game\sokoban')
$ErrorActionPreference = 'Stop'
Add-Type -AssemblyName System.Drawing
$sources = @{
    'floor.png' = 'C:\Users\limji\.codex\generated_images\01a07604-9dbf-7dd0-a447-72320a6e556b\exec-8dfb9bd5-0f11-4d4e-b872-5cb0f61e7a29.png'
    'wall.png' = 'C:\Users\limji\.codex\generated_images\01a07604-9dbf-7dd0-a447-72320a6e556b\exec-05a1bb27-9848-4408-8d8a-f779a79f8caf.png'
    'goal.png' = 'C:\Users\limji\.codex\generated_images\01a07604-9dbf-7dd0-a447-72320a6e556b\exec-5d00714e-87ea-4691-8f4b-7b82654d2f98.png'
}
$destination = Join-Path $ProjectRoot 'assets\sprites'
[System.IO.Directory]::CreateDirectory($destination) | Out-Null
foreach ($name in $sources.Keys) {
    $path = Join-Path $destination $name
    if (Test-Path -LiteralPath $path) { throw "Refusing to overwrite existing asset: $path" }
    $source = [System.Drawing.Bitmap]::new($sources[$name])
    $output = [System.Drawing.Bitmap]::new(256, 256, [System.Drawing.Imaging.PixelFormat]::Format32bppArgb)
    $graphics = [System.Drawing.Graphics]::FromImage($output)
    try {
        $graphics.CompositingMode = [System.Drawing.Drawing2D.CompositingMode]::SourceCopy
        $graphics.CompositingQuality = [System.Drawing.Drawing2D.CompositingQuality]::HighQuality
        $graphics.InterpolationMode = [System.Drawing.Drawing2D.InterpolationMode]::HighQualityBicubic
        $graphics.PixelOffsetMode = [System.Drawing.Drawing2D.PixelOffsetMode]::HighQuality
        $attributes = [System.Drawing.Imaging.ImageAttributes]::new()
        $attributes.SetWrapMode([System.Drawing.Drawing2D.WrapMode]::TileFlipXY)
        try {
            $graphics.DrawImage($source, [System.Drawing.Rectangle]::new(0, 0, 256, 256), 0, 0, $source.Width, $source.Height, [System.Drawing.GraphicsUnit]::Pixel, $attributes)
        } finally { $attributes.Dispose() }
        $output.Save($path, [System.Drawing.Imaging.ImageFormat]::Png)
    } finally {
        $graphics.Dispose()
        $output.Dispose()
        $source.Dispose()
    }
    $verified = [System.Drawing.Bitmap]::new($path)
    try {
        $transparent = 0; $partial = 0; $opaque = 0
        for ($y = 0; $y -lt 256; $y++) {
            for ($x = 0; $x -lt 256; $x++) {
                $alpha = $verified.GetPixel($x, $y).A
                if ($alpha -eq 0) { $transparent++ } elseif ($alpha -eq 255) { $opaque++ } else { $partial++ }
            }
        }
        [pscustomobject]@{File=$path;Width=$verified.Width;Height=$verified.Height;PixelFormat=$verified.PixelFormat.ToString();TransparentPixels=$transparent;PartialAlphaPixels=$partial;OpaquePixels=$opaque;Bytes=(Get-Item -LiteralPath $path).Length}
    } finally { $verified.Dispose() }
}
