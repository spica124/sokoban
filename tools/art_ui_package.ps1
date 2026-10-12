param(
    [string]$ProjectRoot = 'C:/Users/limji/Desktop/game/sokoban',
    [string]$LogoSource = 'C:/Users/limji/.codex/generated_images/01a07604-fddd-7fd0-8fa3-9d390971f6f4/exec-57bd973d-d045-4ba4-ab9b-00a9fef2a87c.png',
    [string]$BackgroundSource = 'C:/Users/limji/.codex/generated_images/01a07604-fddd-7fd0-8fa3-9d390971f6f4/exec-28a0fde4-9811-4c17-ad22-d304e4c3ed5b.png',
    [string]$SmallSource = 'C:/Users/limji/.codex/generated_images/01a07604-fddd-7fd0-8fa3-9d390971f6f4/exec-0dddb3ca-2dea-4a47-9f3d-c2fb06ce0423.png',
    [string]$VerticalSource = 'C:/Users/limji/.codex/generated_images/01a07604-fddd-7fd0-8fa3-9d390971f6f4/exec-1f4965c6-789a-4836-bafd-3ce9e5b4eec7.png',
    [ValidateSet('UI', 'Capsules')][string]$AssetSet = 'UI'
)
$ErrorActionPreference = 'Stop'
Add-Type -AssemblyName System.Drawing

function Save-ArtCanvas {
    param([string]$Source, [string]$Destination, [int]$Width, [int]$Height, [bool]$Cover)
    if (Test-Path -LiteralPath $Destination) { throw "Refusing to overwrite existing asset: $Destination" }
    $sourceImage = [System.Drawing.Bitmap]::FromFile($Source)
    $canvas = [System.Drawing.Bitmap]::new($Width, $Height, [System.Drawing.Imaging.PixelFormat]::Format32bppArgb)
    $graphics = [System.Drawing.Graphics]::FromImage($canvas)
    try {
        $graphics.Clear([System.Drawing.Color]::Transparent)
        $graphics.CompositingMode = [System.Drawing.Drawing2D.CompositingMode]::SourceCopy
        $graphics.CompositingQuality = [System.Drawing.Drawing2D.CompositingQuality]::HighQuality
        $graphics.InterpolationMode = [System.Drawing.Drawing2D.InterpolationMode]::HighQualityBicubic
        $graphics.PixelOffsetMode = [System.Drawing.Drawing2D.PixelOffsetMode]::HighQuality
        $ratioX = $Width / $sourceImage.Width
        $ratioY = $Height / $sourceImage.Height
        $ratio = if ($Cover) { [Math]::Max($ratioX, $ratioY) } else { [Math]::Min($ratioX, $ratioY) }
        $drawWidth = [float]($sourceImage.Width * $ratio)
        $drawHeight = [float]($sourceImage.Height * $ratio)
        $destinationRectangle = [System.Drawing.Rectangle]::new([int][Math]::Round(($Width - $drawWidth) / 2), [int][Math]::Round(($Height - $drawHeight) / 2), [int][Math]::Round($drawWidth), [int][Math]::Round($drawHeight))
        $attributes = [System.Drawing.Imaging.ImageAttributes]::new()
        try {
            $attributes.SetWrapMode([System.Drawing.Drawing2D.WrapMode]::TileFlipXY)
            $graphics.DrawImage($sourceImage, $destinationRectangle, 0, 0, $sourceImage.Width, $sourceImage.Height, [System.Drawing.GraphicsUnit]::Pixel, $attributes)
        } finally { $attributes.Dispose() }
        $canvas.Save($Destination, [System.Drawing.Imaging.ImageFormat]::Png)
    } finally {
        $graphics.Dispose()
        $canvas.Dispose()
        $sourceImage.Dispose()
    }
}

$spriteDirectory = Join-Path $ProjectRoot 'assets/sprites'
$storeDirectory = Join-Path $ProjectRoot 'assets/store'
[void][System.IO.Directory]::CreateDirectory($spriteDirectory)
[void][System.IO.Directory]::CreateDirectory($storeDirectory)
if ($AssetSet -eq 'UI') {
    Save-ArtCanvas -Source $LogoSource -Destination (Join-Path $spriteDirectory 'logo.png') -Width 1040 -Height 400 -Cover $false
    Save-ArtCanvas -Source $LogoSource -Destination (Join-Path $storeDirectory 'library_logo.png') -Width 1280 -Height 720 -Cover $false
    Save-ArtCanvas -Source $BackgroundSource -Destination (Join-Path $spriteDirectory 'bg.png') -Width 1920 -Height 1080 -Cover $true
} else {
    Save-ArtCanvas -Source $SmallSource -Destination (Join-Path $storeDirectory 'capsule_small.png') -Width 231 -Height 87 -Cover $true
    Save-ArtCanvas -Source $VerticalSource -Destination (Join-Path $storeDirectory 'capsule_vertical.png') -Width 374 -Height 448 -Cover $true
}
