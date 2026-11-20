# ESTADO — BlackQuack Studio

Fecha de corte: **2026-11-20**. Rama de trabajo: `demo/semana-1`. Objetivo de la semana (CLAUDE.md §8): **demo estable y presentable** del núcleo de creación, local-first, sin exponer datos.

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

## 4. Bitácora

- **2026-11-20** — Reorientación a herramienta de aula. Auditoría git (trabajo ya protegido en `wip`; docs consolidados en `main`), creada `demo/semana-1`. Verificada la tabla de HDU contra el código y corregidas HDU4 y HDU13 en `docs/HISTORIAS_DE_USUARIO.md`. Diagnóstico de exportación, miniaturas y modo invitado con archivo:línea. Plan de la semana aprobado. Creados `docs/decisiones/0001-modo-local-demo.md` y `scripts/deploy_demo.sh` (pendiente T0).
