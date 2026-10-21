# ============================================================================
#  make-favicons.ps1 - rebuilds the HOV favicon set
#
#  Source  : assets\img\favicons\source\hov-wordmark-512.png (the HOV wordmark)
#  Mark    : the compass symbol is isolated from it (circle around the green
#            centre dot plus the red pointer), un-blended from the white
#            background and recoloured white for the brand-navy tile
#  Output  : assets\img\favicons\  (16/32/48 PNG + favicon.ico, 96, 192, 512,
#            maskable 512, apple-touch-icon 180, mstile 150)
#
#  Pure .NET (System.Drawing); no external tools. Run, then build-deploy.ps1.
#  Usage:  .\make-favicons.ps1 [-Root <HOV folder>] [-Scratch <folder for the review sheet>]
# ============================================================================
#
#   source : the 512px wordmark PNG that shipped as android-chrome-512x512.png
#   mark   : compass ring + ticks + red pointer + green centre, isolated by a
#            circular mask around the centre dot (plus every red pixel, so the
#            pointer tip is kept), navy recoloured to white
#   tiles  : brand navy (#0A2342) rounded square, mark centred
#
# Outputs go to HOV\assets\img\favicons\ (old files are removed first) and a
# review sheet to the scratchpad.
param(
    [string]$Root = (Split-Path -Parent $PSScriptRoot),
    [string]$Scratch = (Join-Path $env:TEMP 'hov-favicons')
)
$ErrorActionPreference = 'Stop'
Add-Type -AssemblyName System.Drawing

$favDir = Join-Path $Root 'assets\img\favicons'
$srcDir = Join-Path $favDir 'source'
New-Item -ItemType Directory -Force $srcDir, $Scratch | Out-Null

# ---- 1. keep the original wordmark as the regeneration source ------------
$wordmarkSrc = Join-Path $favDir 'android-chrome-512x512.png'
$wordmarkKeep = Join-Path $srcDir 'hov-wordmark-512.png'
if (-not (Test-Path $wordmarkKeep)) { Copy-Item $wordmarkSrc $wordmarkKeep }
$wm = [System.Drawing.Bitmap]::FromFile($wordmarkKeep)

# ---- 2. locate the compass: centre from the green dot, radius from the ticks
$gx = 0; $gy = 0; $gn = 0
for ($y = 150; $y -lt 340; $y++) {
    for ($x = 180; $x -lt 340; $x++) {
        $c = $wm.GetPixel($x, $y)
        if ($c.A -gt 200 -and $c.G -gt 140 -and $c.R -lt 110 -and $c.B -lt 140) { $gx += $x; $gy += $y; $gn++ }
    }
}
if ($gn -eq 0) { throw 'green centre dot not found' }
$cx = [math]::Round($gx / $gn); $cy = [math]::Round($gy / $gn)

function Test-Navy($c) { return ($c.A -gt 60 -and $c.B -ge $c.R -and ($c.R + $c.G + $c.B) -lt 330) }
function Test-Red($c)  { return ($c.A -gt 60 -and $c.R -gt 150 -and $c.G -lt 110 -and $c.B -lt 110) }

# The source PNG has an OPAQUE WHITE background and the ring has gaps at the
# four cardinal points, so the radius is taken from every dark pixel in the
# compass band, excluding the H (x < 186), the V (a diagonal from (303,194)
# running down-right) and the "MICE & MORE" line (y > 296).
function Test-V([int]$x, [int]$y) { return ($x -ge (301 + 0.58 * ($y - 194))) }
$R = 0
for ($y = 186; $y -le 296; $y++) {
    for ($x = 186; $x -le 331; $x++) {
        if (Test-V $x $y) { continue }
        $c = $wm.GetPixel($x, $y)
        if (($c.R + $c.G + $c.B) -lt 300 -and -not (Test-Red $c)) {
            $d = [math]::Sqrt(($x - $cx) * ($x - $cx) + ($y - $cy) * ($y - $cy))
            if ($d -gt $R) { $R = $d }
        }
    }
}
$R = [math]::Ceiling($R) + 2
Write-Host ("compass centre ({0},{1})  mask R={2}" -f $cx, $cy, $R)

