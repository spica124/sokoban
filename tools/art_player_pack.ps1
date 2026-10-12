param([switch]$DirectionsOnly, [switch]$SideDirectionsOnly)
# Run with Windows PowerShell 5.1 (powershell.exe).
$ErrorActionPreference='Stop'
Add-Type -AssemblyName System.Drawing
Add-Type -TypeDefinition @'
using System;
using System.Drawing;
using System.Drawing.Imaging;
using System.Drawing.Drawing2D;
public static class ArtPlayerPack {
    public static string Pack(string source, string target) {
        using (var src = new Bitmap(source)) {
            int minX=src.Width, minY=src.Height, maxX=-1, maxY=-1, transparent=0;
            for(int y=0;y<src.Height;y++) for(int x=0;x<src.Width;x++) {
                int a=src.GetPixel(x,y).A;
                if(a==0) transparent++;
                if(a>16) { minX=Math.Min(minX,x); minY=Math.Min(minY,y); maxX=Math.Max(maxX,x); maxY=Math.Max(maxY,y); }
            }
            if(transparent==0 || maxX<0) throw new Exception("Source has no real transparency: "+source);
            int bw=maxX-minX+1, bh=maxY-minY+1;
            double scale=215.0/Math.Max(bw,bh);
            int dw=(int)Math.Round(bw*scale), dh=(int)Math.Round(bh*scale);
            using(var dst=new Bitmap(256,256,PixelFormat.Format32bppArgb)) {
                using(var g=Graphics.FromImage(dst)) {
                    g.Clear(Color.Transparent);
                    g.CompositingMode=CompositingMode.SourceCopy;
                    g.CompositingQuality=CompositingQuality.HighQuality;
                    g.InterpolationMode=InterpolationMode.HighQualityBicubic;
                    g.PixelOffsetMode=PixelOffsetMode.HighQuality;
                    g.DrawImage(src,new Rectangle((256-dw)/2,(256-dh)/2,dw,dh),new Rectangle(minX,minY,bw,bh),GraphicsUnit.Pixel);
                }
                dst.Save(target,ImageFormat.Png);
            }
            return target+" source="+src.Width+"x"+src.Height+" bounds="+minX+","+minY+","+bw+","+bh+" rendered="+dw+"x"+dh;
        }
    }
    public static string Stats(string file) {
        using(var b=new Bitmap(file)) {
            int zeros=0,partial=0,opaque=0,minX=b.Width,minY=b.Height,maxX=-1,maxY=-1;
            for(int y=0;y<b.Height;y++) for(int x=0;x<b.Width;x++) {
                int a=b.GetPixel(x,y).A;
                if(a==0) zeros++; else {
                    if(a==255) opaque++; else partial++;
                    minX=Math.Min(minX,x);minY=Math.Min(minY,y);maxX=Math.Max(maxX,x);maxY=Math.Max(maxY,y);
                }
            }
            return System.IO.Path.GetFileName(file)+" "+b.Width+"x"+b.Height+" alpha0="+zeros+" partial="+partial+" opaque="+opaque+" bounds="+minX+","+minY+","+maxX+","+maxY;
        }
    }
}
'@ -ReferencedAssemblies System.Drawing
$assetDirectory='C:/Users/limji/Desktop/game/sokoban/assets/sprites'
New-Item -ItemType Directory -Path $assetDirectory -Force | Out-Null
$mapping=@(
@('C:/Users/limji/.codex/generated_images/01a07602-6a2b-7190-9f6e-7ba4f7d567df/exec-b4cbeee9-e1a2-4630-ae4e-20bb50f97dff.png','player.png'),
@('C:/Users/limji/.codex/generated_images/01a07602-6a2b-7190-9f6e-7ba4f7d567df/exec-6b876b1f-3efc-4d68-9797-7e70c1596e64.png','player_up.png'),
@('C:/Users/limji/.codex/generated_images/01a07604-cff7-7cc3-8473-bed4e566f13c/exec-f40aa625-62a8-44e0-927b-05b29b101f8a.png','player_left.png'),
@('C:/Users/limji/.codex/generated_images/01a07604-cff7-7cc3-8473-bed4e566f13c/exec-4e80287e-a83b-441d-9980-ffb7153b3c8f.png','player_right.png')
)
foreach($item in $mapping) {
    if($SideDirectionsOnly -and $item[1] -notin @('player_left.png','player_right.png')) { continue }
    if($DirectionsOnly -and $item[1] -eq 'player.png') { continue }
    [ArtPlayerPack]::Pack($item[0],(Join-Path $assetDirectory $item[1]))
}
if(-not $DirectionsOnly -and -not $SideDirectionsOnly) { Copy-Item -LiteralPath (Join-Path $assetDirectory 'player.png') -Destination (Join-Path $assetDirectory 'player_down.png') }
foreach($file in @('player.png','player_down.png','player_up.png','player_left.png','player_right.png')) {
    [ArtPlayerPack]::Stats((Join-Path $assetDirectory $file))
}
