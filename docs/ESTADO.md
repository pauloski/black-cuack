# ESTADO — BlackQuack Studio

Fecha de corte: **2026-11-21** (maratón). Rama de trabajo: `demo/semana-1`. Objetivo (CLAUDE.md §8): **demo del MVP** en `demo.blackquack.cl`, local-first, sin exponer datos.

---

## Estado final del MVP (maratón 2026-11-21)

Todo lo de abajo está **en producción** (`demo.blackquack.cl`), local-first (sin Firebase en la ruta crítica), con tags de reversión `prod-20261121-1..8`. 18 pruebas en verde (repo, codec, modelos, versiones, borrador). `noindex` activo. Prioridad de métricas: **Android** (abrir en Chrome; medir compresión con `?debug=1`).

| HDU | Función | Estado |
|---|---|---|
| HDU1 · Papel cebolla + guardado al instante | Cebolla 1–3 capas + opacidad; compresión al capturar → guardado inmediato; borrador auto-persistido (reabre tras cierre; "atrás" pregunta guardar/descartar) | **Hecho** (🤖 fijar exposición/enfoque/balance = nativo Android, falta) |
| HDU2 · Orientación 9:16 / 16:9 | Elección al crear; recorte fijo en captura, guía de encuadre, GIF/reproductor | **Hecho** |
| HDU3 · Línea de tiempo y FPS | Reordenar (arrastrar), duplicar, borrar con deshacer; FPS 1–30 + atajos 6/8/12/15/24; bucle desde cualquier cuadro | **Hecho** |
| HDU4 · Export GIF/ZIP (/MP4) | GIF y ZIP en web/Android, sin EXIF/ubicación, marca de agua "BlackQuack" | **Parcial** (🤖 MP4 nativo pendiente; sin niveles 720/1080) |
| HDU5 · Versiones por autor | Guardar versión (fecha/autor/nº cuadros), historial restaurar/duplicar, cuadros compartidos | **Hecho** (ejercicios de práctica, falta) |
| HDU6 · Perfiles sin correo (local) | Apodo, avatar, clave de 3 dibujos; elegir al entrar; cada perfil ve solo sus proyectos | **Hecho** (demo local; reset de clave por docente, falta) |
| HDU7 · Sala por QR / código | Código de 5 caracteres (base de `wip`); sin QR ni lista de apodos/OA | **Parcial** |
| HDU8 · Kiosco / fijar pantalla | — | **Falta** (🤖 nativo Android) |
| HDU9 · Grupos con roles | Galería de grupo (nube, gateada por `hasCloudAccount`); sin roles/autoría por versión | **Parcial** (fuera de alcance esta semana) |
| HDU10 · Sincronización asíncrona | Local-first listo; cola a Cloudflare no construida | **Parcial** |
| HDU11 · Dashboard docente | — | **Falta** |
| HDU12 · Reporte UTP | — | **Falta** |
| HDU13 · Proyección pantalla completa | Modo proyección sin controles (proyecto o "Mis proyectos" en secuencia) | **Hecho** |
| HDU14 · Continuidad en casa con código | — | **Falta** |

**Pendiente operativo:** configurar **Cloudflare Access** antes de compartir fuera del equipo; investigar tree-shaking de íconos `_rounded` (hoy fuente completa +1,6 MB).

## Checklist de validación en Android (producción) — 10 pasos

