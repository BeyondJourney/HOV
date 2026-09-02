# ============================================================================
#  build-deploy.ps1 - assembles seo-migration/_deploy/public_html/
#
#  NON-DESTRUCTIVE. Reads your source HTML, never writes to it.
#  Everything is produced into the staging folder.
#
#  Pipeline per page:
#    1. Replace the Tourm mobile menu with the real 5-item menu
#    2. Rewrite every internal link to its final clean URL (no redirect hops)
#    3. Convert document-relative asset paths to root-relative
#    4. Inject title / meta description / canonical / Open Graph
#
#  The six MICE location pages are ordinary source pages now, built by the same
#  loop as everything else. They keep their URL, SEO metadata and body copy.
#
#  Usage:  .\build-deploy.ps1 [-Clean]
# ============================================================================
param([switch]$Clean)

$ErrorActionPreference = "Stop"

# --- UTF-8 safe file IO ------------------------------------------------------
# Get-Content -Raw / Set-Content -Encoding utf8 round-trip through the ANSI code
# page on Windows PowerShell when the source has no BOM, which corrupts every
# non-ASCII character (en-dashes, (c), curly quotes) and adds a BOM on the way
# out. These two helpers are used everywhere the build touches text.
$script:Utf8NoBom = New-Object System.Text.UTF8Encoding($false)
function Read-Text  { param([string]$Path) [System.Text.Encoding]::UTF8.GetString([System.IO.File]::ReadAllBytes($Path)) }
function Write-Text { param([string]$Path,[string]$Text) [System.IO.File]::WriteAllText($Path, $Text, $script:Utf8NoBom) }
. (Join-Path $PSScriptRoot "lib-extract.ps1")

$Root      = Split-Path -Parent $PSScriptRoot
$Kit       = $PSScriptRoot
$Deploy    = Join-Path $Kit "_deploy\public_html"
$SiteUrl   = "https://houseofvacation.com"

if ($Clean -and (Test-Path $Deploy)) {
    Write-Host "Cleaning staging folder..." -ForegroundColor Yellow
    Get-ChildItem $Deploy -Force | Remove-Item -Recurse -Force
}
New-Item -ItemType Directory -Force -Path $Deploy | Out-Null

# ---------------------------------------------------------------------------
#  Source .html  ->  deployed URL path
# ---------------------------------------------------------------------------
$PageMap = [ordered]@{
    "index.html"                        = ""
    "about.html"                        = "about-company"
    "contact.html"                      = "contact-us"
    "blog.html"                         = "blog"
    "our-services.html"                 = "our-services"
    "corporate-travel.html"             = "corporate-travel"
    "corporate-travel-consultancy.html" = "corporate-travel-consultancy"
    "mice-event.html"                   = "mice-event"
    "incentive.html"                    = "incentive"
    "conferences-event.html"            = "conferences-event"
    "corporate-celebration.html"        = "corporate-celebration"
    "offsite-events.html"               = "offsite-events"
    "adventure-group.html"              = "adventure-group"
    "customized-group.html"             = "customized-group"
    "destination-management.html"       = "destination-management"

    # The six MICE location pages are now real source files, edited like any
    # other page. They used to be generated here from a crawl snapshot living
    # in %TEMP%, which meant they could not be edited and would disappear if
    # that folder were ever cleared.
    "mice-company-in-delhi.html"                = "mice-company-in-delhi"
    "mice-company-in-noida.html"                = "mice-company-in-noida"
    "mice-company-in-gurugram.html"             = "mice-company-in-gurugram"
    "corporate-travel-agency-in-mumbai.html"    = "corporate-travel-agency-in-mumbai"
    "corporate-travel-agency-in-bangalore.html" = "corporate-travel-agency-in-bangalore"
    "corporate-event-planners-in-pune.html"     = "corporate-event-planners-in-pune"

    # Legal / commercial pages. Real source pages since 2026-09-02; they replaced
    # the standalone legal-privacy.html / legal-terms.html stubs that used to be
    # copied in verbatim, so they now go through the same menu, link, asset and
    # SEO pipeline as every other page.
    "pricing.html"                      = "pricing"
    "refund-policy.html"                = "refund-policy"
    "terms-and-conditions.html"         = "terms-and-conditions"
    "privacy-policy.html"               = "privacy-policy"
}

