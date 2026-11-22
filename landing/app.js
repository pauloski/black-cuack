// BlackQuack landing — interacciones (todo tolera prefers-reduced-motion y no-JS).
(function () {
  'use strict';
  var reduce = window.matchMedia('(prefers-reduced-motion: reduce)').matches;
  var clamp = function (v, a, b) { return Math.max(a, Math.min(b, v)); };

  // ---- Versión única: desde version.json (lo genera el deploy desde pubspec) ----
  fetch('version.json', { cache: 'no-store' })
    .then(function (r) { return r.ok ? r.json() : null; })
    .then(function (j) {
      if (!j || !j.version) return;
      document.querySelectorAll('[data-version]').forEach(function (el) {
        el.textContent = 'v' + j.version;
      });
    })
    .catch(function () { /* deja el valor por defecto del HTML */ });

  // ---- Flipbook en scroll: avanza cuadro a cuadro ----
  var flip = document.getElementById('flipbook');
  if (flip && !reduce) {
    var frames = flip.querySelectorAll('.fb-frame');
    var n = frames.length;
    var current = 0;
    var ticking = false;
    var update = function () {
      ticking = false;
      var rect = flip.getBoundingClientRect();
      var vh = window.innerHeight || document.documentElement.clientHeight;
      var p = clamp((vh - rect.top) / (vh + rect.height), 0, 1);
      var idx = clamp(Math.round(p * (n - 1)), 0, n - 1);
      if (idx !== current) {
        frames[current].classList.remove('is-active');
        frames[idx].classList.add('is-active');
        current = idx;
      }
    };
    var onScroll = function () {
      if (!ticking) { ticking = true; requestAnimationFrame(update); }
    };
    window.addEventListener('scroll', onScroll, { passive: true });
    window.addEventListener('resize', onScroll, { passive: true });
    update();
  }

  // ---- Manifiesto: aparece palabra por palabra (a 12 fps con steps) ----
  var quote = document.querySelector('[data-words]');
  if (quote && !reduce) {
    var text = quote.textContent.trim();
    quote.textContent = '';
    text.split(/\s+/).forEach(function (word, i) {
      var span = document.createElement('span');
      span.className = 'w';
      span.textContent = word;
      span.style.transitionDelay = (i * 0.0833).toFixed(3) + 's';
      quote.appendChild(span);
      quote.appendChild(document.createTextNode(' '));
    });
    if ('IntersectionObserver' in window) {
      var io = new IntersectionObserver(function (entries) {
        entries.forEach(function (e) {
          if (e.isIntersecting) { quote.classList.add('reveal'); io.disconnect(); }
        });
      }, { threshold: 0.4 });
      io.observe(quote);
    } else {
      quote.classList.add('reveal');
    }
  }

  // ---- Video: carga diferida del iframe (youtube-nocookie) al tocar ----
  var video = document.getElementById('video');
  if (video) {
    var load = function () {
      var id = video.getAttribute('data-video-id');
      if (!id || id === 'VIDEO_ID') {
        // Placeholder: aún sin ID real. Avisa en consola, no rompe la página.
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
    };
    video.addEventListener('click', load);
  }
})();