# ---- 3. isolate + recolour the mark -------------------------------------
# Every pixel is "un-blended" from the white background (alpha = how far it
# is from white), then anything unsaturated (navy, grey, anti-aliasing) is
# turned white so the mark reads on the navy tile; red and green keep their
# colour. Only the circle around the centre plus the red pointer survive.
$pad = 16
$bw = 2 * $R + 2 * $pad; $bh = 2 * $R + 2 * $pad
$mark = New-Object System.Drawing.Bitmap $bw, $bh, ([System.Drawing.Imaging.PixelFormat]::Format32bppArgb)
$ox = $cx - $R - $pad; $oy = $cy - $R - $pad
$padL = $pad
for ($y = 0; $y -lt $bh; $y++) {
    for ($x = 0; $x -lt $bw; $x++) {
        $sx = $ox + $x; $sy = $oy + $y
        if ($sx -lt 0 -or $sy -lt 0 -or $sx -ge $wm.Width -or $sy -ge $wm.Height) { continue }
        if (Test-V $sx $sy -or $sy -gt 298) { continue }
        $c = $wm.GetPixel($sx, $sy)
        $mn = [math]::Min($c.R, [math]::Min($c.G, $c.B)); $mx = [math]::Max($c.R, [math]::Max($c.G, $c.B))
        $alpha = 255 - $mn
        if ($alpha -lt 10) { continue }
        $dx = $sx - $cx; $dy = $sy - $cy
        $inCircle = ($dx * $dx + $dy * $dy) -le ($R * $R)
        $isRed = Test-Red $c
        if (-not $inCircle -and -not ($isRed -and $dx -lt 6 -and $dy -gt -6)) { continue }
        # un-blend from white
        $ur = [math]::Max(0, [math]::Round(255 - (255 - $c.R) * 255 / $alpha))
        $ug = [math]::Max(0, [math]::Round(255 - (255 - $c.G) * 255 / $alpha))
        $ub = [math]::Max(0, [math]::Round(255 - (255 - $c.B) * 255 / $alpha))
        $sat = $mx - $mn
        if ($sat -lt 40 -or ($ub -ge $ur -and $ug -lt 120 -and $ur -lt 90)) {
            $out = [System.Drawing.Color]::FromArgb($alpha, 255, 255, 255)        # navy / grey -> white
        } else {
            $out = [System.Drawing.Color]::FromArgb($alpha, [int][math]::Min(255, $ur), [int][math]::Min(255, $ug), [int][math]::Min(255, $ub))
        }
        $mark.SetPixel($x, $y, $out)
    }
}
$mark.Save((Join-Path $srcDir 'hov-compass-mark-white.png'), [System.Drawing.Imaging.ImageFormat]::Png)
Write-Host ("mark box {0}x{1}" -f $bw, $bh)
# ---- 4. tile renderer -----------------------------------------------------
$navy = [System.Drawing.Color]::FromArgb(255, 10, 35, 66)