$Excluded = @("error.html")

# ---------------------------------------------------------------------------
#  LINK MAP - every internal href rewritten to its FINAL destination.
#  Pointing at the final URL is what keeps internal navigation at zero hops.
#  Left keys are lowercase, space- and %20-normalised before lookup.
# ---------------------------------------------------------------------------
$LinkMap = @{
    # Real pages
    "index.html"                        = "/"
    "index.html.html"                   = "/"          # find/replace bug
    "home-travel.html"                  = "/"          # template home variant
    "about.html"                        = "/about-company/"
    "contact.html"                      = "/contact-us/"
    "blog.html"                         = "/blog/"
    "blog-details.html"                 = "/blog/"
    "our-services.html"                 = "/our-services/"
    "our services.html"                 = "/our-services/"   # filename had a space
    "our%20services.html"               = "/our-services/"
    "corporate-travel.html"             = "/corporate-travel/"
    "corporate-travel-consultancy.html" = "/corporate-travel-consultancy/"
    "mice-event.html"                   = "/mice-event/"
    "incentive.html"                    = "/incentive/"
    "conferences-event.html"            = "/conferences-event/"
    "corporate-celebration.html"        = "/corporate-celebration/"
    "offsite-events.html"               = "/offsite-events/"
    "adventure-group.html"              = "/adventure-group/"
    "customized-group.html"             = "/customized-group/"
    "destination-management.html"       = "/destination-management/"
    "mice-company-in-delhi.html"                = "/mice-company-in-delhi/"
    "mice-company-in-noida.html"                = "/mice-company-in-noida/"
    "mice-company-in-gurugram.html"             = "/mice-company-in-gurugram/"
    "corporate-travel-agency-in-mumbai.html"    = "/corporate-travel-agency-in-mumbai/"
    "corporate-travel-agency-in-bangalore.html" = "/corporate-travel-agency-in-bangalore/"
    "corporate-event-planners-in-pune.html"     = "/corporate-event-planners-in-pune/"
    "pricing.html"                      = "/pricing/"
    "refund-policy.html"                = "/refund-policy/"
    "terms-and-conditions.html"         = "/terms-and-conditions/"
    "privacy-policy.html"               = "/privacy-policy/"

    # Excluded pages
    "my-account.html"                   = "/"
    "error.html"                        = "/"

    # Tourm template leftovers -> nearest real page
    "service.html"                      = "/our-services/"
    "service-details.html"              = "/our-services/"
    "tour.html"                         = "/our-services/"
    "tour-details.html"                 = "/our-services/"
    "activities.html"                   = "/adventure-group/"
    "activities-details.html"           = "/adventure-group/"
    "destination.html"                  = "/destination-management/"
    "destination-details.html"          = "/destination-management/"
    "resort.html"                       = "/offsite-events/"
    "resort-details.html"               = "/offsite-events/"
    "gallery.html"                      = "/"
    "price.html"                        = "/our-services/"
    "faq.html"                          = "/contact-us/"
    "tour-guide.html"                   = "/about-company/"
    "tour-guider-details.html"          = "/about-company/"
    "shop.html"                         = "/"
    "shop-details.html"                 = "/"
    "cart.html"                         = "/"
    "checkout.html"                     = "/"
    "wishlist.html"                     = "/"
    "home-tour.html"                    = "/"
    "home-agency.html"                  = "/"
    "home-resort.html"                  = "/"
    "home-forest.html"                  = "/"
    "home-beach.html"                   = "/"
    "home-yacht.html"                   = "/"
    "home-hiking.html"                  = "/"
    "home-hiking-2.html"                = "/"
    "home-countryside-hotel.html"       = "/"
}

