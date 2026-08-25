# 01 — SESSION SUMMARY

**Project:** House of Vacation India Pvt Ltd — website rebuild + SEO migration
**Domain:** https://houseofvacation.com
**Checkpoint date:** 21 August 2026
**Live site changed:** **NO.** Nothing uploaded, no DNS change, no server file touched.

---

## MIGRATION DECISION (locked)

### PATH A — ACTIVE
**Hostinger shared hosting + LiteSpeed + PHP/static.**
Redirects handled entirely by `.htaccess`. No server or hosting change.

### PATH B — ARCHIVED, NOT IN USE
.NET / ASP.NET Core / IIS / `web.config` / Windows hosting.
Files retained at `seo-migration/_archived-pathB-dotnet-iis/` for reference only.

**Why Path B was rejected:** the live server was fingerprinted as Hostinger shared
hosting running **LiteSpeed + PHP 8.1.34**, with **no .NET runtime** (`/test.aspx`
returns 404). ASP.NET cannot run there, so "rebuild in .NET" and "keep this server"
were mutually exclusive. The user chose to keep the server.

**Do not reopen this decision. Do not propose .NET, IIS, Docker or cloud.**

---

## WHAT THIS SESSION DID, IN ORDER

### Phase 1 — Full SEO audit of the live site
Method: `robots.txt` + `sitemap_index.xml` + recursive raw-HTML crawl + WordPress
REST API enumeration + Wayback Machine CDX history.

Findings:
- **14 live URLs** (13 indexable + 1 noindex author archive). No orphans.
- Stack: WordPress 6.7.7, Astra theme, Elementor 4.1.1, Rank Math SEO,
  Hostinger/LiteSpeed, PHP 8.1.34, GA4 `G-39RQE9L4LF`, Meta Pixel `854699396884800`.
- **Infinite `?no-cache=<hex>` URL trap** — every page emitted unique parameter
  URLs serving duplicate content at 200. Caused by `Cache-Control: no-store` on HTML.
- 130 media files, 86.3 MB, **100 orphaned (77%)**; only 30 in use.
- No FAQPage schema despite FAQs on 7 pages; breadcrumb schema contained only "Home";
  Organization schema `name` was the bare string `"houseofvacation.com"`.
- `/About-Company/` (uppercase) served **200 duplicate content**.
- `/page/2/` and `/page/3/` served byte-identical homepage duplicates.

### Phase 2 — Migration cross-check
Verified no URL class was missed: custom post types, taxonomies, attachment pages,
date archives, pagination, feeds, subdomains.
**Key result: zero legacy URL debt.** Wayback shows only the root URL existed before
2025. The `wp-hotel-booking` plugin and 38 hotel demo images were an unused theme
demo import, never published as pages.

### Phase 3 — Redirect kit (both paths, before the decision)
Produced `.htaccess`, `web.config`, and .NET middleware. Path B later archived.

### Phase 4 — Pre-change audit of the NEW site
Discovered the new static site already existed in the project folder — and was
**not production-ready**. Five blockers found (full detail in `06_AUDIT_FINDINGS.md`).

### Phase 5 — Fixes applied (build pipeline only)
All fixes happen at build time. **Original source HTML was never modified.**

| Fix | Before | After |
|---|---|---|
| Broken internal links | 33 targets | **0** (841 links verified) |
| Page titles | 14 of 17 = `houseofvacation` | **21 unique** |
| Meta descriptions | all 17 = Tourm boilerplate | **21 unique** |
| Canonical tags | 0 | **21** |
| H1 per page | home had 4, city pages 2 | **exactly 1** on all 21 |
| P0 city pages | did not exist | **6 rebuilt** |
| Asset paths | 181/page document-relative | all root-relative |
| WordPress asset deps | 41 per city page | **0** |
| Template artefacts | 101 "Tourm" strings | **0** |

---

## KEY DECISIONS MADE

