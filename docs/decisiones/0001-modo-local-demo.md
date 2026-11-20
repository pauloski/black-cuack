# 0001 — Modo local para la demo: cuadros como bytes detrás de un repositorio

- **Fecha:** 2026-11-20
- **Estado:** Aceptada
- **Contexto:** Semana 1 (demo). CLAUDE.md §6 (arquitectura objetivo) y §8 (objetivo de la semana).

## Contexto y problema

El prototipo guarda los cuadros como **referencias** (`List<String> photoPaths`): en web son URLs `blob:` (mueren al recargar) o URLs de Firebase Storage al recargar un proyecto. Esa única decisión rompe tres cosas a la vez:

1. **Exportación** (ZIP/GIF/MP4): el exportador no obtiene bytes reales (en web el `blob:` no se lee con `dart:io`; en Storage falla por CORS), y en la rama `wip` eso produce un ZIP vacío de 22 bytes.
2. **Miniaturas**: bajo CanvasKit, `NetworkImage` no puede dibujar las URLs de Storage sin CORS → tarjetas negras.
3. **Offline / persistencia**: la fuente de verdad es Firestore + Storage; crear/guardar/exportar depende de la nube, en contra de CLAUDE.md §4.6.

Además, la identidad depende del uid anónimo de Firebase, que se pierde en varios escenarios y "desaparece" proyectos.

## Decisión

Para la demo, **guardar los cuadros como datos (bytes) en un almacén local del dispositivo**, detrás de una **interfaz de repositorio** (`ProjectRepository` / `FrameRepository`), con **Hive CE** como implementación (IndexedDB en web, archivos en nativo). Los cuadros se **comprimen a JPEG con lado mayor máximo 1280 px** antes de guardarse (paquete `image`, ya presente). La exportación consume bytes del repositorio; las miniaturas se pintan con `Image.memory`. Crear, guardar y exportar **no dependen de internet ni de Firebase**.

Firebase se mantiene en el código pero **fuera de la ruta crítica** de la demo (no se borra esta semana).

## Por qué

- Una sola corrección arregla exportación, miniaturas y offline, y elimina la dependencia del uid de Firebase.
- La interfaz de repositorio permite cambiar el backend (Firebase → local → **Cloudflare**: Workers + D1 + R2 con acceso firmado) sin tocar las pantallas, como pide CLAUDE.md §6.
- Alineado con local-first y "las fotos originales no salen del dispositivo" (CLAUDE.md §4.5–4.6).

## Alternativas descartadas

- **Seguir con Storage + configurar CORS**: arregla miniaturas pero no el offline ni la privacidad; mantiene URLs públicas en contra del diseño.
- **Base64 de cuadros en `shared_preferences`**: sin dependencia nueva, pero `localStorage` web (~5 MB) se llena con pocas fotos; inviable para animaciones reales.
- **sembast/sqlite (drift)**: válidos; Hive CE se eligió por API más simple para el patrón de repositorio y por soportar web + nativo con poca configuración.

## Consecuencias

- Dependencias nuevas aprobadas: `hive_ce`, `hive_ce_flutter`, `archive` (`qr_flutter` solo si se construye la sala simulada).
- El exportador se refactoriza para recibir bytes; se agrega la prueba de exportación (N cuadros → N en GIF/ZIP; 0 cuadros → error sin archivo).
- La sincronización a la nube (paquetes livianos a Cloudflare) queda fuera de esta semana.
