# ESTADO — BlackQuack Studio

Fecha de corte: **2026-11-21** (maratón). Rama de trabajo: `demo/semana-1`. Objetivo (CLAUDE.md §8): **demo del MVP** en `demo.blackquack.cl`, local-first, sin exponer datos.

## Landing (postulación BUILD) — `/landing`

Sitio estático independiente de la app (no toca `demo.blackquack.cl`). Estética stop-motion a 12 fps (`steps()`), 8 "cuadros" + pie, `noindex`, Open Graph, accesible (`prefers-reduced-motion`, teclado, contraste).

- **Prod:** https://blackquack-landing.pages.dev · dominio final `build.blackquack.cl` (falta DNS, ver `landing/README.md`).
- **Deploy:** `./scripts/deploy_landing.sh` (proyecto Pages `blackquack-landing`; genera `version.json` desde `pubspec.yaml`).
- **Lighthouse móvil:** rendimiento **99**, accesibilidad **96**.
- **Pendiente del usuario:** DNS de `build.blackquack.cl`; reemplazar imágenes provisorias y `VIDEO_ID` (lista en `landing/README.md`); confirmar `contacto@blackquack.cl`; quitar `noindex` al publicar.

## Versionado (regla, desde v0.1.0)

- **Arreglos → 0.1.x · Funciones nuevas → 0.2.0** (semántico). La versión vive en una sola fuente: `pubspec.yaml` (`version:`); la app la muestra vía `package_info_plus` (`lib/src/core/config/app_info.dart`) en Ajustes y en el overlay `?debug=1`.
- **Cada versión que llega a producción:** sube `pubspec.yaml`, lleva **tag git anotado** (`vX.Y.Z`), una **entrada en `CHANGELOG.md`** y la versión visible en la app.
- La **landing** muestra la misma versión desde `/landing/version.json`, que su script de despliegue genera desde `pubspec.yaml` (nunca a mano).
- `v0.1.0` = prototipo para Start-Up Chile BUILD (equivale a `demo-estable-2` + versión visible).

---

## Ronda de QA en producción (2026-11-21, tags `prod-20261121-9..11`)

QA en `demo.blackquack.cl` (Mac/Chrome) encontró un **P0 de guardado** (y problemas de caché y UX). Correcciones desplegadas:

- **P0 guardado (raíz confirmada por consola):** `_newFrameId` usaba `Random().nextInt(1 << 32)`. En Dart→JS los corrimientos son de 32 bits, así que **`1 << 32 == 0`** y `nextInt(0)` lanzaba `RangeError: max must be in range 0 < max ≤ 2^32, was 0` en **cada `addFrame` del navegador** (pero pasaba en la VM de los tests). Ningún cuadro recibía id → fallaban *guardar*, *versiones* ("Captura algunos cuadros primero" con cuadros en pantalla) y el *borrador* (no se persistía → no salía en "Mis proyectos"). Fix: `lib/src/core/utils/id_gen.dart` genera el id **sin corrimientos** (sorteos de 16 bits con `Random.secure` + timestamp). Además `compressFrameJpeg` ahora **nunca lanza** (blindaje). Tests en navegador (`flutter test --platform chrome`): `id_gen_test` + `save_flow_web_test` (12 en verde en Chrome, 28 en VM) para que no vuelva a pasar los tests. (`prod-9` blindaje + `prod-12` causa raíz)
- **P0 caché:** `index.html` tenía **doble arranque** (`loadEntrypoint` + `flutter_bootstrap`) y `renderer:"html"` obsoleto → se limpió. El deploy reemplaza el **service worker por un kill-switch** (borra cachés y se da de baja) y `_headers` sirve el punto de entrada sin caché: cada carga trae el último build **sin recargar**. (`prod-9`)
- **P1 cámara:** deshacer real (revierte la última acción, incl. recuperar un cuadro borrado); renombrar desde el título; botón **Guardar** claro (antes "Compartir"); **PROYECTAR** visible. (`prod-10`)
- **P1 perfiles (HDU6):** entrada con **clave de imágenes** (avatar+apodo, "Toca tus 3 dibujos en orden"); insignia de número sobre el dibujo + resumen de clave al crear; **"¿Olvidaste tu clave?"** con confirmación de adulto (sin borrar proyectos); **Cambiar perfil** y **Proyectar todo** desde Inicio. (`prod-11`)
- **Verificación visual:** la extensión de Chrome **no estaba conectada** en esta sesión, así que no se recorrieron los ciclos en el navegador; el paso a paso para re-probar está abajo. Correcciones validadas por `flutter analyze` (sin errores), `flutter test` (24 en verde) y `flutter build web`, más `curl` a producción (200, `no-cache`, `noindex`, kill-switch activo).

