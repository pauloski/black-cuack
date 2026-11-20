# Blackcuack Studio

Aplicación de animación stop-motion colaborativa, diseñada para talleres creativos con niños y adolescentes (9–12 años). Permite capturar secuencias de fotos, previsualizar la animación en tiempo real, exportarla en múltiples formatos y compartirla dentro de grupos de trabajo.

---

## Índice

1. [Descripción general](#1-descripción-general)
2. [Características implementadas](#2-características-implementadas)
3. [Stack técnico](#3-stack-técnico)
4. [Arquitectura del proyecto](#4-arquitectura-del-proyecto)
5. [Modelo de datos en Firestore](#5-modelo-de-datos-en-firestore)
6. [Flujos principales](#6-flujos-principales)
7. [Variables y configuración](#7-variables-y-configuración)
8. [Estado actual y limitaciones conocidas](#8-estado-actual-y-limitaciones-conocidas)

---

## 1. Descripción general

**Blackcuack Studio** es una app Flutter multi-plataforma (web + iOS/Android) pensada para que grupos de estudiantes creen animaciones stop-motion durante talleres. Un facilitador crea un "grupo" (Mi Charca), los estudiantes se unen con un código de 5 caracteres, y pueden compartir sus proyectos dentro del grupo.

El nombre "Quack" es la unidad básica del sistema: cada proyecto de animación es un Quack.

---

## 2. Características implementadas

### Autenticación
- **Registro y login** con email/contraseña (Firebase Auth)
- **Login anónimo** como opción rápida para talleres
- **Recuperación de contraseña** vía email (Firebase Auth)
- Manejo de errores tipado con `AuthException` + mensajes en español

### Motor de animación stop-motion
- **Captura de fotos** con la cámara del dispositivo (`camera` package)
- **Cebolla (onion skin)**: previsualización semi-transparente del frame anterior, opacidad ajustable
- **Línea de tiempo** horizontal con miniaturas de todos los frames capturados
- **Eliminación de frames** individuales desde la línea de tiempo
- **Reproducción en vivo** de la secuencia a la FPS configurada
- **Control de FPS** ajustable (slider)
- **Cuadrícula de composición** (grid overlay) activable/desactivable

### Exportación
| Formato | Web | Mobile |
|---------|-----|--------|
| GIF animado | ✅ (descarga directa) | ✅ (share sheet) |
| Video MP4 | ✅ (FFmpeg.wasm, ~30MB 1ª vez) | ✅ (FFmpegKit nativo) |
| Secuencia de imágenes (ZIP) | ✅ (descarga directa) | ✅ (share sheet) |

- Diálogo previo para elegir el **nombre del archivo** antes de exportar
- Barra de progreso durante la exportación

### Proyectos (Quacks)
- **Guardar proyecto** en Firestore (nubes) + persistencia local como respaldo
- **Cargar proyecto existente** para continuar editando
- **Galería personal** con grid de proyectos (miniatura del último frame)
- **Eliminar proyecto** con confirmación

### Grupos (Mi Charca)
- **Crear grupo** con nombre propio → genera código de 5 caracteres
- **Unirse a un grupo** introduciendo el código
- **Galería del grupo**: proyectos de todos los miembros visibles en tiempo real
- **Galería del taller**: vista general de proyectos publicados en el grupo
- Separación visual entre "Grupos creados por mí" y "Grupos a los que me uní"

### Cámara remota (QR)
- Un dispositivo actúa como **Estudio** (la pantalla donde se anima)
- Otro dispositivo actúa como **Cámara** (envía frames al estudio)
- El estudio genera un **código QR** de 6 caracteres
- La cámara escanea el QR o introduce el código manualmente
- Los frames se sincronizan en **tiempo real** vía Firestore + Firebase Storage
- Los frames remotos aparecen en la línea de tiempo del estudio automáticamente

### UI y navegación
- **Pantalla de inicio (Home)** con sistema de **tabs**:
  - `MIS PROYECTOS`: grid de Quacks + botón "Nuevo Proyecto"
  - `MI CHARCA`: lista de grupos + botones "Crear Grupo" / "Unirse con Código"
- **Perfil** de usuario con opción de cerrar sesión y eliminar cuenta
- Tema oscuro con paleta de colores centralizada (`AppColors`)
- Tipografías personalizadas: LuckiestGuy, Barriecito, Lexend, PlusJakartaSans

---

## 3. Stack técnico

### Lenguaje y framework

| Tecnología | Versión | Rol |
|------------|---------|-----|
| **Dart** | 3.11+ | Lenguaje principal |
| **Flutter** | SDK 3.x | Framework UI multi-plataforma |

### Firebase (Backend as a Service)

| Servicio | Uso |
|----------|-----|
| **Firebase Auth** | Registro, login, anónimo, recuperación de contraseña |
| **Cloud Firestore** | Proyectos, grupos, sesiones remotas, frames en tiempo real |
| **Firebase Storage** | Imágenes de los frames (URLs públicas para compartir) |

### Paquetes principales (pubspec.yaml)

#### Cámara y captura
| Paquete | Versión | Uso |
|---------|---------|-----|
| `camera` | ^0.10.5+5 | Acceso a cámara del dispositivo |

#### Exportación de video
| Paquete | Versión | Uso |
|---------|---------|-----|
| `ffmpeg_kit_flutter` | ^6.0.3 | Codificación MP4 nativa (iOS/Android) |
| `image` | ^4.1.3 | Codificación GIF en Dart puro |
| `archive` | ^3.6.1 | Empaquetado ZIP para secuencias de imágenes |
| `@ffmpeg/ffmpeg` (JS) | 0.11.6 | FFmpeg.wasm para MP4 en web (CDN, lazy load) |
| `@ffmpeg/core` (JS) | 0.11.0 | Core WASM de FFmpeg (~30MB, cacheado por el browser) |

#### Firebase
| Paquete | Versión | Uso |
|---------|---------|-----|
| `firebase_core` | ^3.1.1 | Inicialización de Firebase |
| `firebase_auth` | ^5.1.1 | Autenticación |
| `cloud_firestore` | ^5.6.12 | Base de datos en tiempo real |
| `firebase_storage` | ^12.4.10 | Almacenamiento de imágenes |

#### Cámara remota / QR
| Paquete | Versión | Uso |
|---------|---------|-----|
| `qr_flutter` | ^4.1.0 | Generación de códigos QR |
| `mobile_scanner` | ^6.0.0 | Escaneo de QR con la cámara |

#### Utilidades
| Paquete | Versión | Uso |
|---------|---------|-----|
| `path_provider` | ^2.1.2 | Directorios temporales en móvil |
| `shared_preferences` | ^2.2.2 | Persistencia local ligera |
| `http` | ^0.13.6 | Descarga de imágenes por URL (frames remotos) |
| `share_plus` | ^12.0.1 | Share sheet nativo en móvil |
| `url_launcher` | ^6.3.2 | Apertura de URLs externas |
| `universal_html` | ^2.2.4 | Blob downloads en web (GIF, MP4, ZIP) |
| `lottie` | ^3.0.0 | Animación splash en móvil |

#### Interoperabilidad web
| API | Uso |
|-----|-----|
| `dart:js_interop` | Bindings Dart → JavaScript (bridge FFmpeg.wasm) |
| `dart:io` | File system en móvil (guardado temporal de archivos) |

---

## 4. Arquitectura del proyecto

```
lib/
├── main.dart                          # Entry point, rutas, tema global
├── firebase_options.dart              # Config Firebase por plataforma
└── src/
    ├── core/
    │   ├── persistence/
    │   │   └── project_storage.dart   # Persistencia local (SharedPreferences)
    │   ├── theme/
    │   │   └── blackcuack_widgets.dart  # AppColors + QuackButton
    │   └── utils/
    │       ├── video_creator.dart     # Exportación GIF/MP4/ZIP
    │       ├── ffmpeg_web.dart        # Bindings JS para FFmpeg.wasm (solo web)
    │       ├── ffmpeg_web_stub.dart   # Stub vacío para compilación móvil
    │       ├── quack_save_helper.dart # Helper de guardado con feedback
    │       └── group_utils.dart       # Utilidades de grupos
    └── features/
        ├── auth/
        │   ├── data/
        │   │   ├── auth_service.dart    # Login/signup/anónimo + AuthException
        │   │   ├── group_service.dart   # CRUD de grupos en Firestore
        │   │   └── project_service.dart # CRUD de proyectos en Firestore
        │   └── presentation/
        │       ├── splash_page.dart     # Pantalla de carga inicial
        │       └── login_page.dart      # Login / registro / recuperar contraseña
        ├── gallery/
        │   ├── domain/
        │   │   └── project_model.dart   # Modelo QuackProject
        │   └── presentation/
        │       ├── home_page.dart        # Tabs: MIS PROYECTOS + MI CHARCA
        │       ├── camera_page.dart      # Motor stop-motion principal
        │       ├── workshop_gallery_page.dart
        │       ├── pages/
        │       │   ├── profile_page.dart
        │       │   ├── my_groups_page.dart
        │       │   ├── group_details_page.dart
        │       │   ├── group_gallery_page.dart
        │       │   └── movie_player_page.dart
        │       └── widgets/
        │           ├── camera_viewer.dart      # Vista de cámara + onion skin
        │           ├── camera_controls.dart    # Controles (captura, play, FPS...)
        │           ├── camera_timeline.dart    # Línea de tiempo de frames
        │           ├── project_grid_view.dart  # Grid de proyectos
        │           └── group_management_sheet.dart
        └── remote/
            ├── data/
            │   └── remote_session_service.dart  # Sesiones remotas en Firestore
            └── presentation/
                ├── join_session_page.dart        # Escanear QR / ingresar código
                ├── remote_camera_page.dart       # Vista cámara remota
                └── widgets/
                    └── qr_invite_dialog.dart     # Dialog QR del estudio
```

### Convenciones

- **Feature-first**: el código se organiza por funcionalidad, no por tipo de archivo.
- **Stateless cuando es posible**: los widgets sin estado propio son `StatelessWidget`.
- **Servicios de datos** (`*_service.dart`): acceden a Firebase, devuelven Futures/Streams.
- **AppColors**: todos los colores pasan por la clase centralizada en `blackcuack_widgets.dart`.
- **Importaciones condicionales** (`dart.library.js_interop`): permiten código diferente por plataforma sin romper la compilación.

---

## 5. Modelo de datos en Firestore

### Colección `users/{uid}/projects/{projectId}`
```
{
  id: string,
  name: string,
  artistName: string,
  photoPaths: string[],      // URLs de Firebase Storage
  date: ISO8601 string,
  isPublished: bool,
  workshopCode: string | null,
  userId: string
}
```

### Colección `groups/{groupId}`
```
{
  name: string,
  code: string,              // 5 caracteres, ej: "BQC2X"
  ownerId: string,           // uid del creador
  members: string[],         // uids de miembros
  createdAt: Timestamp
}
```

### Colección `sessions/{code}`
```
{
  studioUserId: string,
  createdAt: Timestamp,
  isActive: bool
}
```

### Subcolección `sessions/{code}/frames/{frameId}`
```
{
  url: string,               // URL de Firebase Storage
  index: number,
  uploadedAt: Timestamp
}
```

---

## 6. Flujos principales

### Crear una animación
1. Login → Home → tap "+ NUEVO PROYECTO"
2. `CameraPage` se abre con cámara inicializada
3. El usuario captura frames → aparecen en la línea de tiempo
4. Puede reproducir la secuencia en vivo
5. Al guardar → `quack_save_helper.dart` sube a Firestore + Storage
6. Al exportar → `video_creator.dart` genera GIF, MP4 o ZIP

### Sesión de cámara remota
1. Estudio: Home → ícono WiFi → "SOY EL ESTUDIO" → `CameraPage` con `startRemoteSession: true`
2. Estudio: se crea sesión en Firestore (`sessions/{code}`) → se muestra QR
3. Cámara: Home → ícono WiFi → "SOY LA CÁMARA" → `JoinSessionPage`
4. Cámara escanea QR o escribe código → verifica sesión activa → `RemoteCameraPage`
5. Cámara captura frame → sube a Storage → escribe URL en `sessions/{code}/frames`
6. Estudio escucha stream de frames → agrega a `capturedPhotos` en tiempo real

### Exportación MP4 en web
1. `VideoCreator.exportAs(mp4, paths, fps)` detecta `kIsWeb: true`
2. Descarga los bytes de cada frame (URLs de Firebase Storage)
3. Llama `WebFFmpeg.framesToMp4()` → carga FFmpeg.wasm desde CDN (primera vez ~30MB)
4. Escribe frames en el filesystem virtual de WASM
5. Ejecuta `ffmpeg -framerate N -i frame_%03d.jpg -c:v libx264 -pix_fmt yuv420p output.mp4`
6. Lee el MP4 resultante → dispara descarga en el browser vía Blob URL

---

## 7. Variables y configuración

### Fuentes (assets/fonts/)
- `LuckiestGuy-Regular.ttf` — títulos y CTAs
- `Barriecito-Regular.ttf` — saludos y texto decorativo
- `Lexend-VariableFont_wght.ttf` — cuerpo de texto
- `PlusJakartaSans-VariableFont_wght.ttf` — textos secundarios

### Paleta de colores (`AppColors`)
| Constante | Hex | Uso |
|-----------|-----|-----|
| `background` | `#0E0E0E` | Fondo principal |
| `surface` | `#1A1A1A` | Cards, modales |
| `primary` | `#C1FFFE` | Cyan — CTAs, tabs activos, títulos |
| `secondary` | `#BC87FE` | Violeta — grupos, acentos |
| `tertiary` | `#F3FFCA` | Verde lima — cámara remota |
| `danger` | `#FF4D4D` | Rojo — errores, eliminar |

### Plataformas soportadas
| Plataforma | Estado |
|------------|--------|
| Web (Chrome/Edge) | ✅ Funcional |
| iOS | ✅ Soportado (requiere Xcode) |
| Android | ✅ Soportado |
| macOS nativo | No configurado |

---

## 8. Estado actual y limitaciones conocidas

### Funciona bien
- Flujo completo: login → crear animación → exportar → compartir
- Grupos y galería colaborativa en tiempo real
- Cámara remota vía QR
- Exportación GIF y ZIP en web y móvil
- Exportación MP4 en móvil (FFmpegKit)
- Exportación MP4 en web (FFmpeg.wasm, lazy-loaded)

### Limitaciones conocidas
| Limitación | Detalle |
|------------|---------|
| MP4 web — primera carga | FFmpeg.wasm descarga ~30MB la primera vez; queda cacheado en el browser |
| Cámara en web | `flutter_camera` en web usa Blob URLs; si el usuario toma fotos directamente en la sesión web (sin sesión remota), los frames se exportan bien a GIF/ZIP pero el MP4 puede fallar si el browser no puede resolver los Blob URLs vía XHR |
| Sin modo offline real | El guardado local (SharedPreferences) es un respaldo de emergencia; la fuente de verdad es Firestore |
| `ffmpeg_kit_flutter` deprecado | El paquete fue descontinuado; en el largo plazo habrá que migrar MP4 móvil a otra solución |
| Splash en web | Se omite la animación Lottie en web para evitar dependencia del CDN; muestra logo de texto simple |
