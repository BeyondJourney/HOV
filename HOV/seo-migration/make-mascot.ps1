# ============================================================================
#  make-mascot.ps1 - prepares the HOV Global Travel mascot for the preloader
#
#  Source: mascot-source\hov-global-travel-mascot.png (1536x1024, transparent)
#  Output (assets\img\mascot\):
#    hov-mascot.png        1200 px wide PNG with alpha  (fallback <img src>)
#    hov-mascot.webp       same pixels as WebP          (<source> 1200w)
#    hov-mascot-900.webp   900 px wide WebP             (<source> 900w, 2x phones)
#    hov-mascot-640.webp   640 px wide WebP             (<source> 640w)
#
#  The artwork is trimmed to its bounding box (+ margin), resampled in
#  premultiplied alpha so edges do not darken, never enlarged. WebP is
#  encoded by headless Edge through a canvas, since nothing else on this
#  machine writes WebP. Re-run after replacing the source, then run
#  one-off\add-preloader.ps1 -Refresh and build-deploy.ps1.
# ============================================================================
param(
    [string]$Root = (Split-Path -Parent $PSScriptRoot),
    [int]$Width = 1200,
    [int]$MidWidth = 900,
    [int]$SmallWidth = 640,
    [double]$WebpQuality = 0.86,
    [string]$Edge = 'C:\Program Files (x86)\Microsoft\Edge\Application\msedge.exe'
)
$ErrorActionPreference = 'Stop'
Add-Type -AssemblyName System.Drawing

$src = Join-Path $PSScriptRoot 'mascot-source\hov-global-travel-mascot.png'
$outDir = Join-Path $Root 'assets\img\mascot'
if (-not (Test-Path $src)) { throw "missing source $src" }
New-Item -ItemType Directory -Force $outDir | Out-Null

if (-not ('HovMascotOps' -as [type])) {
Add-Type -ReferencedAssemblies System.Drawing -TypeDefinition @'
using System;
using System.Drawing;
using System.Drawing.Imaging;
using System.Runtime.InteropServices;
public static class HovMascotOps
{
    public static Rectangle AlphaBounds(Bitmap bmp, int threshold)
    {
        var rect = new Rectangle(0, 0, bmp.Width, bmp.Height);
        var d = bmp.LockBits(rect, ImageLockMode.ReadOnly, PixelFormat.Format32bppArgb);
        var buf = new byte[d.Stride * bmp.Height];
        Marshal.Copy(d.Scan0, buf, 0, buf.Length);
        bmp.UnlockBits(d);
        int minX = bmp.Width, minY = bmp.Height, maxX = -1, maxY = -1;
        for (int y = 0; y < bmp.Height; y++)
            for (int x = 0; x < bmp.Width; x++)
                if (buf[y * d.Stride + x * 4 + 3] >= threshold)
                {
                    if (x < minX) minX = x; if (x > maxX) maxX = x;
                    if (y < minY) minY = y; if (y > maxY) maxY = y;
                }
        if (maxX < 0) throw new Exception("no opaque pixels");
        return new Rectangle(minX, minY, maxX - minX + 1, maxY - minY + 1);
    }
    // mean colour of strongly orange pixels in a region (for the brand token)
    public static string OrangeSample(Bitmap bmp, Rectangle region)
    {
        var d = bmp.LockBits(region, ImageLockMode.ReadOnly, PixelFormat.Format32bppArgb);
        var buf = new byte[d.Stride * region.Height];
        Marshal.Copy(d.Scan0, buf, 0, buf.Length);
        bmp.UnlockBits(d);
        long r = 0, g = 0, b = 0, n = 0;
        for (int y = 0; y < region.Height; y++)
            for (int x = 0; x < region.Width; x++)
            {
                int i = y * d.Stride + x * 4;
                int bb = buf[i], gg = buf[i + 1], rr = buf[i + 2], a = buf[i + 3];
                if (a < 200) continue;
                if (rr > 180 && gg > 70 && gg < 170 && bb < 90 && rr - bb > 120) { r += rr; g += gg; b += bb; n++; }
            }
        if (n == 0) return "none";
        return String.Format("#{0:X2}{1:X2}{2:X2} ({3} px)", r / n, g / n, b / n, n);
    }
}
'@
}

