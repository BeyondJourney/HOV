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
})();