# Clean menu markup that replaces the Tourm demo mobile menu
$CleanMobileMenu = @'
<ul>
<li><a href="/">Home</a></li>
<li><a href="/about-company/">About Us</a></li>
<li class="menu-item-has-children"><a href="/our-services/">Our Services</a>
<ul class="sub-menu">
<li><a href="/mice-event/">MICE Events</a></li>
<li><a href="/corporate-travel/">Corporate Travel</a></li>
<li><a href="/incentive/">Incentive Travel</a></li>
<li><a href="/conferences-event/">Conferences</a></li>
<li><a href="/corporate-celebration/">Corporate Celebrations</a></li>
<li><a href="/offsite-events/">Offsite Events</a></li>
<li><a href="/destination-management/">Destination Management</a></li>
</ul>
</li>
<li class="menu-item-has-children"><a href="/our-services/">Locations</a>
<ul class="sub-menu">
<li><a href="/mice-company-in-delhi/">Delhi</a></li>
<li><a href="/mice-company-in-noida/">Noida</a></li>
<li><a href="/mice-company-in-gurugram/">Gurugram</a></li>
<li><a href="/corporate-travel-agency-in-mumbai/">Mumbai</a></li>
<li><a href="/corporate-travel-agency-in-bangalore/">Bangalore</a></li>
<li><a href="/corporate-event-planners-in-pune/">Pune</a></li>
</ul>
</li>
<li><a href="/blog/">Blog</a></li>
<li><a href="/contact-us/">Contact us</a></li>
</ul>
'@

function Get-BlockRange {
    <# Finds a <div class="X"> and returns the index range of its balanced close. #>
    param([string]$Html, [string]$ClassName)
    $open = [regex]::Match($Html, "<div[^>]*class=""[^""]*\b$ClassName\b[^""]*""[^>]*>")
    if (-not $open.Success) { return $null }
    $i = $open.Index + $open.Length
    $depth = 1
    while ($depth -gt 0 -and $i -lt $Html.Length) {
        $next = [regex]::Match($Html.Substring($i), '(?i)<(/?)div\b')
        if (-not $next.Success) { return $null }
        $i += $next.Index + $next.Length
        if ($next.Groups[1].Value -eq '/') { $depth-- } else { $depth++ }
    }
    return @{ Start = $open.Index; End = $i; InnerStart = $open.Index + $open.Length }
}

function Repair-MobileMenu {
    param([string]$Html)
    $r = Get-BlockRange -Html $Html -ClassName 'th-mobile-menu'
    if ($null -eq $r) { return $Html }
    $closeLen = 6   # "</div>"
    $inner = $Html.Substring($r.InnerStart, ($r.End - $closeLen) - $r.InnerStart)
    # Keep the logo block, replace only the menu <ul>
    $ulStart = $inner.IndexOf('<ul')
    if ($ulStart -lt 0) { return $Html }
    $newInner = $inner.Substring(0, $ulStart) + $CleanMobileMenu
    return $Html.Substring(0, $r.InnerStart) + $newInner + $Html.Substring($r.End - $closeLen)
}

function Repair-Links {
    param([string]$Html)
    return [regex]::Replace($Html, '(?i)href="([^"]*\.html)((?:[?#][^"]*)?)"', {
        param($m)
        $raw  = $m.Groups[1].Value
        $frag = $m.Groups[2].Value
        $leaf = ([System.Net.WebUtility]::UrlDecode(($raw -split '/')[-1])).ToLower()
        if ($LinkMap.ContainsKey($leaf)) { return "href=""$($LinkMap[$leaf])$frag""" }
        return $m.Value
    })
}

function Convert-AssetPaths {
    param([string]$Html)
    $Html = $Html -replace '(?i)(=")(?:H/)?assets/', '${1}/assets/'
    $Html = $Html -replace "(?i)(=')(?:H/)?assets/", '${1}/assets/'
    $Html = $Html -replace '(?i)url\(\s*(?:H/)?assets/',  'url(/assets/'
    $Html = $Html -replace '(?i)url\(\s*"(?:H/)?assets/', 'url("/assets/'
    $Html = $Html -replace "(?i)url\(\s*'(?:H/)?assets/", "url('/assets/"
    return $Html
}

