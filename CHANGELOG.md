# Changelog

Todos los cambios notables de **BlackQuack Studio**.
Formato basado en [Keep a Changelog](https://keepachangelog.com/es-ES/1.1.0/);
versionado semántico: **arreglos → 0.1.x**, **funciones nuevas → 0.2.0**.

## [0.1.0] - 2026-11-22

Prototipo para la postulación a **Start-Up Chile BUILD**. Demo local-first en
`demo.blackquack.cl` (sin datos expuestos, `noindex`).

### Agregado
- **HDU1 · Captura con papel cebolla, sin internet.** Cámara cuadro a cuadro con
  papel cebolla de 1 a 3 capas y opacidad ajustable; cada cuadro se guarda al
  instante en el dispositivo; borrador automático que reabre tras un cierre.
- **HDU2 · Orientación del proyecto.** Elección vertical (9:16) u horizontal
  (16:9) al crear; recorte fijo en la captura y guía de encuadre.
- **HDU3 · Línea de tiempo y velocidad.** Reordenar (arrastrar), duplicar y borrar
  con deshacer; velocidad de 1 a 30 cuadros por segundo con atajos; reproducción
  en bucle desde cualquier cuadro.
- **HDU4 · Exportación GIF y ZIP.** En web y Android, sin metadatos de ubicación y
  con marca de agua "BlackQuack".
- **HDU5 · Versiones.** Guardar versiones (fecha, autor, nº de cuadros), ver el
  historial y restaurar o duplicar, compartiendo cuadros sin duplicar el archivo.
- **HDU6 · Perfiles sin correo.** Apodo, avatar y clave de 3 dibujos; se pide la
  clave al entrar; recuperación de clave con confirmación de adulto; cada perfil
  ve solo sus proyectos.
- **HDU13 · Modo proyección.** Reproducción a pantalla completa sin controles (un
  proyecto o "Mis proyectos" en secuencia).
- **Móvil.** La app usa siempre la cámara trasera (apunta a la mesa); pantalla
  completa y bloqueo de orientación según el proyecto, con aviso "gira tu
  teléfono" si no coincide; barra superior y paneles adaptados a pantallas
  angostas.

### Conocido / pendiente
- **MP4**: la exportación a video queda pendiente (ffmpeg-kit fue retirado; se
  evaluarán opciones).
- **APK nativa de Android**: cámara nativa, orientación bloqueada por el sistema y
  MP4 van en una tarea aparte.
- **Capa de aula y nube (BUILD)**: salas por QR, kiosco de aula segura, proyectos
  de grupo con roles, panel docente, reporte para la UTP, continuidad en casa con
  código y publicación en Google Play.

[0.1.0]: https://github.com/pauloski/black-cuack/releases/tag/v0.1.0
