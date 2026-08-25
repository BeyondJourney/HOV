(function ($) {
    "use strict";
    /*=================================
        JS Index Here
    ==================================*/
    /*
    01. On Load Function
    02. Preloader
    03. Mobile Menu
    04. Sticky fix
    05. Scroll To Top
    06. Set Background Image Color & Mask
    07. Global Slider
    08. Ajax Contact Form
    09. Search Box Popup
    10. Popup Sidemenu
    11. Magnific Popup
    12. Section Position
    13. Filter
    14. Counter Up
    15. Shape Mockup
    16. Progress Bar Animation 
    17. Countdown
    18. Image to SVG Code
    00. Woocommerce Toggle
    00. Right Click Disable
    */
    /*=================================
        JS Index End
    ==================================*/
    /*

  /*---------- 01. On Load Function ----------*/
    $(window).on("load", function () {
        $(".preloader").fadeOut();
    });

    // $('select').niceSelect();
    if ($('.nice-select').length) {
        $('.nice-select').niceSelect();
    }

    /*---------- 02. Preloader ----------*/
    if ($(".preloader").length > 0) {
        $(".preloaderCls").each(function () {
            $(this).on("click", function (e) {
                e.preventDefault();
                $(".preloader").css("display", "none");
            });
        });
    }

    $(document).ready(function () {
        // Safety net: window.load never fires if a single image or font request
        // hangs, and the preloader would then cover the page indefinitely.
        // Hide it 4s after DOM ready whatever else happens.
        setTimeout(function () {
            $('#loader').addClass('loaded');
            $('.preloader').fadeOut(300);
        }, 4000);

        // Remove the node once it is off screen so it cannot trap focus or clicks.
        setTimeout(function () { $('#preloader').remove(); }, 9000);
    });

    /*---------- 03. Mobile Menu ----------*/
    $.fn.thmobilemenu = function (options) {
        var opt = $.extend({
                menuToggleBtn: ".th-menu-toggle",
                bodyToggleClass: "th-body-visible",
                subMenuClass: "th-submenu",
                subMenuParent: "menu-item-has-children",
                thSubMenuParent: "th-item-has-children",
                subMenuParentToggle: "th-active",
                meanExpandClass: "th-mean-expand",
                // appendElement: '<span class="th-mean-expand"></span>',
                subMenuToggleClass: "th-open",
                toggleSpeed: 400,
            },
            options
        );

        return this.each(function () {
            var menu = $(this); // Select menu

            // Menu Show & Hide
            function menuToggle() {
                menu.toggleClass(opt.bodyToggleClass);

                // collapse submenu on menu hide or show
                var subMenu = "." + opt.subMenuClass;
                $(subMenu).each(function () {
                    if ($(this).hasClass(opt.subMenuToggleClass)) {
                        $(this).removeClass(opt.subMenuToggleClass);
                        $(this).css("display", "none");
                        $(this).parent().removeClass(opt.subMenuParentToggle);
                    }
                });
            }

            // Class Set Up for every submenu
            menu.find("." + opt.subMenuParent).each(function () {
                var submenu = $(this).find("ul");
                submenu.addClass(opt.subMenuClass);
                submenu.css("display", "none");
                $(this).addClass(opt.subMenuParent);
                $(this).addClass(opt.thSubMenuParent); // Add th-item-has-children class
                $(this).children("a").append(opt.appendElement);
            });

            // Toggle Submenu
            function toggleDropDown($element) {
                var submenu = $element.children("ul");
                if (submenu.length > 0) {
                    $element.toggleClass(opt.subMenuParentToggle);
                    submenu.slideToggle(opt.toggleSpeed);
                    submenu.toggleClass(opt.subMenuToggleClass);
                }
            }

            // Submenu toggle Button
            var itemHasChildren = "." + opt.thSubMenuParent + " > a";
            $(itemHasChildren).each(function () {
                $(this).on("click", function (e) {
                    e.preventDefault();
                    toggleDropDown($(this).parent());
                });
            });

            // Menu Show & Hide On Toggle Btn click
            $(opt.menuToggleBtn).each(function () {
                $(this).on("click", function () {
                    menuToggle();
                });
            });

            // Hide Menu On outside click
            menu.on("click", function (e) {
                e.stopPropagation();
                menuToggle();
            });

            // Stop Hide full menu on menu click
            menu.find("div").on("click", function (e) {
                e.stopPropagation();
            });
        });
    };


    $(".th-menu-wrapper").thmobilemenu();

    /*----------- 3. One Page Nav ----------*/
    function onePageNav(element) {
        // Only same-page anchors are handled here. The original passed every
        // href straight to jQuery, so a plain href="#" threw
        // "Syntax error, unrecognized expression: #" and a page link such as
        // href="about.html" was parsed as a selector.
        $(element).on('click', 'a[href^="#"]', function (e) {
            var href = this.getAttribute('href');
            if (!href || href === '#') { return; }
            var target = $(href);
            if (!target.length) { return; }
            e.preventDefault();
            $('html, body').stop().animate({
                scrollTop: target.offset().top - 10
            }, 1000);
        });
    };
    onePageNav('.onepage-nav');
    onePageNav('.scroll-down');
    //one page sticky menu  
    $(window).on('scroll', function () {
        if ($('.onepage-nav').length > 0) {};
    });

    /*---------- 04. Sticky fix ----------*/
    $(window).scroll(function () {
        var topPos = $(this).scrollTop();
        if (topPos > 500) {
            $('.sticky-wrapper').addClass('sticky');
            $('.category-menu').addClass('close-category');
        } else {
            $('.sticky-wrapper').removeClass('sticky')
            $('.category-menu').removeClass('close-category');
        }
    })

    $(".menu-expand").each(function () {
        $(this).on("click", function (e) {
            e.preventDefault();
            $('.category-menu').toggleClass('open-category');
        });
    });

    /*---------- 05. Scroll To Top ----------*/
    if ($('.scroll-top').length > 0 && document.querySelector('.scroll-top path')) {

        var scrollTopbtn = document.querySelector('.scroll-top');
        var progressPath = document.querySelector('.scroll-top path');
        var pathLength = progressPath.getTotalLength();
        progressPath.style.transition = progressPath.style.WebkitTransition = 'none';
        progressPath.style.strokeDasharray = pathLength + ' ' + pathLength;
        progressPath.style.strokeDashoffset = pathLength;
        progressPath.getBoundingClientRect();
        progressPath.style.transition = progressPath.style.WebkitTransition = 'stroke-dashoffset 10ms linear';
        var updateProgress = function () {
            var scroll = $(window).scrollTop();
            var height = $(document).height() - $(window).height();
            var progress = pathLength - (scroll * pathLength / height);
            progressPath.style.strokeDashoffset = progress;
        }
        updateProgress();
        $(window).scroll(updateProgress);
        var offset = 50;
        var duration = 750;
        jQuery(window).on('scroll', function () {
            if (jQuery(this).scrollTop() > offset) {
                jQuery(scrollTopbtn).addClass('show');
            } else {
                jQuery(scrollTopbtn).removeClass('show');
            }
        });
        jQuery(scrollTopbtn).on('click', function (event) {
            event.preventDefault();
            jQuery('html, body').animate({
                scrollTop: 0
            }, duration);
            return false;
        })
    }

    /*---------- 06. Set Background Image Color & Mask ----------*/
    if ($("[data-bg-src]").length > 0) {
        $("[data-bg-src]").each(function () {
            var src = $(this).attr("data-bg-src");
            $(this).css("background-image", "url(" + src + ")");
            $(this).removeAttr("data-bg-src").addClass("background-image");
        });
    }

    if ($('[data-bg-color]').length > 0) {
        $('[data-bg-color]').each(function () {
            var color = $(this).attr('data-bg-color');
            $(this).css('background-color', color);
            $(this).removeAttr('data-bg-color');
        });
    };

    $('[data-border]').each(function () {
        var borderColor = $(this).data('border');
        $(this).css('--th-border-color', borderColor);
    });

    if ($('[data-mask-src]').length > 0) {
        $('[data-mask-src]').each(function () {
            var mask = $(this).attr('data-mask-src');
            $(this).css({
                'mask-image': 'url(' + mask + ')',
                '-webkit-mask-image': 'url(' + mask + ')'
            });
            $(this).addClass('bg-mask');
            $(this).removeAttr('data-mask-src');
        });
    };

    /*----------- 07. Global Slider ----------*/

    $('.th-slider').each(function () {

        var thSlider = $(this);
        var settings = $(this).data('slider-options');

        // Store references to the navigation Slider
        var prevArrow = thSlider.find('.slider-prev');
        var nextArrow = thSlider.find('.slider-next');
        var paginationElN = thSlider.find('.slider-pagination.pagi-number');
        var paginationExternel = thSlider.siblings('.slider-controller').find('.slider-pagination');

        var paginationEl = paginationExternel.length ? paginationExternel.get(0) : thSlider.find('.slider-pagination').get(0);

        var paginationType = settings['paginationType'] ? settings['paginationType'] : 'bullets';

        var autoplayconditon = settings['autoplay'];

        var sliderDefault = {
            slidesPerView: 1,
            spaceBetween: settings['spaceBetween'] ? settings['spaceBetween'] : 24,
            loop: settings['loop'] == false ? false : true,
            speed: settings['speed'] ? settings['speed'] : 1000,
            autoplay: autoplayconditon ? autoplayconditon : {
                delay: 6000,
                disableOnInteraction: false
            },
            navigation: {
                nextEl: nextArrow.get(0),
                prevEl: prevArrow.get(0),
            },
            pagination: {
                el: paginationEl,
                type: paginationType,
                clickable: true,
                renderBullet: function (index, className) {
                    var number = index + 1;
                    var formattedNumber = number < 10 ? '0' + number : number;
                    if (paginationElN.length) {
                        return '<span class="' + className + ' number">' + formattedNumber + '</span>';
                    } else {
                        return '<span class="' + className + '" aria-label="Go to Slide ' + formattedNumber + '"></span>';
                    }
                },
                formatFractionCurrent: function (number) {
                    if (number < 10) {
                        return '0' + number;
                    } else {
                        return number;
                    }
                },
                formatFractionTotal: function (number) {
                    if (number < 10) {
                        return '0' + number;
                    } else {
                        return number;
                    }
                }
            },
            on: {
                slideChange: function () {
                    setTimeout(function () {
                        swiper.params.mousewheel.releaseOnEdges = false;
                    }, 500);
                },
                reachEnd: function () {
                    setTimeout(function () {
                        swiper.params.mousewheel.releaseOnEdges = true;
                    }, 750);
                }
            }
        };

        var options = JSON.parse(thSlider.attr('data-slider-options'));
        options = $.extend({}, sliderDefault, options);
        var swiper = new Swiper(thSlider.get(0), options); // Assign the swiper variable

        if ($('.slider-area').length > 0) {
            $('.slider-area').closest(".container").parent().addClass("arrow-wrap");
        }

        
    });
   



    // Function to add animation classes
    function animationProperties() {
        $('[data-ani]').each(function () {
            var animationName = $(this).data('ani');
            $(this).addClass(animationName);
        });

        $('[data-ani-delay]').each(function () {
            var delayTime = $(this).data('ani-delay');
            $(this).css('animation-delay', delayTime);
        });
    }
    animationProperties();

    // Add click event handlers for external slider arrows based on data attributes
    $('[data-slider-prev], [data-slider-next]').on('click', function () {
        var sliderSelector = $(this).data('slider-prev') || $(this).data('slider-next');
        var targetSlider = $(sliderSelector);

        if (targetSlider.length) {
            var swiper = targetSlider[0].swiper;

            if (swiper) {
                if ($(this).data('slider-prev')) {
                    swiper.slidePrev();
                } else {
                    swiper.slideNext();
                }
            }
        }
    });

    // Function to add animation classes
    function animationProperties() {
        $('[data-ani]').each(function () {
            var animationName = $(this).data('ani');
            $(this).addClass(animationName);
        });

        $('[data-ani-delay]').each(function () {
            var delayTime = $(this).data('ani-delay');
            $(this).css('animation-delay', delayTime);
        });
    }
    animationProperties();

    // Add click event handlers for external slider arrows based on data attributes
    $('[data-slider-prev], [data-slider-next]').on('click', function () {
        var sliderSelectors = ($(this).data('slider-prev') || $(this).data('slider-next')).split(', ');

        sliderSelectors.forEach(function (sliderSelector) {
            var targetSlider = $(sliderSelector);

            if (targetSlider.length) {
                var swiper = targetSlider[0].swiper;

                if (swiper) {
                    if ($(this).data('slider-prev')) {
                        swiper.slidePrev();
                    } else {
                        swiper.slideNext();
                    }
                }
            }
        });
    });


    var swiper = new Swiper(".heroThumbs", {
        spaceBetween: 10,
        slidesPerView: 2,
        loop: true,
        watchSlidesProgress: true,
        slideToClickedSlide: true,
        watchSlidesVisibility: true,
        centeredSlidesBounds: true,
    });

    var swiper = new Swiper('.hero-slider-2', {
        spaceBetween: 10,
        thumbs: {
            swiper: swiper,
        },
        effect: "fade",
        pagination: {
            el: '.swiper-pagination',
            clickable: true
        },
        navigation: {
            nextEl: '.swiper-button-next',
            prevEl: '.swiper-button-prev'
        },
        autoplay: {
            delay: 6000,
            disableOnInteraction: false
        },
        loop: true,
        watchSlidesProgress: true
    });

    /* hero-3  start */
    var swiper = new Swiper(".hero3Thumbs", {
        spaceBetween: 10,
        slidesPerView: 1,
        freeMode: true,
        watchSlidesProgress: true,
    });
    var swiper = new Swiper('.hero-slider-3', { 
        thumbs: {
            swiper: swiper,
        },
        loop: true,
        effect: "fade",
        autoplay: {
            delay: 6000,
            disableOnInteraction: false
        },
        pagination: {
            el: '.swiper-pagination',
            type: 'fraction',
            formatFractionCurrent: function (number) {
                return '0' + number;
            }
        },
        navigation: {
            nextEl: '.swiper-button-next',
            prevEl: '.swiper-button-prev'
        }
    });

    /* hero-3  end */

    /* hero-6  start */
    var swiper = new Swiper(".hero6Thumbs", {
        spaceBetween: 3,
        slidesPerView: 1,
        freeMode: true,
        watchSlidesProgress: true,
    });
    var swiper = new Swiper('.hero-slider-6', {
        thumbs: {
            swiper: swiper,
        },
        loop: true,
        effect: "fade",
        autoplay: {
            delay: 6000,
            disableOnInteraction: false
        },
        pagination: {
            el: '.swiper-pagination',
            type: 'fraction',
            formatFractionCurrent: function (number) {
                return '' + number;
            }
        },
        navigation: {
            nextEl: '.swiper-button-next',
            prevEl: '.swiper-button-prev'
        }
    });

    /* hero-6  end */

    /* hero-6  start */
    var swiper = new Swiper(".hero6Thumbs", {
        spaceBetween: 3,
        slidesPerView: 1,
        freeMode: true,
        watchSlidesProgress: true,
    });
    var swiper = new Swiper('.hero-slider-6', {
        thumbs: {
            swiper: swiper,
        },
        loop: true,
        effect: "fade",
        autoplay: {
            delay: 6000,
            disableOnInteraction: false
        },
        pagination: {
            el: '.swiper-pagination',
            type: 'fraction',
            formatFractionCurrent: function (number) {
                return '' + number;
            }
        },
        navigation: {
            nextEl: '.swiper-button-next',
            prevEl: '.swiper-button-prev'
        }
    });

    /* hero-6  end */
    /* hero-10  start */
    var swiper = new Swiper(".hero9Thumbs", {
        spaceBetween: 10,
        slidesPerView: 1,
        freeMode: true,
        watchSlidesProgress: true,
    });
    var swiper = new Swiper('.hero-slider-9', {
        thumbs: {
            swiper: swiper,
        },
        loop: true,
        effect: "fade",
        autoplay: {
            delay: 6000,
            disableOnInteraction: false
        },
        pagination: {
            el: '.swiper-pagination',
            type: 'fraction',
            formatFractionCurrent: function (number) {
                return '0' + number;
            }
        },
        navigation: {
            nextEl: '.swiper-button-next',
            prevEl: '.swiper-button-prev'
        }
    });

    /* hero-3  end */

      /* hero-10  start */
      var swiper = new Swiper(".hero10Thumbs", { 
        spaceBetween: 10,
        slidesPerView: 3,
        freeMode: true,
        watchSlidesProgress: true,
    });

    var swiper = new Swiper('.hero-slider-10', {
        spaceBetween: 10,
        thumbs: {
            swiper: swiper,
        },
        effect: "fade",
        pagination: {
            el: '.swiper-pagination',
            type: 'fraction',
        },
        navigation: {
            nextEl: '.swiper-button-next',
            prevEl: '.swiper-button-prev'
        },
        autoplay: {
            delay: 6000,
            disableOnInteraction: false
        },
        loop: true,
        watchSlidesProgress: true
    });
    /* hero-10  end */

    // var swiperEl = document.querySelector('.swiper-container');

    // swiperEl.addEventListener('mouseenter', function(event) {
    document.addEventListener('mouseenter', event => {
        const el = event.target;
        if (el && el.matches && el.matches('.swiper-container')) {
            // console.log('mouseenter');
            // console.log('autoplay running', swiper.autoplay.running);
            el.swiper.autoplay.stop();
            el.classList.add('swiper-paused');

            const activeNavItem = el.querySelector('.swiper-pagination-bullet-active');
            activeNavItem.style.animationPlayState = "paused";
        }
    }, true);

    document.addEventListener('mouseleave', event => {
        // console.log('mouseleave', swiper.activeIndex, swiper.slides[swiper.activeIndex].progress);
        // console.log('autoplay running', swiper.autoplay.running);
        const el = event.target;
        if (el && el.matches && el.matches('.swiper-container')) {
            el.swiper.autoplay.start();
            el.classList.remove('swiper-paused');

            const activeNavItem = el.querySelector('.swiper-pagination-bullet-active');

            activeNavItem.classList.remove('swiper-pagination-bullet-active');
            // activeNavItem.style.animation = 'none';

            setTimeout(() => {
                activeNavItem.classList.add('swiper-pagination-bullet-active');
                // activeNavItem.style.animation = '';
            }, 10);
        }
    }, true);


    /* category slider 1 start ---------------------*/
    $(document).ready(function () {
        $('.categorySlider').each(function () {
            const multiplier = {
                translate: .1,
                rotate: .01
            }

            new Swiper('.categorySlider', {
                slidesPerView: 5,
                spaceBetween: 60,
                centeredSlides: true,
                loop: true,
                grabCursor: true,
                pagination: {
                    el: ".swiper-pagination",
                    clickable: true,
                },
                breakpoints: {
                    300: {
                        slidesPerView: 1,
                        spaceBetween: 10
                    },
                    600: {
                        slidesPerView: 2,
                        spaceBetween: 30
                    },
                    768: {
                        slidesPerView: 3,
                        spaceBetween: 30
                    },
                    1024: {
                        slidesPerView: 4,
                        spaceBetween: 40
                    },
                    1280: {
                        slidesPerView: 5,
                        spaceBetween: 60
                    }
                }
            });

            function calculateWheel() {
                const slides = document.querySelectorAll('.single')
                slides.forEach((slide, i) => {
                    const rect = slide.getBoundingClientRect()
                    const r = window.innerWidth * .5 - (rect.x + rect.width * .5)
                    let ty = Math.abs(r) * multiplier.translate - rect.width * multiplier.translate

                    if (ty < 0) {
                        ty = 0
                    }
                    const transformOrigin = r < 0 ? 'left top' : 'right top'
                    slide.style.transform = `translate(0, ${ty}px) rotate(${-r * multiplier.rotate}deg)`
                    slide.style.transformOrigin = transformOrigin
                })
            }

            function raf() {
                requestAnimationFrame(raf)
                calculateWheel()
            }

            raf();
        });
    });

    /* category slider 1 end ---------------------*/

    /* category slider 2 start ---------------------*/
    $(document).ready(function () {
        $('.categorySlider2').each(function () {
            const multiplier = {
                translate: .1,
                rotate: .0
            }

            new Swiper('.categorySlider2', {
                slidesPerView: 'auto',
                slidesPerView: 5,
                spaceBetween: 60,
                centeredSlides: true,
                loop: true,
                grabCursor: true,
                pagination: {
                    el: ".swiper-pagination",
                    clickable: true,
                },
                breakpoints: {
                    300: {
                        slidesPerView: 1,
                        spaceBetween: 30
                    },
                    600: {
                        slidesPerView: 2,
                        spaceBetween: 30
                    },
                    768: {
                        slidesPerView: 3,
                        spaceBetween: 30
                    },
                    1024: {
                        slidesPerView: 4,
                        spaceBetween: 40
                    },
                    1280: {
                        slidesPerView: 5,
                        spaceBetween: 60
                    }
                }
            });

            function calculateWheel() {
                const slides = document.querySelectorAll('.single2')
                slides.forEach((slide, i) => {
                    const rect = slide.getBoundingClientRect()
                    const r = window.innerWidth * .5 - (rect.x + rect.width * .5)
                    let ty = Math.abs(r) * multiplier.translate - rect.width * multiplier.translate

                    if (ty < 0) {
                        ty = 0
                    }
                    const transformOrigin = r < 0 ? 'left top' : 'right top'
                    slide.style.transform = `translate(0, ${ty}px) rotate(${-r * multiplier.rotate}deg)`
                    slide.style.transformOrigin = transformOrigin
                })
            }

            function raf() {
                requestAnimationFrame(raf)
                calculateWheel()
            }

            raf();
        });
    });



    /* category slider 3 start ---------------------*/

    /* category slider 2 start ---------------------*/
    $(document).ready(function () {
        $('.categorySlider6').each(function () {
            const multiplier = {
                translate: .1,
                rotate: .0
            }

            new Swiper('.categorySlider6', {
                slidesPerView: 'auto',
                slidesPerView: 5,
                spaceBetween: 30,
                centeredSlides: true,
                loop: true,
                grabCursor: true,
                pagination: {
                    el: ".swiper-pagination",
                    type: "progressbar", 
                },
                breakpoints: {
                    300: {
                        slidesPerView: 1,
                        spaceBetween: 30
                    },
                    575: {
                        slidesPerView: 2,
                        spaceBetween: 30
                    },
                    1024: {
                        slidesPerView: 3,
                        spaceBetween: 30
                    },
                    1200: {
                        slidesPerView: 4,
                        spaceBetween: 30
                    },
                    1380: {
                        slidesPerView: 5,
                        spaceBetween: 30
                    }
                }
            });

            function calculateWheel() {
                const slides = document.querySelectorAll('.single2')
                slides.forEach((slide, i) => {
                    const rect = slide.getBoundingClientRect()
                    const r = window.innerWidth * .5 - (rect.x + rect.width * .5)
                    let ty = Math.abs(r) * multiplier.translate - rect.width * multiplier.translate

                    if (ty < 0) {
                        ty = 0
                    }
                    const transformOrigin = r < 0 ? 'left top' : 'right top'
                    slide.style.transform = `translate(0, ${ty}px) rotate(${-r * multiplier.rotate}deg)`
                    slide.style.transformOrigin = transformOrigin
                })
            }

            function raf() {
                requestAnimationFrame(raf)
                calculateWheel()
            }

            raf();
        });
    });

    /* category slider 2 end ---------------------*/

    /*-------------- 09. Custom destination Slider -------------*/
    $('.destination-list-wrap').on('click', function () {
        $(this).addClass('active').siblings().removeClass('active');
    });

    function showNextdestination() {
        var $activedestination = $('.destination-list-area .destination-list-wrap.active');
        if ($activedestination.next().length > 0) {
            $activedestination.removeClass('active');
            $activedestination.next().addClass('active');
        } else {
            $activedestination.removeClass('active');
            $('.destination-list-area .destination-list-wrap:first').addClass('active');
        }
    }

    function showPreviousdestination() {
        var $activedestination = $('.destination-list-area .destination-list-wrap.active');
        if ($activedestination.prev().length > 0) {
            $activedestination.removeClass('active');
            $activedestination.prev().addClass('active');
        } else {
            $activedestination.removeClass('active');
            $('.destination-list-area .destination-list-wrap:last').addClass('active');
        }
    }
    $('.destination-prev').on('click', function () {
        showPreviousdestination();
    });
    $('.destination-next').on('click', function () {
        showNextdestination();
    });




    // Show the first tab and hide the rest
    $('.accordion-item-wrapp li:first-child').addClass('active');
    $('.according-img-tab').hide();
    $('.according-img-tab:first').show();

    // Click function
    $('.accordion-item-wrapp .accordion-item-content').mouseenter(function () {
        $('.accordion-item-wrapp .accordion-item-content').removeClass('active');
        // $(this).addClass('active');
        $('.according-img-tab').hide();

        var activeTab = $(this).find('.accordion-tab-item').attr('data-bs-target');
        $(activeTab).fadeIn();
        return false;
    });
    /*   offer-deals end */
    /* testimonial start --------------------*/
    // $(document).on('mouseover', '.hover-item', function () {
    //     $(this).addClass('item-active');
    //     $('.hover-item').removeClass('item-active'); 
    //     $(this).addClass('item-active');
    // });
    /* testimonial end --------------------*/



    $(document).on('mouseover', '.hover-item', function () {
        $(this).addClass('item-active');
        $('.hover-item').removeClass('item-active');
        $(this).addClass('item-active');
    });
    // Function to add animation classes
    function animationProperties() {
        $('[data-ani]').each(function () {
            var animationName = $(this).data('ani');
            $(this).addClass(animationName);
        });

        $('[data-ani-delay]').each(function () {
            var delayTime = $(this).data('ani-delay');
            $(this).css('animation-delay', delayTime);
        });
    }
    animationProperties();

    // Add click event handlers for external slider arrows based on data attributes
    $('[data-slider-prev], [data-slider-next]').on('click', function () {
        var sliderSelector = $(this).data('slider-prev') || $(this).data('slider-next');
        var targetSlider = $(sliderSelector);

        if (targetSlider.length) {
            var swiper = targetSlider[0].swiper;

            if (swiper) {
                if ($(this).data('slider-prev')) {
                    swiper.slidePrev();
                } else {
                    swiper.slideNext();
                }
            }
        }
    });

   
    
    // var panoramaElement = document.querySelector('.panorama');
    // pannellum.viewer(panoramaElement, {
    //     "type": "equirectangular",
    //     "panorama": "assets/img/hero/hero_10_1.jpg",
    //     "autoLoad": true
    // });
 
    

    /*-------------- 08. Slider Tab -------------*/
    $.fn.activateSliderThumbs = function (options) {
        var opt = $.extend({
                sliderTab: false,
                tabButton: ".tab-btn",
            },
            options
        );

        return this.each(function () {
            var $container = $(this);
            var $thumbs = $container.find(opt.tabButton);
            var $line = $('<span class="indicator"></span>').appendTo($container);

            var sliderSelector = $container.data("slider-tab");
            var $slider = $(sliderSelector);

            var swiper = $slider[0].swiper;

            $thumbs.on("click", function (e) {
                e.preventDefault();
                var clickedThumb = $(this);

                clickedThumb.addClass("active").siblings().removeClass("active");
                linePos(clickedThumb, $container);

                clickedThumb.prevAll(opt.tabButton).addClass('list-active');
                clickedThumb.nextAll(opt.tabButton).removeClass('list-active');

                if (opt.sliderTab) {
                    var slideIndex = clickedThumb.index();
                    swiper.slideTo(slideIndex);
                }
            });

            if (opt.sliderTab) {
                swiper.on("slideChange", function () {
                    var activeIndex = swiper.realIndex;
                    var $activeThumb = $thumbs.eq(activeIndex);

                    $activeThumb.addClass("active").siblings().removeClass("active");
                    linePos($activeThumb, $container);

                    $activeThumb.prevAll(opt.tabButton).addClass('list-active');
                    $activeThumb.nextAll(opt.tabButton).removeClass('list-active');
                });

                var initialSlideIndex = swiper.activeIndex;
                var $initialThumb = $thumbs.eq(initialSlideIndex);
                $initialThumb.addClass("active").siblings().removeClass("active");
                linePos($initialThumb, $container);

                $initialThumb.prevAll(opt.tabButton).addClass('list-active');
                $initialThumb.nextAll(opt.tabButton).removeClass('list-active');
            }

            function linePos($activeThumb) {
                var thumbOffset = $activeThumb.position();

                var marginTop = parseInt($activeThumb.css('margin-top')) || 0;
                var marginLeft = parseInt($activeThumb.css('margin-left')) || 0;

                $line.css("--height-set", $activeThumb.outerHeight() + "px");
                $line.css("--width-set", $activeThumb.outerWidth() + "px");
                $line.css("--pos-y", thumbOffset.top + marginTop + "px");
                $line.css("--pos-x", thumbOffset.left + marginLeft + "px");
            }
        });
    };

    if ($(".product-thumb").length) {
        $(".product-thumb").activateSliderThumbs({
            sliderTab: true,
            tabButton: ".tab-btn",
        });
    }

    if ($(".team-thumb").length) {
        $(".team-thumb").activateSliderThumbs({
            sliderTab: true,
            tabButton: ".tab-btn",
        });
    }

    if ($(".testi-thumb").length) {
        $(".testi-thumb").activateSliderThumbs({
            sliderTab: true,
            tabButton: ".tab-btn",
        });
    }
    if ($(".testi-thumb2").length) {
        $(".testi-thumb2").activateSliderThumbs({
            sliderTab: true,
            tabButton: ".tab-btn",
        });
    }



    /*----------- 08. Ajax Contact Form ----------*/
    // Every handler below is scoped to the form that was actually submitted.
    // The original code used the bare class selector ".ajax-contact", so
    // .serialize() merged every form on the page into one payload, the action
    // came from whichever form happened to be first in the DOM, and
    // $('[name="email"]').val() read the first email field anywhere on the
    // page - which is why a filled-in enquiry could still fail validation.
    var invalidCls = "is-invalid";
    var EMAIL_RE = /^[^\s@]+@[^\s@]+\.[^\s@]{2,}$/;

    function setMessage($form, text, isError) {
        var $msg = $form.find(".form-messages");
        if (!$msg.length) {
            $msg = $('<p class="form-messages mb-0 mt-3"></p>').appendTo($form);
        }
        $msg.attr("role", "status").removeClass("success error")
            .addClass(isError ? "error" : "success").text(text);
    }

    function validateForm($form) {
        var valid = true;
        var $first = null;

        $form.find("[required]").each(function () {
            var $f = $(this);
            var ok = $.trim($f.val()) !== "";
            if (ok && $f.attr("type") === "email") { ok = EMAIL_RE.test($.trim($f.val())); }
            if (ok && $f.attr("type") === "tel") { ok = ($f.val().replace(/\D/g, "").length >= 7); }
            $f.toggleClass(invalidCls, !ok);
            $f.attr("aria-invalid", ok ? null : "true");
            if (!ok) { valid = false; if (!$first) { $first = $f; } }
        });

        if ($first) { $first.trigger("focus"); }
        return valid;
    }

    function sendContact($form) {
        if (!validateForm($form)) {
            setMessage($form, "Please complete the highlighted fields before sending.", true);
            return;
        }

        var $btn = $form.find('button[type="submit"], button:not([type])').first();
        var label = $btn.text();
        $btn.prop("disabled", true).addClass("is-sending").text("Sending...");
        setMessage($form, "Sending your enquiry...", false);

        // Record which page the enquiry came from, for the notification email.
        $form.find('input[name="source_page"]').val(window.location.pathname);

        $.ajax({
            url: $form.attr("action") || "mail.php",
            data: $form.serialize(),
            type: $form.attr("method") || "POST",
            dataType: "json",
            headers: { "X-Requested-With": "XMLHttpRequest" }
        }).done(function (res) {
            if (res && res.ok) {
                setMessage($form, res.message || "Thank you. Your enquiry has been sent.", false);
                $form[0].reset();
                $form.find("." + invalidCls).removeClass(invalidCls);
            } else {
                setMessage($form, (res && res.message) || "Your message could not be sent. Please try again.", true);
            }
        }).fail(function (xhr) {
            var msg = "Sorry, something went wrong. Please email mice@houseofvacation.com or call +91 92204 70800.";
            try {
                var j = JSON.parse(xhr.responseText);
                if (j && j.message) { msg = j.message; }
            } catch (e) { /* server returned HTML, keep the friendly fallback */ }
            setMessage($form, msg, true);
        }).always(function () {
            $btn.prop("disabled", false).removeClass("is-sending").text(label);
        });
    }

    $(document).on("submit", "form.ajax-contact", function (e) {
        e.preventDefault();
        sendContact($(this));
    });

    // Clear the error state as soon as the visitor starts correcting a field.
    $(document).on("input change", "form.ajax-contact ." + invalidCls, function () {
        $(this).removeClass(invalidCls).removeAttr("aria-invalid");
    });

    /*---------- 09. Search Box Popup ----------*/
    function popupSarchBox($searchBox, $searchOpen, $searchCls, $toggleCls) {
        $($searchOpen).on("click", function (e) {
            e.preventDefault();
            $($searchBox).addClass($toggleCls);
        });
        $($searchBox).on("click", function (e) {
            e.stopPropagation();
            $($searchBox).removeClass($toggleCls);
        });
        $($searchBox)
            .find("form")
            .on("click", function (e) {
                e.stopPropagation();
                $($searchBox).addClass($toggleCls);
            });
        $($searchCls).on("click", function (e) {
            e.preventDefault();
            e.stopPropagation();
            $($searchBox).removeClass($toggleCls);
        });
    }
    popupSarchBox(".popup-search-box", ".searchBoxToggler", ".searchClose", "show");

    /*---------- 10. Popup Sidemenu ----------*/
    function popupSideMenu($sideMenu, $sideMunuOpen, $sideMenuCls, $toggleCls) {
        // Sidebar Popup
        $($sideMunuOpen).on('click', function (e) {
            e.preventDefault();
            $($sideMenu).addClass($toggleCls);
        });
        $($sideMenu).on('click', function (e) {
            e.stopPropagation();
            $($sideMenu).removeClass($toggleCls)
        });
        var sideMenuChild = $sideMenu + ' > div';
        $(sideMenuChild).on('click', function (e) {
            e.stopPropagation();
            $($sideMenu).addClass($toggleCls)
        });
        $($sideMenuCls).on('click', function (e) {
            e.preventDefault();
            e.stopPropagation();
            $($sideMenu).removeClass($toggleCls);
        });
    };
    popupSideMenu('.sidemenu-wrapper', '.sideMenuToggler', '.sideMenuCls', 'show');

    /*---------- 10. Popup Sidemenu ----------*/
    function popupSideMenu($sideMenu2, $sideMunuOpen2, $sideMenuCls2, $toggleCls2) {
        // Sidebar Popup
        $($sideMunuOpen2).on('click', function (e) {
            e.preventDefault();
            $($sideMenu2).addClass($toggleCls2);
        });
        $($sideMenu2).on('click', function (e) {
            e.stopPropagation();
            $($sideMenu2).removeClass($toggleCls2)
        });
        var sideMenuChild = $sideMenu2 + ' > div';
        $(sideMenuChild).on('click', function (e) {
            e.stopPropagation();
            $($sideMenu2).addClass($toggleCls2)
        });
        $($sideMenuCls2).on('click', function (e) {
            e.preventDefault();
            e.stopPropagation();
            $($sideMenu2).removeClass($toggleCls2);
        });
    };
    popupSideMenu('.shopping-cart', '.sideMenuToggler2', '.sideMenuCls', 'show');


    /*----------- 11. Magnific Popup ----------*/
    /* magnificPopup img view */
    $(".popup-image").magnificPopup({
        type: "image",
        mainClass: 'mfp-zoom-in',
        removalDelay: 260,
        gallery: {
            enabled: true,
        },
    });

    /* magnificPopup video view */
    $(".popup-video").magnificPopup({
        type: "iframe",
    });

    /* magnificPopup video view */
    $(".popup-content").magnificPopup({
        type: "inline",
        midClick: true,
    });

    /* Removed: the "magic cursor" (a 16px ring plus a 14px teal dot that
       trailed the pointer on every page) and the .th-anim image-reveal block.

       The cursor replaced the native pointer, so link/text/resize cursors no
       longer communicated anything, it ran a GSAP tween on every frame for the
       life of the page, and it is not a fit for a corporate MICE site.

       The .th-anim block called gsap.registerPlugin(ScrollTrigger) - a plugin
       this site never loaded - and appeared twice in this file, so it was dead
       code that would have thrown had any page carried a .th-anim element.

       With both gone nothing on the site uses GSAP, so gsap.min.js (67 KB) is
       no longer requested. */

    /*---------- 12. Section Position ----------*/
    // Interger Converter
    function convertInteger(str) {
        return parseInt(str, 10);
    }

    $.fn.sectionPosition = function (mainAttr, posAttr) {
        $(this).each(function () {
            var section = $(this);

            function setPosition() {
                var sectionHeight = Math.floor(section.height() / 2), // Main Height of section
                    posData = section.attr(mainAttr), // where to position
                    posFor = section.attr(posAttr), // On Which section is for positioning
                    topMark = "top-half", // Pos top
                    bottomMark = "bottom-half", // Pos Bottom
                    parentPT = convertInteger($(posFor).css("padding-top")), // Default Padding of  parent
                    parentPB = convertInteger($(posFor).css("padding-bottom")); // Default Padding of  parent

                if (posData === topMark) {
                    $(posFor).css(
                        "padding-bottom",
                        parentPB + sectionHeight + "px"
                    );
                    section.css("margin-top", "-" + sectionHeight + "px");
                } else if (posData === bottomMark) {
                    $(posFor).css(
                        "padding-top",
                        parentPT + sectionHeight + "px"
                    );
                    section.css("margin-bottom", "-" + sectionHeight + "px");
                }
            }
            setPosition(); // Set Padding On Load
        });
    };

    var postionHandler = "[data-sec-pos]";
    if ($(postionHandler).length) {
        $(postionHandler).imagesLoaded(function () {
            $(postionHandler).sectionPosition("data-sec-pos", "data-pos-for");
        });
    }

    /*---------- 22. Circle Progress ----------*/
    function animateElements() {
        $('.feature-circle .progressbar').each(function () {
            var pathColor = $(this).attr('data-path-color');
            var elementPos = $(this).offset().top;
            var topOfWindow = $(window).scrollTop();
            var percent = $(this).find('.circle').attr('data-percent');
            var percentage = parseInt(percent, 10) / parseInt(100, 10);
            var animate = $(this).data('animate');
            if (elementPos < topOfWindow + $(window).height() - 30 && !animate) {
                $(this).data('animate', true);
                $(this).find('.circle').circleProgress({
                    startAngle: -Math.PI / 2,
                    value: percent / 100,
                    size: 100,
                    thickness: 8,
                    emptyFill: "#E4E4E4",
                    lineCap: 'round',
                    fill: {
                        color: pathColor,
                    }
                }).on('circle-animation-progress', function (event, progress, stepValue) {
                    $(this).find('.circle-num').text((stepValue * 100).toFixed(0) + "%");
                }).stop();
            }
        });

        $('.skill-circle .progressbar').each(function () {
            var elementPos = $(this).offset().top;
            var topOfWindow = $(window).scrollTop();
            var percent = $(this).find('.circle').attr('data-percent');
            var percentage = parseInt(percent, 10) / parseInt(100, 10);
            var animate = $(this).data('animate');
            if (elementPos < topOfWindow + $(window).height() - 30 && !animate) {
                $(this).data('animate', true);
                $(this).find('.circle').circleProgress({
                    startAngle: -Math.PI / 2,
                    value: percent / 100,
                    size: 100,
                    thickness: 8,
                    emptyFill: "#E0E0E0",
                    lineCap: 'round',
                    fill: {
                        gradient: ["#F11F22", "#F2891D"]
                    }
                }).on('circle-animation-progress', function (event, progress, stepValue) {
                    $(this).find('.circle-num').text((stepValue * 100).toFixed(0) + "%");
                }).stop();
            }
        });
    }

    // Show animated elements
    animateElements();
    $(window).scroll(animateElements);

    /*----------- 15. Filter ----------*/
    $(".filter-active").imagesLoaded(function () {
        var $filter = ".filter-active",
            $filterItem = ".filter-item",
            $filterMenu = ".filter-menu-active";

        if ($($filter).length > 0) {
            var $grid = $($filter).isotope({
                itemSelector: $filterItem,
                filter: "*",
                masonry: {
                    // use outer width of grid-sizer for columnWidth
                    columnWidth: 1,
                },
            });

            // filter items on button click
            $($filterMenu).on("click", "button", function () {
                var filterValue = $(this).attr("data-filter");
                $grid.isotope({
                    filter: filterValue,
                });
            });

            // Menu Active Class
            $($filterMenu).on("click", "button", function (event) {
                event.preventDefault();
                $(this).addClass("active");
                $(this).siblings(".active").removeClass("active");
            });
        }
    });

    $(".masonary-active").imagesLoaded(function () {
        var $filter = ".masonary-active",
            $filterItem = ".filter-item";

        if ($($filter).length > 0) {
            $($filter).isotope({
                itemSelector: $filterItem,
                filter: "*",
                masonry: {
                    // use outer width of grid-sizer for columnWidth
                    columnWidth: 1,
                },
            });
        }
    });

    $(".masonary-active, .woocommerce-Reviews .comment-list").imagesLoaded(function () {
        var $filter = ".masonary-active, .woocommerce-Reviews .comment-list",
            $filterItem = ".filter-item, .woocommerce-Reviews .comment-list li";

        if ($($filter).length > 0) {
            $($filter).isotope({
                itemSelector: $filterItem,
                filter: "*",
                masonry: {
                    // use outer width of grid-sizer for columnWidth
                    columnWidth: 1,
                },
            });
        }
        $('[data-bs-toggle="tab"]').on('shown.bs.tab', function (e) {
            $($filter).isotope({
                filter: "*",
            });
        });
    });

    /*----------- 14. Counter Up ----------*/
    $(".counter-number").counterUp({
        delay: 10,
        time: 1000,
    });


    /*----------- 15. Shape Mockup ----------*/
    $.fn.shapeMockup = function () {
        var $shape = $(this);
        $shape.each(function () {
            var $currentShape = $(this),
                shapeTop = $currentShape.data("top"),
                shapeRight = $currentShape.data("right"),
                shapeBottom = $currentShape.data("bottom"),
                shapeLeft = $currentShape.data("left");
            $currentShape
                .css({
                    top: shapeTop,
                    right: shapeRight,
                    bottom: shapeBottom,
                    left: shapeLeft,
                })
                .removeAttr("data-top")
                .removeAttr("data-right")
                .removeAttr("data-bottom")
                .removeAttr("data-left")
                .parent()
                .addClass("shape-mockup-wrap");
        });
    };

    if ($(".shape-mockup")) {
        $(".shape-mockup").shapeMockup();
    }

    /*----------- 16. Progress Bar Animation ----------*/
    $('.progress-bar').waypoint(function () {
        $('.progress-bar').css({
            animation: "animate-positive 1.8s",
            opacity: "1"
        });
    }, {
        offset: '75%'
    });

    /*----------- 17. Countdown ----------*/

    $.fn.countdown = function () {
        $(this).each(function () {
            var $counter = $(this),
                countDownDate = new Date($counter.data("offer-date")).getTime(), // Set the date we're counting down toz
                exprireCls = "expired";

            // Finding Function
            function s$(element) {
                return $counter.find(element);
            }

            // Update the count down every 1 second
            var counter = setInterval(function () {
                // Get today's date and time
                var now = new Date().getTime();

                // Find the distance between now and the count down date
                var distance = countDownDate - now;

                // Time calculations for days, hours, minutes and seconds
                var days = Math.floor(distance / (1000 * 60 * 60 * 24));
                var hours = Math.floor(
                    (distance % (1000 * 60 * 60 * 24)) / (1000 * 60 * 60)
                );
                var minutes = Math.floor(
                    (distance % (1000 * 60 * 60)) / (1000 * 60)
                );
                var seconds = Math.floor((distance % (1000 * 60)) / 1000);

                // Check If value is lower than ten, so add zero before number
                days < 10 ? (days = "0" + days) : null;
                hours < 10 ? (hours = "0" + hours) : null;
                minutes < 10 ? (minutes = "0" + minutes) : null;
                seconds < 10 ? (seconds = "0" + seconds) : null;

                // If the count down is over, write some text
                if (distance < 0) {
                    clearInterval(counter);
                    $counter.addClass(exprireCls);
                    $counter.find(".message").css("display", "block");
                } else {
                    // Output the result in elements
                    s$(".day").html(days);
                    s$(".hour").html(hours);
                    s$(".minute").html(minutes);
                    s$(".seconds").html(seconds);
                }
            }, 1000);
        });
    };

    if ($(".counter-list").length) {
        $(".counter-list").countdown();
    }

    /* ==================================================
#  Load More 
===============================================*/

    $(function () {
        $(".faq-area").slice(0, 4).show();
        $("#loadMore").on("click", function (e) {
            e.preventDefault();
            $(".loadcontent:hidden").slice(0, 3).slideDown();
            if ($(".loadcontent:hidden").length == 0) {
                $("#loadMore").text("No Content").addClass("noContent");
            }
        });

    })

    /*----------- 21. Price Slider ----------*/
    // Requires jQuery UI, which this site no longer ships (no page has a price
    // slider). Guarded so the call cannot throw when the plugin is absent.
    if ($(".price_slider").length && typeof $.fn.slider === "function") {
        $(".price_slider").slider({
            range: true,
            min: 0,
            max: 100,
            values: [0, 30],
            slide: function (event, ui) {
                $(".from").text("$" + ui.values[0]);
                $(".to").text("$" + ui.values[1]);
            }
        });
        $(".from").text("$" + $(".price_slider").slider("values", 0));
        $(".to").text("$" + $(".price_slider").slider("values", 1));
    }



    /*---------- 18. Image to SVG Code ----------*/
    const cache = {};

    $.fn.inlineSvg = function fnInlineSvg() {
        this.each(imgToSvg);

        return this;
    };

    function imgToSvg() {
        const $img = $(this);
        const src = $img.attr("src");

        // fill cache by src with promise
        if (!cache[src]) {
            const d = $.Deferred();
            $.get(src, (data) => {
                d.resolve($(data).find("svg"));
            });
            cache[src] = d.promise();
        }

        // replace img with svg when cached promise resolves
        cache[src].then((svg) => {
            const $svg = $(svg).clone();

            if ($img.attr("id")) $svg.attr("id", $img.attr("id"));
            if ($img.attr("class")) $svg.attr("class", $img.attr("class"));
            if ($img.attr("style")) $svg.attr("style", $img.attr("style"));

            if ($img.attr("width")) {
                $svg.attr("width", $img.attr("width"));
                if (!$img.attr("height")) $svg.removeAttr("height");
            }
            if ($img.attr("height")) {
                $svg.attr("height", $img.attr("height"));
                if (!$img.attr("width")) $svg.removeAttr("width");
            }

            $svg.insertAfter($img);
            $img.trigger("svgInlined", $svg[0]);
            $img.remove();
        });
    }

    $(".svg-img").inlineSvg();


    /* (duplicate .th-anim image-reveal block removed - see the note above) */


    

    /*----------- 00. Woocommerce Toggle ----------*/
    // Ship To Different Address
    $("#ship-to-different-address-checkbox").on("change", function () {
        if ($(this).is(":checked")) {
            $("#ship-to-different-address")
                .next(".shipping_address")
                .slideDown();
        } else {
            $("#ship-to-different-address").next(".shipping_address").slideUp();
        }
    });

    // Login Toggle
    $(".woocommerce-form-login-toggle a").on("click", function (e) {
        e.preventDefault();
        $(".woocommerce-form-login").slideToggle();
    });

    // Coupon Toggle
    $(".woocommerce-form-coupon-toggle a").on("click", function (e) {
        e.preventDefault();
        $(".woocommerce-form-coupon").slideToggle();
    });

    // Woocommerce Shipping Method
    $(".shipping-calculator-button").on("click", function (e) {
        e.preventDefault();
        $(this).next(".shipping-calculator-form").slideToggle();
    });

    // Woocommerce Payment Toggle
    $('.wc_payment_methods input[type="radio"]:checked')
        .siblings(".payment_box")
        .show();
    $('.wc_payment_methods input[type="radio"]').each(function () {
        $(this).on("change", function () {
            $(".payment_box").slideUp();
            $(this).siblings(".payment_box").slideDown();
        });
    });

    // Woocommerce Rating Toggle
    $(".rating-select .stars a").each(function () {
        $(this).on("click", function (e) {
            e.preventDefault();
            $(this).siblings().removeClass("active");
            $(this).parent().parent().addClass("selected");
            $(this).addClass("active");
        });
    });

    // Quantity Plus Minus ---------------------------

    $(".quantity-plus").each(function () {
        $(this).on("click", function (e) {
            e.preventDefault();
            var $qty = $(this).siblings(".qty-input");
            var currentVal = parseInt($qty.val(), 10);
            if (!isNaN(currentVal)) {
                $qty.val(currentVal + 1);
            }
        });
    });

    $(".quantity-minus").each(function () {
        $(this).on("click", function (e) {
            e.preventDefault();
            var $qty = $(this).siblings(".qty-input");
            var currentVal = parseInt($qty.val(), 10);
            if (!isNaN(currentVal) && currentVal > 1) {
                $qty.val(currentVal - 1);
            }
        });
    });

    // /*----------- 00.Color Scheme ----------*/
    $('.color-switch-btns button').each(function () {
        // Get color for button
        const button = $(this);
        const color = button.data('color');
        button.css('--theme-color', color);

        // Change theme color on click
        button.on('click', function () {
            const clickedColor = $(this).data('color');
            $(':root').css('--theme-color', clickedColor);
        });
    });

    $(document).on('click', '.switchIcon', function () {
        $('.color-scheme-wrap').toggleClass('active');
    });


    /*----------- 00. House of Vacation - site behaviour ----------*/

    // Tour galleries already carry cursor:pointer and a hover zoom, so they read
    // as clickable. Wire them to the lightbox that is already on the page
    // instead of leaving that affordance dead.
    if ($.fn.magnificPopup) {
        $('.tour-gallery').each(function () {
            $(this).magnificPopup({
                delegate: '.gallery-item',
                type: 'image',
                mainClass: 'mfp-zoom-in',
                removalDelay: 260,
                closeOnContentClick: false,
                gallery: { enabled: true, navigateByImgClick: true },
                image: {
                    titleSrc: function (item) {
                        var img = item.el.find('img');
                        return img.attr('alt') || '';
                    }
                },
                callbacks: {
                    elementParse: function (item) {
                        item.src = item.el.find('img').attr('src');
                    }
                }
            });
        });
        $('.tour-gallery .gallery-item').attr({ role: 'button', tabindex: '0' });
        $(document).on('keydown', '.tour-gallery .gallery-item', function (e) {
            if (e.key === 'Enter' || e.key === ' ') { e.preventDefault(); $(this).trigger('click'); }
        });
    }

    // Keep the hamburger's aria-expanded in step with the drawer, and let Esc
    // close the drawer and the quick-contact panel.
    var $menuWrap = $('.th-menu-wrapper');
    var $menuBtn = $('.th-menu-toggle.d-block');
    function syncMenuState() {
        $menuBtn.attr('aria-expanded', $menuWrap.hasClass('th-body-visible') ? 'true' : 'false');
    }
    $('.th-menu-toggle').on('click', function () { setTimeout(syncMenuState, 0); });
    $menuWrap.on('click', function () { setTimeout(syncMenuState, 0); });

    $(document).on('keydown', function (e) {
        if (e.key !== 'Escape') { return; }
        if ($menuWrap.hasClass('th-body-visible')) { $menuWrap.removeClass('th-body-visible'); syncMenuState(); }
        $('.sidemenu-wrapper.show').removeClass('show');
    });

    // Prevent a double submit from producing two enquiry emails.
    $(document).on('submit', 'form', function () {
        var $f = $(this);
        if ($f.data('hov-locked')) { return false; }
        if (!$f.hasClass('ajax-contact')) {
            $f.data('hov-locked', true);
            setTimeout(function () { $f.data('hov-locked', false); }, 4000);
        }
    });





    // /*----------- 00. Right Click Disable ----------*/ 
    //   window.addEventListener('contextmenu', function (e) {
    //     // do something here...
    //     e.preventDefault();  
    //   }, false);  

    // /*----------- 00. Inspect Element Disable ----------*/   
    //   document.onkeydown = function (e) {   
    //     if (event.keyCode == 123) {  
    //       return false;
    //     }
    //     if (e.ctrlKey && e.shiftKey && e.keyCode == 'I'.charCodeAt(0)) {
    //       return false;
    //     }
    //     if (e.ctrlKey && e.shiftKey && e.keyCode == 'C'.charCodeAt(0)) {
    //       return false;
    //     }
    //     if (e.ctrlKey && e.shiftKey && e.keyCode == 'J'.charCodeAt(0)) {
    //       return false;
    //     }
    //     if (e.ctrlKey && e.keyCode == 'U'.charCodeAt(0)) {  
    //       return false;
    //     } 
    //   }   

})(jQuery);