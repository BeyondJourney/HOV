# add-preloader.ps1 - inserts the HOV preloader markup after the skip link on
# every page. Styles: assets/css/hov-theme.css §17b. Behaviour:
# assets/js/hov-theme.js §6. Character: assets/img/mascot/hov-mascot.png.
#
#   .\add-preloader.ps1            add where missing (idempotent)
#   .\add-preloader.ps1 -Refresh   rebuild the block on every page - run this
#                                  after dropping hov-mascot.png into
#                                  assets/img/mascot so the pages reference it
#
# While the mascot file is absent the block carries .hov-pl--nomascot and no
# mascot <img>, so qa-staging.ps1 does not see a dangling asset reference and
# the brand mark takes the stage.
param(
    [string]$Root = (Split-Path -Parent (Split-Path -Parent $PSScriptRoot)),
    [switch]$Refresh
)
$ErrorActionPreference = 'Stop'
$utf8 = New-Object Text.UTF8Encoding $false
$anchor = '<a href="#hov-main" class="hov-skip">Skip to content</a>'
$hasMascot = Test-Path (Join-Path $Root 'assets\img\mascot\hov-mascot.png')

$mascotImg = if ($hasMascot) {
    '                <img class="hov-pl-mascot" src="assets/img/mascot/hov-mascot.png" alt="" width="420" height="560" decoding="async" fetchpriority="high" onerror="this.closest(''.hov-preloader'').classList.add(''hov-pl--nomascot'')">' + "`n"
} else { '' }
$rootClass = if ($hasMascot) { 'hov-preloader' } else { 'hov-preloader hov-pl--nomascot' }

$snippet = @"
    <!-- preloader: plays once per visit (hov-theme.css section 17b, hov-theme.js section 6); preview with ?hov-pl=hold -->
    <div class="$rootClass" id="hov-preloader" role="status" aria-live="polite" aria-label="Loading House of Vacation">
        <div class="hov-pl-stage">
            <svg class="hov-pl-path" viewBox="0 0 520 300" aria-hidden="true" focusable="false">
                <circle class="hov-pl-ring" cx="260" cy="200" r="128"/>
                <path class="hov-pl-arc" d="M30 230 C 140 40, 380 40, 490 230"/>
                <circle class="hov-pl-dot" cx="30" cy="230" r="5"/>
                <circle class="hov-pl-dot" cx="490" cy="230" r="5"/>
                <g class="hov-pl-plane">
                    <path d="M18 0 L7 -3 L-6 -11 L-10 -10 L-3 -2 L-11 -1 L-15 -5 L-18 -4 L-15 0 L-18 4 L-15 5 L-11 1 L-3 2 L-10 10 L-6 11 L7 3 Z"/>
                    <animateMotion dur="4.6s" repeatCount="indefinite" rotate="auto" path="M30 230 C 140 40, 380 40, 490 230"/>
                </g>
            </svg>
            <div class="hov-pl-figure">
$mascotImg                <span class="hov-pl-shadow" aria-hidden="true"></span>
                <img class="hov-pl-mark" src="assets/img/Logo-white-HOV.png" alt="" width="200" height="60" aria-hidden="true">
            </div>
        </div>
        <p class="hov-pl-caption">Preparing your journey<span class="hov-pl-dots" aria-hidden="true"><i></i><i></i><i></i></span></p>
        <div class="hov-pl-bar" aria-hidden="true"><i></i></div>
    </div>
    <script>try{var q=location.search;document.documentElement.classList.add((sessionStorage.getItem('hov-pl')&&!/hov-pl=(play|hold)/.test(q))?'hov-pl-skip':'hov-pl-active')}catch(e){document.documentElement.classList.add('hov-pl-active')}</script>
"@

$blockRx = [regex]'(?s)(\r?\n)+[ \t]*<!-- preloader: plays once per visit.*?hov-pl-active''\)\}</script>'

$pages = Get-ChildItem (Join-Path $Root '*.html')
$added = 0; $refreshed = 0
foreach ($f in $pages) {
    $bytes = [IO.File]::ReadAllBytes($f.FullName)
    $bom = ($bytes.Length -ge 3 -and $bytes[0] -eq 0xEF -and $bytes[1] -eq 0xBB -and $bytes[2] -eq 0xBF)
    $t = [IO.File]::ReadAllText($f.FullName)
    $present = $t.Contains('id="hov-preloader"')
    if ($present -and -not $Refresh) { continue }
    if ($present) {
        $t2 = $blockRx.Replace($t, '', 1)
        if ($t2 -eq $t) { "SKIP {0} (block not recognised)" -f $f.Name; continue }
        $t = $t2; $refreshed++
    } else { $added++ }
    $i = $t.IndexOf($anchor)
    if ($i -lt 0) { "SKIP {0} (no skip link)" -f $f.Name; continue }
    $nl = if ($t.Contains("`r`n")) { "`r`n" } else { "`n" }
    $insertAt = $i + $anchor.Length
    $block = ($snippet -replace "`r`n", "`n") -replace "`n", $nl
    $t = $t.Substring(0, $insertAt) + $nl + $nl + $block + $t.Substring($insertAt)
    $enc = if ($bom) { New-Object Text.UTF8Encoding $true } else { $utf8 }
    [IO.File]::WriteAllText($f.FullName, $t, $enc)
}
"mascot file present: $hasMascot | added: $added | refreshed: $refreshed | pages: $($pages.Count)"
