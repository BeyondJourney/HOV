# ============================================================================
#  qa-staging.ps1 - full offline QA of _deploy/public_html/
#
#  Validates the staging build WITHOUT a web server, by resolving every link
#  and asset reference against the files actually present on disk.
#
#  Exit criteria (all must be zero):
#     broken internal links | missing P0 URLs | broken critical assets
#     missing canonical tags | missing titles | missing meta descriptions
#     duplicate titles | leftover .html links | template artefacts
#
#  Also statically analyses .htaccess for 302s, loops and chains.
#
#  Usage:  .\qa-staging.ps1
# ============================================================================
$ErrorActionPreference = "Stop"
$Kit    = $PSScriptRoot
$Deploy = Join-Path $Kit "_deploy\public_html"
$Site   = "https://houseofvacation.com"

if (-not (Test-Path $Deploy)) { Write-Host "Staging not built. Run build-deploy.ps1" -ForegroundColor Red; exit 1 }

$P0 = @(
  "/","/mice-company-in-delhi/","/mice-company-in-noida/","/mice-company-in-gurugram/",
  "/corporate-travel-agency-in-mumbai/","/corporate-travel-agency-in-bangalore/",
  "/corporate-event-planners-in-pune/","/contact-us/","/about-company/","/blog/"
)

$fail = 0; $warn = 0; $rows = @()
function Bad ($m) { $script:fail++; Write-Host "  FAIL  $m" -ForegroundColor Red }
function Warn($m) { $script:warn++; Write-Host "  WARN  $m" -ForegroundColor Yellow }
function Good($m) { Write-Host "  PASS  $m" -ForegroundColor Green }

