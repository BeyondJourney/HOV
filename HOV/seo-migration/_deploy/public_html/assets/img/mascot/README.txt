HOV mascot for the website preloader
====================================

Put the mascot here as:

    hov-mascot.png      transparent background, the full character with the
                        orange suitcase, roughly 800-1100 px tall, under
                        ~250 KB (export as PNG-24 with alpha, or WebP with
                        alpha named hov-mascot.webp and update the <img>).

Then run, from a PowerShell prompt in the project:

    .\HOV\seo-migration\one-off\add-preloader.ps1 -Refresh
    .\HOV\seo-migration\build-deploy.ps1

The first command rewrites the preloader block on every page so it
references the mascot; the second rebuilds the deploy folder. Until the
file exists the preloader shows the HOV brand mark instead.

Preview the loader in a browser at any time by opening a page with
?hov-pl=hold on the URL (click the loader to dismiss it), or ?hov-pl=play
to watch one normal run even if it has already played this session.

Optional, for an independent suitcase bounce: a second cut-out
hov-mascot-case.png with only the suitcase, positioned over the character
with CSS once the artwork is known.