# ---------------------------------------------------------------------------
#  PORTABLE PATHS
#
#  A root-relative URL ("/assets/img/x.jpg") only resolves when the site IS the
#  document root. Drop the same build into a subfolder and every one of them
#  points above that folder and 404s - which is exactly what happened in
#  /prod_HOV/.
#
#  Rewriting them document-relative ("../assets/img/x.jpg") lets ONE build run
#  unchanged at the domain root and in any subfolder, at any depth, on any
#  domain. Nothing needs rebuilding when the site moves.
#
#  Depth is the number of folders between the page and the deploy root:
#    /index.html                depth 0  ->  "assets/img/x.jpg"
#    /about-company/index.html  depth 1  ->  "../assets/img/x.jpg"
#
#  This depends on the trailing slash being present, which DirectorySlash
#  issues natively as a 301 for every real directory (see .htaccess) - so it
#  holds regardless of where the site is mounted.
#
#  Left untouched on purpose: absolute URLs (canonical, og:url, og:image, and
#  the JSON-LD block), protocol-relative //, #anchors, tel: and mailto:.
# ---------------------------------------------------------------------------
function Convert-ToRelative {
    param([string]$Html, [int]$Depth)
    $prefix = if ($Depth -le 0) { "" } else { "../" * $Depth }

    # href / src / data-mask-src / content / action = "/x"
    $Html = [regex]::Replace($Html, '(?i)(\s(?:href|src|data-mask-src|content|action)=")/(?!/)([^"]*)"', {
        param($m)
        $v = $prefix + $m.Groups[2].Value
        if ($v -eq "") { $v = "./" }     # href="/" at depth 0 must not become href=""
        $m.Groups[1].Value + $v + '"'
    })

    # url() in inline styles. Split into quoted and unquoted forms on purpose:
    # four of these filenames contain parentheses ("... BANNNER (1).jpg"), and a
    # single pattern that stops at the first ")" silently skips exactly those.
    # Inside quotes the closing quote is the terminator, so parens are safe.
    $Html = [regex]::Replace($Html, '(?i)url\(\s*(["''])/(?!/)(.*?)\1\s*\)', {
        param($m)
        $q = $m.Groups[1].Value
        'url(' + $q + $prefix + $m.Groups[2].Value + $q + ')'
    })
    # Unquoted url(/x) - a bare URL token cannot contain ) or whitespace anyway.
    $Html = [regex]::Replace($Html, '(?i)url\(\s*/(?!/)([^)"''\s]*)\s*\)', {
        param($m)
        'url(' + $prefix + $m.Groups[1].Value + ')'
    })
    return $Html
}

function Write-Page {
    param([string]$Html, [string]$UrlPath)
    $dest = if ($UrlPath -eq "") { $Deploy } else { Join-Path $Deploy $UrlPath }
    New-Item -ItemType Directory -Force -Path $dest | Out-Null
    Write-Text (Join-Path $dest "index.html") $Html
}

# Load SEO metadata (audit-derived source of truth)
$SeoTable = @{}
$seoPath = Join-Path $Kit "seo-metadata.json"
if (Test-Path $seoPath) {
    foreach ($e in ((Read-Text $seoPath) | ConvertFrom-Json)) { $SeoTable[$e.Url] = $e }
}

# ===========================================================================
Write-Host "`n=== 1. New site pages ===" -ForegroundColor Cyan
$built = 0; $seoApplied = 0; $seoMissing = @()

