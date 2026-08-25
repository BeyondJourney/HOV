# 08 — NEXT STEPS

Exact sequence to complete the migration safely. **Do not reorder. Do not skip.**
Each step has a pass condition. If a step fails, stop and fix before continuing.

---

## STEP 0 — Confirm the checkpoint is intact

```powershell
cd "c:\Users\maduri\OneDrive\Desktop\HOUSE OF VACATION INDIA PVT LTD\HOV\seo-migration"
Get-ChildItem "_backup_2026-08-21"
```
**Pass:** 10 numbered files present (`01_`…`10_`) plus `_manifest_raw.csv`.

---

## STEP 1 — Back up Hostinger  ⚠️ BLOCKER

1. hPanel → **Files → Backups** → Generate new backup
2. **Download it to your machine.** A backup that exists only on the server is not a backup.
3. hPanel → **Databases → phpMyAdmin** → Export the WordPress database
   *(it holds the Rank Math focus keywords, which exist nowhere in the HTML)*
4. Download the current live `.htaccess` from `public_html/.htaccess` and keep it —
   it is part of the rollback plan
5. Record current DNS records (screenshot is fine)

**Pass:** backup archive + `.sql` export + old `.htaccess` all stored locally, and
you have verified you can open them.

---

## STEP 2 — Download `/wp-content/uploads/`  ⚠️ BLOCKER

30 live images and **every `og:image` URL** depend on these exact paths.

1. hPanel → **File Manager** → `public_html/wp-content/uploads/`
2. Download the whole folder — all 7 date subfolders:
   `2021/05`, `2022/11`, `2024/06`, `2024/12`, `2025/01`, `2025/06`, `2025/07`
3. Place locally at:
   ```
   HOV\wp-content\uploads\
   ```

**Pass:**
```powershell
(Get-ChildItem "HOV\wp-content\uploads" -Recurse -File).Count
```
returns roughly **130**.

> Do **not** delete the copy on the server. It stays until the new build serves the
> same paths successfully.

---

## STEP 3 — Rebuild and re-run offline QA

```powershell
cd "HOV\seo-migration"
.\build-deploy.ps1 -Clean
.\qa-staging.ps1
```

**Pass:**
- Build section 4 reads **"/wp-content/uploads/ … files copied"**, not "NOT FOUND LOCALLY"
- `qa-staging.ps1` exits **0** with **0 failures, 0 warnings**

If QA fails, fix the cause and repeat. Do not proceed on a failing QA.

---

## STEP 4 — Create a staging subdomain

1. hPanel → **Domains → Subdomains** → create `staging.houseofvacation.com`
2. Zip `_deploy\public_html\` contents locally, upload the archive, extract into the
   subdomain's document root
3. Confirm `.htaccess` landed at the root
   *(File Manager → Settings → **Show hidden files**)*
4. Add to the **staging `.htaccess` only** — never to production:
   ```apache
   Header always set X-Robots-Tag "noindex, nofollow"
   ```
5. Set permissions: folders `755`, files `644`

**Pass:** `https://staging.houseofvacation.com/` loads and is **styled**.
Unstyled means asset paths broke — stop and investigate.

---

## STEP 5 — Run live tests against staging

```powershell
cd "HOV\seo-migration"
.\test-live.ps1 -BaseUrl "https://staging.houseofvacation.com"
```

**Pass:** exits **0**. Specifically:
- `http://` → `https://` in **1 hop**
- `www.` → non-www in **1 hop**
- `http://www.` + deep path in **1 hop** (the combined worst case)
- All 10 KEEP URLs: **200, redirects=0**
- All 6 P0 city URLs: **200, redirects=0**
- Old WordPress URLs: **301, 1 hop**, correct target
- `/wp-content/uploads/...`: **200, redirects=0**
- `/assets/css/style.css`, `/assets/js/main.js`: **200, redirects=0**
- Nonexistent URL: **genuine 404**, no redirect
- `?no-cache=` stripped
- Homepage canonical = the staging URL (it will differ from production — expected)

