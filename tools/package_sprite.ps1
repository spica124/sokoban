param(
    [Parameter(Mandatory=$true)][string]$Source,
    [Parameter(Mandatory=$true)][string]$Destination,
    [int]$Extent = 215
)
# Run with C:/Windows/System32/WindowsPowerShell/v1.0/powershell.exe.
# Size/placement only; all sprite artwork and alpha are from image_gen.
$ErrorActionPreference = 'Stop'
Add-Type -AssemblyName System.Drawing
Add-Type -TypeDefinition @'
using System;
using System.Drawing;
using System.Drawing.Imaging;
using System.Drawing.Drawing2D;
public static class SingleSpritePack {
 public static string Pack(string source, string target, int extent) {
  if(extent<1 || extent>256) throw new ArgumentOutOfRangeException("extent");
  using(var src=new Bitmap(source)) {
   int x0=src.Width,y0=src.Height,x1=-1,y1=-1,zeros=0;
   for(int y=0;y<src.Height;y++) for(int x=0;x<src.Width;x++) {
    int a=src.GetPixel(x,y).A;
    if(a==0) zeros++;
    if(a>16){x0=Math.Min(x0,x);y0=Math.Min(y0,y);x1=Math.Max(x1,x);y1=Math.Max(y1,y);}
   }
   if(zeros==0 || x1<0) throw new Exception("Source must have real alpha and visible artwork");
   int bw=x1-x0+1,bh=y1-y0+1;
   double scale=(double)extent/Math.Max(bw,bh);
   int dw=(int)Math.Round(bw*scale),dh=(int)Math.Round(bh*scale);
   using(var dst=new Bitmap(256,256,PixelFormat.Format32bppArgb)) {
    using(var g=Graphics.FromImage(dst)) {
     g.Clear(Color.Transparent);
     g.CompositingMode=CompositingMode.SourceCopy;
     g.CompositingQuality=CompositingQuality.HighQuality;
     g.InterpolationMode=InterpolationMode.HighQualityBicubic;
     g.PixelOffsetMode=PixelOffsetMode.HighQuality;
     g.DrawImage(src,new Rectangle((256-dw)/2,(256-dh)/2,dw,dh),new Rectangle(x0,y0,bw,bh),GraphicsUnit.Pixel);
    }
    dst.Save(target,ImageFormat.Png);
   }
   return target+" : 256x256 RGBA; content "+dw+"x"+dh+"; source transparent pixels "+zeros;
  }
 }
}
'@ -ReferencedAssemblies System.Drawing
[SingleSpritePack]::Pack([IO.Path]::GetFullPath($Source),[IO.Path]::GetFullPath($Destination),$Extent)
