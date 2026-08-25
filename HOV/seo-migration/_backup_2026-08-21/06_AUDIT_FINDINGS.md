# 06 — AUDIT FINDINGS (complete)

Audits performed 21 August 2026. Read-only. No live file touched.

---

## PART 1 — THE NEW BUILD: FIVE BLOCKERS FOUND

Audited **before** any change, per instruction. All five are now **RESOLVED in the
staging build** (fixes applied at build time; source files untouched).

---

### BLOCKER 1 — All six P0 city pages missing ✅ RESOLVED

The old site's entire local-search footprint is six city pages, 1,030–1,301 words each.
**None existed in the new build.**

| Old URL | Original words | Existed in new build? |
|---|---|---|
| `/mice-company-in-delhi/` | 1,047 | NO |
| `/mice-company-in-noida/` | 1,031 | NO |
| `/mice-company-in-gurugram/` | 1,229 | NO |
| `/corporate-travel-agency-in-mumbai/` | 1,301 | NO |
| `/corporate-travel-agency-in-bangalore/` | 1,244 | NO |
| `/corporate-event-planners-in-pune/` | 1,030 | NO |

Keyword scan of the new build: **noida, gurugram, bangalore, pune appeared nowhere.**
*delhi* appeared only inside the footer postal address. *mumbai* appeared once on the homepage.

**Resolution — two stages.**
First attempt staged the raw crawl snapshots verbatim. That failed on a second
audit: the snapshots depend on **41 WordPress theme/plugin/core asset files**, and
`.htaccess` correctly 301s `/wp-content/` and `/wp-includes/` to `/`. Those pages
would have rendered **completely unstyled**.

Final approach: extract the semantic content (H1, H2, H3, paragraphs, lists) from
each snapshot and inject it into the **new site template**.

| URL | Words now | Title (verbatim from snapshot) |
|---|---|---|
| `/mice-company-in-delhi/` | 913 | Mice Company In Delhi \| Corporate Event Planner in Delhi |
| `/mice-company-in-noida/` | 898 | Mice Company in Noida \| Corporate Travel Agency in Noida |
| `/mice-company-in-gurugram/` | 1,097 | MICE Company in Gurugram\| MICE Travel Agency in Gurugram |
| `/corporate-travel-agency-in-mumbai/` | 1,169 | Corporate Travel Agency in Mumbai \| Mice Company In Mumbai |
| `/corporate-travel-agency-in-bangalore/` | 1,110 | Corporate Travel Agency in Bangalore \| MICE Company in Bangalore |
| `/corporate-event-planners-in-pune/` | 908 | Corporate Event Planners In Pune \| event planning in pune |

Result: original URL + original SEO metadata + original copy + new design + **zero
WordPress dependencies**. Word counts are 6–15% below the original because chrome
was stripped and repeated headings de-duplicated.

---

### BLOCKER 2 — 33 broken internal link targets ✅ RESOLVED

Every page linked to Tourm template pages that were never created.

| Missing target | Linked from |
|---|---|
| `home-travel.html` | 15 of 17 pages |
| `our services.html` *(space in filename)* | 15 of 17 pages |
| `blog-details.html` | 15 of 17 pages |
| `index.html.html` *(find/replace bug)* | 12 pages |
| `tour-details.html`, `faq.html`, `service-details.html`, `shop.html`, `shop-details.html`, `cart.html`, `checkout.html`, `wishlist.html`, `activities.html`, `activities-details.html`, `resort.html`, `resort-details.html`, `gallery.html`, `price.html`, `tour.html`, `tour-guide.html`, `tour-guider-details.html`, `destination.html`, `destination-details.html`, `service.html` | 2–3 each |
| `home-tour.html`, `home-agency.html`, `home-resort.html`, `home-forest.html`, `home-beach.html`, `home-yacht.html`, `home-hiking.html`, `home-hiking-2.html`, `home-countryside-hotel.html` | 2 each |

**Root cause:** the desktop nav was clean (5 links). The broken links lived in the
**Tourm demo mobile menu** (`th-mobile-menu`) embedded in all 17 pages, carrying
Shop / Activities / Tour / Resort submenus — plus the sidebar logo and "Recent
Posts" widget.