Abrir **https://demo.blackquack.cl** en Chrome de Android (`?debug=1` para ver ms/cuadro):
1. "ENTRAR AL TALLER" → **crear un perfil** (apodo, avatar, 3 dibujos) → entrar. *(correo tras "Soy docente")*
2. "Nuevo proyecto" → elegir **Vertical u Horizontal** → la guía de encuadre respeta la orientación.
3. Capturar **5 cuadros rápido**: el obturador responde al instante; se ve el papel cebolla.
4. En la línea de tiempo: **arrastrar** para reordenar, **duplicar** y **borrar con DESHACER**.
5. Ajustes: fijar FPS con un **atajo (12/15/24)**; reproducir → **bucle** desde el cuadro elegido.
6. **Guardar versión** (📑) y abrir **Historial** (🕘) → **restaurar/duplicar**.
7. **Guardar** (título+artista) → vuelve a Inicio → en "Mis proyectos" aparece **con miniatura**; **recargar** → persiste.
8. Exportar **GIF** y **ZIP** → se abren con todos los cuadros, con marca de agua "BlackQuack".
9. "Mis proyectos" → **Proyectar** (▶ pantalla completa, sin controles); tocar para salir.
10. **Modo avión tras cargar** → crear/guardar/listar/exportar siguen; cerrar sesión y entrar con **otro perfil** → ve solo sus proyectos.

---

## 0. Auditoría de ramas (git)

| Rama / tag | Estado | Contenido |
|---|---|---|
| `main` | `e7451e0` | v1.0.0 + commit de docs de reorientación (CLAUDE.md, docs/, README; CONTEXTO.md movido a `docs/archivo/`) |
| tag `v1.0.0` | `c0e2dec` | Sin cambios; prototipo base |
| `demo/semana-1` | desde `e7451e0` | Rama de trabajo de la semana (actual) |
| `wip/borrado-soportes-y-camara-remota` | `c58b569` | IGNITE congelado: borrado de soportes, cámara remota, afinamiento de exportación web (incl. el ZIP con la regresión). También en origin |

Hallazgo: la "protección del trabajo" ya estaba hecha — el código IGNITE estaba committeado en `wip` y el tag `v1.0.0` existía. Lo único sin commitear era documentación, que se consolidó en `main`.

---

## 1. Tabla de HDU verificada contra el código (niveles A y B)

| HDU | Nivel | Estado verificado | Acción | Comprobado en |
|---|---|---|---|---|
| HDU1 · Papel cebolla | A | Parcial (1 cuadro de cebolla, opacidad ajustable; faltan 1–3) | Adaptar | `camera_viewer.dart:205-219`, `camera_page.dart:34,228-248` |
| HDU2 · Orientación | B | No existe (sin elección vertical/horizontal) | Construir (simple) | — |
| HDU3 · Línea de tiempo y FPS | A | Parcial (FPS 1–24 ok; sin reordenar/duplicar/undo-borrado/atajos/bucle-desde-cuadro) | Adaptar | `camera_timeline.dart:34-66`, `camera_page.dart:89-103,186-196,321-333` |
| HDU4 · Exportación | A | A corregir: en `main` solo GIF+MP4(móvil), **sin ZIP**; ZIP de 22 bytes en `wip`; cuadros como referencias, no datos | Corregir primero | `video_creator.dart` (main y `wip`@c58b569:195-200,167) |
| HDU5 · Versiones por autor | A | No existe (save con merge + campo "artista" libre; sin versiones) | Construir | `project_service.dart:33-48`, `camera_viewer.dart:68-80` |
| HDU6 · Perfiles sin correo | A | Contrario al diseño (email+contraseña y anónimo; sin apodo/avatar/clave de imágenes) | Reemplazar | `auth_service.dart:28-64` |
| HDU7 · Sala por QR / código | A | Parcial (código de 5 caracteres + admin=dueño; sin QR, asignatura, OA, apodos) | Adaptar | `group_utils.dart:5-14`, `group_service.dart:11-55`, `my_groups_page.dart:53-58` |
| HDU8 · Kiosco | A | No existe (sin fijación de pantalla) | Construir (Android) | sin referencias a lockTask/kiosk en `lib/` |
| HDU9 · Grupos con roles | A | Parcial (galería compartida; sin roles ni autoría por versión) | Adaptar | `project_service.dart:75-90`, `group_service.dart:18-24` |
| HDU10 · Sincronización asíncrona | A | Contrario al diseño (Firestore en tiempo real; `ProjectStorage` local es código muerto) | Reemplazar | `project_service.dart:58-90`, `project_storage.dart` (sin referencias) |
| HDU11 · Dashboard | A | No existe (solo galerías) | Construir | — |
| HDU12 · Reporte UTP | B | No existe (sin dependencia pdf) | Construir (simple) | — |
| HDU13 · Proyección | B | Parcial: reproductor en bucle **con controles**, no modo proyección a pantalla completa | Construir (modo proyección) | `movie_player_page.dart:22-39,55,85-197` |
| HDU14 · Continuidad en casa | B | No existe (ligado al uid; sin código personal) | Construir (simple) | `project_service.dart:15,33-48` |

