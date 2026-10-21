# transform-services.ps1 - restructure the ten service pages (idempotent)
param(
    [string]$Root = 'D:\Projects\HOUSE OF VACATION INDIA PVT LTD\HOV'
)
$ErrorActionPreference = 'Stop'
$utf8 = New-Object Text.UTF8Encoding $false
$pages = 'adventure-group','conferences-event','corporate-celebration','corporate-travel-consultancy','corporate-travel','customized-group','destination-management','incentive','mice-event','offsite-events'

function Norm([string]$s) { return (([System.Net.WebUtility]::HtmlDecode(($s -replace '<[^>]+>', ''))) -replace '\s+', ' ').Trim() }

# index just past the </div> that closes the <div starting at $start
function Find-DivEnd([string]$t, [int]$start) {
    $depth = 0
    $m = ([regex]'<div\b|</div>').Match($t, $start)
    while ($m.Success) {
        if ($m.Value -eq '</div>') { $depth--; if ($depth -eq 0) { return $m.Index + 6 } } else { $depth++ }
        $m = $m.NextMatch()
    }
    throw "unbalanced <div> at $start"
}

# text (before the first <h4 / list) and aside (from there on)
function Split-TextAside([string]$inner) {
    $m = [regex]::Match($inner, '<h4\b')
    if (-not $m.Success) { $m = [regex]::Match($inner, '<div class="(service-list|hov-list)"') }
    if (-not $m.Success) { return @($inner, '') }
    return @($inner.Substring(0, $m.Index), $inner.Substring($m.Index))
}

function Build-Split([string]$wrapperClass, [string]$inner, [string]$nl) {
    $parts = Split-TextAside $inner
    $text = $parts[0].Trim()
    $aside = $parts[1].Trim()
    $out = '<div class="' + $wrapperClass + ' hov-svc-split">' + $nl + '        <div class="hov-svc-text">' + $nl + '        ' + $text + $nl + '        </div>'
    if ($aside) { $out += $nl + '        <aside class="hov-svc-aside">' + $nl + '        ' + $aside + $nl + '        </aside>' }
    $out += $nl + '    </div>'
    return $out
}

$tidyH = [System.Text.RegularExpressions.MatchEvaluator]{ param($m) $m.Groups[1].Value + ($m.Groups[2].Value -replace '\s+', ' ').Trim() + $m.Groups[3].Value }

