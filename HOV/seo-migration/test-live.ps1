# ============================================================================
#  Post-deployment verification for houseofvacation.com
#
#  Usage:
#     .\test-live.ps1                                  # test production
#     .\test-live.ps1 -BaseUrl "https://staging."     # test staging first
#
#  Exits 1 if ANY hard requirement fails. Safe to wire into a deploy gate.
#
#  Covers requirement 18:
#     HTTP -> HTTPS | www -> non-www | old URL -> new URL | missing -> 404
#     image -> 200  | CSS/JS -> 200  | redirect chain max 1 hop
# ============================================================================
param([string]$BaseUrl = "https://houseofvacation.com")

$BaseUrl = $BaseUrl.TrimEnd('/')
$Host_   = ([Uri]$BaseUrl).Host
$pass = 0; $fail = 0; $warn = 0
$rows = @()

function Trace {
    param([string]$Url)
    $hops = @(); $cur = $Url
    for ($i = 0; $i -lt 8; $i++) {
        try {
            $rq = [Net.HttpWebRequest]::Create($cur)
            $rq.AllowAutoRedirect = $false
            $rq.UserAgent = "HOV-Deploy-Verifier/1.0"
            $rq.Timeout   = 30000
            $rp = $rq.GetResponse()
            $code = [int]$rp.StatusCode; $loc = $rp.Headers["Location"]
            $ctype = $rp.Headers["Content-Type"]; $rp.Close()
        } catch [Net.WebException] {
            if ($_.Exception.Response) {
                $r = $_.Exception.Response
                $code = [int]$r.StatusCode; $loc = $r.Headers["Location"]; $ctype = $r.Headers["Content-Type"]
            } else { $hops += [pscustomobject]@{Code="ERR"; Url=$cur; Type=""}; break }
        }
        $hops += [pscustomobject]@{Code=$code; Url=$cur; Type=$ctype}
        if ($code -ge 300 -and $code -lt 400 -and $loc) {
            if ($loc -notmatch '^https?://') { $u=[Uri]$cur; $loc = "$($u.Scheme)://$($u.Host)$loc" }
            $cur = $loc
        } else { break }
    }
    return ,$hops
}

function Check {
    param($Name, $Url, $ExpectCode, $ExpectFinal, $MaxHops = 1, $Hard = $true)
    $hops = Trace $Url
    $redirects = @($hops | Where-Object { $_.Code -ge 300 -and $_.Code -lt 400 }).Count
    $finalCode = $hops[-1].Code
    $finalUrl  = $hops[-1].Url

    $issues = @()
    if ($ExpectCode  -and $finalCode -ne $ExpectCode) { $issues += "got $finalCode want $ExpectCode" }
    if ($ExpectFinal -and $finalUrl.TrimEnd('/') -ne $ExpectFinal.TrimEnd('/')) { $issues += "landed $finalUrl" }
    if ($redirects -gt $MaxHops) { $issues += "CHAIN $redirects hops" }
    foreach ($h in $hops) { if ($h.Code -eq 302 -or $h.Code -eq 307) { $issues += "TEMP REDIRECT $($h.Code)" } }

    $script:rows += [pscustomobject]@{Test=$Name; Url=$Url; Final=$finalCode; Hops=$redirects; Issues=($issues -join '; ')}

    if ($issues.Count -eq 0) {
        $script:pass++; Write-Host ("  PASS  {0}" -f $Name) -ForegroundColor Green
    } elseif ($Hard) {
        $script:fail++; Write-Host ("  FAIL  {0}  [{1}]" -f $Name, ($issues -join '; ')) -ForegroundColor Red
    } else {
        $script:warn++; Write-Host ("  WARN  {0}  [{1}]" -f $Name, ($issues -join '; ')) -ForegroundColor Yellow
    }
}

Write-Host "`nTesting $BaseUrl`n" -ForegroundColor Cyan

Write-Host "--- 1. HTTP -> HTTPS (must be ONE hop) ---" -ForegroundColor Cyan
Check "http:// root"          "http://$Host_/"              200 "$BaseUrl/" 1
Check "http:// deep page"     "http://$Host_/contact-us/"   200 "$BaseUrl/contact-us/" 1

Write-Host "`n--- 2. www -> non-www (must be ONE hop) ---" -ForegroundColor Cyan
Check "https www root"        "https://www.$Host_/"                 200 "$BaseUrl/" 1
Check "https www deep"        "https://www.$Host_/about-company/"   200 "$BaseUrl/about-company/" 1
Check "http+www combined"     "http://www.$Host_/about-company/"    200 "$BaseUrl/about-company/" 1

Write-Host "`n--- 3. KEEP URLs must return 200 with NO redirect ---" -ForegroundColor Cyan
foreach ($p in @("/","/mice-company-in-delhi/","/mice-company-in-noida/","/mice-company-in-gurugram/",
                 "/corporate-travel-agency-in-mumbai/","/corporate-travel-agency-in-bangalore/",
                 "/corporate-event-planners-in-pune/","/contact-us/","/about-company/","/blog/")) {
    Check "200 $p" "$BaseUrl$p" 200 "$BaseUrl$p" 0
}