(Niveles C congelados para IGNITE; sin cambios.)

---

## 2. Diagnóstico de los bugs (archivo:línea)

### 2.1 Exportación — ZIP de 22 bytes
- El ZIP de 22 bytes está en la rama **`wip`**, no en `main` (en `main` no hay exportación ZIP).
- `wip`@`c58b569` — `video_creator.dart:195-200`: `_fetchBytes(path)` enruta por `http.get` solo si `path` empieza por `http`; un `blob:` web cae a `File(path).readAsBytes()` (`dart:io`, no soportado en web) → lanza → lo traga el `try/catch` por cuadro (`:167`, solo `debugPrint`) → `archive` vacío → `ZipEncoder` emite el End-Of-Central-Directory = 22 bytes. El guard mira `zipBytes.isEmpty` (22 ≠ 0), así que descarga igual.
- Mismo origen rompe GIF y MP4-web. Android/iOS no se ven afectados (rutas nativas).
- **Causa de fondo:** los cuadros se manejan como referencias (`blob:` en web; URL de Storage al recargar), no como datos.

### 2.2 Miniaturas negras en "Mis proyectos"
- Tarjeta usa `photoPaths[0]` (`project_grid_view.dart:57-59,78`) con `NetworkImage` en web (`blackcuack_widgets.dart:90-91`).
- Al recargar, la URL de Storage es válida, pero la app corre en **CanvasKit** (el `renderer:"html"` de `web/index.html:27` es obsoleto) y el bucket **no tiene CORS** → el dibujo cross-origin se bloquea → fondo `Colors.black38` = tarjeta negra. En sesión funcionan porque `blob:` es same-origin.

### 2.3 Proyectos que "desaparecen" en modo invitado
- `signInAnonymously()` en cada entrada (`login_page.dart:19-38`); sin auth-gate (`splash_page.dart:25`); sin `setPersistence`. Proyectos por `users/{uid}` (`project_service.dart:15,61-66`).
- Firebase reutiliza el uid anónimo si la persistencia (IndexedDB) está intacta; se pierde con otro navegador/dispositivo, incógnito, borrar datos del sitio, o **`signOut()` de un anónimo** (`profile_page.dart:29`), que abandona el uid para siempre → proyectos huérfanos.
- Bug secundario: si el sign-in anónimo falla, navega igual a `/home` sin usuario → `_userId=''` → `saveProject` no guarda nada en silencio (`project_service.dart:19`).

**Corrección raíz (una sola):** guardar los cuadros como **bytes** en un almacén local (Hive CE) detrás de una **interfaz de repositorio**; esto arregla exportación y miniaturas a la vez, elimina la dependencia del uid de Firebase y habilita el modo offline. Ver `docs/decisiones/0001-modo-local-demo.md`.

---

## 3. Plan de la semana (resumen; detalle en el plan aprobado)

