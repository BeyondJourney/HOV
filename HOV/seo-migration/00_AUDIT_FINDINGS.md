# Pre-Change Audit — What I Found and What Will Change

Audited 21 Aug 2026, before any file was modified.
Scope: the live site, the new build in this folder, and the existing kit files.

---

## VERDICT: DO NOT DEPLOY YET

The new static build in this folder is **not ready for production**. Deploying it as-is
would not be a migration — it would be an SEO reset. Five blockers, in severity order.

---

### BLOCKER 1 — All six P0 city pages are missing

The old site's entire local-search footprint is six city pages, 1,030–1,301 words each:

| Old URL | Words | Exists in new build? |
|---|---|---|
| `/mice-company-in-delhi/` | 1,047 | **NO** |
| `/mice-company-in-noida/` | 1,031 | **NO** |
| `/mice-company-in-gurugram/` | 1,229 | **NO** |
| `/corporate-travel-agency-in-mumbai/` | 1,301 | **NO** |
| `/corporate-travel-agency-in-bangalore/` | 1,244 | **NO** |
| `/corporate-event-planners-in-pune/` | 1,030 | **NO** |

The words *noida*, *gurugram*, *bangalore* and *pune* do not appear anywhere in the
new build. *delhi* appears only inside the footer postal address. *mumbai* appears
once on the homepage.

There is no new page to redirect these to that would preserve their rankings.
Redirecting them to `/our-services/` or `/` would drop the local rankings and read
as a soft 404.

**Resolution built into this kit:** the six pages are preserved verbatim at their exact
URLs from the crawl snapshots taken during the audit. They keep ranking while the
redesigned versions are written. Because the URL does not change, swapping in a new
design later is a file copy — **no `.htaccess` change, no redirect, no SEO risk.**

---

### BLOCKER 2 — 33 broken internal link targets

Every page in the new build links to template pages that were never created.

| Missing target | Linked from |
|---|---|
| `home-travel.html` | 15 of 17 pages |
| `our services.html` *(note the space)* | 15 of 17 pages |
| `blog-details.html` | 15 of 17 pages |
| `index.html.html` *(find/replace bug)* | 12 pages |
| `shop.html`, `cart.html`, `checkout.html`, `wishlist.html` | 3 each |
| `tour.html`, `activities.html`, `gallery.html`, `price.html`, `faq.html` … | 2–3 each |

These sit in the **main navigation and footer**, so they appear site-wide.
Requirement 9 says "no broken internal links" — currently there are 33 distinct
broken targets. This must be fixed in the source HTML; `.htaccess` cannot repair it.

---

### BLOCKER 3 — No unique titles, descriptions or canonicals

| Element | Old site | New build |
|---|---|---|
| `<title>` | Unique + keyword-targeted on all 14 URLs | **`houseofvacation`** on 14 of 17 pages |
| Meta description | Present on 11 URLs | **`Tourm - Travel & Tour Booking Agency HTML Template`** on all 17 |
| Canonical | Self-referencing on 13 URLs | **None on any page** |
| H1 | Unique per page | Duplicated across 3–4 pages |

Example of what is being lost:

```
OLD  /mice-company-in-delhi/
     <title>Mice Company In Delhi | Corporate Event Planner in Delhi</title>
     <meta name="description" content="HOV is a leading MICE company in Delhi,
           specializing in corporate events, meetings, incentives...">

NEW  (page does not exist; nearest page carries)
     <title>houseofvacation</title>
     <meta name="description" content="Tourm - Travel & Tour Booking Agency HTML Template">
```

Requirement 14 says do not change titles, descriptions or schema unless required for
migration. Right now they would all change — for the worse. The correct values for
every URL are in `seo-audit-export/07_FULL_SEO_AUDIT.csv`.

---

### BLOCKER 4 — Asset paths are document-relative

All 181 asset references per page use `assets/css/…` with **no `<base>` tag**.

A page served at `/about-company/` would resolve `assets/css/style.css` to
`/about-company/assets/css/style.css` → 404. Every stylesheet, script and image
would break the moment a page sits at a clean URL.

**Fix:** convert `assets/` → `/assets/` (root-relative). `build-deploy.ps1` does this
automatically into the staging folder and never touches your source files.

---

### BLOCKER 5 — Template artefacts still present

| File | Issue |
|---|---|
| `my-account.html` | Tourm e-commerce account page, no purpose here |
| `error.html` | Titled "Tourm - Travel & Tour Booking Agency HTML Template - Error Page" |
| `our services.html` | Space in filename — invalid as a URL |
| `H/assets/` | 859 files duplicating `assets/` (829 files) — two copies of the same library |
| `CORPORATE TRAVEL BANNNER.png` | Space + typo in filename, 1 MB, unreferenced |

---

## What this kit CHANGES, and why

Nothing in your source folder is modified. Everything is assembled into a separate
`_deploy/public_html/` staging folder.

| Change | Why |
|---|---|
| `dotnet/` + `iis/` moved to `_archived-pathB-dotnet-iis/` | Path A confirmed. **Archived, not deleted** — reversible |
| Pages placed as `folder/index.html` | Gives clean trailing-slash URLs natively via `DirectoryIndex`, with **zero rewrite rules** — the safest possible structure |
| `assets/` → `/assets/` in staged copies | Blocker 4. Source files untouched |
| Six city pages staged from audit snapshots | Blocker 1 |
| `/wp-content/uploads/` copied verbatim | 30 live images; `og:image` tags and Google Images depend on these exact URLs |
| `MultiViews` disabled | Stops Apache serving `/about-company` from `about-company.html` as a duplicate |
| `/index.html` → `/` 301 | Prevents the same page being reachable at two URLs |
| Branded `404.html` | Replaces `error.html`; returns a **real 404**, not a redirect |

## What this kit does NOT change

- Any URL marked KEEP in `01_redirect-map.csv`
- Page content, titles, meta descriptions or schema on the six preserved city pages
- Anything inside `/wp-content/uploads/`
- Your original source HTML — the build script only ever reads it

---

## Live site re-verified (unchanged since the audit)

```
http://houseofvacation.com/          301 → https://houseofvacation.com/
https://www.houseofvacation.com/     301 → https://houseofvacation.com/
/about-company                       301 → /about-company/
/dubai/  (attachment)                301 → /
```

Canonical host confirmed: **`https://houseofvacation.com`** — HTTPS, non-www, trailing slash.