function Get-Url ($file) {
    $rel = $file.Directory.FullName.Substring($Deploy.Length).Replace('\','/')
    if ($rel -eq "") { return "/" }
    return "$rel/"
}
function Resolve-LocalPath ($url, $BaseDir = $Deploy) {
    # Paths are document-relative now, so resolution needs the directory of the
    # page doing the referencing. Root-relative input still resolves against the
    # deploy root so the P0/critical-asset checks keep working unchanged.
    $u = ($url -split '[?#]')[0]
    if ($u -eq "")   { return $null }
    if ($u -eq "/")  { return (Join-Path $Deploy "index.html") }
    if ($u -eq "./") { return (Join-Path $BaseDir "index.html") }

    if ($u.StartsWith("/")) { $root = $Deploy;  $p = $u.TrimStart('/') }
    else                    { $root = $BaseDir; $p = $u }

    $combined = Join-Path $root ($p.Replace('/','\'))
    try { $full = [System.IO.Path]::GetFullPath($combined) } catch { return $null }

    # A relative path that climbs out of the deploy root is broken by definition
    # - this is the check that catches a wrong ../ depth.
    if (-not $full.StartsWith($Deploy, [StringComparison]::OrdinalIgnoreCase)) { return $null }

    if (Test-Path $full -PathType Leaf) { return $full }
    $idx = Join-Path $full "index.html"
    if (Test-Path $idx -PathType Leaf) { return $idx }
    return $null
}

$pages = Get-ChildItem $Deploy -Recurse -Filter index.html |
         Where-Object { $_.Directory.FullName -notlike "*\assets*" }

Write-Host "`n############ QA: $($pages.Count) pages ############" -ForegroundColor Cyan

# ---------------------------------------------------------------- 1. P0 URLs
Write-Host "`n=== 1. P0 URLs present ===" -ForegroundColor Cyan
$urls = $pages | ForEach-Object { Get-Url $_ }
foreach ($p in $P0) {
    if ($urls -contains $p) { Good "$p" } else { Bad "MISSING P0 URL: $p" }
}

# ------------------------------------------------------- 2. SEO metadata
Write-Host "`n=== 2. SEO metadata ===" -ForegroundColor Cyan
$titles = @{}
foreach ($f in $pages) {
    $u = Get-Url $f
    $h = Get-Content $f.FullName -Raw
    $t   = if ($h -match '(?is)<title[^>]*>(.*?)</title>') { ([System.Net.WebUtility]::HtmlDecode($matches[1]) -replace '\s+',' ').Trim() } else { "" }
    $d   = if ($h -match '(?is)<meta[^>]*name="description"[^>]*content="([^"]*)"') { [System.Net.WebUtility]::HtmlDecode($matches[1]).Trim() } else { "" }
    $c   = if ($h -match '(?is)<link[^>]*rel="canonical"[^>]*href="([^"]*)"') { $matches[1].Trim() } else { "" }
    $h1s = [regex]::Matches($h,'(?is)<h1[^>]*>(.*?)</h1>')
    $expected = "$Site$u"

    $issues = @()
    if (-not $t) { $issues += "no title" }
    elseif ($t -match 'Tourm|^houseofvacation$') { $issues += "template title" }
    if (-not $d) { $issues += "no meta description" }
    elseif ($d -match 'Tourm') { $issues += "template description" }
    if (-not $c) { $issues += "NO CANONICAL" }
    elseif ($c -ne $expected) { $issues += "canonical=$c" }
    if ($h1s.Count -eq 0) { $issues += "no H1" }
    elseif ($h1s.Count -gt 1) { $issues += "$($h1s.Count) H1s" }

    if ($t) { if (-not $titles[$t]) { $titles[$t] = @() }; $titles[$t] += $u }

    $rows += [pscustomobject]@{
        Url=$u; Title=$t; TitleLen=$t.Length; Desc=$d; DescLen=$d.Length
        Canonical=$c; H1Count=$h1s.Count; Issues=($issues -join '; ')
    }
    if ($issues.Count) { Bad "$u  [$($issues -join '; ')]" } else { Good "$u" }
}

Write-Host "`n--- duplicate titles ---" -ForegroundColor Cyan
$dupes = $titles.GetEnumerator() | Where-Object { $_.Value.Count -gt 1 }
if ($dupes) { foreach ($d in $dupes) { Bad "duplicate title '$($d.Key)' on: $($d.Value -join ', ')" } }
else { Good "all titles unique" }

# --------------------------------------------------- 3. Internal links
Write-Host "`n=== 3. Internal links ===" -ForegroundColor Cyan
$brokenLinks = @{}; $htmlLinks = @{}; $absLinks = @{}; $totalLinks = 0
foreach ($f in $pages) {
    $u = Get-Url $f
    $h = Get-Content $f.FullName -Raw
    foreach ($m in [regex]::Matches($h,'(?i)href="([^"]*)"')) {
        $v = $m.Groups[1].Value.Trim()
        if ($v -match '^(https?:|mailto:|tel:|#|javascript:|data:|//)' -or $v -eq "") { continue }
        if ($v -match '\.(css|js|png|jpe?g|svg|webp|ico|woff2?|json|xml|txt)$') { continue }
        $totalLinks++
        if ($v -match '^/') { if (-not $absLinks[$v]) { $absLinks[$v]=@() }; $absLinks[$v]+=$u }
        if ($v -match '\.html($|[?#])') { if (-not $htmlLinks[$v]) { $htmlLinks[$v]=@() }; $htmlLinks[$v]+=$u }
        if (-not (Resolve-LocalPath $v $f.Directory.FullName)) { if (-not $brokenLinks[$v]) { $brokenLinks[$v]=@() }; $brokenLinks[$v]+=$u }
    }
}
Write-Host "  scanned $totalLinks internal page links"
if ($brokenLinks.Count) {
    foreach ($b in ($brokenLinks.GetEnumerator() | Sort-Object {$_.Value.Count} -Descending)) {
        Bad "broken link '$($b.Key)' on $(($b.Value|Select-Object -Unique).Count) page(s)"
    }
} else { Good "0 broken internal links" }
if ($htmlLinks.Count) {
    foreach ($b in $htmlLinks.GetEnumerator()) { Warn ".html link '$($b.Key)' would cause a 301 hop ($(($b.Value|Select-Object -Unique).Count) pages)" }
} else { Good "0 .html links (no avoidable redirect hops)" }
if ($absLinks.Count) { foreach ($b in $absLinks.GetEnumerator()) { Bad "root-relative link '$($b.Key)' on $(($b.Value|Select-Object -Unique).Count) page(s) - would break in a subfolder" } }
else { Good "all internal links are portable (document-relative)" }

# ----------------------------------------------------- 4. Critical assets
Write-Host "`n=== 4. Assets ===" -ForegroundColor Cyan
$brokenAssets = @{}; $absAssets = @{}; $assetCount = 0
foreach ($f in $pages) {
    $u = Get-Url $f
    $h = Get-Content $f.FullName -Raw
    foreach ($m in [regex]::Matches($h,'(?i)(?:src|href)="([^"]*\.(?:css|js|png|jpe?g|svg|webp|ico|woff2?))"')) {
        $v = $m.Groups[1].Value.Trim()
        if ($v -match '^(https?:|data:|//)') { continue }
        $assetCount++
        if ($v -match '^/wp-content/uploads/') { continue }   # supplied at upload time
        if ($v -match '^/') { if (-not $absAssets[$v]) { $absAssets[$v]=@() }; $absAssets[$v]+=$u }
        if (-not (Resolve-LocalPath $v $f.Directory.FullName)) { if (-not $brokenAssets[$v]) { $brokenAssets[$v]=@() }; $brokenAssets[$v]+=$u }
    }
    # CSS url() in inline styles - these carry the page banners and are easy to
    # miss: they are not src=/href= and four filenames contain parentheses.
    foreach ($m in [regex]::Matches($h,'(?i)url\(\s*(["''])([^"'']*)\1\s*\)')) {
        $v = $m.Groups[2].Value.Trim()
        if ($v -match '^(https?:|data:|//)') { continue }
        $assetCount++
        if ($v -match '^/wp-content/uploads/') { continue }
        if ($v -match '^/') { if (-not $absAssets[$v]) { $absAssets[$v]=@() }; $absAssets[$v]+=$u }
        if (-not (Resolve-LocalPath $v $f.Directory.FullName)) { if (-not $brokenAssets[$v]) { $brokenAssets[$v]=@() }; $brokenAssets[$v]+=$u }
    }
}
Write-Host "  scanned $assetCount asset references"
if ($absAssets.Count) { foreach ($r in $absAssets.GetEnumerator()) { Bad "root-relative asset '$($r.Key)' on $(($r.Value|Select-Object -Unique).Count) page(s) - would break in a subfolder" } }
else { Good "all asset paths are portable (document-relative)" }
if ($brokenAssets.Count) {
    foreach ($b in ($brokenAssets.GetEnumerator() | Sort-Object {$_.Value.Count} -Descending | Select-Object -First 15)) {
        Bad "missing asset '$($b.Key)' on $(($b.Value|Select-Object -Unique).Count) page(s)"
    }
} else { Good "0 broken critical assets" }

# CSS/JS actually present
foreach ($a in @("/assets/css/style.css","/assets/js/main.js")) {
    if (Resolve-LocalPath $a) { Good "exists $a" } else { Bad "MISSING $a" }
}

# ------------------------------------------- 5. WordPress dependency check
Write-Host "`n=== 5. No WordPress asset dependencies ===" -ForegroundColor Cyan
$wpRefs = 0
foreach ($f in $pages) {
    $h = Get-Content $f.FullName -Raw
    $wpRefs += ([regex]::Matches($h,'(?i)(?:src|href)="(?:https://houseofvacation\.com)?/wp-(?:content/(?:themes|plugins)|includes|json)')).Count
}
if ($wpRefs -eq 0) { Good "0 references to wp-themes / wp-plugins / wp-includes" }
else { Bad "$wpRefs WordPress asset references remain (these would 301 to / and break styling)" }

# ------------------------------------------------- 6. Template artefacts
Write-Host "`n=== 6. Template artefacts ===" -ForegroundColor Cyan
foreach ($a in @("my-account","error.html","home-travel","shop.html","cart.html")) {
    if (Resolve-LocalPath "/$a/") { Bad "artefact deployed: $a" } else { Good "absent: $a" }
}
$tourm = 0
foreach ($f in $pages) { $tourm += ([regex]::Matches((Get-Content $f.FullName -Raw),'Tourm')).Count }
if ($tourm -eq 0) { Good "0 'Tourm' strings" } else { Warn "$tourm 'Tourm' strings remain (check alt text / logo alt)" }

# ------------------------------------------------- 7. .htaccess analysis
Write-Host "`n=== 7. .htaccess static analysis ===" -ForegroundColor Cyan
$hta = Join-Path $Deploy ".htaccess"
if (-not (Test-Path $hta)) { Bad ".htaccess missing from staging" }
else {
    # Strip comments first - otherwise explanatory text is analysed as config.
    $ht = ((Get-Content $hta) | Where-Object { $_ -notmatch '^\s*#' }) -join "`n"
    $n302 = ([regex]::Matches($ht,'R=302|R=307')).Count
    if ($n302 -eq 0) { Good "0 x 302/307 redirects" } else { Bad "$n302 temporary redirects found" }

    $n301 = ([regex]::Matches($ht,'R=301')).Count
    Good "$n301 x 301 rules"

    if ($ht -match 'RewriteRule\s+\^wp-content/uploads/\s+-\s+\[L\]') { Good "/wp-content/uploads/ excluded from rewriting" }
    else { Bad "/wp-content/uploads/ NOT excluded" }
    if ($ht -match 'RewriteRule\s+\^assets/\s+-\s+\[L\]') { Good "/assets/ excluded from rewriting" }
    else { Bad "/assets/ NOT excluded" }
    if ($ht -match 'ErrorDocument\s+404') { Good "ErrorDocument 404 set" } else { Bad "no ErrorDocument 404" }
    if ($ht -match '-MultiViews') { Good "MultiViews disabled" } else { Warn "MultiViews not disabled" }
    if ($ht -match 'X-Forwarded-Proto') { Good "X-Forwarded-Proto checked (CDN loop guard)" } else { Bad "no X-Forwarded-Proto guard - risk of redirect loop behind hcdn" }
    if ($ht -match 'no-store') { Bad "'no-store' present - this caused the ?no-cache URL explosion" } else { Good "no 'no-store' on HTML" }

    # ---- Rule model -------------------------------------------------------
    # Only UNCONDITIONAL rules can be analysed statically. A rule preceded by
    # RewriteCond only fires when that condition holds (e.g. the ?no-cache
    # stripper needs a matching query string), so a catch-all pattern like
    # ^(.*)$ is NOT a loop - treating it as one is a false positive.
    $lines = $ht -split "`n"
    $rules = @()
    for ($i = 0; $i -lt $lines.Count; $i++) {
        $m = [regex]::Match($lines[$i], '^\s*RewriteRule\s+(\S+)\s+(\S+)\s+\[([^\]]*)\]')
        if (-not $m.Success) { continue }
        $guarded = ($i -gt 0 -and $lines[$i-1] -match '^\s*RewriteCond')
        $rules += [pscustomobject]@{
            Pattern = $m.Groups[1].Value
            Target  = $m.Groups[2].Value
            Flags   = $m.Groups[3].Value
            Guarded = $guarded
            Line    = $i + 1
        }
    }
    $redirectRules = $rules | Where-Object { $_.Flags -match 'R=301' }
    Good "$($redirectRules.Count) redirect rules parsed ($(($redirectRules | Where-Object {$_.Guarded}).Count) condition-guarded)"

    # Chain: an UNGUARDED rule's literal target re-matches an earlier UNGUARDED pattern
    $chains = @()
    foreach ($r in ($redirectRules | Where-Object { -not $_.Guarded })) {
        if ($r.Target -match '[\$%]') { continue }          # back-reference target, not literal
        $probe = $r.Target.TrimStart('/')
        foreach ($o in ($redirectRules | Where-Object { -not $_.Guarded -and $_.Line -ne $r.Line })) {
            if ($o.Pattern -eq '^') { continue }
            $pat = $o.Pattern
            try { if ($probe -match $pat) { $chains += "line $($r.Line) -> $($r.Target) re-matches line $($o.Line) [$pat]" } } catch {}
        }
    }
    if ($chains.Count -eq 0) { Good "0 redirect chains" }
    else { $chains | Select-Object -Unique | ForEach-Object { Bad "CHAIN: $_" } }

    # Loop: an UNGUARDED rule whose literal target still matches its own pattern
    $loops = @()
    foreach ($r in ($redirectRules | Where-Object { -not $_.Guarded })) {
        if ($r.Target -match '[\$%]') { continue }
        $tgt = $r.Target.TrimStart('/')
        if ($tgt -eq '') { continue }
        try { if ($tgt -match $r.Pattern) { $loops += "line $($r.Line): $($r.Pattern) -> $($r.Target)" } } catch {}
    }
    if ($loops.Count -eq 0) { Good "0 redirect loops" }
    else { $loops | ForEach-Object { Bad "LOOP: $_" } }
}

# ------------------------------------------------- 8. Support files
Write-Host "`n=== 8. Support files ===" -ForegroundColor Cyan
foreach ($f in @("404.html","robots.txt","sitemap.xml","index.html","mail.php")) {
    if (Test-Path (Join-Path $Deploy $f)) { Good "/$f" } else { Bad "MISSING /$f" }
}
$sm = Join-Path $Deploy "sitemap.xml"
if (Test-Path $sm) {
    [xml]$x = Get-Content $sm -Raw
    $smUrls = $x.urlset.url | ForEach-Object { $_.loc }
    Good "sitemap lists $($smUrls.Count) URLs"
    foreach ($p in $P0) { if ($smUrls -notcontains "$Site$p") { Bad "sitemap missing P0 $p" } }
    foreach ($su in $smUrls) {
        $path = $su.Replace($Site,"")
        if (-not (Resolve-LocalPath $path)) { Bad "sitemap URL has no page: $su" }
    }
}

# ------------------------------------------------- report
$rows | Export-Csv (Join-Path $Kit "qa-report.csv") -NoTypeInformation -Encoding utf8

Write-Host "`n#############################################" -ForegroundColor Cyan
Write-Host ("  FAILURES: {0}    WARNINGS: {1}" -f $fail,$warn) -ForegroundColor $(if($fail -eq 0){"Green"}else{"Red"})
Write-Host "  Per-page detail: qa-report.csv"
Write-Host "#############################################`n"
if ($fail -gt 0) { exit 1 }