Orden: **T0** vía de publicación operativa (Cloudflare Pages `blackquack-demo` + `demo.blackquack.cl` + Access; `scripts/deploy_demo.sh`; publicar versión actual para validar la vía) → **T1** repositorio local-first (Hive CE, cuadros como bytes) → **T2a** guardado local + compresión JPEG ≤1280 px → **T2b** entrada sin email, identidad local, arranque offline, arreglo del toast "se guardó localmente" → **T3** prueba de exportación (TDD, debe fallar primero) → **T4** GIF por bytes → **T5** ZIP por bytes (rescatado de `wip`, reescrito) → **T6** miniaturas (`Image.memory`) → **T7** línea de tiempo (HDU3) → **T8** papel cebolla 1–3 (HDU1) → **T9** versiones (HDU5). Si alcanza: **T10** sala simulada con QR (HDU6/7, prioridad) → **T11** kiosco Android (HDU8). Cierre: **T12** docs + APK.

Despliegue continuo y bajo demanda desde T0; cada publicación se aprueba.

---

## Estado de T0

- **T0 CERRADO:** demo publicada en **https://demo.blackquack.cl** (y `blackquack-demo.pages.dev`) con la **interfaz final** de `wip` y la **exportación GIF funcionando** en web (12 cuadros verificados por Paulo). Vía de publicación operativa (`scripts/deploy_demo.sh`), `noindex` activo en ambos hostnames.

## Estado de T2a (Bloque A) — local-first

- **En producción (`demo.blackquack.cl`):** ciclo personal completo **local-first** (Hive, cuadros como bytes JPEG ≤1280): entrar sin email, capturar, guardar, listar con miniatura (`Image.memory`), reabrir/añadir, reproducir y borrar — **sin Firebase**. Exportación GIF web OK; ZIP/MP4 "en corrección" en web. IGNITE oculto tras `kEnableIgniteFeatures`.
- **Compresión al capturar** (cola en segundo plano, no bloquea el obturador) con respaldo al guardar; `pruneOrphanFrames(olderThan:24h)` al arranque.
- **En preview, pendiente de prueba en Android** (`t2a-preview.blackquack-demo.pages.dev`, rama `feat/hdu1-draft`): **borrador HDU1 auto-persistido** (`isDraft`) e **indicador `?debug=1`** de ms/cuadro. Al aprobar → merge a `demo/semana-1` + deploy producción.
- **Prioridad de validación/métricas: Android** (MVP a Google Play), no iPad/Safari.
- Pruebas: 15 en verde (frame_codec, repo Hive+LazyBox, save-flow, borrador, prune 24h, in-memory).

## Offline — qué cubre (web vs Android)

- **Datos (IndexedDB vía Hive):** crear, guardar, listar, reabrir, reproducir y exportar GIF funcionan **sin red** una vez cargada la app, y **persisten** entre recargas.
- **Cargar la app sin red (web):** depende del **service worker** de Flutter (`flutter_service_worker.js`): tras la primera carga con red, una recarga posterior puede funcionar offline desde su caché; una primera carga sin red no. En **Android nativo (APK/Play)** la app es offline total.
- **Safari/iPad (WebKit/ITP):** puede **borrar IndexedDB tras ~7 días** sin visitas al sitio (política de almacenamiento de WebKit). Mitigación: al iniciar se pide `navigator.storage.persist()` (best-effort; Safari puede no concederlo). **Sin garantía de persistencia en Safari sin visitas periódicas.** Por eso el MVP prioriza Android.
- **Respaldo en memoria:** si el navegador bloquea IndexedDB, la app corre pero **no persiste**; se muestra un **banner rojo** permanente y el guardado avisa que se perderá al cerrar.

## Auditoría HDU1–5 vs `docs/HISTORIAS_DE_USUARIO.md` (2026-11-21)

Leyenda: ✅ hecho · ⚠️ parcial · ❌ falta · 🤖 solo cumplible en **nativo Android**.

**HDU1 · Papel cebolla, sin internet**
- ✅ 1–3 cuadros anteriores con opacidad ajustable (`camera_viewer.dart:242-253` + slider).
- 🤖❌ Fijar exposición, enfoque y balance de blancos (controles de cámara: nativo Android; en web son limitados/no fiables).
- ✅ Cada cuadro se guarda al instante en el dispositivo; en modo avión no se pierde (compresión al capturar → repo local).
- ✅ Reabre en el último cuadro tras un cierre (borrador auto-persistido; reabrible desde "Mis proyectos"). *(en preview)*