> Note: the canonical check will report a mismatch on staging because canonicals are
> hard-coded to `https://houseofvacation.com/`. That is **correct and intentional** —
> canonicals must always point at production. Ignore only that one check on staging.

---

## STEP 6 — Manual QA on staging (the script cannot do these)

- [ ] Homepage renders styled on desktop
- [ ] Check on a **real phone**, not a resized browser
- [ ] Open the mobile menu — verify the new Services and Locations submenus work
- [ ] Click **every** nav and footer link — zero 404s
- [ ] Visit all 6 city pages, confirm content and headings render
- [ ] Submit the contact form; confirm the email arrives (`mail.php`)
- [ ] Paste a city page URL into WhatsApp or LinkedIn — preview card renders
- [ ] Confirm images load (this is what Step 2 was for)
- [ ] Browser devtools → Console: no fatal JS errors; Network: no 404s

---

## STEP 7 — Deploy to production

Only when Steps 1–6 have all passed.

1. hPanel → File Manager → `public_html/`
2. Delete old WordPress files — **KEEP `wp-content/uploads/`**
   Remove: `wp-admin/`, `wp-includes/`, `wp-content/themes/`,
   `wp-content/plugins/`, `wp-config.php`, `index.php`, `xmlrpc.php`, `wp-*.php`
3. Upload the **contents** of `_deploy\public_html\` into `public_html/`
   *(zip → upload → extract; not file-by-file over FTP)*
4. Confirm `.htaccess` is at `public_html/.htaccess`
5. Permissions: folders `755`, files `644`
6. hPanel → **Advanced → LiteSpeed Cache → Purge All**

**Pass:** `https://houseofvacation.com/` loads the new site, styled.

---

## STEP 8 — Verify production immediately

```powershell
.\test-live.ps1
```

**Pass:** exits **0**, and the homepage canonical now reads
`https://houseofvacation.com/`.

Then within the first hour:
- [ ] Google Search Console → URL Inspection on all 6 city pages → "URL is on Google"
- [ ] GSC → Sitemaps → submit `https://houseofvacation.com/sitemap.xml`
- [ ] Remove the old `sitemap_index.xml` entry once the new one reports Success
- [ ] Confirm GA4 (`G-39RQE9L4LF`) firing — Realtime report
- [ ] Confirm Meta Pixel (`854699396884800`) firing
- [ ] Submit the contact form on production

---

## STEP 9 — Monitor

Follow `seo-migration/POST_LAUNCH_CHECKLIST.md` for T+24h, T+1 week, T+1 month.

Watch for:

| Symptom | Likely cause |
|---|---|
| Rankings drop >50% in a week | A URL changed without a 301 |
| GSC "Soft 404" climbing | Something is redirecting unknown URLs to `/` |
| GSC "Redirect error" | A loop or chain — run `test-live.ps1` |
| Images 404 in GSC | `/wp-content/uploads/` not uploaded |
| Site unstyled | Asset paths not root-relative |
| Traffic to `?no-cache=` URLs | `no-store` header came back |

---

## OPTIONAL — after a stable launch

Not blockers. Do these once traffic is confirmed steady.

1. Add `Organization` / `LocalBusiness` schema with real NAP and `sameAs`
   *(old site had only `"name":"houseofvacation.com"`)*
2. Add `FAQPage` schema — 7 pages have visible FAQs, none marked up
3. Create privacy policy and terms pages (both 404 today; site runs GA4 + Meta Pixel)
4. Restyle the 6 city pages into a bespoke layout —
   **URL never changes, so no `.htaccess` edit and no re-indexing**
5. Top up city page copy to the original 1,030–1,301 word range
6. Differentiate duplicate H1 *text* on the new service pages
7. Add editorial cross-links between city pages
   *(the old site had zero — all 30 inbound links per page came from global nav)*
8. Clean the media library — 100 of 130 files are orphaned, including 38 MB of unused MP4s
