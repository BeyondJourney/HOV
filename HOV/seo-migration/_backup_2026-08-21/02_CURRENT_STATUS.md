# 02 — CURRENT STATUS

**Checkpoint:** 21 August 2026
**Path:** A — Hostinger + LiteSpeed + PHP/static

---

## ⚠️ HAS THE LIVE WEBSITE BEEN CHANGED?

# NO

Verified at checkpoint time by read-only HTTP request:

```
GET https://houseofvacation.com/  ->  200
<title>MICE Company in India | Corporate Travel Agency</title>
X-Powered-By: PHP/8.1.34
platform: hostinger
```

The live site is still the original WordPress installation, serving its original
title. Across this entire session:

- **NO** files uploaded to Hostinger
- **NO** files deleted from Hostinger
- **NO** `.htaccess` placed on the live server
- **NO** DNS records changed
- **NO** database modified
- **NO** original source file in the project folder modified

Every HTTP request made to the live domain was a **GET** (crawling, auditing,
verifying). All writes went to the local staging folder only.

---

## COMPLETE ✅

| Area | Detail |
|---|---|
| Live-site SEO audit | 14 URLs, full metadata, schema, assets, internal links |
| Migration cross-check | All URL classes verified; **zero legacy URL debt** |
| Redirect map | 54 rows — 21 KEEP-200, 30 REDIRECT-301, 2 NEVER-REDIRECT, 1 GENUINE-404 |
| Production `.htaccess` | 23 × 301, 0 × 302, 0 chains, 0 loops |
| Broken internal links | **33 → 0** (841 links verified) |
| SEO metadata | 21/21 unique titles, descriptions, canonicals |
| H1 structure | Exactly 1 per page on all 21 |
| 6 P0 city pages | Rebuilt into new template with original copy + metadata |
| Asset paths | 1,447 refs, all root-relative |
| WordPress dependencies | 0 |
| Template artefacts | 0 (`my-account`, `error.html`, 101 "Tourm" strings removed) |
| Branded 404 page | Real 404 status, links to all 6 city pages |
| `robots.txt` + `sitemap.xml` | 21 URLs, XML-validated |
| Offline QA suite | `qa-staging.ps1` — **exits 0, 0 failures, 0 warnings** |
| Live test suite | `test-live.ps1` — written, **not yet run against a server** |
| Staging build | 21 pages, 972 files, 127.2 MB |

---

## IN PROGRESS 🔄

Nothing. Work was deliberately halted at this checkpoint on user instruction.

---

## NOT COMPLETE ❌

| # | Item | Severity | Blocks deploy? |
|---|---|---|---|
| 1 | `/wp-content/uploads/` not staged (not present locally) | **BLOCKER** | **YES** |
| 2 | `test-live.ps1` never executed against a real server | **BLOCKER** | **YES** |
| 3 | No Hostinger backup taken yet | **BLOCKER** | **YES** |
| 4 | WordPress DB not exported (holds Rank Math focus keywords) | **BLOCKER** | **YES** |
| 5 | Staging subdomain not created | High | Recommended |
| 6 | `mail.php` contact form never tested | High | Recommended |
| 7 | Organization / LocalBusiness schema absent | Medium | No |
| 8 | FAQPage schema absent (7 pages have FAQs) | Medium | No |
| 9 | Privacy policy / terms pages absent (404 today) | Medium | No |
| 10 | City page word counts 6–15% below original | Medium | No |
| 11 | City pages use generic `our-services` layout | Medium | No |
| 12 | Duplicate H1 *text* on some new service pages | Low | No |
| 13 | Visual/browser QA never performed | High | Recommended |

---

## MUST HAPPEN BEFORE PRODUCTION DEPLOYMENT

Strict order. Do not skip or reorder.

1. **Back up Hostinger.** hPanel → Files → Backups → generate → **download locally**.
2. **Export the WordPress database.** It holds the Rank Math focus keywords, which
   exist nowhere in the HTML.
3. **Download `/wp-content/uploads/`** from `public_html/wp-content/uploads/`
   (all 7 date folders) → place at `HOV\wp-content\uploads\`.
4. **Rebuild + re-QA:**
   ```powershell
   cd "HOV\seo-migration"
   .\build-deploy.ps1 -Clean
   .\qa-staging.ps1              # MUST exit 0
   ```
   Build section 4 must now read "copied", not "NOT FOUND LOCALLY".
5. **Create staging subdomain**, upload there, add `X-Robots-Tag: noindex` to the
   staging `.htaccess` **only**.
6. **Run live tests:**
   ```powershell
   .\test-live.ps1 -BaseUrl "https://staging.houseofvacation.com"   # MUST exit 0
   ```
7. **Manual QA on staging:** styling renders, contact form sends, every nav/footer
   link clicked, mobile checked, social preview card renders.
8. Only then deploy to production, and re-run `test-live.ps1` against the live URL.

---

## STAGING IS NOT PRODUCTION-READY

`seo-migration/_deploy/public_html/` passes **offline** QA. It has **never** been
served by a web server. Not yet verified:

- Real HTTP status codes and redirect behaviour
- `.htaccess` execution under LiteSpeed (rules are statically analysed only)
- Visual rendering in a browser
- JavaScript execution
- Contact form delivery
- Image loading (the uploads folder is not even staged yet)

Treat this build as **a candidate**, not a release.