1. **Folder + `index.html` structure.** Every page deploys as `folder/index.html`,
   so Apache serves the trailing-slash URL natively at 200 with **no rewrite rule**.
   Clean URLs come from the folder layout, not from rewriting. Fewer rules, fewer
   ways to break.

2. **The 6 P0 city pages were REBUILT, not copied verbatim.**
   Originally they were staged as raw snapshots. That failed because the snapshots
   depend on **41 WordPress theme/plugin/core assets**, and `.htaccess` correctly
   301s `/wp-content/` and `/wp-includes/` to `/` — the pages would have rendered
   completely unstyled. Instead the semantic content (H1, H2, H3, paragraphs, lists)
   is extracted from each snapshot and injected into the new site template.
   Result: original URL + original SEO metadata + original copy + new design +
   zero WordPress dependencies.

3. **404s return a genuine 404.** The original brief asked for "never show a 404,
   fall back to homepage." That was flagged as an SEO anti-pattern — Google treats
   mass redirect-to-homepage as **soft 404**. The `.htaccess` uses
   `ErrorDocument 404 /404.html` with a real 404 status and a branded page listing
   all six city pages. Do not change this without a deliberate decision.

4. **Existing city slugs are NOT normalised.** Three inconsistent patterns are in
   use (`mice-company-in-X`, `corporate-travel-agency-in-X`,
   `corporate-event-planners-in-X`). Tidying them would cost the rankings those
   pages already hold. Keep them exactly. Apply consistency only to NEW pages.

5. **`/wp-content/uploads/` is preserved at the identical path.** 30 live images
   and every `og:image` URL depend on it. Excluded from rewriting in `.htaccess`
   rule 0, before any other rule can match.

6. **SEO metadata provenance is recorded.** Audit values used verbatim where they
   exist; created only where the audit value was junk or missing. Every entry in
   `seo-metadata.json` carries a `Source` field saying which.

---

## BLOCKERS

### OPEN — must be resolved before deployment
**`/wp-content/uploads/` is not staged.** It does not exist in the local project
folder. Must be downloaded from Hostinger File Manager
(`public_html/wp-content/uploads/`, all 7 date folders `2021/05`–`2025/07`) and
placed at `HOV\wp-content\uploads\`, then rebuild + re-QA.
Without it, 30 images and every social preview card break.

### RESOLVED during this session
- 33 broken internal links → 0
- Missing SEO metadata → 21/21 complete
- 4 H1s on homepage, 2 on city pages → exactly 1 each
- Missing P0 city pages → 6 rebuilt
- Document-relative asset paths → all root-relative
- WordPress asset dependencies on city pages → 0
- `data-mask-src` attribute missed by first asset-path pass → fixed
- QA analyser false positives (read `.htaccess` comments as config; treated
  `RewriteCond`-guarded catch-alls as loops) → fixed

---

## PENDING TASKS (not started)

1. Download `/wp-content/uploads/` — **blocker**
2. Add `Organization` / `LocalBusiness` schema with real NAP and `sameAs`
3. Add `FAQPage` schema (7 pages have visible FAQs, none marked up)
4. Privacy policy and terms pages (both 404 today; site runs GA4 + Meta Pixel)
5. Optionally restyle the 6 city pages — **URL never changes, so this needs no
   `.htaccess` edit and no re-indexing**
6. Differentiate duplicate H1 *text* on some new service pages
7. Test `mail.php` contact form after upload

---

## VERIFIED FACTS ABOUT THE LIVE SITE (as of this checkpoint)

```
https://houseofvacation.com/            200, still WordPress
<title>MICE Company in India | Corporate Travel Agency</title>
X-Powered-By: PHP/8.1.34   platform: hostinger   Server: hcdn

http://houseofvacation.com/          301 -> https://houseofvacation.com/
https://www.houseofvacation.com/     301 -> https://houseofvacation.com/
/about-company                       301 -> /about-company/
/dubai/ (attachment)                 301 -> /
```

Canonical host: **`https://houseofvacation.com`** — HTTPS, non-www, trailing slash.