foreach ($src in $PageMap.Keys) {
    $path = Join-Path $Root $src
    if (-not (Test-Path $path)) { Write-Host "  SKIP (missing): $src" -ForegroundColor Yellow; continue }

    $html = Read-Text $path
    $html = Repair-MobileMenu   $html
    $html = Repair-Links        $html
    $html = Convert-AssetPaths  $html
    $html = Repair-Headings     $html   # exactly one H1 per page
    $html = Remove-TemplateBranding $html
    $html = Remove-DeadControls     $html   # login/register forms, href="" anchors
    $html = Add-MainLandmark        $html   # accessibility landmark for the skip link
    $html = Repair-Quality          $html   # lang, lazy, noopener, dead form, honeypot
    $html = Repair-FormLabels       $html   # aria-label on every visible field

    $urlPath = $PageMap[$src]
    $url = if ($urlPath -eq "") { "$SiteUrl/" } else { "$SiteUrl/$urlPath/" }
    $key = if ($urlPath -eq "") { "/" } else { "/$urlPath/" }

    if ($SeoTable.ContainsKey($key)) {
        $m = $SeoTable[$key]
        $html = Set-SeoMeta -Html $html -Title $m.Title -Description $m.Description -CanonicalUrl $url
        $html = Add-StructuredData -Html $html -PageUrl $url -PageTitle $m.Title -PageDesc $m.Description
        if ($urlPath -ne "") {
            $crumb = (Get-Culture).TextInfo.ToTitleCase(($urlPath -replace '-', ' '))
            $html = Add-Breadcrumbs -Html $html -PageUrl $url -PageName $crumb
        }
        $seoApplied++
        $tag = if ($m.Source -like "AUDIT*") { "audit" } else { "created" }
    } else {
        $seoMissing += $key; $tag = "NO META"
    }

    Write-Page -Html $html -UrlPath $urlPath
    $built++
    Write-Host ("  {0,-40} {1,-8} {2}" -f $key, $tag, $src) -ForegroundColor Gray
}