## Ronda móvil (2026-11-21, tags `prod-20261121-13..15`, `demo-estable-2`)

QA en Samsung (Chrome y Samsung Internet). Las correcciones de web se confirmaron en el teléfono (lo anterior era caché). Ajustes propios del móvil:

- **P0-A cámara trasera** (`prod-13`): la app abre **siempre la trasera** (`pickBackCamera`, `lensDirection.back`; con varias, la principal). Sin trasera (webcam del Mac), usa la disponible sin error. Sin botón de cambio. Test VM de la selección.
- **P0-B orientación** (`prod-14`): al entrar al editor (solo web/teléfono) **pantalla completa + bloqueo de orientación** del proyecto (9:16→vertical, 16:9→horizontal); al salir se liberan. Si el navegador no bloquea o el usuario gira, aparece **"Gira tu teléfono…"** y se **bloquea la captura** (no se guardan cuadros torcidos); al volver, el layout se recompone. En pantallas grandes no se fuerza nada. APIs web aisladas por *conditional import* (no-op en nativo/VM).
- **P1 layout** (`prod-15`): barra superior responsiva (secundarios en menú **⋯**, título con "…"); **opacidad** del papel cebolla movida a Ajustes (deslizador horizontal) en vez del vertical diminuto; hojas (Ajustes/Exportar/Versiones) con **scroll** para no cortarse en horizontal.
- **Caché (Samsung Internet):** kill-switch del service worker + `_headers` sin caché, verificado en producción (`no-cache`, `noindex`, SW kill-switch, un solo bootstrap).
- **Verificación:** `analyze` sin errores, **31 pruebas VM** y **12 en Chrome** (`--platform chrome`), build OK. La extensión de Chrome no está conectada, así que no recorrí viewports de teléfono en DevTools; checklist de teléfono abajo.

### Checklist corta en Android (teléfono) — 8 pasos
Abrir **https://demo.blackquack.cl** en Chrome/Samsung Internet (sin recargar; la caché se limpia sola):
1. Entrar y crear/elegir perfil con su clave.
2. Nuevo proyecto **Vertical**: el teléfono queda en vertical; girar a horizontal → aparece "Gira tu teléfono a vertical" y no deja capturar; volver a vertical → sigue.
3. Repetir con proyecto **Horizontal** (pide horizontal).
4. Confirmar que la cámara es la **trasera** (apunta a la mesa, sin espejo).
5. Capturar 5 cuadros: obturador instantáneo, papel cebolla correcto.
6. Barra superior: el título "Mi Animación" se ve sin superponerse; los secundarios están en **⋯**; Deshacer y **Guardar** visibles.
7. Abrir **Ajustes**, **Exportar** y **Versiones**: las hojas caben/scrollean; mover la **opacidad** en Ajustes.
8. **Guardar** → Mis proyectos con miniatura; exportar **GIF** y **ZIP**; **Proyectar**.

## Estado final del MVP (maratón 2026-11-21)

Todo lo de abajo está **en producción** (`demo.blackquack.cl`), local-first (sin Firebase en la ruta crítica), con tags de reversión `prod-20261121-1..15` (hito estable: `demo-estable-2`). **31 pruebas VM + 12 en Chrome** (`--platform chrome`). `noindex` activo. Prioridad de métricas: **Android** (abrir en Chrome; medir compresión con `?debug=1`).

