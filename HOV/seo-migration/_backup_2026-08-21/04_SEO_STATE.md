# 04 - SEO STATE

**Checkpoint:** 21 August 2026 | **Canonical host:** `https://houseofvacation.com` (HTTPS, non-www, trailing slash)

---

## THE SIX P0 CITY PAGES

These carry the entire local-search footprint. **Their URLs must never change.**
They did NOT exist in the new build and were rebuilt from pre-migration crawl
snapshots: original title, meta description, og:image and body copy injected into
the new site template.

### `/corporate-event-planners-in-pune/`
- **Title** (57): Corporate Event Planners In Pune | event planning in pune
- **Meta description** (160): Welcome to HOV, your Trusted Corporate MICE Event Planners in Pune, offering end-to-end solutions for corporate travel, events, and incentive tours | Contact us
- **Canonical:** https://houseofvacation.com/corporate-event-planners-in-pune/
- **H1 count:** 1
- **Metadata source:** VERBATIM from pre-migration snapshot

### `/corporate-travel-agency-in-bangalore/`
- **Title** (64): Corporate Travel Agency in Bangalore | MICE Company in Bangalore
- **Meta description** (159): Leading Corporate Travel Agency in Bangalore for MICE & events. Travel smart, plan better—partner with House of Vacations today! | Contact us at +91 9220470800
- **Canonical:** https://houseofvacation.com/corporate-travel-agency-in-bangalore/
- **H1 count:** 1
- **Metadata source:** VERBATIM from pre-migration snapshot

### `/corporate-travel-agency-in-mumbai/`
- **Title** (58): Corporate Travel Agency in Mumbai | Mice Company In Mumbai
- **Meta description** (156): Welcome to HOV, your Trusted Corporate Travel Agency in Mumbai, offering end-to-end solutions for corporate travel, events, and incentive tours | Contact us
- **Canonical:** https://houseofvacation.com/corporate-travel-agency-in-mumbai/
- **H1 count:** 1
- **Metadata source:** VERBATIM from pre-migration snapshot

### `/mice-company-in-delhi/`
- **Title** (56): Mice Company In Delhi | Corporate Event Planner in Delhi
- **Meta description** (158): HOV is a leading MICE company in Delhi, specializing in corporate events, meetings, incentives, conferences, and exhibitions. Contact us today for your MICE !
- **Canonical:** https://houseofvacation.com/mice-company-in-delhi/
- **H1 count:** 1
- **Metadata source:** VERBATIM from pre-migration snapshot

### `/mice-company-in-gurugram/`
- **Title** (56): MICE Company in Gurugram| MICE Travel Agency in Gurugram
- **Meta description** (162): Welcome to House of Vacations, your Trusted MICE Company in Gurugram, offering end-to-end solutions for corporate travel, events, and incentive tours | Contact us
- **Canonical:** https://houseofvacation.com/mice-company-in-gurugram/
- **H1 count:** 1
- **Metadata source:** VERBATIM from pre-migration snapshot

### `/mice-company-in-noida/`
- **Title** (56): Mice Company in Noida | Corporate Travel Agency in Noida
- **Meta description** (140): Welcome to HOV, your Trusted Mice Company in Noida, offering end-to-end solutions for corporate travel, events, and tours | Contact us Today
- **Canonical:** https://houseofvacation.com/mice-company-in-noida/
- **H1 count:** 1
- **Metadata source:** VERBATIM from pre-migration snapshot

---

## ALL 21 STAGED URLs - CURRENT SEO STATE

| URL | Title | Len | Desc len | Canonical OK | H1 |
|---|---|---|---|---|---|
| `/` | MICE Company in India \| Corporate Travel Agency | 47 | 144 | YES | 1 |
| `/about-company/` | About us - House of Vacations | 29 | 154 | YES | 1 |
| `/adventure-group/` | Adventure Group Tours for Corporates \| House of Vacations | 57 | 131 | YES | 1 |
| `/blog/` | Blog - House of Vacations | 25 | 112 | YES | 1 |
| `/conferences-event/` | Corporate Conference Management in India \| House of Vacations | 61 | 124 | YES | 1 |
| `/contact-us/` | Contact us - House of Vacations | 31 | 152 | YES | 1 |
| `/corporate-celebration/` | Corporate Celebrations & Annual Day Events \| House of Vacations | 63 | 120 | YES | 1 |
| `/corporate-event-planners-in-pune/` | Corporate Event Planners In Pune \| event planning in pune | 57 | 160 | YES | 1 |
| `/corporate-travel/` | Corporate Travel Management Services \| House of Vacations | 57 | 148 | YES | 1 |
| `/corporate-travel-agency-in-bangalore/` | Corporate Travel Agency in Bangalore \| MICE Company in Bangalore | 64 | 159 | YES | 1 |
| `/corporate-travel-agency-in-mumbai/` | Corporate Travel Agency in Mumbai \| Mice Company In Mumbai | 58 | 156 | YES | 1 |
| `/corporate-travel-consultancy/` | Corporate Travel Consultancy \| House of Vacations | 49 | 142 | YES | 1 |
| `/customized-group/` | Customised Group Tours for Corporates \| House of Vacations | 58 | 127 | YES | 1 |
| `/destination-management/` | Destination Management & Visa Assistance \| House of Vacations | 61 | 120 | YES | 1 |
| `/incentive/` | Incentive Travel Programmes for Corporates \| House of Vacations | 63 | 124 | YES | 1 |
| `/mice-company-in-delhi/` | Mice Company In Delhi \| Corporate Event Planner in Delhi | 56 | 158 | YES | 1 |
| `/mice-company-in-gurugram/` | MICE Company in Gurugram\| MICE Travel Agency in Gurugram | 56 | 162 | YES | 1 |
| `/mice-company-in-noida/` | Mice Company in Noida \| Corporate Travel Agency in Noida | 56 | 140 | YES | 1 |
| `/mice-event/` | MICE Event Management Company in India \| House of Vacations | 59 | 137 | YES | 1 |
| `/offsite-events/` | Corporate Offsite Event Planning in India \| House of Vacations | 62 | 119 | YES | 1 |
| `/our-services/` | Our MICE & Corporate Travel Services \| House of Vacations | 57 | 148 | YES | 1 |


