# ============================================================================
#  serve-local.ps1 - preview the staging build in a browser
#
#  A minimal static file server. No PHP, Node or Python needed.
#
#  Usage:  .\serve-local.ps1            then open http://localhost:8080/
#          .\serve-local.ps1 -Port 9000
#
#  LIMITS (important):
#   * .htaccess is NOT applied - no redirects, no HTTPS/www canonicalisation.
#     Those must be tested on Hostinger with test-live.ps1.
#   * mail.php will NOT execute - PHP is not installed on this machine.
#     The form will download the file instead of sending. Test it on staging.
#   * Clean URLs DO work: /about-company/ serves about-company/index.html,
#     which is exactly how Apache DirectoryIndex behaves.
# ============================================================================
param([int]$Port = 8080)

$Deploy = Join-Path $PSScriptRoot "_deploy\public_html"
if (-not (Test-Path $Deploy)) { Write-Host "Staging not built. Run build-deploy.ps1 first." -ForegroundColor Red; exit 1 }

$mime = @{
    ".html"="text/html; charset=utf-8"; ".css"="text/css; charset=utf-8"
    ".js"="application/javascript; charset=utf-8"; ".json"="application/json"
    ".png"="image/png"; ".jpg"="image/jpeg"; ".jpeg"="image/jpeg"; ".gif"="image/gif"
    ".svg"="image/svg+xml"; ".webp"="image/webp"; ".ico"="image/x-icon"
    ".woff"="font/woff"; ".woff2"="font/woff2"; ".mp4"="video/mp4"
    ".xml"="application/xml"; ".txt"="text/plain; charset=utf-8"; ".php"="text/plain; charset=utf-8"
}

$listener = New-Object System.Net.HttpListener
$listener.Prefixes.Add("http://localhost:$Port/")
try { $listener.Start() }
catch { Write-Host "Could not bind port $Port. Try another with -Port." -ForegroundColor Red; exit 1 }

Write-Host ""
Write-Host "  House of Vacation - local preview" -ForegroundColor Cyan
Write-Host "  ---------------------------------"
Write-Host "  Serving : $Deploy"
Write-Host "  URL     : http://localhost:$Port/" -ForegroundColor Green
Write-Host ""
Write-Host "  NOT simulated here: .htaccess redirects, PHP execution." -ForegroundColor Yellow
Write-Host "  Press Ctrl+C to stop." -ForegroundColor DarkGray
Write-Host ""

try {
    while ($listener.IsListening) {
        $ctx = $listener.GetContext()
        # Per-request try/catch: one bad request must never stop the server.
        try {
            $req = $ctx.Request
            $res = $ctx.Response
            $path = [System.Uri]::UnescapeDataString($req.Url.AbsolutePath)
            $isHead = ($req.HttpMethod -eq 'HEAD')

            # Resolve like Apache: exact file, else folder/index.html
            $rel  = $path.TrimStart('/').Replace('/', '\')
            $file = Join-Path $Deploy $rel
            if ($path.EndsWith('/') -or -not (Test-Path $file -PathType Leaf)) {
                $idx = Join-Path (Join-Path $Deploy $rel) "index.html"
                if (Test-Path $idx -PathType Leaf) { $file = $idx }
            }

            if (Test-Path $file -PathType Leaf) {
                $ext = [System.IO.Path]::GetExtension($file).ToLower()
                $res.ContentType = if ($mime.ContainsKey($ext)) { $mime[$ext] } else { "application/octet-stream" }
                $bytes = [System.IO.File]::ReadAllBytes($file)
                $res.StatusCode = 200
                $code = 200
            } else {
                $nf = Join-Path $Deploy "404.html"
                $res.StatusCode = 404
                $res.ContentType = "text/html; charset=utf-8"
                $bytes = if (Test-Path $nf) { [System.IO.File]::ReadAllBytes($nf) } else { [Text.Encoding]::UTF8.GetBytes("404") }
                $code = 404
            }

            $res.ContentLength64 = $bytes.Length
            # A HEAD response carries headers only - writing a body throws.
            if (-not $isHead) { $res.OutputStream.Write($bytes, 0, $bytes.Length) }
            $res.OutputStream.Close()

            $colour = if ($code -eq 200) { "DarkGray" } else { "Yellow" }
            Write-Host ("  {0}  {1}" -f $code, $path) -ForegroundColor $colour
        }
        catch {
            Write-Host ("  ERR {0}" -f $_.Exception.Message) -ForegroundColor Red
            try { $ctx.Response.Close() } catch { }
        }
    }
} finally {
    $listener.Stop(); $listener.Close()
    Write-Host "`n  Server stopped." -ForegroundColor Cyan
}