| HDU | Función | Estado |
|---|---|---|
| HDU1 · Papel cebolla + guardado al instante | Cebolla 1–3 capas + opacidad; compresión al capturar → guardado inmediato; borrador auto-persistido (reabre tras cierre; "atrás" pregunta guardar/descartar) | **Hecho** (🤖 fijar exposición/enfoque/balance = nativo Android, falta) |
| HDU2 · Orientación 9:16 / 16:9 | Elección al crear; recorte fijo en captura, guía de encuadre, GIF/reproductor | **Hecho** |
| HDU3 · Línea de tiempo y FPS | Reordenar (arrastrar), duplicar, borrar con deshacer; FPS 1–30 + atajos 6/8/12/15/24; bucle desde cualquier cuadro | **Hecho** |
| HDU4 · Export GIF/ZIP (/MP4) | GIF y ZIP en web/Android, sin EXIF/ubicación, marca de agua "BlackQuack" | **Parcial** (🤖 MP4 nativo pendiente; sin niveles 720/1080) |
| HDU5 · Versiones por autor | Guardar versión (fecha/autor/nº cuadros), historial restaurar/duplicar, cuadros compartidos | **Hecho** (ejercicios de práctica, falta) |
| HDU6 · Perfiles sin correo (local) | Apodo, avatar, clave de 3 dibujos; **se pide la clave al entrar**; reset de clave con confirmación de adulto (sin borrar proyectos); cambiar perfil desde Inicio; cada perfil ve solo sus proyectos | **Hecho** (demo local) |
| HDU7 · Sala por QR / código | Código de 5 caracteres (base de `wip`); sin QR ni lista de apodos/OA | **Parcial** |
| HDU8 · Kiosco / fijar pantalla | — | **Falta** (🤖 nativo Android) |
| HDU9 · Grupos con roles | Galería de grupo (nube, gateada por `hasCloudAccount`); sin roles/autoría por versión | **Parcial** (fuera de alcance esta semana) |
| HDU10 · Sincronización asíncrona | Local-first listo; cola a Cloudflare no construida | **Parcial** |
| HDU11 · Dashboard docente | — | **Falta** |
| HDU12 · Reporte UTP | — | **Falta** |
| HDU13 · Proyección pantalla completa | Modo proyección sin controles (proyecto o "Mis proyectos" en secuencia) | **Hecho** |
| HDU14 · Continuidad en casa con código | — | **Falta** |

**Pendiente operativo:** configurar **Cloudflare Access** antes de compartir fuera del equipo; investigar tree-shaking de íconos `_rounded` (hoy fuente completa +1,6 MB); **optimizar compresión** (hoy 1,1–1,8 s/cuadro en Mac): la webcam entrega ~1080p y el códec de `image` (dart2js) decodifica/recodifica desde resolución completa → capturar/encodear a 1280 px con el canvas nativo del navegador en vez del paquete `image`.

**Rutina de despliegue (actualizada):** además de `flutter analyze` + `flutter test`, correr `flutter test --platform chrome test/id_gen_test.dart test/save_flow_web_test.dart test/frame_codec_test.dart` — atrapa fallos que solo ocurren en JS (p. ej. corrimientos de 32 bits).

## Checklist para re-probar en Mac y Android — 10 pasos

Abrir **https://demo.blackquack.cl** (Chrome en Mac y en Android; añade `?debug=1` para ver ms/cuadro). **No hace falta recargar**: el deploy limpia la caché. En Mac, da permiso de cámara.

