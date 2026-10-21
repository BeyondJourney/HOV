# ============================================================================
#  make-badges.ps1 - builds the footer accreditation badges
#
#  Sources (badge-source\):
#    iata-logo.svg       vector IATA mark + wordmark (Wikimedia Commons
#                        "IATAlogo.svg"). This is what the pages use, copied
#                        by hand to assets\img\iata-accredited.svg with only
#                        the viewBox and the path kept. Not touched here.
#    iata-logo-150.png   150x150 PNG with a transparent background. Cropped to
#                        its artwork as a raster fallback, never enlarged.
#    otoai-logo-a4.jpg   1754x1241 render of the OTOAI logo PDF, white page.
#                        Cropped to the artwork, the white page is un-blended
#                        to transparency, then down-sampled.
#
#  Outputs (assets\img\):
#    iata-accredited.png   ~140x83, transparent (fallback, unused by pages)
#    otoai-member.png      640 px wide, transparent
#
#  Pure .NET (System.Drawing). Re-run after replacing a source, then run
#  build-deploy.ps1.
# ============================================================================
param(
    [string]$Root = (Split-Path -Parent $PSScriptRoot),
    [int]$OtoaiWidth = 640
)
$ErrorActionPreference = 'Stop'
Add-Type -AssemblyName System.Drawing

$srcDir = Join-Path $PSScriptRoot 'badge-source'
$outDir = Join-Path $Root 'assets\img'
$iataSrc = Join-Path $srcDir 'iata-logo-150.png'
$otoaiSrc = Join-Path $srcDir 'otoai-logo-a4.jpg'
foreach ($p in $iataSrc, $otoaiSrc) { if (-not (Test-Path $p)) { throw "missing source $p" } }

# Pixel work in C# - PowerShell loops over a 2-megapixel page are too slow.
if (-not ('HovBadgeOps' -as [type])) {
Add-Type -ReferencedAssemblies System.Drawing -TypeDefinition @'
using System;
using System.Drawing;
using System.Drawing.Imaging;
using System.Runtime.InteropServices;

public static class HovBadgeOps
{
    static byte[] Read(Bitmap bmp, Rectangle rect, out int stride)
    {
        var d = bmp.LockBits(rect, ImageLockMode.ReadOnly, PixelFormat.Format32bppArgb);
        stride = d.Stride;
        var buf = new byte[stride * rect.Height];
        Marshal.Copy(d.Scan0, buf, 0, buf.Length);
        bmp.UnlockBits(d);
        return buf;
    }

    // Bounding box of the artwork. alphaMode: background = transparent pixels;
    // otherwise background = pixels whose every channel is above whiteFloor.
    public static Rectangle InkBounds(Bitmap bmp, bool alphaMode, int whiteFloor)
    {
        int stride;
        var buf = Read(bmp, new Rectangle(0, 0, bmp.Width, bmp.Height), out stride);
        int minX = bmp.Width, minY = bmp.Height, maxX = -1, maxY = -1;
        for (int y = 0; y < bmp.Height; y++)
        {
            for (int x = 0; x < bmp.Width; x++)
            {
                int i = y * stride + x * 4;
                byte b = buf[i], g = buf[i + 1], r = buf[i + 2], a = buf[i + 3];
                bool bg = alphaMode ? a < 24 : (r > whiteFloor && g > whiteFloor && b > whiteFloor);
                if (bg) continue;
                if (x < minX) minX = x;
                if (x > maxX) maxX = x;
                if (y < minY) minY = y;
                if (y > maxY) maxY = y;
            }
        }
        if (maxX < 0) throw new Exception("no artwork found");
        return new Rectangle(minX, minY, maxX - minX + 1, maxY - minY + 1);
    }

    static int Clamp(int v) { return v < 0 ? 0 : (v > 255 ? 255 : v); }

    // Treat the crop as artwork composited over white and recover colour + alpha:
    // C = a*F + (1-a)*255  =>  a = 255 - min(R,G,B), F = (C - (255-a)) * 255 / a.
    // Composited back over white this reproduces the source exactly.
    public static Bitmap UnblendWhite(Bitmap src, Rectangle crop)
    {
        int sStride;
        var sbuf = Read(src, crop, out sStride);
        var outBmp = new Bitmap(crop.Width, crop.Height, PixelFormat.Format32bppArgb);
        var od = outBmp.LockBits(new Rectangle(0, 0, crop.Width, crop.Height), ImageLockMode.WriteOnly, PixelFormat.Format32bppArgb);
        var obuf = new byte[od.Stride * crop.Height];
        for (int y = 0; y < crop.Height; y++)
        {
            for (int x = 0; x < crop.Width; x++)
            {
                int si = y * sStride + x * 4, oi = y * od.Stride + x * 4;
                int b = sbuf[si], g = sbuf[si + 1], r = sbuf[si + 2];
                int a = 255 - Math.Min(r, Math.Min(g, b));
                if (a < 10) a = 0;            // JPEG noise on the white page
                if (a > 247) a = 255;
                if (a > 0)
                {
                    r = Clamp((r - (255 - a)) * 255 / a);
                    g = Clamp((g - (255 - a)) * 255 / a);
                    b = Clamp((b - (255 - a)) * 255 / a);
                }
                else { r = 0; g = 0; b = 0; }
                obuf[oi] = (byte)b; obuf[oi + 1] = (byte)g; obuf[oi + 2] = (byte)r; obuf[oi + 3] = (byte)a;
            }
        }
        Marshal.Copy(obuf, 0, od.Scan0, obuf.Length);
        outBmp.UnlockBits(od);
        return outBmp;
    }
}
'@
}

