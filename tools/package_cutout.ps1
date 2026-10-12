param(
    [Parameter(Mandatory=$true)][string]$Source,
    [Parameter(Mandatory=$true)][string]$Destination,
    [int]$Size = 128,
    [int]$Extent = 108,
    [int]$BoundAlpha = 16
)
# Windows PowerShell 5.1. Placement/resize only; image_gen supplies art and alpha.
$ErrorActionPreference = 'Stop'
Add-Type -AssemblyName System.Drawing
Add-Type -TypeDefinition @'
using System;
using System.Drawing;
using System.Drawing.Imaging;
using System.Drawing.Drawing2D;
public static class ArtCutoutPack {
 public static string Pack(string source, string target, int size, int extent, int threshold) {
  using(var src=new Bitmap(source)) {
   int x0=src.Width,y0=src.Height,x1=-1,y1=-1,zeros=0;
   for(int y=0;y<src.Height;y++) for(int x=0;x<src.Width;x++) {
    int a=src.GetPixel(x,y).A;
    if(a==0) zeros++;
    if(a>threshold){x0=Math.Min(x0,x);y0=Math.Min(y0,y);x1=Math.Max(x1,x);y1=Math.Max(y1,y);}
   }
   if(zeros==0 || x1<0) throw new Exception("Source needs genuine alpha and visible artwork");
   double scale=(double)extent/Math.Max(x1-x0+1,y1-y0+1);
   float w=(float)(src.Width*scale),h=(float)(src.Height*scale);
   float dx=(float)(size/2.0-((x0+x1+1)/2.0)*scale);
   float dy=(float)(size/2.0-((y0+y1+1)/2.0)*scale);
   using(var dst=new Bitmap(size,size,PixelFormat.Format32bppArgb)) {
    using(var g=Graphics.FromImage(dst)) {
     g.Clear(Color.Transparent);
     g.CompositingMode=CompositingMode.SourceCopy;
     g.CompositingQuality=CompositingQuality.HighQuality;
     g.InterpolationMode=InterpolationMode.HighQualityBicubic;
     g.PixelOffsetMode=PixelOffsetMode.HighQuality;
     g.DrawImage(src,new RectangleF(dx,dy,w,h),new RectangleF(0,0,src.Width,src.Height),GraphicsUnit.Pixel);
    }
    dst.Save(target,ImageFormat.Png);
   }
   return target+" : "+size+"x"+size+" RGBA; content extent "+extent+"; source transparent pixels "+zeros;
  }
 }
}
'@ -ReferencedAssemblies System.Drawing
[IO.Directory]::CreateDirectory([IO.Path]::GetDirectoryName([IO.Path]::GetFullPath($Destination))) | Out-Null
[ArtCutoutPack]::Pack([IO.Path]::GetFullPath($Source),[IO.Path]::GetFullPath($Destination),$Size,$Extent,$BoundAlpha)
