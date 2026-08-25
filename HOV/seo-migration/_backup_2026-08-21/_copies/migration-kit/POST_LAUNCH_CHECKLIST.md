# Post-Launch Checklist

---

## T + 15 MINUTES — smoke test

```powershell
cd "HOV\seo-migration"
.\test-live.ps1
```

- [ ] Script exits **0**
- [ ] Homepage loads with correct styling (if unstyled → asset paths broke)
- [ ] All 6 city pages return 200
- [ ] Images load — spot-check `og:image` targets
- [ ] Contact form submits and the email arrives
- [ ] Check on a real phone, not just a resized browser

**If styling is broken:** almost always the `assets/` → `/assets/` conversion.
Re-run `build-deploy.ps1` and re-upload. Do not hand-edit on the server.

---

## T + 1 HOUR

- [ ] Google Search Console → **URL Inspection** on all 6 city pages → "URL is on Google"
- [ ] GSC → Sitemaps → submit `https://houseofvacation.com/sitemap.xml`
- [ ] Remove the old sitemap entry (`sitemap_index.xml`) once the new one shows "Success"
- [ ] Confirm GA4 (`G-39RQE9L4LF`) is firing — Realtime report
- [ ] Confirm Meta Pixel (`854699396884800`) is firing
- [ ] `https://houseofvacation.com/robots.txt` loads and points at the new sitemap
- [ ] Test social sharing — paste a city page URL into LinkedIn or WhatsApp and confirm
      the preview card renders (this is what `og:image` drives)

---

## T + 24 HOURS

- [ ] GSC → **Coverage / Pages** — no spike in "Not found (404)"
- [ ] GSC → no spike in "Redirect error" or "Soft 404"
- [ ] GA4 → organic sessions within ~20% of the previous day
- [ ] Check server error logs in hPanel for 500s
- [ ] Re-run `test-live.ps1` — still exits 0

---

## T + 1 WEEK

- [ ] GSC → Performance → compare impressions/clicks to the prior week
      A 10–20% dip is normal during re-crawl. **A 50%+ drop means something is wrong** —
      check for a URL that changed without a 301
- [ ] GSC → Pages → all 21 URLs indexed
- [ ] Confirm the 6 city pages still rank for their focus keywords:
      `MICE company in Delhi`, `Mice Company in Noida`, `MICE Company in Gurugram`,
      `Corporate Travel Agency in Mumbai`, `Corporate Travel Agency in Bangalore`,
      `Corporate Event Planners In Pune`
- [ ] Review hPanel access logs, filter status 404, add any recurring URL with a real
      referer into the `.htaccess` redirect map (Section 4 of that file)
- [ ] Confirm no `?no-cache=` URLs appear in GSC

---

## T + 1 MONTH

- [ ] Rankings recovered to baseline or better
- [ ] All 21 URLs indexed, 0 excluded by error
- [ ] Old WordPress URLs dropping out of the index (expected and correct)
- [ ] Decide whether the six preserved city pages are being rebuilt in the new design
- [ ] Once rebuilt: drop the new HTML into the same folder. **No `.htaccess` change,
      no redirect, no re-indexing needed** — the URL never moved
- [ ] Consider adding the content gaps identified in the original audit:
      privacy policy, terms, destination pages, industry pages

---

## Ongoing — monthly

- [ ] Run `test-live.ps1`, confirm exit 0
- [ ] Review 404 logs → promote recurring hits into the redirect map
- [ ] Confirm no redirect chains have crept in (the script checks this)
- [ ] Keep `sitemap.xml` in sync when pages are added

---

## Warning signs — act immediately

| Symptom | Likely cause |
|---|---|
| Rankings drop >50% in a week | A URL changed without a 301 |
| GSC "Soft 404" climbing | Something is redirecting unknown URLs to `/` |
| GSC "Redirect error" | A redirect loop or chain — run `test-live.ps1` |
| Images 404 in GSC | `/wp-content/uploads/` was not uploaded |
| Site unstyled | `assets/` paths not converted to root-relative |
| Traffic to `?no-cache=` URLs | The `no-store` cache header came back |

**Rollback:** restore the `public_html/` backup from hPanel. Because no URL changes,
rollback is complete and immediate with no SEO side-effects.