**Resolution:** the mobile menu `<ul>` is replaced at build time with a real 5-item
menu plus Services and Locations submenus. All remaining internal links are rewritten
through a 45-entry link map to their **final** clean URL, so navigation costs zero
redirect hops. Verified: **841 links scanned, 0 broken, 0 `.html` links remaining.**

---

### BLOCKER 3 — No unique titles, descriptions or canonicals ✅ RESOLVED

| Element | Old live site | New build (before) | Staging (now) |
|---|---|---|---|
| `<title>` | Unique on all 14 URLs | **`houseofvacation`** on 14 of 17 | **21 unique**, 25–64 chars |
| Meta description | Present on 11 | **`Tourm - Travel & Tour Booking Agency HTML Template`** on all 17 | **21 unique**, 112–162 chars |
| Canonical | Self-referencing on 13 | **none on any page** | **21**, all correct |
| H1 | Unique per page | duplicated across 3–4 pages | **exactly 1** per page |

**Provenance policy applied:** audit values used **verbatim** where they exist
(`/`, `/about-company/`, and all six city pages). Created only where the audit
value was unusable — `/contact-us/` (original was `"Phone Number:"`, 13 chars) and
`/blog/` (had none) — and for the 11 new service pages that never existed.
Every entry records this in `seo-metadata.json` under `Source`.

---

### BLOCKER 4 — Document-relative asset paths ✅ RESOLVED

All **181 asset references per page** used `assets/css/…` with **no `<base>` tag**.
A page served at `/about-company/` would resolve `assets/css/style.css` to
`/about-company/assets/css/style.css` → 404. Every stylesheet, script and image
would break at a clean URL.

**Resolution:** converted to root-relative `/assets/…` at build time.
The first pass missed `data-mask-src="assets/img/logo_bg_mask.png"` — a custom data
attribute the theme's JS reads — because the regex only covered `src`/`href`/`srcset`.
Broadened to cover **every** attribute plus CSS `url()`.
Verified: **1,447 asset references, 0 document-relative, 0 broken.**

---

### BLOCKER 5 — Template artefacts ✅ RESOLVED

| Item | Resolution |
|---|---|
| `my-account.html` | Excluded from deployment |
| `error.html` (titled "Tourm … Error Page") | Excluded; replaced by branded `404.html` |
| `our services.html` (space in filename) | Link map → `/our-services/` |
| 101 × `"Tourm"` strings | **0** — 59 `alt="Tourm"` → `alt="House of Vacations"`; `author` meta corrected; template `keywords` meta removed |
| `H/assets/` (859 files duplicating 829) | 117 unique files merged into `/assets/`; rest are duplicates |
| `CORPORATE TRAVEL BANNNER.png` | Unreferenced, 1 MB, space + typo — not deployed |

---

## PART 2 — LIVE SITE AUDIT (pre-migration baseline)

### URL inventory: 14 live URLs
13 indexable + 1 noindex author archive. **Zero orphans. Zero legacy URL debt** —
Wayback CDX shows only the root URL existed before 2025; the `wp-hotel-booking`
plugin and 38 hotel demo images were an unused theme demo, never published.

### Technical stack
```
WordPress 6.7.7 · Astra theme · Elementor 4.1.1 · Rank Math SEO
Hostinger shared (hPanel) · LiteSpeed · PHP 8.1.34 · Server: hcdn (Mumbai edge)
GA4 G-39RQE9L4LF · Meta Pixel 854699396884800 · No GTM
Plugins: wp-hotel-booking, forminator, call-now-button, wp-whatsapp-chat,
         bdthemes-element-pack-lite, prime-slider-lite, pixel-gallery,
         ultimate-post-kit, pro-elements
```

### Existing live redirect behaviour (re-verified at checkpoint)
```
http://houseofvacation.com/          301 -> https://houseofvacation.com/
https://www.houseofvacation.com/     301 -> https://houseofvacation.com/
/about-company                       301 -> /about-company/
/index.php                           301 -> /
/dubai/  (attachment page)           301 -> /
/2024/  /2025/  (date archives)      301 -> /
/sitemap.xml, /wp-sitemap.xml        301 -> /sitemap_index.xml
Unknown URL                          404 (correct header)
/favicon.ico                         404
http://www. + deep path              2 hops (acceptable worst case)
```

