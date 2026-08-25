# House of Vacation — SEO Migration Kit

Generated 21 Aug 2026 from a live audit of `houseofvacation.com`.

---

## READ THIS FIRST — hosting constraint

Your current server was fingerprinted as:

| | |
|---|---|
| Host | Hostinger shared (hPanel) |
| Web server | LiteSpeed (`X-LiteSpeed-Cache: hit`) |
| Runtime | **PHP 8.1.34** |
| CDN | `Server: hcdn`, Mumbai edge |
| .NET | **Not present** — `/test.aspx` returns 404 |

**ASP.NET cannot run on Hostinger shared hosting.** "Rebuild in .NET" and "keep this
exact server" cannot both be true. You have two viable paths:

### Path A — Keep the server (no hosting change)
Rebuild in PHP or as a static site. Use `apache/.htaccess`.
LiteSpeed honours Apache rewrite rules natively, so it works as-is today.
The .NET files in this kit are then unused.

### Path B — Go .NET (requires a Windows host)
Move to SmartASP.NET, GoDaddy Windows, or any IIS plan — both of which you named
in your brief. Use `iis/web.config` plus the `dotnet/` middleware.
This *is* a hosting change, but it is the only way to run .NET.

Everything below works on basic shared hosting. No cloud services, no Docker,
no containers, no CI requirement.

---

## Files

| File | Purpose |
|---|---|
| `01_redirect-map.csv` | Master old → new URL map, 34 rows |
| `apache/.htaccess` | Apache / LiteSpeed redirect layer (Path A) |
| `iis/web.config` | IIS URL Rewrite config (Path B) |
| `dotnet/RedirectMapService.cs` | Loads map, **flattens chains**, detects loops |
| `dotnet/SeoRedirectMiddleware.cs` | Canonical host/scheme/case/slash in **one 301** |
| `dotnet/NotFoundFallbackMiddleware.cs` | Smart 404 recovery + structured logging |
| `dotnet/Program.cs` | Pipeline wiring — **order matters, see comments** |
| `dotnet/redirect-map.json` | Editable redirect list, no redeploy needed |
| `dotnet/appsettings.json` | All toggles |
| `05_verify-redirects.ps1` | Pre-cutover test — fails the build on chains/302s/404s |

---

## URL strategy

**13 URLs keep their exact slug.** No redirect needed — the new app serves them directly.
These carry the entire commercial footprint; changing any of them resets its ranking.

**21 URLs redirect.** All WordPress artefacts (feeds, author archive, `wp-*`,
date archives, sitemaps) plus the three low-value posts that fold into `/blog/`.

**One rule that is easy to miss:** `/wp-content/uploads/` **must keep working.**
30 live images sit there and are referenced by `og:image` tags and possibly
Google Images. Copy the uploads folder into `wwwroot/wp-content/uploads/` in the
new build and serve it from the identical path. Both configs explicitly exclude
this prefix from all rewriting.

---

## How chains are avoided

A redirect chain (A → B → C) leaks link equity and Google may stop following
after ~5 hops. Three mechanisms prevent them here:

1. **Combined canonical rule.** Host + scheme are corrected in a single rule, so
   `http://www.…` costs one hop, not two.
2. **Startup chain flattening.** `RedirectMapService.Flatten()` walks the map at
   boot and rewrites A → B → C into A → C. It also detects cycles and drops
   those rules with an error log rather than looping at runtime.
3. **Single-redirect middleware.** `SeoRedirectMiddleware` computes scheme, host,
   query, case, trailing slash *and* the map lookup before responding, then issues
   exactly one 301. A URL wrong in four ways still costs one hop.

The .htaccess version cannot do #3 — pure Apache has no way to buffer corrections.
Worst case there is **2 hops** (`http://www.site.com/page` → host fix → slash fix).
That is acceptable and standard; the .NET path is strictly better on this point.

---

## The soft-404 warning — please read before enabling

Your brief says *"DO NOT show default 404 page"* and *"redirect to homepage as
last fallback."* Implemented literally, that is an SEO anti-pattern.

Google explicitly treats **mass redirects of unknown URLs to the homepage as soft
404s.** The URLs stay in the index as errors, and it becomes impossible to spot
genuinely broken internal links because everything silently "works."

So `NotFoundFallbackMiddleware` does this instead:

1. Exact match ignoring case/slash → **301** to the real page.
2. Topic keyword in the URL (`delhi`, `mumbai`, `contact`, `blog`…) → **301** to
   the relevant page. This catches most renamed or mistyped URLs.
3. Fuzzy slug-token overlap above `MatchThreshold` → **301**.
4. Otherwise → **real 404** with a branded, helpful page.

That satisfies the intent — visitors never see a dead end, and every recoverable
URL gets a genuine 301 — without manufacturing soft 404s.

If you still want literal behaviour, set `"AlwaysRedirect": true` in
`appsettings.json`. It is one flag, and it is off by default deliberately.

---

## Logging

`NotFoundFallbackMiddleware` writes three structured events:

```
404_HIT        path=… referer=… ua=… ip=…     every miss
404_RECOVERED  path=… -> target=…             smart match fired
404_SERVED     path=…                         genuine 404 shown
```

`SeoRedirectMiddleware` writes `REDIRECT_MAP {From} -> {To}` on every map hit.

**Weekly routine:** grep for `404_HIT`, sort by frequency, and promote anything
recurring with a real referer into `redirect-map.json`. That file is read at
startup, so adding a redirect is a file edit and an app-pool recycle — no rebuild.

On Apache, enable the same visibility with your host's access log and filter on
status 404.

---

## Deployment order (do not improvise this)

1. Build the new site on a **staging URL**, noindexed.
2. Copy `/wp-content/uploads/` across, path unchanged.
3. Drop in `.htaccess` **or** `web.config`.
4. Run `05_verify-redirects.ps1 -BaseUrl "https://staging…"` — **must exit 0.**
5. Confirm titles, meta descriptions and canonicals match `07_FULL_SEO_AUDIT.csv`
   on the 8 P0 URLs.
6. Cut over DNS.
7. Re-run the verify script against production.
8. Submit the new sitemap in Google Search Console and use **Removals → outdated
   content** for nothing; just let the 301s work.
9. Watch GSC Coverage daily for two weeks. A spike in "Not found (404)" or
   "Redirect error" means a rule is missing.

---

## Best practices to avoid SEO loss

**URLs**
- Never change a P0 slug. If one truly must change, 301 it and keep the old URL
  redirecting **permanently** — not for 6 months.
- Keep trailing slashes. Every canonical on the old site has one.
- One canonical host: `https://houseofvacation.com` (no `www`).
- Serve lowercase only; 301 mixed case. The old server served `/About-Company/`
  as a 200 duplicate.

**Redirects**
- 301 only. Never 302 for a permanent move — it does not pass equity reliably.
- Point every rule at the **final** destination.
- Never redirect everything to the homepage.
- Test before cutover, not after.

**On-page**
- Carry `<title>`, meta description and canonical across verbatim for the P0 set.
  They are in `07_FULL_SEO_AUDIT.csv`.
- Keep the city pages at 1,030–1,301 words. Thinner content loses rankings even
  when the URL is preserved.
- Self-referencing canonical on every page.
- **Export Rank Math focus keywords from the WordPress database before you
  decommission it.** They exist nowhere in the HTML. The seven recovered from
  Article schema are in the audit CSV, but pull a full export to be safe.

**Do not carry forward**
- `Cache-Control: no-store` on HTML — that is what generated the infinite
  `?no-cache=` URLs.
- `/page/2/` and `/page/3/` homepage duplicates.
- The open `/wp-json/` REST API.