---

## REDIRECT REQUIREMENTS

Full machine-readable map: `03_URL_MIGRATION_STATE.csv` (54 rows).

### Canonicalisation - all 301, single hop
| From | To |
|---|---|
| `http://*` | `https://houseofvacation.com/*` |
| `https://www.*` | `https://houseofvacation.com/*` |
| `http://www.*` + deep path | `https://houseofvacation.com/path/` (ONE rule handles all three) |
| `/path` (no slash) | `/path/` (native Apache `DirectorySlash`) |
| `/About-Company/` (uppercase) | `/about-company/` |
| `/index.html`, `/*.html` | clean folder URL |

The HTTPS rule checks `X-Forwarded-Proto` because Hostinger fronts the origin with
a CDN (`Server: hcdn`). Without that guard `%{HTTPS}` reads "off" at origin and the
rule produces an **infinite redirect loop**. Do not remove it.

### Obsolete WordPress URLs - 301
| From | To |
|---|---|
| `/category/uncategorized/`, `/hello-world/`, `/new-blog/`, `/author/*`, all feeds | `/blog/` |
| `/wp-admin/*`, `/wp-json/*`, `/wp-includes/*`, `/wp-login.php`, `/xmlrpc.php`, `/index.php` | `/` |
| `/wp-content/*` **except** `/uploads/` | `/` |
| `/2024/`, `/2025/`, `/page/N/` | `/` |
| `/sitemap_index.xml` + 3 legacy child sitemaps | `/sitemap.xml` |
| `*?no-cache=*`, `*?attachment_id=*` | clean URL, query stripped |

### NEVER redirected
`/wp-content/uploads/*` and `/assets/*` are excluded in **rule 0**, before any other
rule can match. Any real file or directory also short-circuits with `[L]`.

**Guarantees verified by static analysis:** 23 x 301, **0 x 302**, **0 chains**, **0 loops**.

---

## 404 STRATEGY

**Unknown URLs return a genuine HTTP 404** via `ErrorDocument 404 /404.html`.

They are deliberately **NOT** redirected to the homepage. The original brief asked
for that, and it was flagged as an SEO anti-pattern: Google treats mass
redirect-to-homepage as a **soft 404**, the dead URLs stay in the index as errors,
and genuinely broken internal links become invisible because everything appears to
"work".

`404.html` is branded, returns a real 404 status, carries `noindex, follow`, and
links to all six city pages plus services, about, blog and contact.

**Do not change this without a deliberate decision.**

---

## SITEMAP STRATEGY

- Single `sitemap.xml` at the domain root, **21 URLs**, XML-validated.
- Priorities: `/` = 1.0, six city pages = 0.9, contact/about/services = 0.8,
  remaining service pages = 0.7, blog = 0.6.
- `robots.txt` points at `https://houseofvacation.com/sitemap.xml`.
- All four legacy Rank Math sitemaps 301 to the new one.
- `robots.txt` blocks `/wp-admin/`, `/wp-json/`, `/wp-includes/`, `/author/`,
  `*?no-cache=`, `*?attachment_id=` but **explicitly allows** `/wp-content/uploads/`
  and `/assets/` so image indexing survives.
- After go-live: submit the new sitemap in Search Console and remove the old
  `sitemap_index.xml` entry once the new one reports Success.

---

## KNOWN SEO RISKS

