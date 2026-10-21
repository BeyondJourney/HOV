# ============================================================================
#  make-collage.ps1 - builds the "pan-India MICE" collage for the home page
#
#  Five real programme photographs (collage-source\) are laid out on a 3:4
#  canvas with a thin white gutter, every photo DOWN-sampled from its original,
#  never enlarged. Written as JPEG at two widths for a srcset:
#
#    assets\img\hov-pan-india-collage-1600.jpg   1600 x 2120  (2x / retina)
#    assets\img\hov-pan-india-collage-800.jpg     800 x 1060  (1x)
#
#  Layout (1600 wide):
#    +---------------------------------------------+
#    |  A  Merdeka Square group, Kuala Lumpur  (16:9, full width, uncropped)
#    +------------------------------+--------------+
#    |  B  Sunway Putra Hotel group |  D  Dubai    |
#    |     (16:9, uncropped)        |     lobby    |
#    +------------------------------+--------------+
#    |  C  Group at themed venue    |  E  Hoi An   |
#    |     (16:9, uncropped)        |     boat     |
#    +------------------------------+--------------+
#
#  Pure .NET (System.Drawing). Re-run after replacing a source photo, then
#  run build-deploy.ps1.
# ============================================================================
param(
    [string]$Root = (Split-Path -Parent $PSScriptRoot),
    [int]$Quality = 90
)
$ErrorActionPreference = 'Stop'
Add-Type -AssemblyName System.Drawing

$srcDir = Join-Path $PSScriptRoot 'collage-source'
$outDir = Join-Path $Root 'assets\img'
$photos = @{
    A = Join-Path $srcDir 'kuala-lumpur-merdeka-square-group.jpg'
    B = Join-Path $srcDir 'sunway-putra-hotel-group.jpg'
    C = Join-Path $srcDir 'group-themed-venue.jpg'
    D = Join-Path $srcDir 'dubai-hotel-lobby-group.jpg'
    E = Join-Path $srcDir 'hoi-an-basket-boat.jpg'
}
foreach ($k in $photos.Keys) { if (-not (Test-Path $photos[$k])) { throw "missing source photo $k : $($photos[$k])" } }

$W = 1600; $gap = 16
$leftW = 1056; $rightW = $W - $leftW - $gap         # 528
$rowA = [int][math]::Round($W * 9 / 16)             # 900
$rowB = [int][math]::Round($leftW * 9 / 16)         # 594
$rowC = $rowB
$H = $rowA + $gap + $rowB + $gap + $rowC            # 2120
$rightH = $rowB + $gap + $rowC                      # 1204
$dH = 600; $eH = $rightH - $gap - $dH               # 600 / 588

function Draw-Cover($g, [string]$path, [System.Drawing.Rectangle]$dest, [double]$focusY) {
    # object-fit: cover with a vertical focus (0 = keep top, 1 = keep bottom)
    $img = [System.Drawing.Image]::FromFile($path)
    try {
        $scale = [math]::Max($dest.Width / $img.Width, $dest.Height / $img.Height)
        $sw = $dest.Width / $scale; $sh = $dest.Height / $scale
        $sx = ($img.Width - $sw) / 2
        $sy = ($img.Height - $sh) * $focusY
        $src = New-Object System.Drawing.RectangleF $sx, $sy, $sw, $sh
        # both rectangles must be the same type for this DrawImage overload
        $destF = New-Object System.Drawing.RectangleF $dest.X, $dest.Y, $dest.Width, $dest.Height
        $g.DrawImage($img, $destF, $src, [System.Drawing.GraphicsUnit]::Pixel)
        Write-Host ("  {0,-40} {1}x{2} -> {3}x{4} (scale {5:N2})" -f (Split-Path $path -Leaf), $img.Width, $img.Height, $dest.Width, $dest.Height, $scale)
        if ($scale -gt 1) { Write-Warning "  $path is being enlarged ($scale x)" }
    } finally { $img.Dispose() }
}

function Save-Jpeg($bmp, [string]$path, [int]$q) {
    $codec = [System.Drawing.Imaging.ImageCodecInfo]::GetImageEncoders() | Where-Object { $_.MimeType -eq 'image/jpeg' }
    $ep = New-Object System.Drawing.Imaging.EncoderParameters 1
    $ep.Param[0] = New-Object System.Drawing.Imaging.EncoderParameter ([System.Drawing.Imaging.Encoder]::Quality), ([long]$q)
    $bmp.Save($path, $codec, $ep)
    Write-Host ("  wrote {0} ({1}x{2}, {3} KB)" -f (Split-Path $path -Leaf), $bmp.Width, $bmp.Height, [math]::Round((Get-Item $path).Length / 1KB))
}

Write-Host "canvas ${W}x${H}"
$canvas = New-Object System.Drawing.Bitmap $W, $H, ([System.Drawing.Imaging.PixelFormat]::Format24bppRgb)
$g = [System.Drawing.Graphics]::FromImage($canvas)
$g.InterpolationMode = 'HighQualityBicubic'; $g.PixelOffsetMode = 'HighQuality'
$g.CompositingQuality = 'HighQuality'; $g.SmoothingMode = 'HighQuality'
$g.Clear([System.Drawing.Color]::White)

Draw-Cover $g $photos.A (New-Object System.Drawing.Rectangle 0, 0, $W, $rowA) 0.5
$y2 = $rowA + $gap
Draw-Cover $g $photos.B (New-Object System.Drawing.Rectangle 0, $y2, $leftW, $rowB) 0.5
$y3 = $y2 + $rowB + $gap
Draw-Cover $g $photos.C (New-Object System.Drawing.Rectangle 0, $y3, $leftW, $rowC) 0.5
$xr = $leftW + $gap
Draw-Cover $g $photos.D (New-Object System.Drawing.Rectangle $xr, $y2, $rightW, $dH) 0.42   # faces sit just above centre
Draw-Cover $g $photos.E (New-Object System.Drawing.Rectangle $xr, ($y2 + $dH + $gap), $rightW, $eH) 0.55
$g.Dispose()

Save-Jpeg $canvas (Join-Path $outDir 'hov-pan-india-collage-1600.jpg') $Quality

$half = New-Object System.Drawing.Bitmap 800, 1060, ([System.Drawing.Imaging.PixelFormat]::Format24bppRgb)
$g2 = [System.Drawing.Graphics]::FromImage($half)
$g2.InterpolationMode = 'HighQualityBicubic'; $g2.PixelOffsetMode = 'HighQuality'; $g2.CompositingQuality = 'HighQuality'
$g2.DrawImage($canvas, (New-Object System.Drawing.Rectangle 0, 0, 800, 1060), (New-Object System.Drawing.Rectangle 0, 0, $W, $H), [System.Drawing.GraphicsUnit]::Pixel)
$g2.Dispose()
Save-Jpeg $half (Join-Path $outDir 'hov-pan-india-collage-800.jpg') $Quality
$half.Dispose(); $canvas.Dispose()