function Save-Png([System.Drawing.Bitmap]$bmp, [string]$path) {
    $bmp.Save($path, [System.Drawing.Imaging.ImageFormat]::Png)
    Write-Host ("  wrote {0} ({1}x{2}, {3} KB)" -f (Split-Path $path -Leaf), $bmp.Width, $bmp.Height, [math]::Round((Get-Item $path).Length / 1KB))
}

function Resize-Alpha([System.Drawing.Bitmap]$src, [int]$w, [int]$h) {
    # premultiplied on both sides so the bicubic filter does not darken edges
    $pre = $src.Clone((New-Object System.Drawing.Rectangle 0, 0, $src.Width, $src.Height), [System.Drawing.Imaging.PixelFormat]::Format32bppPArgb)
    $dst = New-Object System.Drawing.Bitmap $w, $h, ([System.Drawing.Imaging.PixelFormat]::Format32bppPArgb)
    $g = [System.Drawing.Graphics]::FromImage($dst)
    $g.InterpolationMode = 'HighQualityBicubic'; $g.PixelOffsetMode = 'HighQuality'
    $g.CompositingQuality = 'HighQuality'; $g.SmoothingMode = 'HighQuality'
    $g.DrawImage($pre, (New-Object System.Drawing.Rectangle 0, 0, $w, $h), (New-Object System.Drawing.Rectangle 0, 0, $pre.Width, $pre.Height), [System.Drawing.GraphicsUnit]::Pixel)
    $g.Dispose(); $pre.Dispose()
    $straight = $dst.Clone((New-Object System.Drawing.Rectangle 0, 0, $w, $h), [System.Drawing.Imaging.PixelFormat]::Format32bppArgb)
    $dst.Dispose()
    return $straight
}

# ---- IATA: transparent PNG, crop to artwork, keep native pixels ------------
Write-Host 'IATA'
$iata = New-Object System.Drawing.Bitmap $iataSrc
$box = [HovBadgeOps]::InkBounds($iata, $true, 0)
Write-Host ("  source {0}x{1}, artwork {2}x{3} at ({4},{5})" -f $iata.Width, $iata.Height, $box.Width, $box.Height, $box.X, $box.Y)
$iataOut = $iata.Clone($box, [System.Drawing.Imaging.PixelFormat]::Format32bppArgb)
Save-Png $iataOut (Join-Path $outDir 'iata-accredited.png')
$iataOut.Dispose(); $iata.Dispose()

# ---- OTOAI: white page JPG -> crop, un-blend, down-sample ------------------
Write-Host 'OTOAI'
$page = New-Object System.Drawing.Bitmap $otoaiSrc
$box = [HovBadgeOps]::InkBounds($page, $false, 236)
$pad = 6
$box = New-Object System.Drawing.Rectangle ([math]::Max(0, $box.X - $pad)), ([math]::Max(0, $box.Y - $pad)), ([math]::Min($page.Width - [math]::Max(0, $box.X - $pad), $box.Width + 2 * $pad)), ([math]::Min($page.Height - [math]::Max(0, $box.Y - $pad), $box.Height + 2 * $pad))
Write-Host ("  page {0}x{1}, artwork {2}x{3} at ({4},{5})" -f $page.Width, $page.Height, $box.Width, $box.Height, $box.X, $box.Y)
$full = [HovBadgeOps]::UnblendWhite($page, $box)
$page.Dispose()
$h = [int][math]::Round($full.Height * $OtoaiWidth / $full.Width)
if ($OtoaiWidth -gt $full.Width) { throw "OtoaiWidth $OtoaiWidth would enlarge the $($full.Width)px source" }
$small = Resize-Alpha $full $OtoaiWidth $h
Save-Png $small (Join-Path $outDir 'otoai-member.png')
$small.Dispose(); $full.Dispose()
