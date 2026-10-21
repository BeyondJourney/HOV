One-off page transforms run on 2026-10-21 (both idempotent, both skip pages
that already carry their marker class):

  transform-services.ps1  the ten service pages: inline stylesheet removed,
                          "Corporate-Trip.com" -> House of Vacation, duplicate
                          h3 dropped, overview + photo + actions, every text
                          section split into .hov-svc-text | aside.
  transform-city.ps1      the six location pages: proposal button, chip lists,
                          definition cards, grouped destinations, two-column
                          long cards, Bangalore "Gujarat" heading corrected.

The layout they produce is styled in assets/css/hov-theme.css section 13 and
assets/css/site-fixes.css section 20. Kept here for provenance only.