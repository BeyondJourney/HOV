/* ==========================================================================
   House of Vacation — theme behaviour
   --------------------------------------------------------------------------
   Small, dependency-free helpers for the brand layer. main.js (the template)
   still owns the sliders, the mobile drawer, the lightbox and the enquiry
   form; this file only adds:

     1. header state  — .is-scrolled once the page has moved, so the
                        transparent home header turns solid
     2. plan form     — the hero "plan your programme" card hands its values
                        to the contact page through the query string
     3. prefill       — the contact form reads those values back and scrolls
                        itself into view
     4. drawer        — body scroll lock while the mobile menu is open
   ========================================================================== */
(function () {
    'use strict';

    var d = document;

    /* ---- 1. header state --------------------------------------------- */
    var header = d.querySelector('.hov-header');
    if (header) {
        var threshold = header.classList.contains('hov-header--overlay') ? 40 : 8;
        var ticking = false;
        var update = function () {
            header.classList.toggle('is-scrolled', (window.scrollY || window.pageYOffset) > threshold);
            ticking = false;
        };
        window.addEventListener('scroll', function () {
            if (!ticking) { ticking = true; window.requestAnimationFrame(update); }
        }, { passive: true });
        update();
    }

    /* ---- 2. plan form → contact page --------------------------------- */
    var plan = d.querySelector('.hov-plan-form');
    if (plan) {
        plan.addEventListener('submit', function (e) {
            e.preventDefault();
            var params = new URLSearchParams();
            ['travel_type', 'destination', 'travellers'].forEach(function (name) {
                var field = plan.elements[name];
                if (field && field.value.trim() !== '') { params.set(name, field.value.trim()); }
            });
            var target = plan.getAttribute('action') || 'contact.html';
            var qs = params.toString();
            window.location.href = target + (qs ? '?' + qs : '') + '#enquiry';
        });
    }

    /* ---- 3. contact form prefill -------------------------------------- */
    var contactForm = d.querySelector('form.ajax-contact');
    if (contactForm && window.location.search) {
        var q = new URLSearchParams(window.location.search);
        var filled = false;
        ['travel_type', 'destination', 'travellers'].forEach(function (name) {
            var val = q.get(name);
            var field = contactForm.elements[name];
            if (!val || !field) { return; }
            if (field.tagName === 'SELECT') {
                var match = Array.prototype.find.call(field.options, function (o) {
                    return o.value === val || o.text === val;
                });
                if (match) { field.value = match.value; filled = true; }
            } else {
                field.value = val;
                filled = true;
            }
        });
        if (filled) {
            var card = contactForm.closest('.hov-form-card') || contactForm;
            window.setTimeout(function () {
                card.scrollIntoView({ behavior: 'smooth', block: 'start' });
            }, 150);
        }
    }

    /* ---- 4. drawer scroll lock ---------------------------------------- */
    var drawer = d.querySelector('.th-menu-wrapper');
    if (drawer && 'MutationObserver' in window) {
        new MutationObserver(function () {
            d.documentElement.classList.toggle('hov-drawer-open', drawer.classList.contains('th-body-visible'));
        }).observe(drawer, { attributes: true, attributeFilter: ['class'] });
    }

    /* ---- 5. footer link groups collapse on phones --------------------- */
    /* Each "Services / Company / Legal" heading becomes a button that shows
       or hides its list while the footer carries .hov-ft-acc (phones only,
       see the CSS). The contact list is never collapsed. Without JS the
       lists simply stay visible. */
    var footer = d.querySelector('.hov-ft');
    if (footer && 'matchMedia' in window) {
        var n = 0;
        Array.prototype.forEach.call(footer.querySelectorAll('.hov-ft-col > h3'), function (h) {
            var list = h.nextElementSibling;
            if (!list || list.tagName !== 'UL' || list.classList.contains('hov-ft-contact')) { return; }
            var id = 'hov-ft-list-' + (++n);
            list.id = id;
            var btn = d.createElement('button');
            btn.type = 'button';
            btn.className = 'hov-ft-toggle';
            btn.setAttribute('aria-controls', id);
            btn.setAttribute('aria-expanded', 'false');
            btn.textContent = h.textContent;
            h.textContent = '';
            h.appendChild(btn);
            btn.addEventListener('click', function () {
                if (!footer.classList.contains('hov-ft-acc')) { return; }
                var open = !h.classList.contains('is-open');
                h.classList.toggle('is-open', open);
                btn.setAttribute('aria-expanded', open ? 'true' : 'false');
            });
        });
        var mq = window.matchMedia('(max-width: 767.98px)');
        var applyAcc = function () {
            footer.classList.toggle('hov-ft-acc', mq.matches);
            if (!mq.matches) {
                Array.prototype.forEach.call(footer.querySelectorAll('.hov-ft-col > h3.is-open'), function (h) {
                    h.classList.remove('is-open');
                    h.firstElementChild.setAttribute('aria-expanded', 'false');
                });
            }
        };
        if (mq.addEventListener) { mq.addEventListener('change', applyAcc); } else if (mq.addListener) { mq.addListener(applyAcc); }
        applyAcc();
    }

    /* ---- 6. preloader ------------------------------------------------- */
    /* The inline script under the preloader markup already decided, before
       first paint, whether this visit shows it (html.hov-pl-active) or skips
       it (html.hov-pl-skip, set once sessionStorage says it has played).
       Here: keep it up for at least minShow so the entrance is seen, then
       on window.load play the exit and remove it. A hung image or font must
       never trap the page, hence the 5s net. */
    var pl = d.getElementById('hov-preloader');
    var root = d.documentElement;
    if (pl && root.classList.contains('hov-pl-active')) {
        var t0 = Date.now();
        var reduce = !!(window.matchMedia && window.matchMedia('(prefers-reduced-motion: reduce)').matches);
        var minShow = reduce ? 250 : 900;   /* long enough for the entrance, no longer */
        var finished = false;
        var finish = function () {
            if (finished) { return; }
            finished = true;
            try { sessionStorage.setItem('hov-pl', '1'); } catch (e) {}
            pl.classList.add('is-leaving');
            pl.setAttribute('aria-hidden', 'true');
            window.setTimeout(function () {
                pl.classList.add('is-done');
                root.classList.remove('hov-pl-active');
                root.classList.add('hov-loaded');
                if (pl.parentNode) { pl.parentNode.removeChild(pl); }
            }, reduce ? 320 : 620);
        };
        var onReady = function () {
            window.setTimeout(finish, Math.max(0, minShow - (Date.now() - t0)));
        };
        if (/[?&]hov-pl=hold\b/.test(window.location.search)) {
            /* design review: ?hov-pl=hold keeps the loader on screen until it is clicked */
            pl.style.cursor = 'pointer';
            pl.addEventListener('click', finish);
        } else {
            if (d.readyState === 'complete') { onReady(); } else { window.addEventListener('load', onReady); }
            window.setTimeout(finish, 5000);
        }
        window.addEventListener('pageshow', function (e) { if (e.persisted) { finish(); } });
    } else if (pl) {
        root.classList.remove('hov-pl-active');
        root.classList.add('hov-loaded');
        if (pl.parentNode) { pl.parentNode.removeChild(pl); }
    }
})();
