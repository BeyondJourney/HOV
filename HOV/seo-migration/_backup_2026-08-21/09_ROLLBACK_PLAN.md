# 09 — ROLLBACK PLAN

**Objective:** restore the previous working website with zero SEO loss.

**Current position at this checkpoint: nothing to roll back.**
The live site has not been changed. This plan applies only *after* a deployment.

---

## THE CORE ADVANTAGE

**No URL changes in this migration.** Every URL the old site served either:
- serves the same content at the same URL in the new build, or
- 301s to a live equivalent

That means rollback is **complete and immediate** with no SEO side-effects.
There are no redirects to unwind and no URLs to re-map. Google sees the site
return to exactly what it indexed before.

---

## PRIORITY ORDER (highest first)

1. **Preserve `/wp-content/uploads/`** — never delete it, in any scenario
2. **Restore the old `.htaccess`** — this alone fixes most redirect emergencies
3. **Restore the old website files**
4. **Preserve all existing SEO URLs**
5. **Avoid accidental deletion** — always copy aside before removing

---

## WHAT YOU MUST HAVE BEFORE DEPLOYING

Rollback is only possible if these exist. Confirm before Step 7 of `08_NEXT_STEPS.md`.

| Artefact | Where | Why |
|---|---|---|
| Full `public_html/` backup | Downloaded locally from hPanel | The whole old site |
| WordPress database export | Downloaded `.sql` | Rank Math focus keywords live only here |
| Old `.htaccess` | Downloaded separately | Fastest possible fix path |
| `/wp-content/uploads/` copy | Downloaded locally | 30 live images + all `og:image` |
| DNS record screenshot | Local | In case anything touches DNS |

**If any of these is missing, do not deploy.**

---

## SCENARIO A — Redirect loop, chain, or mass 404 (most likely)

**Symptom:** site unreachable, browser reports "too many redirects", or every URL 404s.
**Cause:** almost always `.htaccess`.
**Time to fix: under 2 minutes.**

1. hPanel → File Manager → `public_html/`
2. Settings → **Show hidden files**
3. Rename the current `.htaccess` to `.htaccess.broken`
   *(rename — do **not** delete; you will want it to diagnose)*
4. Upload the old `.htaccess` from your backup
5. hPanel → Advanced → **LiteSpeed Cache → Purge All**
6. Test:
   ```powershell
   curl.exe -sI https://houseofvacation.com/ | findstr /i "HTTP/"
   ```

**Most common single cause:** the `X-Forwarded-Proto` guard was removed from the
HTTPS rule. Hostinger fronts the origin with a CDN (`Server: hcdn`), so `%{HTTPS}`
reads "off" at origin and the rule redirects forever. That guard must stay.

---

## SCENARIO B — Site loads but is completely unstyled

**Symptom:** plain HTML, no CSS.
**Cause:** asset paths, or `/assets/` did not upload.

1. Open devtools → Network → look for 404s on `/assets/css/style.css`
2. If 404: `/assets/` did not upload — re-upload that folder only. **No rollback needed.**
3. If the path is `assets/...` without a leading slash: the build did not convert
   paths. Rebuild locally and re-upload:
   ```powershell
   cd "HOV\seo-migration"
   .\build-deploy.ps1 -Clean
   .\qa-staging.ps1
   ```

---

## SCENARIO C — Images broken across the site

**Symptom:** page text fine, images missing, social preview cards blank.
**Cause:** `/wp-content/uploads/` missing or was deleted.

1. **Do not roll back the whole site.** Restore only the uploads folder.
2. Upload `wp-content/uploads/` from your local copy into `public_html/wp-content/`
3. Verify:
   ```powershell
   curl.exe -s -o NUL -w "%{http_code}" "https://houseofvacation.com/wp-content/uploads/2025/07/MICE-3.jpg"
   ```
   Expect **200**.

> This is why the uploads folder is never deleted from the server during deployment.

---

## SCENARIO D — Full rollback to WordPress

**Symptom:** rankings collapsing, or the new site is fundamentally broken.

1. **Copy the failed build aside first — do not delete it:**
   hPanel → File Manager → create `public_html_failed_YYYYMMDD/` and move the new
   files into it. You will want them for diagnosis.
2. **Keep `wp-content/uploads/` exactly where it is.** Both the old and new sites
   use the same path. Do not move or delete it.
3. Restore the `public_html/` backup:
   hPanel → **Files → Backups** → select the pre-migration backup → Restore
   *(or upload your downloaded archive and extract)*
4. Restore the database if it was dropped:
   hPanel → phpMyAdmin → import the `.sql` export
5. Confirm `wp-config.php` is present and its DB credentials match
6. hPanel → Advanced → **LiteSpeed Cache → Purge All**
7. Verify:
   ```powershell
   curl.exe -s "https://houseofvacation.com/" | findstr /i "<title>"
   ```
   Expect: `MICE Company in India | Corporate Travel Agency`
8. Spot-check all six city pages return 200

**Expected time: 15–30 minutes**, mostly restore time.

---

## POST-ROLLBACK VERIFICATION

Run the checkpoint's own test suite — it validates the *old* URLs too, since none changed:

```powershell
cd "HOV\seo-migration"
.\test-live.ps1
```

Then confirm manually:
- [ ] All 6 P0 city URLs return **200**
- [ ] `/`, `/about-company/`, `/contact-us/`, `/blog/` return **200**
- [ ] `/wp-content/uploads/2025/07/MICE-3.jpg` returns **200**
- [ ] `http://` and `www.` still 301 to the canonical host
- [ ] An unknown URL returns **404**
- [ ] Contact form works
- [ ] GSC shows no spike in Coverage errors over the next 48h

---

## THINGS THAT MUST NEVER BE DELETED

| Path | Consequence if deleted |
|---|---|
| `public_html/wp-content/uploads/` | 30 live images dead; every `og:image` and social card breaks; Google Images traffic lost |
| Your local `.htaccess` backup | Loses the fastest rollback path |
| The WordPress database export | Rank Math focus keywords unrecoverable |
| `HOV\` source `*.html` files | The staging build cannot be regenerated |
| `HOV\seo-migration\_backup_2026-08-21\` | This checkpoint |
| `HOV\seo-audit-export\` | Pre-migration SEO baseline — the only record of original metadata |

---

## SAFE-DELETION RULE

Before removing anything on the server:

1. **Rename or move it first** (`.old`, or into `_failed_YYYYMMDD/`)
2. Verify the site still behaves correctly
3. Delete only after 7 days of stable operation

Renaming is instant and reversible. Deletion is neither.

---

## ROLLBACK DECISION GUIDE

| Situation | Action |
|---|---|
| Redirect loop / mass 404 | Scenario A — swap `.htaccess`, 2 min |
| Unstyled site | Scenario B — re-upload `/assets/`, no rollback |
| Images missing | Scenario C — re-upload uploads folder, no rollback |
| One page wrong | Fix that page, re-upload it. No rollback |
| Rankings dropping >50% after a week | Investigate first — check for a URL that changed without a 301. Full rollback only if the cause cannot be found |
| Site fundamentally broken | Scenario D — full rollback |

**Do not roll back for a cosmetic issue.** Rollback is for structural failure.
Most problems are fixed by replacing one file.
