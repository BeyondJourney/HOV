# transform-city.ps1 - compact the six location pages (idempotent)
param(
    [string]$Root = 'D:\Projects\HOUSE OF VACATION INDIA PVT LTD\HOV'
)
$ErrorActionPreference = 'Stop'
$utf8 = New-Object Text.UTF8Encoding $false
$pages = 'mice-company-in-delhi','mice-company-in-noida','mice-company-in-gurugram','corporate-travel-agency-in-mumbai','corporate-travel-agency-in-bangalore','corporate-event-planners-in-pune'

function Norm([string]$s) { return (([System.Net.WebUtility]::HtmlDecode(($s -replace '<[^>]+>', ''))) -replace '\s+', ' ').Trim() }

function Find-DivEnd([string]$t, [int]$start) {
    $depth = 0
    $m = ([regex]'<div\b|</div>').Match($t, $start)
    while ($m.Success) {
        if ($m.Value -eq '</div>') { $depth--; if ($depth -eq 0) { return $m.Index + 6 } } else { $depth++ }
        $m = $m.NextMatch()
    }
    throw "unbalanced <div> at $start"
}

# lists: short items -> chips; "Label: text" items -> definition cards; long runs -> two columns
$listEval = [System.Text.RegularExpressions.MatchEvaluator]{
    param($m)
    $inner = $m.Groups[1].Value
    $items = [regex]::Matches($inner, '(?s)<li>(.*?)</li>') | ForEach-Object { Norm $_.Groups[1].Value }
    if ($items.Count -eq 0) { return $m.Value }
    $max = ($items | ForEach-Object { $_.Length } | Measure-Object -Maximum).Maximum
    $colons = @($items | Where-Object { $_ -match '^[^:]{3,60}:\s' }).Count
    if ($max -le 45 -and $colons -eq 0) {
        return '<ul class="hov-chip-list">' + $inner + '</ul>'
    }
    if ($colons -ge [math]::Ceiling($items.Count * 0.8)) {
        $defs = [regex]::Replace($inner, '(?s)<li>\s*([^:<]{3,60}):\s*(.*?)</li>', '<li><strong>$1</strong>$2</li>')
        return '<ul class="hov-city-list hov-city-list--defs">' + $defs + '</ul>'
    }
    if ($items.Count -ge 4) {
        return '<ul class="hov-city-list hov-city-list--2">' + $inner + '</ul>'
    }
    return $m.Value
}

foreach ($n in $pages) {
    $path = Join-Path $Root "$n.html"
    $bytes = [IO.File]::ReadAllBytes($path)
    $bom = ($bytes.Length -ge 3 -and $bytes[0] -eq 0xEF -and $bytes[1] -eq 0xBB -and $bytes[2] -eq 0xBF)
    $t = [IO.File]::ReadAllText($path)
    if ($t.Contains('hov-city-actions')) { "SKIP $n (already transformed)"; continue }
    $nl = if ($t.Contains("`r`n")) { "`r`n" } else { "`n" }
    $log = @()

    # 1. proposal button at the top, beside the existing call pill
    $btn = '<a href="contact.html" class="th-btn hov-btn-primary th-icon">Request a Proposal</a>'
    if ($t -match '<p class="hov-city-call">') {
        $t = [regex]::Replace($t, '([ \t]*)<p class="hov-city-call">(.*?)</p>', ('$1<div class="hov-city-actions">' + $nl + '$1    ' + $btn + $nl + '$1    <p class="hov-city-call">$2</p>' + $nl + '$1</div>'), 1)
        $log += 'actions (with call pill)'
    } else {
        $is = $t.IndexOf('<section class="hov-city-section hov-city-intro">')
        $bs = $t.IndexOf('<div class="hov-city-body">', $is); $be = Find-DivEnd $t $bs
        $t = $t.Insert($be - 6, '    <div class="hov-city-actions">' + $btn + '</div>' + $nl + '            ')
        $log += 'actions (button only)'
    }

    # 2. card groups: long cards get two columns on desktop
    $pos = 0; $wide = 0
    while (($cs = $t.IndexOf('<div class="hov-city-cards">', $pos)) -ge 0) {
        $ce = Find-DivEnd $t $cs
        $block = $t.Substring($cs, $ce - $cs)
        $ps = [regex]::Matches($block, '(?s)<article class="hov-city-card">.*?<p>(.*?)</p>') | ForEach-Object { (Norm $_.Groups[1].Value).Length }
        $avg = if ($ps.Count) { ($ps | Measure-Object -Average).Average } else { 0 }
        if ($avg -gt 150) {
            $block = $block.Replace('<div class="hov-city-cards">', '<div class="hov-city-cards hov-city-cards--2">')
            $t = $t.Substring(0, $cs) + $block + $t.Substring($ce)
            $wide++
        }
        $pos = $cs + $block.Length
    }
    if ($wide) { $log += "wide cards x$wide" }

    # 3. lists
    $before = $t
    $t = [regex]::Replace($t, '(?s)<ul class="hov-city-list">(.*?)</ul>', $listEval)
    $chips = ([regex]::Matches($t, 'class="hov-chip-list"')).Count - ([regex]::Matches($before, 'class="hov-chip-list"')).Count
    $defs = ([regex]::Matches($t, 'hov-city-list--defs')).Count
    $two = ([regex]::Matches($t, 'hov-city-list--2"')).Count
    $log += "chips x$chips, defs x$defs, 2col x$two"

    # 4. h3 + list pairs side by side
    $pos = 0; $groups = 0
    while (($bs = $t.IndexOf('<div class="hov-city-body">', $pos)) -ge 0) {
        $be = Find-DivEnd $t $bs
        $body = $t.Substring($bs, $be - $bs)
        $pairRx = [regex]'(?s)([ \t]*)<h3>(.*?)</h3>\s*(<ul class="[^"]*">.*?</ul>)'
        if ($pairRx.Matches($body).Count -ge 2) {
            $body = $pairRx.Replace($body, ('$1<div class="hov-city-group">' + $nl + '$1    <h3>$2</h3>' + $nl + '$1    $3' + $nl + '$1</div>'))
            $body = $body.Replace('<div class="hov-city-body">', '<div class="hov-city-body hov-city-body--groups">')
            $t = $t.Substring(0, $bs) + $body + $t.Substring($be)
            $groups++
        }
        $pos = $bs + $body.Length
    }
    if ($groups) { $log += "group sections x$groups" }

    # 5. copy error on the Bangalore page
    if ($t.Contains('Types of MICE Services We Offer in Gujarat')) {
        $t = $t.Replace('Types of MICE Services We Offer in Gujarat', 'Types of MICE Services We Offer in Bangalore')
        $log += 'Gujarat -> Bangalore'
    }

    $enc = if ($bom) { New-Object Text.UTF8Encoding $true } else { $utf8 }
    [IO.File]::WriteAllText($path, $t, $enc)
    "{0,-38} {1}" -f $n, ($log -join ', ')
}
