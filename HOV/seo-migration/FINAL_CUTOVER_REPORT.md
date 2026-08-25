# FINAL CUTOVER REPORT

**Status:** Staging build complete. QA passes with **0 failures, 0 warnings**.
**Nothing has been uploaded. The live site is untouched.**

Build: 21 pages · 972 files · 127.2 MB
Environment: Hostinger shared / LiteSpeed / static + PHP. No .NET, no IIS, no cloud.

---

## A. FILES READY TO UPLOAD

Everything lives in `seo-migration/_deploy/public_html/`.

```
public_html/
├── .htaccess                 23 x 301 rules, 0 x 302
├── index.html                /
├── 404.html                  branded, real 404 status
├── robots.txt                points at /sitemap.xml
├── sitemap.xml               21 URLs, validated
├── mail.php                  contact form handler
│
├── about-company/            ← old URL preserved
├── contact-us/               ← old URL preserved
├── blog/                     ← old URL preserved
│
├── mice-company-in-delhi/                 ← P0, rebuilt, 913 words
├── mice-company-in-noida/                 ← P0, rebuilt, 898 words
├── mice-company-in-gurugram/              ← P0, rebuilt, 1,097 words
├── corporate-travel-agency-in-mumbai/     ← P0, rebuilt, 1,169 words
├── corporate-travel-agency-in-bangalore/  ← P0, rebuilt, 1,110 words
├── corporate-event-planners-in-pune/      ← P0, rebuilt, 908 words
│
├── our-services/  corporate-travel/  corporate-travel-consultancy/
├── mice-event/  incentive/  conferences-event/
├── corporate-celebration/  offsite-events/
├── adventure-group/  customized-group/  destination-management/
│
├── assets/                   946 files (829 + 117 merged from H/assets/)
└── wp-content/uploads/       ⚠️ NOT YET PRESENT — see step B2
```

Every page is `folder/index.html`, so Apache serves the trailing-slash URL
natively at 200 with **no rewrite rule**. Clean URLs come from the folder layout.

---

## B. HOSTINGER UPLOAD INSTRUCTIONS

### B1. Back up first (non-negotiable)
1. hPanel → **Files → Backups** → Generate new backup
2. **Download it locally.** Do not rely only on the server copy.
3. hPanel → **Databases** → Export the WordPress DB
   (it holds the Rank Math focus keywords; they exist nowhere in the HTML)

### B2. Fetch the uploads folder — do this before anything else
The build reported `/wp-content/uploads/` missing locally. **30 live images and
every `og:image` URL depend on it.**

