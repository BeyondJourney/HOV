# ============================================================================
#  lib-extract.ps1 - shared helpers, dot-sourced by build-deploy.ps1
#  Extracts semantic content from the old WordPress/Elementor snapshots and
#  rebuilds it as clean HTML inside the new site template.
# ============================================================================

function Get-DecodedText {
    param([string]$Raw)
    if ($null -eq $Raw) { return "" }
    $t = $Raw -replace '(?is)<(script|style)[^>]*>.*?</\1>', ''
    $t = $t -replace '<[^>]+>', ''
    $t = [System.Net.WebUtility]::HtmlDecode($t)
    return ($t -replace '\s+', ' ').Trim()
}

function Get-PageMeta {
    param([string]$Html)
    $title = if ($Html -match '(?is)<title[^>]*>(.*?)</title>') { Get-DecodedText $matches[1] } else { "" }
    $desc  = if ($Html -match '(?is)<meta[^>]*name="description"[^>]*content="([^"]*)"') { [System.Net.WebUtility]::HtmlDecode($matches[1]).Trim() } else { "" }
    $canon = if ($Html -match '(?is)<link[^>]*rel="canonical"[^>]*href="([^"]*)"') { $matches[1].Trim() } else { "" }
    $ogimg = if ($Html -match '(?is)<meta[^>]*property="og:image"[^>]*content="([^"]*)"') { $matches[1].Trim() } else { "" }
    $h1    = ""
    if ($Html -match '(?is)<h1[^>]*>(.*?)</h1>') { $h1 = Get-DecodedText $matches[1] }
    return [pscustomobject]@{ Title = $title; Description = $desc; Canonical = $canon; OgImage = $ogimg; H1 = $h1 }
}

# Chrome / boilerplate that must never reach the rebuilt page
$script:NoisePatterns = @(
    '^Skip to content', '^Follow us', '^Read More', '^Rate your experience',
    '^Leave a review', '^Give your review', '^Upload', '^Call Now Button',
    '^Type here', '^Save my name', '^Your email address will not be published',
    '^Required fields', '^Previous Post', '^Next Post', '^Leave a Comment',
    '^Cancel Reply', '^Full Name', '^Phone Number', '^Company Name',
    '^Email Address', '^Desired Location', '^Number of Pax', '^Type of Offering',
    '^Additional Deta', '^Click here', '^Get Quote', '^Contact us$', '^Submit',
    '^Home$', '^About$', '^Blog$', '^\d+$', '^Menu$'
)

function Test-IsNoise {
    param([string]$Text)
    if ($Text.Length -lt 3) { return $true }
    # A block this long that still contains page chrome is a container that
    # swallowed the whole document, not real copy.
    if ($Text.Length -gt 400 -and $Text -match 'Skip to content') { return $true }
    foreach ($p in $script:NoisePatterns) { if ($Text -match $p) { return $true } }
    return $false
}

function Get-ContentBlocks {
    <#
      Returns an ordered list of {Tag, Text} for the page's real content.
      Strips chrome, de-duplicates, and drops container elements that
      accidentally matched across nested markup.
    #>
    param([string]$Html)

    $body = $Html
    foreach ($p in @(
        '(?is)<script.*?</script>', '(?is)<style.*?</style>',
        '(?is)<header[^>]*>.*?</header>', '(?is)<footer[^>]*>.*?</footer>',
        '(?is)<nav[^>]*>.*?</nav>', '(?is)<noscript.*?</noscript>',
        '(?is)<form.*?</form>')) { $body = $body -replace $p, '' }

    $blocks = @()
    $seen = @{}

    foreach ($m in [regex]::Matches($body, '(?is)<(h2|h3|h4|p|li)\b[^>]*>(.*?)</\1>')) {
        $tag = $m.Groups[1].Value.ToLower()
        $txt = Get-DecodedText $m.Groups[2].Value

        if (Test-IsNoise $txt) { continue }

        # A list item longer than a paragraph is almost always a wrapper.
        if ($tag -eq 'li' -and $txt.Length -gt 320) { continue }

        $key = "$tag|$txt"
        if ($seen.ContainsKey($key)) { continue }
        $seen[$key] = $true

        $blocks += [pscustomobject]@{ Tag = $tag; Text = $txt }
    }
    return $blocks
}

function ConvertTo-ContentHtml {
    <# Renders extracted blocks as clean semantic HTML, grouping runs of <li>. #>
    param([object[]]$Blocks)

    $sb = New-Object System.Text.StringBuilder
    $inList = $false

    foreach ($b in $Blocks) {
        $safe = [System.Net.WebUtility]::HtmlEncode($b.Text)

        if ($b.Tag -eq 'li') {
            if (-not $inList) { [void]$sb.AppendLine('          <ul class="hov-list">'); $inList = $true }
            [void]$sb.AppendLine("            <li>$safe</li>")
            continue
        }

        if ($inList) { [void]$sb.AppendLine('          </ul>'); $inList = $false }

        switch ($b.Tag) {
            'h2' { [void]$sb.AppendLine("          <h2>$safe</h2>") }
            'h3' { [void]$sb.AppendLine("          <h3>$safe</h3>") }
            'h4' { [void]$sb.AppendLine("          <h4>$safe</h4>") }
            'p'  { [void]$sb.AppendLine("          <p>$safe</p>") }
        }
    }
    if ($inList) { [void]$sb.AppendLine('          </ul>') }

    return $sb.ToString()
}

