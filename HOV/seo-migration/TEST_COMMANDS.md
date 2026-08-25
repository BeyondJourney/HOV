# Exact Test Commands

Two ways to run everything: the automated script, or manual `curl` per requirement 18.

```powershell
cd "HOV\seo-migration"
.\test-live.ps1                                        # production
.\test-live.ps1 -BaseUrl "https://staging.hov.com"     # staging
```

Exits `0` if all hard checks pass, `1` otherwise. Writes `test-results.csv`.

---

## Manual tests

`curl.exe` is built into Windows 11. **Use `curl.exe`, not `curl`** — in PowerShell,
bare `curl` is an alias for `Invoke-WebRequest` and takes different flags.

### 1. HTTP → HTTPS  (expect: 301, ONE hop)

```powershell
curl.exe -sI http://houseofvacation.com/ | findstr /i "HTTP/ Location"
```
```
HTTP/1.1 301 Moved Permanently
Location: https://houseofvacation.com/
```

Count the hops — must be exactly 1:
```powershell
curl.exe -s -o NUL -L -w "hops=%{num_redirects} final=%{url_effective} code=%{http_code}\n" http://houseofvacation.com/
```
```
hops=1 final=https://houseofvacation.com/ code=200
```

### 2. www → non-www  (expect: 301, ONE hop)

```powershell
curl.exe -sI https://www.houseofvacation.com/ | findstr /i "HTTP/ Location"
curl.exe -s -o NUL -L -w "hops=%{num_redirects} final=%{url_effective}\n" https://www.houseofvacation.com/about-company/
```

**The combined worst case** — `http` *and* `www` *and* a deep path. Still one hop:
```powershell
curl.exe -s -o NUL -L -w "hops=%{num_redirects} final=%{url_effective}\n" http://www.houseofvacation.com/about-company/
```
```
hops=1 final=https://houseofvacation.com/about-company/
```
> If this reports `hops=2`, rule 2 in `.htaccess` was split into two rules. Recombine it.

### 3. Old URL → new URL  (expect: 301, ONE hop)

```powershell
$old = @(
  "/about-company", "/category/uncategorized/", "/hello-world/", "/new-blog/",
  "/author/essenceofnature43gmail-com/", "/feed/", "/wp-login.php",
  "/page/2/", "/2024/", "/sitemap_index.xml", "/?no-cache=abc123"
)
foreach ($u in $old) {
  $r = curl.exe -s -o NUL -L -w "%{num_redirects} hop -> %{url_effective} [%{http_code}]" --max-time 20 "https://houseofvacation.com$u"
  "{0,-42} {1}" -f $u, $r
}
```
Every line must read `1 hop` and end `[200]`.

### 4. Missing URL → 404  (must NOT redirect)

```powershell
curl.exe -sI https://houseofvacation.com/this-never-existed-xyz/ | findstr /i "HTTP/"
```
```
HTTP/1.1 404 Not Found
```
> A `301` or `200` here means soft 404s are being created. Check `ErrorDocument`
> and confirm nothing redirects unknown URLs to `/`.

### 5. Image URL → 200  (must NOT redirect)

```powershell
$imgs = @(
  "/wp-content/uploads/2025/07/MICE-3.jpg",
  "/wp-content/uploads/2025/07/MICE-4.jpg",
  "/wp-content/uploads/2025/06/hov-mice-team-before-flight.webp",
  "/wp-content/uploads/2024/12/cropped-Untitled-design-6-210x70.png"
)
foreach ($i in $imgs) {
  $r = curl.exe -s -o NUL -w "%{http_code} redirects=%{num_redirects} type=%{content_type}" --max-time 20 "https://houseofvacation.com$i"
  "{0,-62} {1}" -f $i, $r
}
```
Must be `200 redirects=0`. **Any redirect here breaks `og:image` and Google Images.**

### 6. CSS / JS → 200  (must NOT redirect)

```powershell
foreach ($a in @("/assets/css/style.css","/assets/css/bootstrap.min.css","/assets/js/main.js")) {
  $r = curl.exe -s -o NUL -w "%{http_code} redirects=%{num_redirects} type=%{content_type}" --max-time 20 "https://houseofvacation.com$a"
  "{0,-44} {1}" -f $a, $r
}
```
Must be `200 redirects=0` with the correct MIME type.

### 7. Redirect chain → maximum 1 hop

Full trace of every hop:
```powershell
curl.exe -sIL http://www.houseofvacation.com/about-company | findstr /i "HTTP/ Location"
```
```
HTTP/1.1 301 Moved Permanently
Location: https://houseofvacation.com/about-company
HTTP/1.1 301 Moved Permanently
Location: https://houseofvacation.com/about-company/
HTTP/1.1 200 OK
```
> Two hops is the accepted worst case for `http+www+no-slash` — Apache cannot buffer
> corrections. Anything reaching **3+ hops is a defect**: a rule is pointing at another
> redirect instead of the final target.

Sweep every KEEP URL for accidental redirects:
```powershell
$keep = @("/","/mice-company-in-delhi/","/mice-company-in-noida/","/mice-company-in-gurugram/",
          "/corporate-travel-agency-in-mumbai/","/corporate-travel-agency-in-bangalore/",
          "/corporate-event-planners-in-pune/","/contact-us/","/about-company/","/blog/")
foreach ($u in $keep) {
  $r = curl.exe -s -o NUL -w "%{http_code} redirects=%{num_redirects}" --max-time 20 "https://houseofvacation.com$u"
  "{0,-44} {1}" -f $u, $r
}
```
Every line must be `200 redirects=0`.

### 8. No 302s anywhere

```powershell
$all = $keep + $old
foreach ($u in $all) {
  $out = curl.exe -sIL --max-time 20 "https://houseofvacation.com$u" 2>$null | Select-String "^HTTP/"
  if ($out -match "302|307") { "TEMP REDIRECT FOUND: $u" }
}
"scan complete"
```
Should print only `scan complete`.

### 9. Canonical tag correctness

```powershell
foreach ($u in $keep) {
  $h = (Invoke-WebRequest "https://houseofvacation.com$u" -UseBasicParsing).Content
  $c = if ($h -match '(?is)rel="canonical"[^>]*href="([^"]*)"') { $matches[1] } else { "*** MISSING ***" }
  $ok = if ($c -eq "https://houseofvacation.com$u") { "OK" } else { "MISMATCH" }
  "{0,-44} {1,-9} {2}" -f $u, $ok, $c
}
```
Every line must read `OK`.

### 10. Headers sanity

```powershell
curl.exe -sI https://houseofvacation.com/ | findstr /i "cache-control content-encoding server"
```
- `Cache-Control` must **not** contain `no-store` — that is what generated the
  `?no-cache=` URL explosion on the old site.
- `Content-Encoding: gzip` should be present.

---

## Testing before DNS cutover

Point your machine at the new server without changing public DNS.
Edit `C:\Windows\System32\drivers\etc\hosts` as Administrator:

```
203.0.113.10   houseofvacation.com
203.0.113.10   www.houseofvacation.com
```

Use the real server IP from hPanel. Flush DNS, then run the full suite:

```powershell
ipconfig /flushdns
cd "HOV\seo-migration"
.\test-live.ps1
```

Remove the `hosts` lines when finished.
