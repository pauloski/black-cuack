# BlackQuack Studio

Plataforma para enseñar y experimentar la animación cuadro a cuadro en el aula. Convierte las tablets y celulares del colegio en estaciones de trabajo seguras: sin publicidad, sin salidas a otras apps y sin depender de internet, para que niños y niñas creen solos o en grupo mientras el docente acompaña el proceso de cada uno.

*Crear requiere tiempo. La tecnología debe hacerlo posible.*

## Estado

- **Versión:** 1.0.0 (etiqueta `v1.0.0`), prototipo funcional.
- **Funciona:** captura con papel cebolla, línea de tiempo, velocidad (FPS), reproducción, grupos con código e identidad de marca.
- **En corrección:** exportación en web (GIF, MP4 y ZIP).
- **En curso:** demo para la postulación a Start-Up Chile BUILD y orientación del producto hacia la capa de aula (sala por QR, perfiles sin correo, kiosco y seguimiento docente).

El estado detallado está en [`docs/ESTADO.md`](docs/ESTADO.md) y el avance por historia de usuario en [`docs/HISTORIAS_DE_USUARIO.md`](docs/HISTORIAS_DE_USUARIO.md).

## Stack

- **App:** Flutter (Dart 3.11 o superior), una sola base de código para web, Android e iOS. Android es la plataforma prioritaria del MVP.
- **Backend actual:** Firebase (temporal).
- **Backend objetivo:** arquitectura local-first con Cloudflare (Workers, D1 y R2).

## Cómo ejecutarlo

Requisitos: Flutter instalado y la configuración de Firebase del proyecto.

```bash
flutter pub get
flutter run -d chrome     # web
flutter run -d android    # Android, con un dispositivo o emulador conectado
```

## Estructura

```
lib/
├── main.dart             # Entrada, rutas y tema global
└── src/
    ├── core/             # Persistencia local, tema y utilidades (exportación de video y GIF)
    └── features/
        ├── auth/         # Acceso y servicios de proyectos y grupos
        ├── gallery/      # Inicio, cámara (motor de animación) y galerías
        └── remote/       # Cámara remota (congelada; ver rama wip)
docs/
├── HISTORIAS_DE_USUARIO.md
├── PROMPTS.md
└── archivo/              # Documentos de la dirección anterior
```

## Documentación

- [`CLAUDE.md`](CLAUDE.md): contexto del proyecto, principios de producto, arquitectura objetivo y forma de trabajo. **Es la fuente de verdad del proyecto.**
- [`docs/HISTORIAS_DE_USUARIO.md`](docs/HISTORIAS_DE_USUARIO.md): historias de usuario con criterios de aceptación y estado actual.
- [`docs/PROMPTS.md`](docs/PROMPTS.md): prompts para trabajar con Claude Code.

## Ramas

- `main`: rama principal.
- `wip/borrado-soportes-y-camara-remota`: borrado de soportes y cámara remota, congelados hasta IGNITE.

## Equipo

- **Karen Bravo:** líder del proyecto.
- **Paulo Correa:** líder técnico, diseño UX/UI y estrategia didáctica.

Repositorio privado. © BlackQuack Studio.
