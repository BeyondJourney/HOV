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

$script:DimCache = @{}

function Get-ImageDimensions {
    <#
      Reads real pixel dimensions from an image file so width/height can be
      written into the markup. Without these the browser cannot reserve space
      and every image causes layout shift (a Core Web Vitals penalty).
      Returns $null when the size cannot be determined.
    #>
    param([string]$FullPath)

    if ($script:DimCache.ContainsKey($FullPath)) { return $script:DimCache[$FullPath] }
    $result = $null

    try {
        if ($FullPath -match '\.svg$') {
            # SVG: prefer explicit width/height, else derive from viewBox.
            $svg = [System.Text.Encoding]::UTF8.GetString([System.IO.File]::ReadAllBytes($FullPath))
            if ($svg -match '(?is)<svg[^>]*\swidth="(\d+(?:\.\d+)?)[^"]*"[^>]*\sheight="(\d+(?:\.\d+)?)') {
                $result = @{ W = [int][double]$matches[1]; H = [int][double]$matches[2] }
            } elseif ($svg -match '(?is)viewBox="\s*[\d.-]+\s+[\d.-]+\s+([\d.]+)\s+([\d.]+)') {
                $result = @{ W = [int][double]$matches[1]; H = [int][double]$matches[2] }
            }
        } else {
            Add-Type -AssemblyName System.Drawing -ErrorAction SilentlyContinue
            $img = [System.Drawing.Image]::FromFile($FullPath)
            $result = @{ W = $img.Width; H = $img.Height }
            $img.Dispose()
        }
    } catch { $result = $null }

    $script:DimCache[$FullPath] = $result
    return $result
}

