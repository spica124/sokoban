param(
    [Parameter(Mandatory)][string]$Source,
    [Parameter(Mandatory)][ValidateSet('logo','main','header','small','vertical','hero','library_logo','icon')][string]$Asset
)
$ErrorActionPreference = 'Stop'
Add-Type -AssemblyName System.Drawing
$specifications = @{
    logo=@(1040,400,'assets/sprites/logo.png',$false)
    main=@(616,353,'assets/store/capsule_main.png',$true)
    header=@(460,215,'assets/store/capsule_header.png',$true)
    small=@(231,87,'assets/store/capsule_small.png',$true)
    vertical=@(374,448,'assets/store/capsule_vertical.png',$true)
    hero=@(3840,1240,'assets/store/library_hero.png',$true)
    library_logo=@(1280,720,'assets/store/library_logo.png',$false)
    icon=@(512,512,'assets/store/icon.png',$true)
}
$specification=$specifications[$Asset]
$width=[int]$specification[0]
$height=[int]$specification[1]
$destination=Join-Path 'C:/Users/limji/Desktop/game/sokoban' $specification[2]
$cover=[bool]$specification[3]
$sourceImage=[System.Drawing.Bitmap]::FromFile($Source)
$canvas=[System.Drawing.Bitmap]::new($width,$height,[System.Drawing.Imaging.PixelFormat]::Format32bppArgb)
$graphics=[System.Drawing.Graphics]::FromImage($canvas)
$attributes=[System.Drawing.Imaging.ImageAttributes]::new()
try {
    $graphics.Clear([System.Drawing.Color]::Transparent)
    $graphics.CompositingMode=[System.Drawing.Drawing2D.CompositingMode]::SourceCopy
    $graphics.CompositingQuality=[System.Drawing.Drawing2D.CompositingQuality]::HighQuality
    $graphics.InterpolationMode=[System.Drawing.Drawing2D.InterpolationMode]::HighQualityBicubic
    $graphics.PixelOffsetMode=[System.Drawing.Drawing2D.PixelOffsetMode]::HighQuality
    $attributes.SetWrapMode([System.Drawing.Drawing2D.WrapMode]::TileFlipXY)
    $ratio=if($cover){[Math]::Max($width/$sourceImage.Width,$height/$sourceImage.Height)}else{[Math]::Min($width/$sourceImage.Width,$height/$sourceImage.Height)}
    $drawWidth=[int][Math]::Round($sourceImage.Width*$ratio)
    $drawHeight=[int][Math]::Round($sourceImage.Height*$ratio)
    $verticalAnchor=if($Asset -eq 'hero'){0.75}else{0.5}
    $rectangle=[System.Drawing.Rectangle]::new([int][Math]::Round(($width-$drawWidth)/2),[int][Math]::Round(($height-$drawHeight)*$verticalAnchor),$drawWidth,$drawHeight)
    $graphics.DrawImage($sourceImage,$rectangle,0,0,$sourceImage.Width,$sourceImage.Height,[System.Drawing.GraphicsUnit]::Pixel,$attributes)
    $canvas.Save($destination,[System.Drawing.Imaging.ImageFormat]::Png)
} finally {
    $attributes.Dispose()
    $graphics.Dispose()
    $canvas.Dispose()
    $sourceImage.Dispose()
}