foreach ($n in $pages) {
    $path = Join-Path $Root "$n.html"
    $bytes = [IO.File]::ReadAllBytes($path)
    $bom = ($bytes.Length -ge 3 -and $bytes[0] -eq 0xEF -and $bytes[1] -eq 0xBB -and $bytes[2] -eq 0xBF)
    $t = [IO.File]::ReadAllText($path)
    if ($t.Contains('hov-svc-split')) { "SKIP $n (already transformed)"; continue }
    $nl = if ($t.Contains("`r`n")) { "`r`n" } else { "`n" }
    $log = @()

    # 1. the 3.7 KB inline stylesheet duplicated on every service page
    $rx = [regex]'(?s)<style>\s*\.service-detail\{.*?</style>[ \t]*\r?\n?'
    $before = $t.Length; $t = $rx.Replace($t, '', 1); if ($t.Length -ne $before) { $log += 'inline css removed' }

    # 2. wrong brand in the copy
    $c = ([regex]::Matches($t, 'Corporate-Trip\.com')).Count
    if ($c) { $t = $t -replace 'Corporate-Trip\.com', 'House of Vacation'; $log += "brand x$c" }

    # service name from the breadcrumb
    $crumbs = [regex]::Matches([regex]::Match($t, '(?s)<ul class="breadcumb-menu">(.*?)</ul>').Groups[1].Value, '(?s)<li>(.*?)</li>') | ForEach-Object { Norm $_.Groups[1].Value }
    $name = $crumbs[-1]
    $nameHtml = [System.Net.WebUtility]::HtmlEncode($name)

    # 3. overview block
    $sdStart = $t.IndexOf('<section class="service-detail">')
    $sdEnd = $t.IndexOf('</section>', $sdStart) + 10
    $sd = $t.Substring($sdStart, $sdEnd - $sdStart)

    $sd = [regex]::Replace($sd, '(?s)(<h2>)(.*?)(</h2>)', $tidyH)
    $sd = [regex]::Replace($sd, '(?s)(<h3>)(.*?)(</h3>)', $tidyH)

    $h2 = Norm ([regex]::Match($sd, '(?s)<div class="service-heading">\s*<h2>(.*?)</h2>').Groups[1].Value)
    $h3m = [regex]::Match($sd, '(?s)(<div class="content-left">\s*)<h3>(.*?)</h3>\s*')
    if ($h3m.Success -and ((Norm $h3m.Groups[2].Value) -eq $h2)) {
        $sd = $sd.Remove($h3m.Index + $h3m.Groups[1].Length, $h3m.Length - $h3m.Groups[1].Length)
        $log += 'duplicate h3 removed'
    }

    # eyebrow above the h2
    $sd = [regex]::Replace($sd, '(<div class="service-heading">\s*)(<h2>)', ('$1<span class="hov-eyebrow">' + $nameHtml + '</span>' + $nl + '            $2'), 1)

    # actions at the end of the heading block
    $actions = '<div class="hov-svc-actions">' + $nl +
               '                <a href="contact.html" class="th-btn hov-btn-primary th-icon">Request a Proposal</a>' + $nl +
               '                <a href="tel:+919220470800" class="hov-call-link"><i class="fas fa-phone-alt" aria-hidden="true"></i><span>+91 92204 70800</span></a>' + $nl +
               '            </div>' + $nl + '        '
    $hs = $sd.IndexOf('<div class="service-heading">'); $he = Find-DivEnd $sd $hs
    $sd = $sd.Insert($he - 6, $actions)

    # image alt (was "Incentive Travel" on eight of the ten pages)
    $sd = [regex]::Replace($sd, '(<div class="content-right">\s*<img[^>]*?)alt="[^"]*"', ('$1alt="' + $nameHtml + ' - House of Vacation"'), 1)

    # move the image up beside the heading
    $crs = $sd.IndexOf('<div class="content-right">'); $cre = Find-DivEnd $sd $crs
    $cr = $sd.Substring($crs, $cre - $crs)
    $sd = $sd.Remove($crs, $cre - $crs)
    $hs = $sd.IndexOf('<div class="service-heading">'); $he = Find-DivEnd $sd $hs
    $sd = $sd.Insert($he, $nl + '            ' + $cr + $nl + '        </div>')
    $sd = $sd.Insert($hs, '<div class="hov-svc-overview">' + $nl + '            ')
    $t = $t.Substring(0, $sdStart) + $sd + $t.Substring($sdEnd)

    # 4. travel-service sections -> text | aside
    $pos = 0; $k = 0
    while (($s = $t.IndexOf('<section class="hov-travel-service">', $pos)) -ge 0) {
        $cs = $t.IndexOf('<div class="container">', $s); $ce = Find-DivEnd $t $cs
        $inner = $t.Substring($cs + 23, ($ce - 6) - ($cs + 23))
        $inner = [regex]::Replace($inner, '(?s)(<h2>)(.*?)(</h2>)', $tidyH)
        $inner = [regex]::Replace($inner, '(?s)(<h4>)(.*?)(</h4>)', $tidyH)
        $new = Build-Split 'container' $inner $nl
        $t = $t.Substring(0, $cs) + $new + $t.Substring($ce)
        $pos = $cs + $new.Length; $k++
    }
    $log += "travel sections x$k"

    # 5. content blocks -> text | aside
    $pos = 0; $k = 0
    while (($bs = $t.IndexOf('<div class="hov-block">', $pos)) -ge 0) {
        $be = Find-DivEnd $t $bs
        $inner = $t.Substring($bs + 23, ($be - 6) - ($bs + 23))
        $inner = [regex]::Replace($inner, '(?s)(<h2>)(.*?)(</h2>)', $tidyH)
        $inner = [regex]::Replace($inner, '(?s)(<h4>)(.*?)(</h4>)', $tidyH)
        $new = Build-Split 'hov-block' $inner $nl
        $t = $t.Substring(0, $bs) + $new + $t.Substring($be)
        $pos = $bs + $new.Length; $k++
    }
    $log += "blocks x$k"

    $enc = if ($bom) { New-Object Text.UTF8Encoding $true } else { $utf8 }
    [IO.File]::WriteAllText($path, $t, $enc)
    "{0,-30} {1}" -f $n, ($log -join ', ')
}