1. hPanel → **File Manager** → `public_html/wp-content/uploads/`
2. Download the whole folder — all 7 date subfolders, `2021/05` through `2025/07`
3. Place it at `HOV\wp-content\uploads\`
4. Re-run:
   ```powershell
   cd "HOV\seo-migration"
   .\build-deploy.ps1 -Clean
   .\qa-staging.ps1        # must still exit 0
   ```
   Section 4 must now read **"copied"**, not "NOT FOUND LOCALLY".

### B3. Stage on a subdomain (recommended)
1. hPanel → **Domains → Subdomains** → create `staging.houseofvacation.com`
2. Upload `_deploy/public_html/` contents there
3. Add to that staging `.htaccess` **only**:
   ```apache
   Header always set X-Robots-Tag "noindex, nofollow"
   ```
4. Run `.\test-live.ps1 -BaseUrl "https://staging.houseofvacation.com"`

### B4. Go live
1. hPanel → **File Manager** → `public_html/`
2. Delete old WordPress files — **except** `wp-content/uploads/`
   (Remove: `wp-admin/`, `wp-includes/`, `wp-content/themes/`,
   `wp-content/plugins/`, `wp-config.php`, `index.php`, `xmlrpc.php`, `wp-*.php`)
3. Upload the **contents** of `_deploy/public_html/` into `public_html/`
   — upload the contents, not the folder itself
4. Confirm `.htaccess` is at `public_html/.htaccess`
   (File Manager → Settings → **Show hidden files**)
5. Set permissions: folders `755`, files `644`
6. hPanel → **Advanced → LiteSpeed Cache** → Purge All

**Upload method:** for 972 files, zip locally, upload the single archive, then
extract in File Manager. FTP file-by-file will take hours and drop connections.

---

## C. URL / REDIRECT SUMMARY

### Serving 200 — no redirect (21 URLs)

| URL | Source | Words |
|---|---|---|
| `/` | new build | — |
| `/about-company/` | new build, old URL kept | — |
| `/contact-us/` | new build, old URL kept | — |
| `/blog/` | new build, old URL kept | — |
| `/mice-company-in-delhi/` | **P0 rebuilt** | 913 |
| `/mice-company-in-noida/` | **P0 rebuilt** | 898 |
| `/mice-company-in-gurugram/` | **P0 rebuilt** | 1,097 |
| `/corporate-travel-agency-in-mumbai/` | **P0 rebuilt** | 1,169 |
| `/corporate-travel-agency-in-bangalore/` | **P0 rebuilt** | 1,110 |
| `/corporate-event-planners-in-pune/` | **P0 rebuilt** | 908 |
| `/our-services/` + 10 more service pages | new build | — |

### 301 redirects (23 rules, 0 × 302)

| From | To |
|---|---|
| `http://*` · `https://www.*` | `https://houseofvacation.com/*` (one rule, one hop) |
| `/path` (no slash) | `/path/` (native `DirectorySlash`) |
| `/category/uncategorized/` · `/hello-world/` · `/new-blog/` · `/author/*` · all feeds | `/blog/` |
| `/wp-admin/*` · `/wp-json/*` · `/wp-includes/*` · `/wp-login.php` · `/xmlrpc.php` · `/index.php` | `/` |
| `/wp-content/*` **except** `/uploads/` | `/` |
| `/2024/` · `/2025/` · `/page/N/` | `/` |
| `/sitemap_index.xml` + 3 legacy sitemaps | `/sitemap.xml` |
| `*?no-cache=*` · `*?attachment_id=*` | clean URL, query stripped |
| `/anything.html` · `/index.html` | clean folder URL |

### Never redirected
`/wp-content/uploads/*` and `/assets/*` are excluded in **rule 0**, before any
other rule can match. Any real file or directory also short-circuits with `[L]`.

---

## D. SEO ISSUES FIXED

| # | Issue | Before | After |
|---|---|---|---|
| 1 | Broken internal links | **33 targets**, some on 15 of 17 pages | **0** (841 links verified) |
| 2 | `index.html.html` bug | 12 pages | fixed → `/` |
| 3 | `our services.html` (space) | 15 pages | fixed → `/our-services/` |
| 4 | Tourm demo mobile menu | 20+ dead links/page | replaced with real 5-item menu + Services and Locations submenus |
| 5 | Page titles | 14 of 17 = `houseofvacation` | **21 unique**, 25–64 chars |
| 6 | Meta descriptions | all 17 = Tourm boilerplate | **21 unique**, 112–162 chars |
| 7 | Canonical tags | **0 pages** | **21**, all `https://houseofvacation.com/…/` |
| 8 | Open Graph | inconsistent | full OG + Twitter card on all 21 |
| 9 | Multiple H1s | home had 4, city pages 2 | **exactly 1** on all 21 |
| 10 | P0 city pages | **did not exist** | 6 rebuilt with original copy + metadata |
| 11 | Asset paths | 181/page document-relative | **all root-relative**, 1,447 refs verified |
| 12 | WordPress asset deps | 41 per city page | **0** |
| 13 | Template artefacts | `my-account`, `error.html`, 101 "Tourm" strings | **0** |
| 14 | `no-store` on HTML | caused infinite `?no-cache=` URLs | removed |
| 15 | Uppercase duplicate URLs | `/About-Company/` served 200 | 301 to lowercase |

**Metadata provenance:** `/` and `/about-company/` use audit values **verbatim**.
The 6 city pages inherit title, description and `og:image` **verbatim from the
pre-migration snapshots**. `/contact-us/` and `/blog/` were written new because the
audit values were unusable (`"Phone Number:"` at 13 chars, and empty). The 11 new
service pages were written new — no audit data existed. Every value and its origin
is recorded in `seo-metadata.json` under `Source`.

---

## E. REMAINING ISSUES