1. "ENTRAR AL TALLER" → **Crear perfil** (apodo, avatar, 3 dibujos: el dibujo se ve con un número de insignia; al final sale el resumen "Tu clave es…"). Entra.
2. **Vuelve a entrar con el perfil**: pide la clave (avatar+apodo, "Toca tus 3 dibujos en orden"). Prueba una clave mal (avisa) y la correcta (entra). Prueba **"¿Olvidaste tu clave?"** (suma de adulto → nueva clave; los proyectos siguen).
3. "Nuevo proyecto" → **Vertical u Horizontal** → la guía de encuadre respeta la orientación. Renombra tocando el **título** (lápiz).
4. Captura **5 cuadros rápido** (obturador instantáneo, papel cebolla). **Deshacer** una vez: quita el último cuadro (no borra de más).
5. Línea de tiempo: **arrastrar** para reordenar, **duplicar**, **borrar con DESHACER**; luego **Deshacer** (↶) arriba recupera el cuadro borrado.
6. Ajustes: atajo de **FPS (12/15/24)**; reproducir → **bucle** desde el cuadro elegido.
7. **Guardar versión** (📑) → **Historial** (🕘) → **restaurar** y **duplicar**.
8. Botón **Guardar** (amarillo) → título+artista → vuelve a Inicio → en "Mis proyectos" aparece **con miniatura**; **recarga la página** → sigue ahí. Sal con "atrás" de un proyecto nuevo → **Guardar borrador** → aparece con insignia **BORRADOR** y al abrirlo vuelve a la cámara.
9. Exportar **GIF** y **ZIP** → se abren con todos los cuadros y marca de agua "BlackQuack" (nunca un archivo vacío).
10. **Proyectar**: en el reproductor (botón **PROYECTAR**) y en "Mi espacio" (**Proyectar todo**). Borra un proyecto → no vuelve al recargar. En **modo avión tras cargar**, crear/guardar/listar/exportar siguen. **Cambiar perfil** desde Inicio → el otro perfil ve solo lo suyo.

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

**HDU2 · Orientación vertical/horizontal**
- ⚠️ Elección por proyecto (9:16 / 16:9): ✅ existe (`_aspect`).
- ✅ Respeto en cámara: **nativo** fuerza el giro con `SystemChrome` (16:9→horizontal, 9:16→vertical, sin depender del autogiro); **PWA** desbloqueada (`manifest.json` orientation `any`); **web** best-effort + aviso "gira el teléfono". Visor a **pantalla completa** con marco de recorte atenuado (vista previa y papel cebolla calzan). *(2026-11-23)*
- ❌ Falta: respeto en timeline y export, 720p/marca de agua.

**HDU3 · Línea de tiempo y FPS**
- ⚠️ Reordenar / duplicar / borrar con deshacer: borrar ✅ y deshacer-última-captura ✅; **reordenar, duplicar y deshacer-borrado faltan** (→ T7).
- ⚠️ FPS 1–30 con atajos 6/8/12/15/24: slider **1–24 sin atajos** (→ T7).
- ⚠️ Bucle desde cualquier cuadro: hay bucle desde 0; **"desde cualquier cuadro" falta** (→ T7).

**HDU4 · Export MP4/GIF/ZIP**
- ⚠️ Exporta sin internet: **GIF ✅** (web+móvil); **ZIP** nativo ✅ pero "en corrección" en web (→ T5); **🤖 MP4** nativo (MediaCodec) pendiente post-demo.
- ❌ 720p con marca de agua (gratis) / 1080p sin marca (pago).
- ⚠️ Sin ubicación ni metadatos: los cuadros se **recodifican a JPEG** (descarta EXIF), pero no está verificado explícitamente para geolocalización.
- ❌ En aula, exportar fuera de la app lo habilita el docente (capa de aula).

**HDU5 · Versiones firmadas por autor**
- ✅ Guardar versión **con nombre**, historial, **restaurar**, **duplicar** y **renombrar**; cuadros compartidos sin duplicar. **"Versión de inicio"** automática (solo el primer cuadro) como punto de partida para el flujo de grupo. *(2026-11-23)*
- ❌ Falta: autoría ligada a perfil (hoy `artistName` libre), origen clase/casa, ejercicios de práctica (→ HDU9).

## Pendientes

- **Promover a producción el Bloque A+** (borrador HDU1 + `?debug`) tras tu prueba en **Android** del preview `t2a-preview` (rama `feat/hdu1-draft`).
- **Configurar Cloudflare Access** (`demo.blackquack.cl` y `blackquack-demo.pages.dev`) **antes de compartir la demo fuera del equipo.**
- **Íconos `_rounded` en blanco** (inicio, cámara, exportar): causados por el tree-shaking de íconos del build web, que dejaba una fuente MaterialIcons de 16 KB sin los glifos de las variantes `_rounded`. **Corregido y publicado** con `--no-tree-shake-icons` en `scripts/deploy_demo.sh` (fuente completa de 1,6 MB; verificado en vivo).
- **Investigar por qué el tree-shaking de íconos excluye las variantes `_rounded`, para volver al build optimizado** (hoy se publica con la fuente completa, +1,6 MB). Mientras tanto, la demo lleva `noindex`/`X-Robots-Tag: noindex` para que no la indexen los buscadores, pero el enlace sigue siendo accesible para quien lo tenga.

