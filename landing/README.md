# Landing — BlackQuack Studio (Start-Up Chile BUILD)

Sitio estático (HTML + CSS + JS, sin framework), claro y minimalista. Contenido de
brochure (fuente: `tema-1.html`) con el estilo de la landing. Independiente de la app.

- **Prod:** https://blackquack-landing.pages.dev (dominio final: `build.blackquack.cl`)
- **Desplegar:** `./scripts/deploy_landing.sh` (genera `version.json` desde `pubspec.yaml` y sube a Cloudflare Pages, proyecto `blackquack-landing`). No toca la app ni el apex.
- **Lighthouse (móvil):** rendimiento 98, accesibilidad 96, CLS 0.
- **Tipografía:** Bricolage Grotesque (títulos) + Inter (texto), vía Google Fonts.
- `tema-1.html` queda como referencia de contenido (no se publica como página).

## Quitar el `noindex` (cuando sea pública)
1. Borra el bloque `X-Robots-Tag` de `landing/_headers`.
2. Borra `<meta name="robots" content="noindex, nofollow">` de `landing/index.html`.
3. Redespliega.

## DNS para `build.blackquack.cl`
**Cloudflare Pages → proyecto `blackquack-landing` → Custom domains → Add** `build.blackquack.cl`. Como la zona `blackquack.cl` ya está en Cloudflare, el registro se crea solo (`CNAME build → blackquack-landing.pages.dev`, proxied). **No** se toca el apex ni `demo.`.

## Video demo
Reemplaza `data-video-id="VIDEO_ID"` en `index.html` por el ID real de YouTube (carga diferida con `youtube-nocookie`).

---

## Imágenes: qué va en cada slot (placeholders en `/landing/assets/`)
Son placeholders estáticos. Reemplaza el archivo con el mismo nombre (o cambia la ruta en `index.html`). Ya subiste algunos reales (`kb.png`, `banner-taller.jpg`, `g-taller-002.jpg`, `brand-*.png`, `h-brand-001.jpg`): dime cuál va en cada slot y los conecto.

| Slot (archivo actual) | Uso | Tamaño sugerido |
|---|---|---|
| `logo-nav-light.svg` | Logo en portada y pie (ya es el tuyo) | vectorial |
| `hero-principal.svg` | Foto principal de portada (niños animando) | ~1040×860 |
| `video-preview.svg` | Miniatura del video demo | 1280×720 |
| `captura-prototipo.svg` | Captura real del prototipo (sección Tecnología) | 1200×800 |
| `animakids-1/2/3.svg` | 3 fotos del taller (sección Animakids) | 800×600 |
| `team-karen.svg`, `team-paulo.svg` | Fotos del equipo (circulares) | 400×400 |
| `logo-yerpun.svg` | Logo Colegio Montessori Yerpún | 300×150 (fondo transparente) |
| `logo-uv-diseno.svg` | Logo Escuela de Diseño UV | 300×150 (fondo transparente) |
| `og-cover.png` | Imagen al compartir el enlace (Open Graph) | **1200×630 PNG/JPG** |

## Textos a confirmar/reemplazar
- **Video:** `VIDEO_ID` (ID de YouTube).
- **Contacto:** `contacto@blackquack.cl`.
- **Dominio OG:** `og:image`/`og:url` apuntan a `https://build.blackquack.cl/…`.
- El resto del texto proviene de `tema-1.html` (problema, oportunidad, solución, tecnología, validación/Animakids, diferenciación, modelo de negocio, Chile, equipo) + las secciones mantenidas (iniciativa, guía de 2 min, instituciones).
