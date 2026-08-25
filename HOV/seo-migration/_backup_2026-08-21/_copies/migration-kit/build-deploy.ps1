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
#  The six P0 city pages are rebuilt from the pre-migration crawl snapshots
#  into the NEW site template, so they keep their URL, SEO metadata and body
#  copy without depending on any WordPress theme or plugin asset.
#
#  Usage:  .\build-deploy.ps1 [-Clean]
# ============================================================================
param([switch]$Clean)

$ErrorActionPreference = "Stop"
. (Join-Path $PSScriptRoot "lib-extract.ps1")

$Root      = Split-Path -Parent $PSScriptRoot
$Kit       = $PSScriptRoot
$Deploy    = Join-Path $Kit "_deploy\public_html"
$Snapshots = "C:\Users\maduri\AppData\Local\Temp\claude\c--Users-maduri-OneDrive-Desktop-HOUSE-OF-VACATION-INDIA-PVT-LTD-HOV\0e4e3172-b5bd-4b60-84ca-5f357597236b\scratchpad\html"
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
}

$Excluded = @("my-account.html", "error.html")

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

function Write-Page {
    param([string]$Html, [string]$UrlPath)
    $dest = if ($UrlPath -eq "") { $Deploy } else { Join-Path $Deploy $UrlPath }
    New-Item -ItemType Directory -Force -Path $dest | Out-Null
    Set-Content -Path (Join-Path $dest "index.html") -Value $Html -Encoding utf8 -NoNewline
}

# Load SEO metadata (audit-derived source of truth)
$SeoTable = @{}
$seoPath = Join-Path $Kit "seo-metadata.json"
if (Test-Path $seoPath) {
    foreach ($e in (Get-Content $seoPath -Raw | ConvertFrom-Json)) { $SeoTable[$e.Url] = $e }
}

# ===========================================================================
Write-Host "`n=== 1. New site pages ===" -ForegroundColor Cyan
$built = 0; $seoApplied = 0; $seoMissing = @()

foreach ($src in $PageMap.Keys) {
    $path = Join-Path $Root $src
    if (-not (Test-Path $path)) { Write-Host "  SKIP (missing): $src" -ForegroundColor Yellow; continue }

    $html = Get-Content $path -Raw
    $html = Repair-MobileMenu   $html
    $html = Repair-Links        $html
    $html = Convert-AssetPaths  $html
    $html = Repair-Headings     $html   # exactly one H1 per page
    $html = Remove-TemplateBranding $html

    $urlPath = $PageMap[$src]
    $url = if ($urlPath -eq "") { "$SiteUrl/" } else { "$SiteUrl/$urlPath/" }
    $key = if ($urlPath -eq "") { "/" } else { "/$urlPath/" }

    if ($SeoTable.ContainsKey($key)) {
        $m = $SeoTable[$key]
        $html = Set-SeoMeta -Html $html -Title $m.Title -Description $m.Description -CanonicalUrl $url
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
Write-Host "`n=== 2. P0 city pages rebuilt into the new template ===" -ForegroundColor Cyan

$CityPages = [ordered]@{
    "p_mice_company_in_delhi_.html"                = "mice-company-in-delhi"
    "p_mice_company_in_noida_.html"                = "mice-company-in-noida"
    "p_mice_company_in_gurugram_.html"             = "mice-company-in-gurugram"
    "p_corporate_travel_agency_in_mumbai_.html"    = "corporate-travel-agency-in-mumbai"
    "p_corporate_travel_agency_in_bangalore_.html" = "corporate-travel-agency-in-bangalore"
    "p_corporate_event_planners_in_pune_.html"     = "corporate-event-planners-in-pune"
}

# Shell = a finished new-site page, already link-fixed and asset-fixed.
$shellSrc = Join-Path $Root "our-services.html"
$shell = Get-Content $shellSrc -Raw
$shell = Repair-MobileMenu  $shell
$shell = Repair-Links       $shell
$shell = Convert-AssetPaths $shell
$shell = Remove-TemplateBranding $shell

# Locate the shell's main content region so old copy can be swapped in.
$mainMatch = [regex]::Match($shell, '(?is)(<main\b[^>]*>)(.*)(</main>)')
$useMain = $mainMatch.Success

$preserved = 0
foreach ($snap in $CityPages.Keys) {
    $path = Join-Path $Snapshots $snap
    if (-not (Test-Path $path)) { Write-Host "  MISSING SNAPSHOT: $snap" -ForegroundColor Red; continue }

    $old  = Get-Content $path -Raw
    $meta = Get-PageMeta $old
    $blocks = Get-ContentBlocks $old
    $contentHtml = ConvertTo-ContentHtml $blocks
    $words = (($blocks | ForEach-Object { $_.Text }) -join ' ').Split(' ').Count

    $urlPath = $CityPages[$snap]
    $url = "$SiteUrl/$urlPath/"

    # The shell's breadcrumb heading becomes this page's single H1, so the
    # injected content carries no second H1.
    $section = @"
      <section class="hov-content space">
        <div class="container">
$contentHtml        </div>
      </section>
"@

    if ($useMain) {
        $page = $shell.Substring(0, $mainMatch.Groups[2].Index) + "`n$section`n" +
                $shell.Substring($mainMatch.Groups[2].Index + $mainMatch.Groups[2].Length)
    } else {
        # No <main>: inject before the footer instead.
        $fi = $shell.LastIndexOf('<footer')
        if ($fi -lt 0) { $fi = $shell.LastIndexOf('</body>') }
        $page = $shell.Substring(0, $fi) + "`n$section`n" + $shell.Substring($fi)
    }

    # The old page's H1 replaces the shell's breadcrumb heading.
    $page = Set-BreadcrumbTitle -Html $page -Text $meta.H1
    $page = Repair-Headings -Html $page

    # Metadata comes from the OLD page verbatim - this is the SEO that must survive.
    $page = Set-SeoMeta -Html $page -Title $meta.Title -Description $meta.Description `
                        -CanonicalUrl $url -OgImage $meta.OgImage

    Write-Page -Html $page -UrlPath $urlPath
    $preserved++
    Write-Host ("  /{0,-39} {1,4} words  {2}" -f "$urlPath/", $words, $meta.Title) -ForegroundColor Gray
}

# ===========================================================================
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
foreach ($f in @(".htaccess", "404.html", "robots.txt", "sitemap.xml")) {
    $s = Join-Path $Kit "deploy\$f"
    if (Test-Path $s) { Copy-Item $s (Join-Path $Deploy $f) -Force; Write-Host "  /$f" -ForegroundColor Gray }
}
if (Test-Path (Join-Path $Root "mail.php")) {
    Copy-Item (Join-Path $Root "mail.php") (Join-Path $Deploy "mail.php") -Force
    Write-Host "  /mail.php" -ForegroundColor Gray
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
Write-Host "  Pages  : $built new + $preserved city = $($built + $preserved)"
Write-Host "  SEO    : $seoApplied metadata sets applied + $preserved from audit snapshots"
Write-Host "  Files  : $($tf.Count)   Size: $([math]::Round(($tf | Measure-Object Length -Sum).Sum/1MB,1)) MB"
Write-Host "============================================"
Write-Host "  Next: .\qa-staging.ps1`n"
