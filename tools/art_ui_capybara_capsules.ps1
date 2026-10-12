param(
    [Parameter(Mandatory)][string]$Source,
    [Parameter(Mandatory)][ValidateSet('main','header','vertical')][string]$Capsule
)
$ErrorActionPreference = 'Stop'
Add-Type -AssemblyName System.Drawing
$dimensions = @{ main = @(616,353); header = @(460,215); vertical = @(374,448) }
$outputSize = $dimensions[$Capsule]
$destination = 'C:/Users/limji/Desktop/game/sokoban/assets/store/capsule_' + $Capsule + '.png'
$sourceImage = [System.Drawing.Bitmap]::FromFile($Source)
$canvas = [System.Drawing.Bitmap]::new($outputSize[0],$outputSize[1],[System.Drawing.Imaging.PixelFormat]::Format32bppArgb)
$graphics = [System.Drawing.Graphics]::FromImage($canvas)
$attributes = [System.Drawing.Imaging.ImageAttributes]::new()
try {
    $graphics.CompositingMode = [System.Drawing.Drawing2D.CompositingMode]::SourceCopy
    $graphics.CompositingQuality = [System.Drawing.Drawing2D.CompositingQuality]::HighQuality
    $graphics.InterpolationMode = [System.Drawing.Drawing2D.InterpolationMode]::HighQualityBicubic
    $graphics.PixelOffsetMode = [System.Drawing.Drawing2D.PixelOffsetMode]::HighQuality
    $attributes.SetWrapMode([System.Drawing.Drawing2D.WrapMode]::TileFlipXY)
    $ratio = [Math]::Max($outputSize[0]/$sourceImage.Width,$outputSize[1]/$sourceImage.Height)
    $drawWidth = [int][Math]::Round($sourceImage.Width*$ratio)
    $drawHeight = [int][Math]::Round($sourceImage.Height*$ratio)
    $rectangle = [System.Drawing.Rectangle]::new([int][Math]::Round(($outputSize[0]-$drawWidth)/2),[int][Math]::Round(($outputSize[1]-$drawHeight)/2),$drawWidth,$drawHeight)
    $graphics.DrawImage($sourceImage,$rectangle,0,0,$sourceImage.Width,$sourceImage.Height,[System.Drawing.GraphicsUnit]::Pixel,$attributes)
    $canvas.Save($destination,[System.Drawing.Imaging.ImageFormat]::Png)
} finally {
    $attributes.Dispose()
    $graphics.Dispose()
    $canvas.Dispose()
    $sourceImage.Dispose()
}