function New-Tile([int]$size, [double]$fill, [double]$radiusPct, [bool]$opaqueSquare) {
    $bmp = New-Object System.Drawing.Bitmap $size, $size, ([System.Drawing.Imaging.PixelFormat]::Format32bppArgb)
    $g = [System.Drawing.Graphics]::FromImage($bmp)
    $g.SmoothingMode = 'AntiAlias'; $g.InterpolationMode = 'HighQualityBicubic'
    $g.PixelOffsetMode = 'HighQuality'; $g.CompositingQuality = 'HighQuality'
    $g.Clear([System.Drawing.Color]::Transparent)
    $brush = New-Object System.Drawing.SolidBrush $navy
    if ($opaqueSquare -or $radiusPct -le 0) {
        $g.FillRectangle($brush, 0, 0, $size, $size)
    } else {
        # NB: PowerShell variable names are case-insensitive, so this must not
        # be called $r - that would overwrite the compass radius $R.
        $cornerR = [math]::Max(2, [math]::Round($size * $radiusPct))
        $path = New-Object System.Drawing.Drawing2D.GraphicsPath
        $d = $cornerR * 2
        $path.AddArc(0, 0, $d, $d, 180, 90)
        $path.AddArc($size - $d, 0, $d, $d, 270, 90)
        $path.AddArc($size - $d, $size - $d, $d, $d, 0, 90)
        $path.AddArc(0, $size - $d, $d, $d, 90, 90)
        $path.CloseFigure()
        $g.FillPath($brush, $path)
    }
    # mark: scale the box so the ring (2R) spans `fill` of the tile
    $scale = ($size * $fill) / (2 * $R)
    $mw = $script:mark.Width * $scale; $mh = $script:mark.Height * $scale
    # centre the ring (not the box): ring centre sits at (R+padL, R) in the box
    $ringCx = ($R + $padL) * $scale; $ringCy = ($R + $padL) * $scale
    $left = ($size / 2) - $ringCx; $top = ($size / 2) - $ringCy
    $g.DrawImage($script:mark, (New-Object System.Drawing.RectangleF $left, $top, $mw, $mh))
    $g.Dispose(); $brush.Dispose()
    return $bmp
}

function Save-Png($bmp, $name) {
    $p = Join-Path $favDir $name
    $bmp.Save($p, [System.Drawing.Imaging.ImageFormat]::Png)
    Write-Host ("  wrote {0} ({1}x{1}, {2} B)" -f $name, $bmp.Width, (Get-Item $p).Length)
}

# ---- 5. clear the old set -----------------------------------------------
Get-ChildItem $favDir -File | Where-Object { $_.Extension -in '.png', '.ico' } | Remove-Item -Force
Write-Host 'old PNG/ICO files removed'

# ---- 6. render ----------------------------------------------------------
# Small sizes render from a 4x intermediate: GDI+ downsamples a large bitmap
# in one step more smoothly than drawing the mark straight into 16px.
function New-SmallTile([int]$size, [double]$fill, [double]$radiusPct) {
    $big = New-Tile ($size * 4) $fill $radiusPct $false
    $bmp = New-Object System.Drawing.Bitmap $size, $size, ([System.Drawing.Imaging.PixelFormat]::Format32bppArgb)
    $g = [System.Drawing.Graphics]::FromImage($bmp)
    $g.InterpolationMode = 'HighQualityBicubic'; $g.PixelOffsetMode = 'HighQuality'; $g.CompositingQuality = 'HighQuality'
    # explicit (dest, src, unit) overload: the RectangleF form drew the 4x bitmap unscaled
    $dest = New-Object System.Drawing.Rectangle 0, 0, $size, $size
    $srcR = New-Object System.Drawing.Rectangle 0, 0, $big.Width, $big.Height
    $g.DrawImage($big, $dest, $srcR, [System.Drawing.GraphicsUnit]::Pixel)
    $g.Dispose(); $big.Dispose()
    return $bmp
}

$t16 = New-SmallTile 16 0.80 0.20
$t32 = New-SmallTile 32 0.78 0.20
$t48 = New-SmallTile 48 0.76 0.20
$t96 = New-Tile 96 0.72 0.21 $false
$t192 = New-Tile 192 0.70 0.21 $false
$t512 = New-Tile 512 0.70 0.21 $false
$apple = New-Tile 180 0.70 0 $true          # iOS applies its own mask
$mask512 = New-Tile 512 0.58 0 $true        # maskable: mark inside the 80% safe zone
$tile150 = New-Tile 150 0.68 0 $true        # Windows tile