function Remove-TemplateBranding {
    <#
      Strips the "Tourm" template identity that shipped with the theme:
        - alt="Tourm..."           on logo and content images
        - <meta name="author">     still crediting the template
        - <meta name="keywords">   holding the template's marketing string
      The keywords tag is removed outright; Google has ignored it for years and
      the value here is template boilerplate, not our keywords.
    #>
    param([string]$Html)

    $Html = [regex]::Replace($Html, '(?i)alt="Tourm[^"]*"', 'alt="House of Vacations"')
    $Html = [regex]::Replace($Html, '(?i)<meta\s+name="author"\s+content="[^"]*"\s*/?>',
                             '<meta name="author" content="House of Vacations">')
    $Html = [regex]::Replace($Html, '(?i)\s*<meta\s+name="keywords"\s+content="[^"]*"\s*/?>', '')
    $Html = $Html -replace 'Tourm - Travel & Tour Booking Agency HTML Template', 'House of Vacations'
    return $Html
}

function Repair-Headings {
    <#
      Exactly one <h1> per page.
      Extra H1s (hero carousel slides) are demoted to <h2>. The class attribute
      is kept, so the CSS still targets them and nothing changes visually.
    #>
    param([string]$Html)

    $script:h1Seen = 0
    return [regex]::Replace($Html, '(?is)<(/?)h1(\s[^>]*)?>', {
        param($m)
        $isClose = $m.Groups[1].Value -eq '/'
        $attrs   = $m.Groups[2].Value
        if (-not $isClose) {
            $script:h1Seen++
            if ($script:h1Seen -eq 1) { return $m.Value }
            return "<h2$attrs>"
        } else {
            if ($script:h1Seen -le 1) { return $m.Value }
            return "</h2>"
        }
    })
}

function Set-BreadcrumbTitle {
    <#
      Replaces the template's breadcrumb heading text. Used so a rebuilt city
      page carries its real H1 instead of the shell page's heading.
    #>
    param([string]$Html, [string]$Text)
    $safe = [System.Net.WebUtility]::HtmlEncode($Text)
    return [regex]::Replace($Html,
        '(?is)(<h1[^>]*class="[^"]*breadcumb-title[^"]*"[^>]*>).*?(</h1>)',
        "`${1}$safe`${2}", 1)
}

function Set-SeoMeta {
    <#
      Replaces <title>, meta description and canonical in a page.
      Inserts the tag when it is absent rather than only replacing.
    #>
    param(
        [string]$Html,
        [string]$Title,
        [string]$Description,
        [string]$CanonicalUrl,
        [string]$OgImage = ""
    )

    $encTitle = [System.Net.WebUtility]::HtmlEncode($Title)
    $encDesc  = [System.Net.WebUtility]::HtmlEncode($Description)

    # --- <title>
    if ($Html -match '(?is)<title[^>]*>.*?</title>') {
        $Html = [regex]::Replace($Html, '(?is)<title[^>]*>.*?</title>', "<title>$encTitle</title>", 1)
    } else {
        $Html = [regex]::Replace($Html, '(?is)(<head[^>]*>)', "`$1`n<title>$encTitle</title>", 1)
    }

    # --- meta description
    if ($Html -match '(?is)<meta[^>]*name="description"[^>]*>') {
        $Html = [regex]::Replace($Html, '(?is)<meta[^>]*name="description"[^>]*>',
                "<meta name=""description"" content=""$encDesc"">", 1)
    } else {
        $Html = [regex]::Replace($Html, '(?is)(</title>)',
                "`$1`n<meta name=""description"" content=""$encDesc"">", 1)
    }

    # --- canonical
    if ($Html -match '(?is)<link[^>]*rel="canonical"[^>]*>') {
        $Html = [regex]::Replace($Html, '(?is)<link[^>]*rel="canonical"[^>]*>',
                "<link rel=""canonical"" href=""$CanonicalUrl"">", 1)
    } else {
        $Html = [regex]::Replace($Html, '(?is)(</title>)',
                "`$1`n<link rel=""canonical"" href=""$CanonicalUrl"">", 1)
    }

    # --- Open Graph (kept consistent with title/description)
    $og = @"
<meta property="og:type" content="website">
<meta property="og:site_name" content="House of Vacations">
<meta property="og:url" content="$CanonicalUrl">
<meta property="og:title" content="$encTitle">
<meta property="og:description" content="$encDesc">
"@
    if ($OgImage) { $og += "`n<meta property=""og:image"" content=""$OgImage"">" }
    $og += "`n<meta name=""twitter:card"" content=""summary_large_image"">"

    $Html = [regex]::Replace($Html, '(?is)<meta[^>]*(?:property="og:[^"]*"|name="twitter:[^"]*")[^>]*>\s*', '')
    $Html = [regex]::Replace($Html, '(?is)(<link rel="canonical"[^>]*>)', "`$1`n$og", 1)

    return $Html
}
