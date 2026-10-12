param([string]$ProjectRoot = 'C:\Users\limji\Desktop\game\sokoban')
$ErrorActionPreference = 'Stop'
Add-Type -AssemblyName System.Drawing
$sources = @(
    @{Name='floor.png'; Width=256; Height=256; Source='C:\Users\limji\.codex\generated_images\01a07604-9dbf-7dd0-a447-72320a6e556b\exec-8b4b23d0-f70e-4278-9b68-c40f675c8b17.png'},
    @{Name='wall.png'; Width=256; Height=256; Source='C:\Users\limji\.codex\generated_images\01a07604-9dbf-7dd0-a447-72320a6e556b\exec-cd2db8c8-372c-42e5-ac27-4fc25621c270.png'},
    @{Name='goal_tile.png'; Width=256; Height=256; Source='C:\Users\limji\.codex\generated_images\01a07602-6a2b-7190-9f6e-7ba4f7d567df\exec-4eb70286-bc82-4f5b-975d-cdad690b54fe.png'},
    @{Name='bg.png'; Width=1920; Height=1080; Source='C:\Users\limji\.codex\generated_images\01a07604-9dbf-7dd0-a447-72320a6e556b\exec-c9021b06-d923-4791-acc3-479ab0d16254.png'}
)
$destination = Join-Path $ProjectRoot 'assets\sprites'
foreach ($item in $sources) {
    $path = Join-Path $destination $item.Name
    $source = [System.Drawing.Bitmap]::new($item.Source)
    $sourceWidth = $source.Width
    $sourceHeight = $source.Height
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
        $rect = [System.Drawing.Rectangle]::new(0,0,$verified.Width,$verified.Height)
        $data = $verified.LockBits($rect,[System.Drawing.Imaging.ImageLockMode]::ReadOnly,[System.Drawing.Imaging.PixelFormat]::Format32bppArgb)
        try {
            $pixels = [byte[]]::new([Math]::Abs($data.Stride)*$verified.Height)
            [System.Runtime.InteropServices.Marshal]::Copy($data.Scan0,$pixels,0,$pixels.Length)
        } finally { $verified.UnlockBits($data) }
        $transparent=0; $partial=0; $opaque=0
        for ($i=3; $i -lt $pixels.Length; $i+=4) {
            $a=$pixels[$i]
            if ($a -eq 0) {$transparent++} elseif ($a -eq 255) {$opaque++} else {$partial++}
        }
        if ($transparent -ne 0 -or $partial -ne 0) { throw "Expected fully opaque asset: $path" }
        [pscustomobject]@{File=$path;SourceSize="$sourceWidth x $sourceHeight";Width=$verified.Width;Height=$verified.Height;PixelFormat=$verified.PixelFormat.ToString();TransparentPixels=$transparent;PartialAlphaPixels=$partial;OpaquePixels=$opaque;Bytes=(Get-Item -LiteralPath $path).Length}
    } finally { $verified.Dispose() }
}