# ===========================================================================
# ===========================================================================
# The P0 city pages were previously rebuilt here from crawl snapshots. They are
# now first-class source pages and are built by the loop above like every other
# page, so this step only reports on them.
$preserved = 0
Write-Host "`n=== 2. MICE location pages (now built from source) ===" -ForegroundColor Cyan
foreach ($slug in @("mice-company-in-delhi","mice-company-in-noida","mice-company-in-gurugram",
                    "corporate-travel-agency-in-mumbai","corporate-travel-agency-in-bangalore",
                    "corporate-event-planners-in-pune")) {
    if (Test-Path (Join-Path $Deploy "$slug\index.html")) {
        $preserved++
        Write-Host ("  /{0}/" -f $slug) -ForegroundColor Gray
    } else {
        Write-Host ("  MISSING /{0}/" -f $slug) -ForegroundColor Red
    }
}
Write-Host "`n=== 3. Static assets ===" -ForegroundColor Cyan
if (Test-Path (Join-Path $Root "assets")) {
    Copy-Item (Join-Path $Root "assets") -Destination $Deploy -Recurse -Force

    $ac = (Get-ChildItem (Join-Path $Deploy "assets") -Recurse -File).Count
    Write-Host "  /assets/  $ac files" -ForegroundColor Gray
}
if (Test-Path (Join-Path $Root "H\assets")) {
    $merged = 0
    $srcRoot = Join-Path $Root "H\assets"
    Get-ChildItem $srcRoot -Recurse -File | ForEach-Object {
        $rel = $_.FullName.Substring($srcRoot.Length).TrimStart('\')
        $tgt = Join-Path $Deploy "assets\$rel"
        if (-not (Test-Path $tgt)) {
            New-Item -ItemType Directory -Force -Path (Split-Path $tgt) | Out-Null
            Copy-Item $_.FullName $tgt -Force
            $merged++
        }
    }
    Write-Host "  merged $merged unique file(s) from H/assets/" -ForegroundColor Gray
}

# --- Purge dead weight from the STAGING COPY only ---------------------------
# Runs AFTER the H/assets merge, because H/assets carries its own duplicate
# copies of the videos and legacy fonts. Source files are never touched.
#   * hero .mp4 files - referenced by NO page in the project
#   * legacy font formats (svg/ttf/eot/otf) - only woff2 is needed by any
#     browser from the last decade, and the site uses just 22 icons
$purged = 0
$purgedBytes = 0
foreach ($v in (Get-ChildItem (Join-Path $Deploy "assets") -Recurse -File -Filter *.mp4 -EA SilentlyContinue)) {
    $purgedBytes += $v.Length; $purged++
    [System.IO.File]::Delete($v.FullName)
}
$fontDir = Join-Path $Deploy "assets\fonts"
if (Test-Path $fontDir) {
    foreach ($ft in (Get-ChildItem $fontDir -Recurse -File -Include *.svg,*.ttf,*.eot,*.otf -EA SilentlyContinue)) {
        $purgedBytes += $ft.Length; $purged++
        [System.IO.File]::Delete($ft.FullName)
    }
}
$acFinal = (Get-ChildItem (Join-Path $Deploy "assets") -Recurse -File).Count
$mbFinal = [math]::Round(((Get-ChildItem (Join-Path $Deploy "assets") -Recurse -File | Measure-Object Length -Sum).Sum/1MB),1)
Write-Host ("  purged {0} dead-weight files (-{1} MB)" -f $purged, [math]::Round($purgedBytes/1MB,1)) -ForegroundColor Gray
Write-Host ("  /assets/ final: {0} files, {1} MB" -f $acFinal, $mbFinal) -ForegroundColor Gray

Write-Host "`n=== 4. Legacy uploads (URL-critical) ===" -ForegroundColor Cyan
if (Test-Path (Join-Path $Root "wp-content\uploads")) {
    Copy-Item (Join-Path $Root "wp-content") -Destination $Deploy -Recurse -Force
    $uc = (Get-ChildItem (Join-Path $Deploy "wp-content") -Recurse -File).Count
    Write-Host "  /wp-content/uploads/  $uc files copied" -ForegroundColor Gray
} else {
    Write-Host "  NOT FOUND LOCALLY - download from Hostinger before upload:" -ForegroundColor Yellow
    Write-Host "    public_html/wp-content/uploads/  ->  HOV\wp-content\uploads\" -ForegroundColor Yellow
    Write-Host "  30 live images and every og:image depend on these exact URLs." -ForegroundColor Yellow
}

Write-Host "`n=== 5. Config files ===" -ForegroundColor Cyan
foreach ($f in @(".htaccess", "404.html", "robots.txt", "sitemap.xml", "mail.php")) {
    $s = Join-Path $Kit "deploy\$f"
    if (Test-Path $s) { Copy-Item $s (Join-Path $Deploy $f) -Force; Write-Host "  /$f" -ForegroundColor Gray }
}
# Hardened thank-you page at its own clean URL (needed for GA4 conversion tracking)
$ty = Join-Path $Kit "deploy\thank-you.html"
if (Test-Path $ty) {
    New-Item -ItemType Directory -Force -Path (Join-Path $Deploy "thank-you") | Out-Null
    Copy-Item $ty (Join-Path $Deploy "thank-you\index.html") -Force
    Write-Host "  /thank-you/" -ForegroundColor Gray
}

# ===========================================================================
# This step used to copy deploy/legal-privacy.html and deploy/legal-terms.html
# to /privacy-policy/ and /terms-and-conditions/. Those URLs, plus /pricing/
# and /refund-policy/, are now built by the page loop in step 1 from the real
# source pages, so the stubs were removed and this only reports on the result.
Write-Host "`n=== 6. Legal pages (built from source in step 1) ===" -ForegroundColor Cyan
foreach ($slug in @("pricing","refund-policy","terms-and-conditions","privacy-policy")) {
    if (Test-Path (Join-Path $Deploy "$slug\index.html")) { Write-Host ("  /{0}/" -f $slug) -ForegroundColor Gray }
    else { Write-Host ("  MISSING /{0}/" -f $slug) -ForegroundColor Red }
}

# Root favicon - the live site returns 404 for /favicon.ico today.
$favSrc = Join-Path $Deploy "assets\img\favicons\favicon.ico"
if (-not (Test-Path $favSrc)) {
    $favSrc = Get-ChildItem (Join-Path $Deploy "assets\img\favicons") -Filter "*.png" -EA SilentlyContinue |
              Sort-Object Length | Select-Object -First 1 -ExpandProperty FullName
}
if ($favSrc -and (Test-Path $favSrc)) {
    Copy-Item $favSrc (Join-Path $Deploy "favicon.ico") -Force
    Write-Host "  /favicon.ico" -ForegroundColor Gray
}

# ===========================================================================
Write-Host "`n=== 7. Image dimensions (CLS fix) ===" -ForegroundColor Cyan
# Runs last: resolves every src against the staged /assets/ tree, which only
# exists after step 3. Without width/height the browser cannot reserve space
# and every image shifts the layout as it loads.
$dimPages = 0; $dimImgs = 0
foreach ($pf in (Get-ChildItem $Deploy -Recurse -Filter index.html |
                 Where-Object { $_.Directory.FullName -notlike "*\assets*" })) {
    $html = Read-Text $pf.FullName
    $before = ([regex]::Matches($html, '(?is)<img[^>]*\swidth=')).Count
    $html = Repair-Images -Html $html -DeployRoot $Deploy
    $after = ([regex]::Matches($html, '(?is)<img[^>]*\swidth=')).Count
    if ($after -gt $before) { $dimImgs += ($after - $before); $dimPages++ }
    Write-Text $pf.FullName $html
}
Write-Host "  added width/height to $dimImgs images across $dimPages pages" -ForegroundColor Gray

Write-Host "`n=== 8. Portable paths (root-relative -> document-relative) ===" -ForegroundColor Cyan
# Runs dead last, after Repair-Images: every earlier step resolves asset paths
# against the deploy root, so they must still be root-relative until now.
$portPages = 0; $portRefs = 0
foreach ($pf in (Get-ChildItem $Deploy -Recurse -Filter index.html |
                 Where-Object { $_.Directory.FullName -notlike "*\assets*" })) {
    $relDir = $pf.Directory.FullName.Substring($Deploy.Length).Trim('\')
    $depth  = if ($relDir -eq "") { 0 } else { $relDir.Split([char]0x5C).Count }
    $html   = Read-Text $pf.FullName
    $portRefs += ([regex]::Matches($html, '(?i)(?:href|src|data-mask-src|content|action)="/(?!/)')).Count
    $html   = Convert-ToRelative -Html $html -Depth $depth
    Write-Text $pf.FullName $html
    $portPages++
}
Write-Host "  rewrote $portRefs references across $portPages pages" -ForegroundColor Gray

# The 404 page is the one exception. ErrorDocument serves it at whatever depth
# the bad URL happened to have (/a/b/c/ -> still /404.html), so there is no
# fixed depth to compute a relative path from. Absolute URLs are the only form
# that resolves correctly from every one of them.
$e404 = Join-Path $Deploy "404.html"
if (Test-Path $e404) {
    $h = Read-Text $e404
    $n = ([regex]::Matches($h, '(?i)(?:href|src)="/(?!/)')).Count
    $h = [regex]::Replace($h, '(?i)(\s(?:href|src)=")/(?!/)', { param($m) $m.Groups[1].Value + $SiteUrl + "/" })
    Write-Text $e404 $h
    Write-Host "  /404.html: $n links made absolute (served at unpredictable depth)" -ForegroundColor Gray
}

Write-Host "`n=== EXCLUDED ===" -ForegroundColor Cyan
$Excluded | ForEach-Object { Write-Host "  $_" -ForegroundColor DarkGray }
if ($seoMissing.Count) {
    Write-Host "`n  PAGES WITHOUT SEO METADATA:" -ForegroundColor Yellow
    $seoMissing | ForEach-Object { Write-Host "    $_" -ForegroundColor Yellow }
}

$tf = (Get-ChildItem $Deploy -Recurse -File -Force)
Write-Host "`n============================================" -ForegroundColor Green
Write-Host "  Staging: $Deploy"
Write-Host "  Pages  : $built pages ($preserved of them MICE location pages)"
Write-Host "  SEO    : $seoApplied metadata sets applied ($preserved location pages)"
Write-Host "  Files  : $($tf.Count)   Size: $([math]::Round(($tf | Measure-Object Length -Sum).Sum/1MB,1)) MB"
Write-Host "============================================"
Write-Host "  Next: .\qa-staging.ps1`n"
