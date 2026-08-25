HOUSE OF VACATION - SEO URL EXPORT
Captured: 21 August 2026
Source: https://houseofvacation.com/

METHOD
  - robots.txt + sitemap_index.xml (Rank Math)
  - Full recursive HTML crawl (raw source, not rendered text)
  - WordPress REST API enumeration (all post types, taxonomies, users, media)
  - Wayback Machine CDX history check (legacy URL verification)

HEADLINE NUMBERS
  14   total live URLs
  13   indexable URLs (author archive is noindex)
  10   WordPress pages + 2 posts + 1 category + 1 author archive
  0    orphan pages
  0    legacy URLs requiring redirects
  130  media assets (30 in use, 100 orphaned)
  504  internal link edges

FILES
  01_URL_LIST.csv                    14 URLs with priority, type, title, meta, H1, word count
  02_URL_LIST_PLAIN.txt              Plain URL list, one per line (paste into Screaming Frog etc.)
  03_sitemap.xml                     Ready-to-deploy sitemap, 13 indexable URLs
  04_NON_PAGE_URLS_AND_REDIRECTS.csv Redirect rules, feeds, duplicate-URL gaps, 404s
  05_ALL_IMAGE_ASSET_URLS.csv        All 130 media URLs with size, alt, in-use flag
  06_INTERNAL_LINK_MAP.csv           All 504 internal + external link edges
  07_FULL_SEO_AUDIT.csv              Complete 26-column per-page SEO audit

PRIORITY KEY
  P0  Commercial pages carrying search traffic. URL must not change.
  P1  Supporting pages with significant internal links.
  P2  Archive page, currently indexable and in sitemap.
  P3  Low value. Placeholder / WordPress default content.

CRITICAL MIGRATION NOTES
  1. ALL URLs use a TRAILING SLASH. Non-slash variants 301 to the slash version.
     Many modern frameworks strip trailing slashes by default. If that happens,
     all 13 URLs change silently.
  2. Keep all 6 city slugs exactly as-is despite inconsistent naming
     (mice-company-in-X vs corporate-travel-agency-in-X vs corporate-event-planners-in-X).
     Normalising them costs existing rankings.
  3. Rank Math focus keywords exist only in the WordPress database.
     They are recovered in 07_FULL_SEO_AUDIT.csv. Export before decommissioning WP.
  4. Three duplicate-URL gaps must NOT be reproduced: ?no-cache= random params,
     uppercase paths serving 200, and /page/2/ + /page/3/ duplicating the homepage.