| # | Item | Severity | Action |
|---|---|---|---|
| 1 | **`/wp-content/uploads/` not staged** | **BLOCKER** | Download per B2, rebuild, re-QA |
| 2 | City page word counts down 6–15% (e.g. Delhi 1,047 → 913) | Medium | Extraction drops chrome and de-duplicates repeated headings. Copy is intact; review one page and top up if you want parity |
| 3 | City pages use the `our-services` layout | Medium | Content and SEO correct, layout generic. Restyle any time — **URL never changes, so no `.htaccess` edit and no re-indexing** |
| 4 | No `Organization` / `LocalBusiness` schema | Medium | Old site had only `"name":"houseofvacation.com"` with no address or phone. Add real NAP + `sameAs` |
| 5 | No `FAQPage` schema | Medium | 7 pages have visible FAQs, none marked up. Was also missing before — not a regression |
| 6 | No privacy policy / terms page | Medium | Both 404 today. Site runs GA4 + Meta Pixel, so these are expected |
| 7 | Duplicate H1 *text* across some new pages | Low | e.g. `corporate-travel` and `corporate-travel-consultancy` share an H1 string. Structurally valid, weak for SEO |
| 8 | Contact form untested | Low | `mail.php` deployed but not exercised. Test after upload |
| 9 | `H/` folder | Low | 117 unique files merged into `/assets/`; the rest were duplicates. Do not upload `H/` |

---

## F. TESTS THAT MUST PASS BEFORE REPLACING THE LIVE SITE

### F1. Offline — passing now

```powershell
cd "HOV\seo-migration"
.\qa-staging.ps1
```

| Criterion | Required | Actual |
|---|---|---|
| Broken internal links | 0 | **0** ✅ |
| Missing P0 URLs | 0 | **0** ✅ |
| Broken critical assets | 0 | **0** ✅ |
| Missing canonical tags | 0 | **0** ✅ |
| Missing titles / descriptions | 0 | **0** ✅ |
| Duplicate titles | 0 | **0** ✅ |
| Pages with ≠1 H1 | 0 | **0** ✅ |
| `.html` links (avoidable hops) | 0 | **0** ✅ |
| WordPress asset dependencies | 0 | **0** ✅ |
| Template artefacts | 0 | **0** ✅ |
| 302 / 307 redirects | 0 | **0** ✅ |
| Redirect chains | 0 | **0** ✅ |
| Redirect loops | 0 | **0** ✅ |

**Re-run this after adding `wp-content/uploads/`. It must still exit 0.**

### F2. Live server — run on staging, then production

```powershell
.\test-live.ps1 -BaseUrl "https://staging.houseofvacation.com"
```

Must pass:
1. `http://` → `https://` — **1 hop**
2. `https://www.` → non-www — **1 hop**
3. `http://www.` + deep path — **1 hop** (the combined worst case)
4. `/about-company` → `/about-company/` — 301, 1 hop
5. All 10 KEEP URLs — **200, redirects=0**
6. All 6 P0 city URLs — **200, redirects=0**
7. Old WordPress URLs — 301, 1 hop, correct target
8. `/wp-content/uploads/...` — **200, redirects=0**
9. `/assets/css/style.css`, `/assets/js/main.js` — **200, redirects=0**
10. Nonexistent URL — **genuine 404**, no redirect
11. `?no-cache=` — stripped, 301 to clean URL
12. Homepage canonical = `https://houseofvacation.com/`
13. `/robots.txt` and `/sitemap.xml` — 200

Manual checks the script cannot make:
- [ ] Homepage renders **styled** (unstyled ⇒ asset paths broke)
- [ ] Contact form submits and the email arrives
- [ ] Click every nav + footer link — no 404s
- [ ] Check on a real phone
- [ ] Paste a city page URL into WhatsApp/LinkedIn — preview card renders

### F3. Go / no-go
Proceed only when `qa-staging.ps1` **and** `test-live.ps1` both exit 0 on staging,
the manual checks pass, and the backup is downloaded and verified.

**Rollback:** restore the `public_html/` backup. No URL changes, so rollback is
immediate and complete with no SEO side-effects.

---

## COMMAND REFERENCE

```powershell
cd "HOV\seo-migration"

.\build-deploy.ps1 -Clean       # rebuild staging from source (never edits source)
.\qa-staging.ps1                # offline QA - must exit 0
.\test-live.ps1 -BaseUrl "..."  # live/staging HTTP tests - must exit 0
```

Outputs: `qa-report.csv` (per-page SEO), `test-results.csv` (per-URL HTTP).