| # | Risk | Severity | Mitigation |
|---|---|---|---|
| 1 | `/wp-content/uploads/` not yet staged | **CRITICAL** | Download before deploy. 30 images + every `og:image` depend on it |
| 2 | Trailing-slash convention broken by a future tool | **HIGH** | Every canonical, link and sitemap entry uses a trailing slash. `.htaccess` enforces it. Never let a build tool strip them |
| 3 | Someone "tidies" the inconsistent city slugs | **HIGH** | Three patterns are in use. Normalising costs existing rankings. Keep exactly as-is |
| 4 | Rank Math focus keywords lost | **HIGH** | They live only in the WP database. Seven were recovered from Article schema into `seo-audit-export/07_FULL_SEO_AUDIT.csv`. Export the DB before decommissioning |
| 5 | City page copy 6-15% shorter than original | MEDIUM | Extraction dropped chrome and de-duplicated repeated headings. Review one page and top up if parity is wanted |
| 6 | No Organization / LocalBusiness schema | MEDIUM | Old site had only `"name":"houseofvacation.com"` with no NAP. Add real address, phone, `sameAs` |
| 7 | No FAQPage schema | MEDIUM | 7 pages have visible FAQs. Was missing before too, so not a regression |
| 8 | `Cache-Control: no-store` reintroduced | MEDIUM | That header caused the infinite `?no-cache=` URL explosion. The new `.htaccess` sets `max-age=0, must-revalidate` instead. QA checks for it |
| 9 | City pages use a generic layout | MEDIUM | Content and SEO correct. Restyling later needs **no** `.htaccess` change and **no** re-indexing - the URL never moves |
| 10 | Duplicate H1 *text* on some new service pages | LOW | Structurally valid (1 H1 each) but weak differentiation |
| 11 | No privacy policy / terms | MEDIUM | Both 404 today; site runs GA4 + Meta Pixel |

---

## REFERENCE: ORIGINAL LIVE-SITE SEO (pre-migration baseline)

Source of truth: `seo-audit-export/07_FULL_SEO_AUDIT.csv` (14 URLs x 26 columns).

| Old URL | Original title | Fate |
|---|---|---|
| `/` | MICE Company in India \| Corporate Travel Agency | KEEP, metadata verbatim |
| `/about-company/` | About us - House of Vacations | KEEP, metadata verbatim |
| `/contact-us/` | Contact us - House of Vacations | KEEP, description rewritten (original was `"Phone Number:"`, 13 chars) |
| `/blog/` | Blog - House of Vacations | KEEP, description created (original had none) |
| `/mice-company-in-delhi/` | Mice Company In Delhi \| Corporate Event Planner in Delhi | REBUILT, verbatim metadata |
| `/mice-company-in-noida/` | Mice Company in Noida \| Corporate Travel Agency in Noida | REBUILT, verbatim metadata |
| `/mice-company-in-gurugram/` | MICE Company in Gurugram\| MICE Travel Agency in Gurugram | REBUILT, verbatim metadata |
| `/corporate-travel-agency-in-mumbai/` | Corporate Travel Agency in Mumbai \| Mice Company In Mumbai | REBUILT, verbatim metadata |
| `/corporate-travel-agency-in-bangalore/` | Corporate Travel Agency in Bangalore \| MICE Company in Bangalore | REBUILT, verbatim metadata |
| `/corporate-event-planners-in-pune/` | Corporate Event Planners In Pune \| event planning in pune | REBUILT, verbatim metadata |
| `/category/uncategorized/` | Uncategorized - House of Vacations | 301 to `/blog/` |
| `/hello-world/` | Hello world! - House of Vacations | 301 to `/blog/` |
| `/new-blog/` | new blog - House of Vacations | 301 to `/blog/` |
| `/author/essenceofnature43gmail-com/` | info@houseofvacation.com - House of Vacations | 301 to `/blog/` (was noindex) |

### Rank Math focus keywords recovered from the live site
| URL | Focus keyword |
|---|---|
| `/` | MICE Company in India |
| `/mice-company-in-delhi/` | Mice Company In Delhi |
| `/mice-company-in-noida/` | Mice Company in Noida |
| `/mice-company-in-gurugram/` | MICE Company in Gurugram |
| `/corporate-travel-agency-in-mumbai/` | Corporate Travel Agency in Mumbai |
| `/corporate-travel-agency-in-bangalore/` | Corporate Travel Agency in Bangalore |
| `/corporate-event-planners-in-pune/` | Corporate Event Planners In Pune |

### Business NAP (must stay consistent everywhere)
- **Address:** 1st Floor, Office No. 115, Gagandeep Building, Rajendra Nagar, New Delhi - 110008
- **Phone:** +91-9220470800
- **Email:** mice@houseofvacation.com, info@houseofvacation.com
- **Social:** Facebook, Instagram (`houseofvacations_`), X (`houseofvacation`), LinkedIn (`house-of-vacations-india-pvt-ltd`), YouTube (`@HouseofVacations`)

> The old site contained a broken `tel:+91922047800` link - one digit short. Do not copy it.
