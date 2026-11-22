// BlackQuack landing — interacciones (tolera prefers-reduced-motion y no-JS).
(function () {
  'use strict';
  var reduce = window.matchMedia('(prefers-reduced-motion: reduce)').matches;

  // ---- Versión única: desde version.json (lo genera el deploy desde pubspec) ----
  fetch('version.json', { cache: 'no-store' })
    .then(function (r) { return r.ok ? r.json() : null; })
    .then(function (j) {
      if (!j || !j.version) return;
      document.querySelectorAll('[data-version]').forEach(function (el) {
        el.textContent = 'v' + j.version;
      });
    })
    .catch(function () {});

  // ---- Header: sombra al hacer scroll ----
  var header = document.getElementById('site-header');
  if (header) {
    var onScroll = function () {
      header.classList.toggle('scrolled', window.scrollY > 8);
    };
    window.addEventListener('scroll', onScroll, { passive: true });
    onScroll();
  }

  // ---- Reveal on scroll ----
  var reveals = document.querySelectorAll('.reveal');
  if (reduce || !('IntersectionObserver' in window)) {
    reveals.forEach(function (el) { el.classList.add('in'); });
  } else {
    var io = new IntersectionObserver(function (entries) {
      entries.forEach(function (e) {
        if (e.isIntersecting) { e.target.classList.add('in'); io.unobserve(e.target); }
      });
    }, { threshold: 0.12, rootMargin: '0px 0px -8% 0px' });
    reveals.forEach(function (el) { io.observe(el); });
  }

  // ---- Video: carga diferida del iframe (youtube-nocookie) al tocar ----
  var video = document.getElementById('video-player');
  if (video) {
    video.addEventListener('click', function () {
      var id = video.getAttribute('data-video-id');
      if (!id || id === 'VIDEO_ID') {
        console.info('[BlackQuack] Reemplaza data-video-id="VIDEO_ID" por el ID real de YouTube.');
        return;
      }
      var iframe = document.createElement('iframe');
      iframe.src = 'https://www.youtube-nocookie.com/embed/' + id + '?autoplay=1&rel=0';
      iframe.title = 'Video de BlackQuack Studio';
      iframe.allow = 'accelerometer; autoplay; clipboard-write; encrypted-media; gyroscope; picture-in-picture';
      iframe.allowFullscreen = true;
      video.innerHTML = '';
      video.appendChild(iframe);
    });
  }
})();
