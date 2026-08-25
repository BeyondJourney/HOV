# ============================================================================
#  Pre-cutover redirect verification
#  Usage:  .\05_verify-redirects.ps1 -BaseUrl "https://staging.houseofvacation.com"
#
#  Checks every URL from the audit and FAILS the build if it finds:
#    - a 404 on a URL that must survive
#    - a 302 anywhere (must be 301)
#    - a redirect chain (more than one hop)
#    - a URL that should redirect but returns 200
# ============================================================================
param(
    [string]$BaseUrl = "https://houseofvacation.com"
)

$ErrorActionPreference = "Continue"
$BaseUrl = $BaseUrl.TrimEnd('/')

# --- URLs that MUST return 200 -------------------------------------------
$mustBe200 = @(
    "/", "/mice-company-in-delhi/", "/mice-company-in-noida/",
    "/mice-company-in-gurugram/", "/corporate-travel-agency-in-mumbai/",
    "/corporate-travel-agency-in-bangalore/", "/corporate-event-planners-in-pune/",
    "/contact-us/", "/about-company/", "/blog/",
    "/wp-content/uploads/2025/07/MICE-3.jpg"
)

# --- URLs that MUST 301, and where to ------------------------------------
$mustRedirect = @{
    "/about-company"                        = "/about-company/"
    "/About-Company/"                       = "/about-company/"
    "/category/uncategorized/"              = "/blog/"
    "/hello-world/"                         = "/blog/"
    "/new-blog/"                            = "/blog/"
    "/author/essenceofnature43gmail-com/"   = "/blog/"
    "/feed/"                                = "/blog/"
    "/index.php"                            = "/"
    "/page/2/"                              = "/"
    "/2024/"                                = "/"
    "/wp-login.php"                         = "/"
    "/sitemap_index.xml"                    = "/sitemap.xml"
}

$pass = 0; $fail = 0
$results = @()

function Get-Hops($url) {
    $hops = @()
    $current = $url
    for ($i = 0; $i -lt 8; $i++) {
        try {
            $req = [Net.HttpWebRequest]::Create($current)
            $req.AllowAutoRedirect = $false
            $req.UserAgent = "SEO-Migration-Verifier/1.0"
            $req.Timeout = 30000
            $resp = $req.GetResponse()
            $code = [int]$resp.StatusCode
            $loc = $resp.Headers["Location"]
            $resp.Close()
        } catch [Net.WebException] {
            if ($_.Exception.Response) {
                $r = $_.Exception.Response
                $code = [int]$r.StatusCode
                $loc = $r.Headers["Location"]
            } else { $hops += @{ Code = "ERR"; Url = $current }; break }
        }
        $hops += @{ Code = $code; Url = $current }
        if ($code -ge 300 -and $code -lt 400 -and $loc) {
            if ($loc -notmatch '^https?://') {
                $u = [Uri]$current
                $loc = "$($u.Scheme)://$($u.Host)$loc"
            }
            $current = $loc
        } else { break }
    }
    return $hops
}

Write-Host "`n=== MUST RETURN 200 ===" -ForegroundColor Cyan
foreach ($p in $mustBe200) {
    $hops = Get-Hops "$BaseUrl$p"
    $final = $hops[-1].Code
    $ok = ($final -eq 200 -and $hops.Count -eq 1)
    if ($ok) { $pass++; Write-Host "  PASS  $p" -ForegroundColor Green }
    else {
        $fail++
        $trail = ($hops | ForEach-Object { $_.Code }) -join " -> "
        Write-Host "  FAIL  $p  [$trail]" -ForegroundColor Red
    }
    $results += [pscustomobject]@{Check="must200"; Url=$p; Result=$(if($ok){"PASS"}else{"FAIL"}); Hops=$hops.Count; Final=$final}
}

Write-Host "`n=== MUST 301 TO EXPECTED TARGET ===" -ForegroundColor Cyan
foreach ($p in $mustRedirect.Keys) {
    $expected = "$BaseUrl$($mustRedirect[$p])"
    $hops = Get-Hops "$BaseUrl$p"
    $firstCode = $hops[0].Code
    $finalUrl = $hops[-1].Url
    $redirectHops = ($hops | Where-Object { $_.Code -ge 300 -and $_.Code -lt 400 }).Count

    $isPermanent = ($firstCode -eq 301)
    $noChain = ($redirectHops -le 1)
    $rightTarget = ($finalUrl.TrimEnd('/') -eq $expected.TrimEnd('/'))
    $ok = $isPermanent -and $noChain -and $rightTarget

    if ($ok) { $pass++; Write-Host "  PASS  $p -> $($mustRedirect[$p])" -ForegroundColor Green }
    else {
        $fail++
        $why = @()
        if (-not $isPermanent) { $why += "not 301 (got $firstCode)" }
        if (-not $noChain)     { $why += "CHAIN: $redirectHops hops" }
        if (-not $rightTarget) { $why += "landed on $finalUrl" }
        Write-Host "  FAIL  $p  [$($why -join '; ')]" -ForegroundColor Red
    }
    $results += [pscustomobject]@{Check="must301"; Url=$p; Result=$(if($ok){"PASS"}else{"FAIL"}); Hops=$redirectHops; Final=$finalUrl}
}

Write-Host "`n=== MUST RETURN A REAL 404 ===" -ForegroundColor Cyan
foreach ($p in @("/this-page-never-existed-xyz/", "/random-junk-url/")) {
    $hops = Get-Hops "$BaseUrl$p"
    $final = $hops[-1].Code
    $ok = ($final -eq 404 -or $final -eq 410)
    if ($ok) { $pass++; Write-Host "  PASS  $p returns $final" -ForegroundColor Green }
    else {
        $fail++
        Write-Host "  WARN  $p returns $final (soft-404 risk if 200/301)" -ForegroundColor Yellow
    }
    $results += [pscustomobject]@{Check="must404"; Url=$p; Result=$(if($ok){"PASS"}else{"WARN"}); Hops=$hops.Count; Final=$final}
}

$results | Export-Csv "verify-results.csv" -NoTypeInformation -Encoding utf8

Write-Host "`n============================================" -ForegroundColor Cyan
Write-Host "  PASSED: $pass    FAILED: $fail" -ForegroundColor $(if ($fail -eq 0) { "Green" } else { "Red" })
Write-Host "  Detail written to verify-results.csv"
Write-Host "============================================`n"

if ($fail -gt 0) { exit 1 }