Write-Host "`n--- 4. Old URL -> new URL (301, one hop) ---" -ForegroundColor Cyan
Check "no-slash -> slash"     "$BaseUrl/about-company"                       200 "$BaseUrl/about-company/" 1
Check "uncategorized -> blog" "$BaseUrl/category/uncategorized/"             200 "$BaseUrl/blog/" 1
Check "hello-world -> blog"   "$BaseUrl/hello-world/"                        200 "$BaseUrl/blog/" 1
Check "new-blog -> blog"      "$BaseUrl/new-blog/"                           200 "$BaseUrl/blog/" 1
Check "author -> blog"        "$BaseUrl/author/essenceofnature43gmail-com/"  200 "$BaseUrl/blog/" 1
Check "feed -> blog"          "$BaseUrl/feed/"                               200 "$BaseUrl/blog/" 1
Check "wp-login -> home"      "$BaseUrl/wp-login.php"                        200 "$BaseUrl/" 1
Check "page/2 -> home"        "$BaseUrl/page/2/"                             200 "$BaseUrl/" 1
Check "2024 archive -> home"  "$BaseUrl/2024/"                               200 "$BaseUrl/" 1
Check "old sitemap"           "$BaseUrl/sitemap_index.xml"                   200 "$BaseUrl/sitemap.xml" 1
Check "?no-cache stripped"    "$BaseUrl/?no-cache=abc123"                    200 "$BaseUrl/" 1

Write-Host "`n--- 5. Missing URL must return a REAL 404 ---" -ForegroundColor Cyan
foreach ($p in @("/this-never-existed-xyz/","/random-junk/","/shop.html")) {
    $hops = Trace "$BaseUrl$p"
    $fc = $hops[-1].Code
    if ($fc -eq 404) { $pass++; Write-Host "  PASS  404 on $p" -ForegroundColor Green }
    else { $fail++; Write-Host "  FAIL  $p returned $fc (soft-404 risk)" -ForegroundColor Red }
    $rows += [pscustomobject]@{Test="404 $p"; Url="$BaseUrl$p"; Final=$fc; Hops=0; Issues=$(if($fc -eq 404){""}else{"not a real 404"})}
}

Write-Host "`n--- 6. Images must be 200 and NEVER redirected ---" -ForegroundColor Cyan
foreach ($p in @("/wp-content/uploads/2025/07/MICE-3.jpg",
                 "/wp-content/uploads/2025/07/MICE-4.jpg",
                 "/wp-content/uploads/2025/06/hov-mice-team-before-flight.webp",
                 "/wp-content/uploads/2024/12/cropped-Untitled-design-6-210x70.png")) {
    Check "img $p" "$BaseUrl$p" 200 "$BaseUrl$p" 0
}

Write-Host "`n--- 7. CSS / JS must be 200 and NEVER redirected ---" -ForegroundColor Cyan
foreach ($p in @("/assets/css/style.css","/assets/css/bootstrap.min.css","/assets/js/main.js")) {
    Check "asset $p" "$BaseUrl$p" 200 "$BaseUrl$p" 0 $false
}

Write-Host "`n--- 8. No duplicate entry points ---" -ForegroundColor Cyan
Check "/index.html -> /"      "$BaseUrl/index.html"        200 "$BaseUrl/" 1
Check "/about.html -> folder" "$BaseUrl/about.html"        200 "$BaseUrl/about-company/" 1 $false

Write-Host "`n--- 9. Canonical + robots + sitemap ---" -ForegroundColor Cyan
try {
    $r = Invoke-WebRequest "$BaseUrl/" -UseBasicParsing -TimeoutSec 30
    $can = if ($r.Content -match '(?is)rel="canonical"[^>]*href="([^"]*)"') { $matches[1] } else { $null }
    if ($can -eq "$BaseUrl/") { $pass++; Write-Host "  PASS  homepage canonical = $can" -ForegroundColor Green }
    elseif ($can) { $fail++; Write-Host "  FAIL  canonical is $can (expected $BaseUrl/)" -ForegroundColor Red }
    else { $fail++; Write-Host "  FAIL  homepage has NO canonical tag" -ForegroundColor Red }
} catch { $fail++; Write-Host "  FAIL  homepage unreachable" -ForegroundColor Red }

foreach ($p in @("/robots.txt","/sitemap.xml")) { Check "exists $p" "$BaseUrl$p" 200 "$BaseUrl$p" 0 }

$rows | Export-Csv (Join-Path $PSScriptRoot "test-results.csv") -NoTypeInformation -Encoding utf8

Write-Host "`n=============================================" -ForegroundColor Cyan
Write-Host ("  PASSED {0}   FAILED {1}   WARNINGS {2}" -f $pass,$fail,$warn) -ForegroundColor $(if($fail -eq 0){"Green"}else{"Red"})
Write-Host "  Detail: test-results.csv"
Write-Host "=============================================`n"
if ($fail -gt 0) { exit 1 }