**HDU2 · Orientación vertical/horizontal** — ❌ Falta todo (elección por proyecto, respeto en cámara/timeline, export). Cross-platform.

**HDU3 · Línea de tiempo y FPS**
- ⚠️ Reordenar / duplicar / borrar con deshacer: borrar ✅ y deshacer-última-captura ✅; **reordenar, duplicar y deshacer-borrado faltan** (→ T7).
- ⚠️ FPS 1–30 con atajos 6/8/12/15/24: slider **1–24 sin atajos** (→ T7).
- ⚠️ Bucle desde cualquier cuadro: hay bucle desde 0; **"desde cualquier cuadro" falta** (→ T7).

**HDU4 · Export MP4/GIF/ZIP**
- ⚠️ Exporta sin internet: **GIF ✅** (web+móvil); **ZIP** nativo ✅ pero "en corrección" en web (→ T5); **🤖 MP4** nativo (MediaCodec) pendiente post-demo.
- ❌ 720p con marca de agua (gratis) / 1080p sin marca (pago).
- ⚠️ Sin ubicación ni metadatos: los cuadros se **recodifican a JPEG** (descarta EXIF), pero no está verificado explícitamente para geolocalización.
- ❌ En aula, exportar fuera de la app lo habilita el docente (capa de aula).

**HDU5 · Versiones firmadas por autor** — ❌ Falta la función (guardar versión, historial, restaurar, autor/origen, ejercicios). **Base lista:** el repositorio **ya comparte cuadros entre proyectos/versiones sin duplicar** (→ T9).

## Pendientes

- **Promover a producción el Bloque A+** (borrador HDU1 + `?debug`) tras tu prueba en **Android** del preview `t2a-preview` (rama `feat/hdu1-draft`).
- **Configurar Cloudflare Access** (`demo.blackquack.cl` y `blackquack-demo.pages.dev`) **antes de compartir la demo fuera del equipo.**
- **Íconos `_rounded` en blanco** (inicio, cámara, exportar): causados por el tree-shaking de íconos del build web, que dejaba una fuente MaterialIcons de 16 KB sin los glifos de las variantes `_rounded`. **Corregido y publicado** con `--no-tree-shake-icons` en `scripts/deploy_demo.sh` (fuente completa de 1,6 MB; verificado en vivo).
- **Investigar por qué el tree-shaking de íconos excluye las variantes `_rounded`, para volver al build optimizado** (hoy se publica con la fuente completa, +1,6 MB). Mientras tanto, la demo lleva `noindex`/`X-Robots-Tag: noindex` para que no la indexen los buscadores, pero el enlace sigue siendo accesible para quien lo tenga.

## 4. Bitácora

- **2026-11-20** — Reorientación a herramienta de aula. Auditoría git (trabajo ya protegido en `wip`; docs consolidados en `main`), creada `demo/semana-1`. Verificada la tabla de HDU contra el código y corregidas HDU4 y HDU13 en `docs/HISTORIAS_DE_USUARIO.md`. Diagnóstico de exportación, miniaturas y modo invitado con archivo:línea. Plan de la semana aprobado. Creados `docs/decisiones/0001-modo-local-demo.md` y `scripts/deploy_demo.sh` (pendiente T0).
- **2026-11-20/21** — T0 cerrado (demo en producción con interfaz final de `wip` + GIF web + íconos completos). Merge `wip`→`demo/semana-1` con IGNITE tras flag. **Bloque A (T2a) completo y en producción**: repositorio local-first (Hive), compresión al capturar, ciclo personal sin Firebase, banner de almacén efímero, gate `hasCloudAccount`. **En preview pendiente de prueba (Android):** borrador HDU1 (`isDraft`) + `?debug`. Auditoría HDU1–5 arriba. **Próximo:** Bloque B (T2b: login sin email, timeout del anónimo, doc offline).
