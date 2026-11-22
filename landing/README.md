# Landing — BlackQuack Studio (Start-Up Chile BUILD)

Sitio estático (HTML + CSS + JS, sin framework). Estética stop-motion: todo el
movimiento a 12 fps con `steps()`. Independiente de la app Flutter.

- **Prod:** https://blackquack-landing.pages.dev (dominio final: `build.blackquack.cl`)
- **Desplegar:** `./scripts/deploy_landing.sh` (genera `version.json` desde `pubspec.yaml` y sube a Cloudflare Pages, proyecto `blackquack-landing`). No toca la app ni el apex.
- **Lighthouse (móvil):** rendimiento 99, accesibilidad 96.

## Quitar el `noindex` (cuando sea pública)
1. Borra el bloque `X-Robots-Tag` de `landing/_headers`.
2. Borra `<meta name="robots" content="noindex, nofollow">` de `landing/index.html`.
3. Redespliega.

## DNS para `build.blackquack.cl`
En el panel de **Cloudflare Pages → proyecto `blackquack-landing` → Custom domains → Add** `build.blackquack.cl`. Como la zona `blackquack.cl` ya está en Cloudflare, el registro se crea solo (un `CNAME build → blackquack-landing.pages.dev`, proxied). **No** se toca el apex `blackquack.cl` ni `demo.`. Si prefieres hacerlo a mano en DNS: `CNAME build blackquack-landing.pages.dev` (naranja/proxied).

## Video (Cuadro 04)
Reemplaza `data-video-id="VIDEO_ID"` en `index.html` por el ID real de YouTube. Carga diferida con `youtube-nocookie`.

---

## Imágenes provisorias a reemplazar (todas en `/landing/assets/`)
Son placeholders SVG (y un PNG de dummyimage para OG). Mantén los mismos nombres o actualiza las rutas en `index.html`.

| Archivo | Uso | Tamaño sugerido |
|---|---|---|
| `logo-blackquack.svg` | Logo (portada, pie, favicon) | vectorial o 420×120 |
| `frame-01.svg` … `frame-12.svg` | Flipbook de portada (12 cuadros reales de una secuencia) | 900×1100 (vertical) |
| `captura-app-1/2/3.svg` | Capturas reales del prototipo (Cuadro 05 y vista previa del video) | 1200×800 |
| `taller-1.svg` … `taller-6.svg` | Fotos del taller Animakids (Cuadro 07) | 800×600 |
| `team-karen.svg`, `team-paulo.svg`, `team-bastian.svg` | Fotos del equipo (circulares) | 400×400 |
| `logo-yerpun.svg` | Logo Colegio Montessori Yerpún | 300×150 (fondo transparente) |
| `logo-uv-diseno.svg` | Logo Escuela de Diseño UV | 300×150 (fondo transparente) |
| `og-cover.png` | Imagen al compartir el enlace (Open Graph) | **1200×630 PNG/JPG** |

## Textos provisorios a confirmar/reemplazar
- **Video:** `VIDEO_ID` (ID de YouTube real).
- **Contacto:** `contacto@blackquack.cl` (confirmar el correo definitivo).
- **Dominio OG:** `og:image`/`og:url` apuntan a `https://build.blackquack.cl/…` (ajustar si el dominio final cambia).
- El resto del texto es el entregado para la postulación (portada, manifiesto, iniciativa, cómo funciona, equipo, Animakids, colaboración).
