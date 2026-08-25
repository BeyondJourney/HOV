# Pre-Launch Checklist

Work top to bottom. **Do not proceed past Section A until every box is ticked** —
those are the items that cause irreversible ranking loss.

---

## SECTION A — BLOCKERS (launch is unsafe until these are done)

### A1. Fix 33 broken internal links
Every page links to template pages that were never built. These sit in the main
nav and footer, so they appear site-wide.

- [ ] `home-travel.html` — linked from 15 pages → repoint to `/`
- [ ] `our services.html` — linked from 15 pages, **filename has a space** → `/our-services/`
- [ ] `blog-details.html` — linked from 15 pages → `/blog/` or build the page
- [ ] `index.html.html` — linked from 12 pages, find/replace bug → `/`
- [ ] Remove e-commerce leftovers: `shop`, `cart`, `checkout`, `wishlist`
- [ ] Remove unused template links: `tour*`, `activities*`, `resort*`, `gallery`, `price`, `faq`, `home-*`
- [ ] Re-run `build-deploy.ps1`, confirm 0 broken targets

### A2. Write unique titles and meta descriptions
Currently 14 of 17 pages have `<title>houseofvacation</title>` and **all 17** carry
`Tourm - Travel & Tour Booking Agency HTML Template` as the description.

- [ ] Unique `<title>` per page, 50–60 chars
- [ ] Unique meta description per page, 140–160 chars
- [ ] Copy the four preserved values exactly from `seo-audit-export/07_FULL_SEO_AUDIT.csv`:
      `/`, `/about-company/`, `/contact-us/`, `/blog/`
- [ ] Confirm no page still says "Tourm"

### A3. Add self-referencing canonicals
Zero pages currently have one.

- [ ] `<link rel="canonical" href="https://houseofvacation.com/{path}/">` on every page
- [ ] HTTPS, non-www, **trailing slash** — must match the deployed URL exactly

### A4. Download `/wp-content/uploads/`
The build script reported this missing locally. **30 live images depend on these URLs**,
including every `og:image` tag.

- [ ] Hostinger hPanel → File Manager → `public_html/wp-content/uploads/`
- [ ] Download the whole folder (all 7 date subfolders, 2021/05 through 2025/07)
- [ ] Place at `HOV/wp-content/uploads/`
- [ ] Re-run `build-deploy.ps1` and confirm section 4 says "copied"

### A5. Decide on the six preserved city pages
They are currently staged **verbatim from the old site** — correct SEO, old design.

- [ ] Confirm this is acceptable for launch, **or**
- [ ] Rebuild them in the new design, carrying over: the H1, all H2s, 1,030–1,301 words
      of body copy, title, meta description and canonical from the audit CSV
- [ ] Either way the URL is unchanged, so **no `.htaccess` edit is needed**

---

## SECTION B — CONTENT AND STRUCTURE

- [ ] Every page has exactly one `<h1>`
- [ ] `/about-company/`, `/contact-us/`, `/blog/` have an H1 (old site had none — this is an improvement, not a regression)
- [ ] No duplicate H1 across pages (currently `about`, `corporate-travel`, and `corporate-travel-consultancy` share one)
- [ ] NAP matches the old site exactly:
      `1st Floor, Office No. 115, Gagandeep Building, Rajendra Nagar, New Delhi - 110008`
- [ ] Phone consistent everywhere: `+91-9220470800`
      (the old site had a broken `tel:+91922047800` — one digit short. Do not copy it)
- [ ] Emails present: `mice@houseofvacation.com`, `info@houseofvacation.com`
- [ ] Social links: Facebook, Instagram, X, LinkedIn, YouTube
- [ ] Add `Organization` / `TravelAgency` schema with real name, address, phone, `sameAs`
      (old site had only `"name":"houseofvacation.com"`)
- [ ] Add `FAQPage` schema where FAQ sections exist — 7 pages have FAQs, none had markup
- [ ] `/page-not-found/` and `error.html` removed; `404.html` in place

---

## SECTION C — TECHNICAL

- [ ] `.htaccess` at `public_html/.htaccess` (not in a subfolder)
- [ ] `404.html`, `robots.txt`, `sitemap.xml` at `public_html/` root
- [ ] `mail.php` present and the contact form action points at `/mail.php`
- [ ] Every page is `folder/index.html` — no bare `.html` at root except `404.html`
- [ ] No `assets/` document-relative paths remain (build script verifies: must be 0)
- [ ] `sitemap.xml` lists 21 URLs, all HTTPS non-www with trailing slash
- [ ] `robots.txt` references `https://houseofvacation.com/sitemap.xml`
- [ ] Remove `my-account.html`, `error.html`, `CORPORATE TRAVEL BANNNER.png`
- [ ] `H/` folder not uploaded — its unique files are merged into `/assets/`

---

## SECTION D — STAGING TEST (before touching production)

Deploy to a staging subdomain first, `noindex` it, then:

```powershell
cd "HOV\seo-migration"
.\test-live.ps1 -BaseUrl "https://staging.houseofvacation.com"
```

- [ ] Script exits **0** — every hard check passed
- [ ] `test-results.csv` shows 0 chains over 1 hop
- [ ] 0 × 302 anywhere
- [ ] All 10 KEEP URLs return 200 with **zero** redirects
- [ ] All 4 image URLs return 200, never redirected
- [ ] CSS/JS return 200
- [ ] Unknown URLs return a real **404**, not a redirect
- [ ] Click through every nav and footer link manually — no 404s
- [ ] Submit the contact form and confirm the email arrives
- [ ] Check on mobile

---

## SECTION E — BACKUP (do not skip)

- [ ] Full backup of current `public_html/` via hPanel → Files → Backups
- [ ] Download the backup locally — do not rely only on the server copy
- [ ] Export the WordPress database (contains Rank Math focus keywords)
- [ ] Note the current DNS records
- [ ] Confirm you can restore within 15 minutes if needed

**Rollback plan:** restore the `public_html/` backup. Because no URL changes and
the old `.htaccess` is part of the backup, rollback is complete and immediate.
