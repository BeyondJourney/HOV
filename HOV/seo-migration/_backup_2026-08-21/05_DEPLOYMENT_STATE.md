# 05 — DEPLOYMENT STATE

**Checkpoint:** 21 August 2026 | **Path A** — Hostinger + LiteSpeed + PHP/static

---

## CURRENT STAGING FOLDER

```
HOV\seo-migration\_deploy\public_html\
```

**21 pages · 972 files · 127.2 MB**

This folder is **generated**. It is safe to delete and rebuild at any time with
`.\build-deploy.ps1 -Clean`. It has never been served by a web server.

---

## FOLDER LAYOUT

```
HOV\
├── *.html  (17 files)              SOURCE — never modified
├── mail.php                        SOURCE
├── assets\           (829 files)   SOURCE
├── H\assets\         (859 files)   SOURCE — 117 unique files merged into /assets/
├── seo-audit-export\ (8 files)     AUDIT EXPORT — pre-migration baseline
└── seo-migration\
    ├── build-deploy.ps1            MIGRATION KIT — builds staging
    ├── lib-extract.ps1             MIGRATION KIT — content extraction helpers
    ├── qa-staging.ps1              MIGRATION KIT — offline QA
    ├── test-live.ps1               MIGRATION KIT — live HTTP tests
    ├── 05_verify-redirects.ps1     MIGRATION KIT — earlier redirect checker
    ├── seo-metadata.json           MIGRATION KIT — title/desc source of truth
    ├── 01_redirect-map.csv         MIGRATION KIT
    ├── qa-report.csv               MIGRATION KIT — latest QA output
    ├── *.md  (docs)                MIGRATION KIT
    ├── deploy\                     DEPLOYMENT templates
    │   ├── .htaccess
    │   ├── 404.html
    │   ├── robots.txt
    │   └── sitemap.xml
    ├── apache\.htaccess            DEPLOYMENT — earlier draft, superseded
    ├── _archived-pathB-dotnet-iis\ ARCHIVED — .NET/IIS, NOT used
    ├── _deploy\public_html\        STAGING — the upload target
    └── _backup_2026-08-21\         BACKUP — this checkpoint
```

---

## FILES CREATED THIS SESSION

### Migration kit
| File | Purpose |
|---|---|
| `build-deploy.ps1` | Builds staging from source. Non-destructive |
| `lib-extract.ps1` | Content extraction, heading repair, SEO injection, branding cleanup |
| `qa-staging.ps1` | Offline QA — links, SEO, assets, `.htaccess` analysis |
| `test-live.ps1` | Live HTTP tests — 9 sections |
| `05_verify-redirects.ps1` | Earlier standalone redirect checker |
| `seo-metadata.json` | Title/description per URL, each with a `Source` field |
| `01_redirect-map.csv` | 34-row master map |
| `qa-report.csv` | Latest QA output, 21 rows |
| `00_AUDIT_FINDINGS.md` | Pre-change audit |
| `00_README.md` | Hosting decision + best practices |
| `PRE_LAUNCH_CHECKLIST.md` | Blockers → content → technical → staging → backup |
| `POST_LAUNCH_CHECKLIST.md` | T+15min → T+1month |
| `TEST_COMMANDS.md` | Manual `curl` for all required tests |
| `FINAL_CUTOVER_REPORT.md` | Sections A–F cutover report |

### Deployment templates (`seo-migration/deploy/`)
| File | Purpose |
|---|---|
| `.htaccess` | **Production redirect layer** — 23 × 301, 0 × 302 |
| `404.html` | Branded 404, real 404 status, `noindex, follow` |
| `robots.txt` | Points at new sitemap; allows `/wp-content/uploads/` |
| `sitemap.xml` | 21 URLs, validated |

### Audit exports (`seo-audit-export/`)
`00_README.txt`, `01_URL_LIST.csv`, `02_URL_LIST_PLAIN.txt`, `03_sitemap.xml`,
`04_NON_PAGE_URLS_AND_REDIRECTS.csv`, `05_ALL_IMAGE_ASSET_URLS.csv`,
`06_INTERNAL_LINK_MAP.csv`, `07_FULL_SEO_AUDIT.csv`

---

## FILES MODIFIED

**No original source file was modified at any point.**

All transformation happens in memory inside `build-deploy.ps1` and is written only
to `_deploy/public_html/`. Verify with the SHA-256 hashes in `10_CHECKSUMS.txt`.

Files modified within the migration kit itself (my own scripts, iterated during
development): `build-deploy.ps1`, `lib-extract.ps1`, `qa-staging.ps1`,
`test-live.ps1`, `deploy/.htaccess`.

---

## FILES ARCHIVED

`seo-migration/_archived-pathB-dotnet-iis/` — **7 files, moved not deleted**