## 4. Bitácora

- **2026-11-20** — Reorientación a herramienta de aula. Auditoría git (trabajo ya protegido en `wip`; docs consolidados en `main`), creada `demo/semana-1`. Verificada la tabla de HDU contra el código y corregidas HDU4 y HDU13 en `docs/HISTORIAS_DE_USUARIO.md`. Diagnóstico de exportación, miniaturas y modo invitado con archivo:línea. Plan de la semana aprobado. Creados `docs/decisiones/0001-modo-local-demo.md` y `scripts/deploy_demo.sh` (pendiente T0).
- **2026-11-23** — **Rediseño del editor de cámara + versiones con nombre (HDU2/3/5).** Sesión larga de UX validada en PWA Android. Cambios:
  - **HDU2 · Orientación nativa.** El control estaba todo tras `kIsWeb`: en la APK/PWA nada forzaba ni detectaba el giro y el stub nativo (`screen_lock_stub.dart`) era no-op. Reimplementado con `SystemChrome` para **forzar** la rotación según el aspecto (16:9→horizontal, 9:16→vertical) + immersiveSticky; `_maybeEnterImmersive` corre también en nativo. **PWA:** `web/manifest.json` tenía `orientation: portrait-primary`, que bloqueaba la app instalada en vertical → cambiado a `any`.
  - **HDU2 · Visor a pantalla completa.** El `CameraViewer` ahora llena el visor con la cámara completa y un **atenuado** marca el recorte del proyecto (lo que se captura). Vista previa y papel cebolla comparten el mismo marco para que **calcen** (clave del stop motion). En horizontal ultra-wide queda algún margen por fidelidad del marco (decisión de producto).
  - **HDU3 · Bug de reproducción.** Tras play→stop el visor quedaba **congelado** en web: la reproducción reemplazaba el árbol y desmontaba el `CameraPreview`. Ahora la reproducción es una **capa encima**; el preview no se desmonta. Resuelto.
  - **HDU3 · Controles flotantes + timeline colapsable.** Barra superior → esquinas flotantes (X · ⚙️); las acciones (Guardar, renombrar, deshacer, versiones, exportar) viven en una **hoja del ⚙️** (desplazable, para que no se corte en horizontal). Timeline flota sobre el visor, se expande/contrae con un tirador, contenedor negro ~opaco, thumbnails con la forma del proyecto. Slider vertical visible de opacidad del papel cebolla.
  - **HDU5 · Versiones con nombre.** `saveVersion` pide **nombre**; se crea sola una **"Versión de inicio"** con **solo el primer cuadro** al capturarlo (punto de partida para el flujo de grupo); **renombrar/duplicar** por versión; `copyWith` en el modelo. Al descartar un proyecto se borran también sus versiones (sin huérfanos).
  - **Marca.** Unificado **BlackQuack** en PWA (`manifest.json`), Android (`android:label`), iOS (`CFBundleDisplayName`) y app (`main.dart` title, texto de compartir).
  - Pendiente: prueba en APK física; decidir si se elimina del todo el concepto interno `isDraft` (hoy solo se quitó la palabra "borrador" de la interfaz).
- **2026-11-20/21** — T0 cerrado (demo en producción con interfaz final de `wip` + GIF web + íconos completos). Merge `wip`→`demo/semana-1` con IGNITE tras flag. **Bloque A (T2a) completo y en producción**: repositorio local-first (Hive), compresión al capturar, ciclo personal sin Firebase, banner de almacén efímero, gate `hasCloudAccount`. **En preview pendiente de prueba (Android):** borrador HDU1 (`isDraft`) + `?debug`. Auditoría HDU1–5 arriba. **Próximo:** Bloque B (T2b: login sin email, timeout del anónimo, doc offline).