Save-Png $t16 'favicon-16x16.png'
Save-Png $t32 'favicon-32x32.png'
Save-Png $t48 'favicon-48x48.png'
Save-Png $t96 'favicon-96x96.png'
Save-Png $t192 'android-chrome-192x192.png'
Save-Png $t512 'android-chrome-512x512.png'
Save-Png $mask512 'maskable-icon-512x512.png'
Save-Png $apple 'apple-touch-icon.png'
Save-Png $tile150 'mstile-150x150.png'

# ---- 7. favicon.ico (PNG-compressed entries: 16, 32, 48) -----------------
function Get-PngBytes($bmp) { $ms = New-Object IO.MemoryStream; $bmp.Save($ms, [System.Drawing.Imaging.ImageFormat]::Png); [byte[]]$b = $ms.ToArray(); $ms.Dispose(); return ,$b }
$entries = @(@{ s = 16; b = (Get-PngBytes $t16) }, @{ s = 32; b = (Get-PngBytes $t32) }, @{ s = 48; b = (Get-PngBytes $t48) })
$ico = New-Object IO.MemoryStream
$bw2 = New-Object IO.BinaryWriter $ico
$bw2.Write([uint16]0); $bw2.Write([uint16]1); $bw2.Write([uint16]$entries.Count)
$offset = 6 + 16 * $entries.Count
foreach ($e in $entries) {
    $bw2.Write([byte]$e.s); $bw2.Write([byte]$e.s)      # width, height
    $bw2.Write([byte]0); $bw2.Write([byte]0)            # palette, reserved
    $bw2.Write([uint16]1); $bw2.Write([uint16]32)       # planes, bpp
    $bw2.Write([uint32]$e.b.Length); $bw2.Write([uint32]$offset)
    $offset += $e.b.Length
}
foreach ($e in $entries) { [byte[]]$bytes = $e.b; $bw2.Write($bytes, 0, $bytes.Length) }
$bw2.Flush()
[IO.File]::WriteAllBytes((Join-Path $favDir 'favicon.ico'), $ico.ToArray())
Write-Host ("  wrote favicon.ico ({0} B, 16/32/48)" -f (Get-Item (Join-Path $favDir 'favicon.ico')).Length)
$bw2.Dispose(); $ico.Dispose()

# ---- 8. review sheet: real size and 8x, on light and dark ----------------
$sheet = New-Object System.Drawing.Bitmap 760, 420
$g = [System.Drawing.Graphics]::FromImage($sheet)
$g.InterpolationMode = 'NearestNeighbor'; $g.PixelOffsetMode = 'Half'
$g.FillRectangle([System.Drawing.Brushes]::White, 0, 0, 760, 210)
$g.FillRectangle((New-Object System.Drawing.SolidBrush ([System.Drawing.Color]::FromArgb(255, 32, 33, 36))), 0, 210, 760, 210)
foreach ($row in 0, 1) {
    $y0 = 20 + $row * 210
    $g.DrawImage($t16, (New-Object System.Drawing.Rectangle 20, $y0, 16, 16))
    $g.DrawImage($t32, (New-Object System.Drawing.Rectangle 50, $y0, 32, 32))
    $g.DrawImage($t48, (New-Object System.Drawing.Rectangle 100, $y0, 48, 48))
    $g.DrawImage($t16, (New-Object System.Drawing.Rectangle 170, $y0, 128, 128))
    $g.DrawImage($t32, (New-Object System.Drawing.Rectangle 320, $y0, 128, 128))
    $g.DrawImage($apple, (New-Object System.Drawing.Rectangle 470, $y0, 128, 128))
    $g.DrawImage($t512, (New-Object System.Drawing.Rectangle 620, $y0, 128, 128))
}
$g.Dispose()
$sheet.Save((Join-Path $Scratch 'favicon-review.png'), [System.Drawing.Imaging.ImageFormat]::Png)
Write-Host "review sheet: $Scratch\favicon-review.png"
foreach ($b in $t16, $t32, $t48, $t96, $t192, $t512, $apple, $mask512, $tile150, $mark, $wm, $sheet) { $b.Dispose() }