Canonical host confirmed: **`https://houseofvacation.com`** — HTTPS, non-www,
trailing slash. Every canonical, internal link and sitemap entry uses a trailing slash.

### Live-site SEO defects found
| # | Issue | Severity |
|---|---|---|
| 1 | **Infinite `?no-cache=<hex>` URLs** — unique per pageload, 200, full duplicate content, unblocked. A test crawl reached 80 URLs and was still generating | CRITICAL |
| 2 | `Cache-Control: no-store` on HTML + `Expires: 1981` — the cause of #1 | HIGH |
| 3 | Breadcrumb schema contained **only "Home"** on all 11 pages that had it | HIGH |
| 4 | **No FAQPage schema** despite FAQs on 7 pages | HIGH |
| 5 | **No LocalBusiness/TravelAgency schema** on any service or contact page — it fired only on blog/category/author | HIGH |
| 6 | Organization schema `name` was the bare string `"houseofvacation.com"`; no address, phone, email or `sameAs` | HIGH |
| 7 | `/hello-world/` — unedited WordPress default post, indexable | HIGH |
| 8 | `/new-blog/` — body and meta description both read `"Test blog pag e"`, indexable | HIGH |
| 9 | H2 **"Types of MICE Services We Offer in Gujarat"** on the Bangalore page — copy-paste error; no Gujarat page exists | HIGH |
| 10 | `/About-Company/` (uppercase) served **200 duplicate content**, saved only by canonical | MEDIUM |
| 11 | `/page/2/`, `/page/3/` served byte-identical homepage duplicates | MEDIUM |
| 12 | 100 of 130 media files orphaned (77%); 38 MB of unused MP4s; 18 destination JPGs at 2–3 MB each | MEDIUM |
| 13 | Homepage client logos had `alt="1"`…`alt="10"` and no width/height | MEDIUM |
| 14 | 52 CSS + 52 JS files on the homepage, unbundled; 344 KB raw HTML | MEDIUM |
| 15 | Broken `tel:+91922047800` — one digit short | MEDIUM |
| 16 | Inconsistent city slug patterns across the same page type | MEDIUM |
| 17 | WP REST API fully open at `/wp-json/` — enumerates pages, posts, users, media | MEDIUM |
| 18 | `/favicon.ico` 404 | LOW |
| 19 | `X-Powered-By: PHP/8.1.34` disclosed | LOW |
| 20 | `twitter:card = summary_large_image` on 8 pages with no `og:image` | LOW |

### Missing SEO elements on the live site
| Element | Missing on |
|---|---|
| H1 | `/blog/`, `/contact-us/`, `/about-company/` |
| Meta description | `/blog/`, `/category/uncategorized/`, `/author/…` |
| `og:image` | 8 of 14 URLs incl. homepage |
| Canonical | `/author/essenceofnature43gmail-com/` |
| FAQPage schema | all 7 pages with FAQs |
| hreflang | all 14 |

### Media library
130 files · 86.3 MB · **30 in use, 100 orphaned**
Only 13 of 130 have alt text. Heaviest: three MP4s totalling 38 MB (all orphaned),
18 destination JPGs at 2–3 MB each (all orphaned).
`/wp-content/uploads/` folders: `2021/05` (38 hotel demo), `2022/11` (1),
`2024/06` (10), `2024/12` (45), `2025/01` (18), `2025/06` (10), `2025/07` (8).

### Internal linking (live site)
504 link edges, flat template-driven structure. Every one of the six city pages
received **exactly 30** inbound links — all from global header/footer nav, meaning
**zero contextual/editorial cross-linking**. Each city page mentioned the other five
cities exactly twice (nav only, never in body copy).

### Content gaps observed on the live site
No `/services/` page; no pages for the 16 offering types listed in the homepage form
dropdown; no destination pages despite 18 destination photos in the library; no
industry pages despite 10 industries named as H2s; no case studies; no privacy
policy, terms or cookie page (site runs GA4 + Meta Pixel); no team page.