function Resize-Alpha([System.Drawing.Bitmap]$srcBmp, [System.Drawing.Rectangle]$crop, [int]$w) {
    $h = [int][math]::Round($crop.Height * $w / $crop.Width)
    if ($w -gt $crop.Width) { throw "would enlarge: $w > $($crop.Width)" }
    $pre = $srcBmp.Clone($crop, [System.Drawing.Imaging.PixelFormat]::Format32bppPArgb)
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

function Save-Png([System.Drawing.Bitmap]$bmp, [string]$path) {
    $bmp.Save($path, [System.Drawing.Imaging.ImageFormat]::Png)
    Write-Host ("  wrote {0} ({1}x{2}, {3} KB)" -f (Split-Path $path -Leaf), $bmp.Width, $bmp.Height, [math]::Round((Get-Item $path).Length / 1KB))
}

# WebP through headless Edge: a tiny page draws the PNG on a canvas and
# prints canvas.toDataURL('image/webp') into the DOM, which --dump-dom returns.
function Convert-ToWebp([string]$pngPath, [string]$webpPath, [double]$q) {
    $tmpDir = Join-Path $env:TEMP ('hov-webp-' + [guid]::NewGuid().ToString('N'))
    New-Item -ItemType Directory -Force $tmpDir | Out-Null
    $pngUrl = 'file:///' + ($pngPath -replace '\\', '/')
    $html = @"
<!doctype html><meta charset="utf-8"><body><pre id="out"></pre><script>
var img = new Image();
img.onload = function () {
  var c = document.createElement('canvas'); c.width = img.naturalWidth; c.height = img.naturalHeight;
  var ctx = c.getContext('2d'); ctx.drawImage(img, 0, 0);
  document.getElementById('out').textContent = c.toDataURL('image/webp', $q);
  document.title = 'WEBP-DONE';
};
img.onerror = function () { document.getElementById('out').textContent = 'ERROR'; };
img.src = '$pngUrl';
</script></body>
"@
    $page = Join-Path $tmpDir 'webp.html'
    [IO.File]::WriteAllText($page, $html, (New-Object Text.UTF8Encoding $false))
    $outTxt = Join-Path $tmpDir 'dom.txt'
    $edgeArgs = @('--headless=new', '--disable-gpu', '--no-first-run', '--allow-file-access-from-files',
                  '--virtual-time-budget=8000', "--user-data-dir=`"$tmpDir\profile`"", '--dump-dom',
                  "`"file:///$($page -replace '\\', '/')`"")
    Start-Process -FilePath $Edge -ArgumentList $edgeArgs -Wait -WindowStyle Hidden -RedirectStandardOutput $outTxt
    $dom = [IO.File]::ReadAllText($outTxt)
    $m = [regex]::Match($dom, 'data:image/webp;base64,([A-Za-z0-9+/=]+)')
    if (-not $m.Success) { throw "Edge did not return a WebP for $pngPath" }
    [IO.File]::WriteAllBytes($webpPath, [Convert]::FromBase64String($m.Groups[1].Value))
    Remove-Item $tmpDir -Recurse -Force -ErrorAction SilentlyContinue
    Write-Host ("  wrote {0} ({1} KB)" -f (Split-Path $webpPath -Leaf), [math]::Round((Get-Item $webpPath).Length / 1KB))
}

Write-Host "source $src"
$bmp = New-Object System.Drawing.Bitmap $src
$box = [HovMascotOps]::AlphaBounds($bmp, 12)
$pad = 10
$crop = New-Object System.Drawing.Rectangle ([math]::Max(0, $box.X - $pad)), ([math]::Max(0, $box.Y - $pad)), ([math]::Min($bmp.Width - [math]::Max(0, $box.X - $pad), $box.Width + 2 * $pad)), ([math]::Min($bmp.Height - [math]::Max(0, $box.Y - $pad), $box.Height + 2 * $pad))
Write-Host ("  {0}x{1}, artwork {2}x{3} at ({4},{5}), crop {6}x{7}" -f $bmp.Width, $bmp.Height, $box.Width, $box.Height, $box.X, $box.Y, $crop.Width, $crop.Height)
Write-Host ("  suitcase orange sample: " + [HovMascotOps]::OrangeSample($bmp, (New-Object System.Drawing.Rectangle 380, 650, 260, 280)))

$big = Resize-Alpha $bmp $crop $Width
$pngBig = Join-Path $outDir 'hov-mascot.png'
Save-Png $big $pngBig
Convert-ToWebp $pngBig (Join-Path $outDir 'hov-mascot.webp') $WebpQuality

foreach ($w in @($MidWidth, $SmallWidth)) {
    $small = Resize-Alpha $bmp $crop $w
    $pngSmall = Join-Path $env:TEMP "hov-mascot-$w-tmp.png"
    $small.Save($pngSmall, [System.Drawing.Imaging.ImageFormat]::Png)
    Convert-ToWebp $pngSmall (Join-Path $outDir "hov-mascot-$w.webp") $WebpQuality
    Remove-Item $pngSmall -Force -ErrorAction SilentlyContinue
    $small.Dispose()
}

"dimensions: {0}x{1} (use width/height on the <img>)" -f $big.Width, $big.Height
$big.Dispose(); $bmp.Dispose()