function Repair-Images {
    <#
      Three image fixes:
        1. width/height from the real file  -> removes layout shift (CLS)
        2. alt text derived from the filename where alt="" on a content image
        3. decorative icons/logos keep alt="" but gain role="presentation"
    #>
    param([string]$Html, [string]$DeployRoot)

    # NOTE: attribute patterns use (?:^|\s) - anchoring on \s alone silently
    # skips any tag whose FIRST attribute is the one being matched.
    return [regex]::Replace($Html, '(?is)<img\s([^>]*?)/?>', {
        param($m)
        $attrs = $m.Groups[1].Value

        # --- source path ---
        if ($attrs -notmatch '(?i)(?:^|\s)src="([^"]+)"') { return $m.Value }
        $src = $matches[1]
        if ($src -match '^(https?:|data:)') { return $m.Value }

        # --- 1. dimensions ---
        if ($attrs -notmatch '(?i)(?:^|\s)width=' -and $attrs -notmatch '(?i)(?:^|\s)height=') {
            $local = Join-Path $DeployRoot ($src.TrimStart('/').Replace('/', '\'))
            if (Test-Path $local -PathType Leaf) {
                $d = Get-ImageDimensions $local
                if ($null -ne $d -and $d.W -gt 0 -and $d.H -gt 0) {
                    $attrs = 'width="' + $d.W + '" height="' + $d.H + '" ' + $attrs
                }
            }
        }

        # --- 2/3. alt text ---
        if ($attrs -match '(?i)(?:^|\s)alt\s*=\s*"\s*"') {
            $file = [System.IO.Path]::GetFileNameWithoutExtension($src)
            $isDecorative = $src -match '/icon/|/shape|/favicons/|menu\.svg|arrow|dot|line|bg-'
            if ($isDecorative) {
                if ($attrs -notmatch 'role=') { $attrs = $attrs + ' role="presentation"' }
            } else {
                # "mice event 2" -> "Mice Event"  (strip counters and separators)
                $alt = $file -replace '[-_]', ' ' -replace '\(\d+\)', '' -replace '\s+\d+$', ''
                $alt = ($alt -replace '\s+', ' ').Trim()
                if ($alt.Length -gt 1) {
                    $alt = (Get-Culture).TextInfo.ToTitleCase($alt.ToLower())
                    $safe = [System.Net.WebUtility]::HtmlEncode("$alt - House of Vacations")
                    $attrs = [regex]::Replace($attrs, '(?i)(?:^|\s)alt\s*=\s*"\s*"', " alt=""$safe""", 1)
                }
            }
        }

        return '<img ' + $attrs.Trim() + '>'
    })
}

function Remove-DeadControls {
    <#
      Strips template controls that are non-functional and confusing:
        * the login / register forms (Tourm e-commerce leftovers). They post to
          mail.php, so a "login" attempt would silently send an enquiry email.
        * anchors with href="" which reload the current page when clicked.
    #>
    param([string]$Html)

    # Login / register forms - identified by the template's misspelled fields.
    $Html = [regex]::Replace($Html,
        '(?is)<form\b(?:(?!</form>).)*?name="(?:pasword|usename|new_email|new_email_confirm)"(?:(?!</form>).)*?</form>',
        '')

    # href="" on a wrapper anchor: unwrap, keep the inner content.
    $Html = [regex]::Replace($Html, '(?is)<a\b[^>]*href=""[^>]*>(.*?)</a>', '${1}')

    return $Html
}

function Repair-FormLabels {
    <#
      Every visible field gets an accessible name. Placeholder text is NOT a
      label - it disappears on focus and screen readers may skip it.
      Adds aria-label derived from the placeholder or the field name.
    #>
    param([string]$Html)

    # \s* after the tag name so a bare <select> (no attributes) still matches.
    return [regex]::Replace($Html, '(?is)<(input|textarea|select)(\s[^>]*?)?/?>', {
        param($m)
        $tag   = $m.Groups[1].Value
        $attrs = $m.Groups[2].Value

        if ($attrs -match '(?i)type="(hidden|submit|button|image)"') { return $m.Value }
        if ($attrs -match '(?i)(?:^|\s)aria-label=')                 { return $m.Value }
        if ($attrs -match '(?i)tabindex="-1"')                       { return $m.Value }  # honeypot

        $name = ''
        if     ($attrs -match '(?i)(?:^|\s)placeholder="([^"]+)"') { $name = $matches[1] }
        elseif ($attrs -match '(?i)(?:^|\s)name="([^"]+)"')        { $name = $matches[1] }
        elseif ($attrs -match '(?i)(?:^|\s)id="([^"]+)"')          { $name = $matches[1] }
        elseif ($tag -eq 'select')                                 { $name = 'Select an option' }
        if ($name -eq '') { return $m.Value }

        $clean = ($name -replace '[-_\[\]]', ' ' -replace '\.\.\.$', '' -replace '\s+', ' ').Trim()
        $clean = (Get-Culture).TextInfo.ToTitleCase($clean.ToLower())
        $safe  = [System.Net.WebUtility]::HtmlEncode($clean)
        return "<$tag aria-label=""$safe""$attrs>"
    })
}

function Add-StructuredData {
    <#
      Injects JSON-LD. The old WordPress site had Organization schema whose name
      was the bare string "houseofvacation.com" with no address or phone, no
      LocalBusiness on any service page, and no FAQPage despite FAQs on 7 pages.
    #>
    param([string]$Html, [string]$PageUrl, [string]$PageTitle, [string]$PageDesc)

    if ($Html -match 'application/ld\+json') { return $Html }

    $org = @'
{
  "@context": "https://schema.org",
  "@type": ["TravelAgency","Organization"],
  "@id": "https://houseofvacation.com/#organization",
  "name": "House of Vacations India Pvt Ltd",
  "alternateName": "HOV",
  "url": "https://houseofvacation.com/",
  "logo": "https://houseofvacation.com/assets/img/Logo-HOV.png",
  "image": "https://houseofvacation.com/assets/img/Logo-HOV.png",
  "description": "MICE company and corporate travel agency in India, delivering meetings, incentives, conferences and exhibitions end to end.",
  "telephone": "+91-9220470800",
  "email": "mice@houseofvacation.com",
  "address": {
    "@type": "PostalAddress",
    "streetAddress": "1st Floor, Office No. 115, Gagandeep Building, Rajendra Nagar",
    "addressLocality": "New Delhi",
    "postalCode": "110008",
    "addressRegion": "Delhi",
    "addressCountry": "IN"
  },
  "openingHoursSpecification": {
    "@type": "OpeningHoursSpecification",
    "dayOfWeek": ["Monday","Tuesday","Wednesday","Thursday","Friday","Saturday"],
    "opens": "09:00",
    "closes": "18:00"
  },
  "areaServed": [
    {"@type":"City","name":"Delhi"},{"@type":"City","name":"Noida"},
    {"@type":"City","name":"Gurugram"},{"@type":"City","name":"Mumbai"},
    {"@type":"City","name":"Bangalore"},{"@type":"City","name":"Pune"},
    {"@type":"Country","name":"India"}
  ],
  "sameAs": [
    "https://facebook.com/houseofvacations/",
    "https://instagram.com/houseofvacations_/",
    "https://x.com/houseofvacation",
    "https://linkedin.com/company/house-of-vacations-india-pvt-ltd/",
    "https://youtube.com/@HouseofVacations"
  ]
}
'@

    $encT = ($PageTitle -replace '"', '\"')
    $encD = ($PageDesc  -replace '"', '\"')
    $webpage = @"
{
  "@context": "https://schema.org",
  "@type": "WebPage",
  "@id": "$PageUrl#webpage",
  "url": "$PageUrl",
  "name": "$encT",
  "description": "$encD",
  "isPartOf": { "@id": "https://houseofvacation.com/#website" },
  "about": { "@id": "https://houseofvacation.com/#organization" },
  "inLanguage": "en-IN"
}
"@

    $block = "`n<script type=""application/ld+json"">$org</script>`n" +
             "<script type=""application/ld+json"">$webpage</script>`n"

    return [regex]::Replace($Html, '(?is)(</head>)', "$block`$1", 1)
}

function Add-Breadcrumbs {
    <# BreadcrumbList with the real trail. The old site emitted only "Home". #>
    param([string]$Html, [string]$PageUrl, [string]$PageName)

    if ($PageUrl -eq 'https://houseofvacation.com/') { return $Html }
    $encN = ($PageName -replace '"', '\"')
    $bc = @"
{
  "@context": "https://schema.org",
  "@type": "BreadcrumbList",
  "itemListElement": [
    { "@type": "ListItem", "position": 1, "name": "Home", "item": "https://houseofvacation.com/" },
    { "@type": "ListItem", "position": 2, "name": "$encN", "item": "$PageUrl" }
  ]
}
"@
    return [regex]::Replace($Html, '(?is)(</head>)', "<script type=""application/ld+json"">$bc</script>`n`$1", 1)
}

function Repair-Quality {
    <#
      Build-time quality fixes. Applied to every page.
      Source files are never touched - all of this happens in memory.

        1. lang="zxx" -> "en-IN"   (zxx means "no linguistic content")
        2. loading="lazy" + decoding="async" on images
        3. rel="noopener noreferrer" on external links (tabnabbing)
        4. remove the dead site-wide search form (action="#")
        5. add a skip-to-content link
        6. honeypot + source_page field on every mail.php form
    #>
    param([string]$Html)

    # --- 1. Language ---------------------------------------------------------
    $Html = [regex]::Replace($Html, '(?i)(<html[^>]*\slang=")[^"]*(")', '${1}en-IN${2}', 1)

    # --- 2. Lazy-load images (skip the first two - they are usually above fold)
    $script:imgSeen = 0
    $Html = [regex]::Replace($Html, '(?is)<img\s([^>]*)>', {
        param($m)
        $attrs = $m.Groups[1].Value
        $script:imgSeen++
        if ($attrs -match '(?i)\bloading\s*=') { return $m.Value }
        if ($script:imgSeen -le 2) { return $m.Value }          # keep LCP image eager
        return '<img loading="lazy" decoding="async" ' + $attrs + '>'
    })

    # --- 3. External links: rel="noopener noreferrer" ------------------------
    $Html = [regex]::Replace($Html, '(?is)<a\s([^>]*href="https?://(?!(?:www\.)?houseofvacation\.com)[^"]*"[^>]*)>', {
        param($m)
        $attrs = $m.Groups[1].Value
        if ($attrs -match '(?i)\brel\s*=') {
            if ($attrs -match '(?i)noopener') { return $m.Value }
            return '<a ' + ([regex]::Replace($attrs, '(?i)(rel=")', '${1}noopener noreferrer ', 1)) + '>'
        }
        return '<a rel="noopener noreferrer" ' + $attrs + '>'
    })

    # --- 4. Remove the dead search form (action="#", does nothing) -----------
    $Html = [regex]::Replace($Html, '(?is)<form[^>]*action="#"[^>]*>.*?</form>', '')

    # --- 5. Skip-to-content link --------------------------------------------
    if ($Html -notmatch '(?i)class="hov-skip"') {
        $skip = '<a href="#hov-main" class="hov-skip">Skip to content</a>' +
                '<style>.hov-skip{position:absolute;left:-9999px;top:0;z-index:99999;padding:10px 16px;' +
                'background:#1f5f8b;color:#fff;text-decoration:none}' +
                '.hov-skip:focus{left:0}</style>'
        $Html = [regex]::Replace($Html, '(?is)(<body[^>]*>)', "`$1`n$skip", 1)
    }

    # --- 6. Harden every mail.php form --------------------------------------
    $Html = [regex]::Replace($Html, '(?is)(<form[^>]*action="[^"]*mail\.php"[^>]*>)', {
        param($m)
        $open = $m.Groups[1].Value
        $extra = "`n" +
          '<div style="position:absolute;left:-9999px;" aria-hidden="true">' +
          '<label>Website<input type="text" name="website" tabindex="-1" autocomplete="off"></label></div>' + "`n" +
          '<input type="hidden" name="source_page" value="">'
        return $open + $extra
    })

    return $Html
}

function Add-MainLandmark {
    <# Wraps the primary content region in <main id="hov-main"> for the skip link. #>
    param([string]$Html)
    if ($Html -match '(?i)<main[\s>]') { return $Html }

    # Insert <main> after the header and close it before the footer.
    $hEnd = [regex]::Match($Html, '(?is)</header\s*>')
    $fSt  = [regex]::Match($Html, '(?is)<footer[\s>]')
    if (-not $hEnd.Success -or -not $fSt.Success -or $fSt.Index -le $hEnd.Index) { return $Html }

    $open  = $hEnd.Index + $hEnd.Length
    return $Html.Substring(0, $open) +
           "`n<main id=""hov-main"">`n" +
           $Html.Substring($open, $fSt.Index - $open) +
           "`n</main>`n" +
           $Html.Substring($fSt.Index)
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