```
dotnet/RedirectMapService.cs
dotnet/SeoRedirectMiddleware.cs
dotnet/NotFoundFallbackMiddleware.cs
dotnet/Program.cs
dotnet/redirect-map.json
dotnet/appsettings.json
iis/web.config
```

Path B (.NET/IIS/Windows) is **not in use**. Retained for reference only.
**Do not deploy these. Do not reopen the .NET path.**

---

## WHAT MUST BE UPLOADED TO HOSTINGER

Upload the **contents** of `seo-migration\_deploy\public_html\` into
`public_html/` — the contents, not the folder itself.

```
.htaccess                 ← must land at public_html/.htaccess
index.html
404.html
robots.txt
sitemap.xml
mail.php
about-company/            contact-us/            blog/
mice-company-in-delhi/                 ← P0
mice-company-in-noida/                 ← P0
mice-company-in-gurugram/              ← P0
corporate-travel-agency-in-mumbai/     ← P0
corporate-travel-agency-in-bangalore/  ← P0
corporate-event-planners-in-pune/      ← P0
our-services/  corporate-travel/  corporate-travel-consultancy/
mice-event/  incentive/  conferences-event/
corporate-celebration/  offsite-events/
adventure-group/  customized-group/  destination-management/
assets/                   946 files
wp-content/uploads/       ⚠️ NOT YET STAGED — see blocker
```

**Method:** zip locally, upload the single archive, extract in File Manager.
972 files over FTP will take hours and drop connections.

**Permissions:** folders `755`, files `644`.

---

## WHAT MUST *NOT* BE UPLOADED

| Item | Why |
|---|---|
| `seo-migration/` itself | Internal tooling. Never expose scripts, audit data or backups publicly |
| `_archived-pathB-dotnet-iis/` | .NET/IIS, unused |
| `_backup_2026-08-21/` | This checkpoint |
| `_deploy/` wrapper folder | Upload its **contents**, not the folder |
| `H/` | 117 unique files already merged into `/assets/`; the rest are duplicates |
| `my-account.html` | Tourm e-commerce artefact |
| `error.html` | Tourm error page, replaced by `404.html` |
| `CORPORATE TRAVEL BANNNER.png` | Unreferenced, 1 MB, space + typo in filename |
| Source `*.html` at `HOV\` root | Superseded by `folder/index.html` in staging |
| `seo-audit-export/` | Internal reference |
| `apache/.htaccess` | Superseded by `deploy/.htaccess` |

---

## WHAT MUST *NOT* BE DELETED FROM HOSTINGER

| Path | Why |
|---|---|
| **`public_html/wp-content/uploads/`** | **CRITICAL.** 30 live images; every `og:image` URL points here. Download it first, then keep the live copy in place until the new build serves the same paths |
| Existing `public_html/.htaccess` | Back it up before replacing — it is part of the rollback |
| The WordPress database | Holds Rank Math focus keywords, which exist nowhere in HTML |

Safe to remove **after** a verified backup: `wp-admin/`, `wp-includes/`,
`wp-content/themes/`, `wp-content/plugins/`, `wp-config.php`, `index.php`,
`xmlrpc.php`, `wp-*.php`.

---

## `.htaccess` STATUS

| | |
|---|---|
| **Production file** | `seo-migration/deploy/.htaccess` |
| **Staged copy** | `seo-migration/_deploy/public_html/.htaccess` (identical) |
| **On live server** | **NOT DEPLOYED.** The live server still has its WordPress `.htaccess` |
| **Superseded draft** | `seo-migration/apache/.htaccess` — earlier version, do not use |

### Verified by static analysis
```
23 x 301 rules          0 x 302/307
0 redirect chains       0 redirect loops
/wp-content/uploads/ excluded from rewriting   (rule 0)
/assets/ excluded from rewriting               (rule 0)
MultiViews disabled     ErrorDocument 404 set
X-Forwarded-Proto guard present (prevents CDN redirect loop)
No 'no-store' on HTML
```

### Rule order (deliberate — do not reorder)
```
0. Hard exclusions      .well-known, wp-content/uploads, assets, real files/dirs
1. Query cleanup        strip ?no-cache= and ?attachment_id=
2. Canonical host+scheme ONE rule: http, www and http+www all in a single hop
3. Duplicate collapse   /index.html and /*.html -> clean folder URL
4. Redirect map         obsolete WordPress URLs -> final targets
5. (template comments for adding future rules)
6. ErrorDocument 404    genuine 404, never a homepage redirect
7. Caching              HTML max-age=0 must-revalidate; assets 1 year immutable
8. MIME types
9. Hardening            deny .htaccess/.env/.git
```

### Not yet verified
`.htaccess` has been **statically analysed only**. It has never executed under
LiteSpeed. Rule behaviour must be confirmed on staging with `test-live.ps1` before
production.
