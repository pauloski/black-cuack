# BlackQuack Studio · Contexto del proyecto para Claude Code

Lee este archivo completo al iniciar cada sesión. Las historias de usuario, con el estado actual del prototipo, están en `docs/HISTORIAS_DE_USUARIO.md`. El estado del trabajo está en `docs/ESTADO.md` (créalo si no existe).

## 1. Qué es BlackQuack Studio

Una plataforma digital orientada a facilitar la enseñanza y experimentación de la animación cuadro a cuadro en contextos educativos, promoviendo el pensamiento creativo, la expresión artística y el uso significativo de la tecnología en el aula.

Para lograrlo, convierte las tablets y celulares **del colegio** en estaciones de trabajo seguras: sin publicidad, sin salidas a otras apps y sin depender de internet. Niños y niñas crean solos o en grupo mientras el docente acompaña el proceso de cada uno.

Lema: *Crear requiere tiempo. La tecnología debe hacerlo posible.*

**Nuestro valor no es el editor de animación** (Stop Motion Studio ya es un buen editor). Es la **capa de aula**: sala por QR, tablets fijadas, perfiles sin correo, proyectos de grupo con autoría, trabajo sin conexión y seguimiento para el docente. Todo lo que construyas debe acercar el producto a eso.

## 2. Contexto

- Se postula a **Start-Up Chile BUILD** (Corfo): 4 meses para construir el MVP y validarlo en un curso real.
- Equipo: **Karen Bravo** (líder del proyecto, negocio) y **Paulo Correa** (líder técnico, UX/UI y estrategia didáctica). Paulo trabaja contigo; no hay otro desarrollador.
- Paulo decide la arquitectura, la seguridad y qué entra al producto. Tú propones e implementas.
- Contexto legal chileno: la Ley 21.801 saca los celulares personales de la sala (el uso pedagógico pasa a los equipos del colegio); la Ley 21.719 protege los datos personales (menores de 14 años requieren consentimiento de padres, gestionado por el colegio).

## 3. Usuarios

| Usuario | Qué necesita |
|---|---|
| Estudiante, flujo niños (3.° a 6.° básico, 8 a 12 años) | Crear con las manos y capturar cuadro a cuadro, solo o en grupo, sin correo |
| Docente | Abrir una sala con un QR, dejar las tablets fijas en la app, ver el avance de cada proyecto e integrante |
| Jefatura de UTP | Un reporte del taller con asignatura, OA y participación |
| Familia | Que el estudiante siga en casa con su código, sin publicidad |

El **flujo jóvenes** (7.° básico a 4.° medio) es la fase 2: no se construye ahora, pero no tomes decisiones que lo impidan.

## 4. Principios de producto (no negociables)

1. **Sin IA generativa en la creación.** La app nunca dibuja, anima, completa ni corrige el movimiento. Captura, ordena y reproduce lo que unas manos construyeron.
2. **Sin publicidad, sin enlaces externos, sin compras dentro de la app, sin rastreo.**
3. **Las manos primero:** la app no interrumpe mientras el grupo construye.
4. **El error se conversa, no se corrige solo.**
5. **Mínimos datos:** apodo y avatar; nunca nombre real, correo ni teléfono de estudiantes. **Las fotos originales no salen del dispositivo** y nunca se publican con URL pública.
6. **Trabajo sin conexión siempre:** ninguna acción de creación depende de internet.

## 5. El prototipo actual (punto de partida)

Repositorio `black-cuack`, versión 1.0.0, **Flutter (Dart 3.11+)** para web, iOS y Android, arquitectura feature-first con servicios `*_service.dart`. El stack de la app se mantiene: Flutter es el que declara el anteproyecto.

**Qué se conserva y se mejora:**
- La identidad visual: paleta `AppColors`, tipografías, splash con Blacky, pantalla de inicio. Está muy lograda; no la rediseñes.
- El motor de captura: cámara, papel cebolla, línea de tiempo, FPS, reproducción, cuadrícula, deshacer.
- La exportación (GIF, MP4, ZIP), **una vez corregida**.
- El concepto de grupo con código de 5 caracteres ("Mis grupos": crear, unirse, rol admin), como base de la sala (HDU7). El rol admin es la semilla del rol docente.
- El diálogo "Guardar animación" con título y artista: el campo artista es la semilla de la autoría por versión (HDU5 y HDU9), aunque hoy es texto libre y no está ligado a un perfil.

**Qué está roto:**
- **Exportación en web:** el ZIP descargado pesa 22 bytes, que es exactamente un ZIP vacío. Los cuadros no llegan al exportador.
- **Miniaturas vacías en "Mis proyectos":** los proyectos guardados aparecen como tarjetas negras, sin imagen.
- **Proyectos que desaparecen (por confirmar):** en una sesión "Mis proyectos" aparece vacío y en otra con proyectos. Hipótesis: el modo invitado crea un usuario anónimo nuevo en cada sesión y los proyectos quedan ligados al anterior.
- **Hipótesis común para los dos primeros:** los cuadros se guardan como referencias (URLs blob, que mueren al recargar la página, o URLs de Storage que fallan por CORS en web) en vez de como datos. Si se confirma, guardar los cuadros como datos locales corrige exportación y miniaturas a la vez. Es la primera corrección.

**Qué va en contra del diseño y se reemplaza (por etapas, no de golpe):**
- Login con email y contraseña → perfiles sin correo (apodo, avatar, clave de imágenes). Para la demo: entrar sin email.
- Firestore como fuente de verdad y fotos en Firebase Storage con **URLs públicas** → local-first: cuadros y proyectos en el dispositivo; a la nube solo paquetes livianos.
- Firebase como backend → **Cloudflare** (Workers, D1 una por colegio, R2 con acceso firmado). La migración del backend **no es de esta semana**.
- FFmpegKit (descontinuado) para MP4 en móvil → codificación nativa (MediaCodec) en Android. No es de esta semana.

**Qué se congela (no se sigue desarrollando ahora):**
- Borrado de soportes (HDU18) y cámara remota: son de IGNITE. El trabajo sin commit se guarda en una rama propia, sin mezclar con `main`.

**Vocabulario:** en la interfaz se puede mantener la voz de marca ("Quack" para un proyecto), pero el concepto de aula se llama **sala** o **taller**, no "charca", en la documentación y el código nuevo. Unifica el nombre de la marca como **BlackQuack** (no "Blackcuack").

## 6. Arquitectura objetivo del MVP

- **App:** Flutter, Android primero (tablets y celulares); web se mantiene para demos.
- **Local-first:** base local en el dispositivo (proyectos, cuadros, versiones). Al guardar una versión o exportar se arma un **paquete liviano** (metadatos, autor, vista previa de baja resolución) que entra a una **cola persistente** y se envía cuando hay red.
- **Backend: Cloudflare.** Workers (API y emisión de tokens), D1 (SQL, una base por colegio), R2 (vistas previas con acceso firmado). Datos fuera de Chile: por eso solo suben apodos, metadatos y vistas previas.
- **Identidad sin correo:** apodo, avatar y clave de imágenes (3 dibujos en orden de un set de 12); identificadores aleatorios; tokens firmados de corta duración por colegio, taller y estudiante; permisos verificados en el backend.
- **Kiosco ligero:** fijación de pantalla de Android al entrar a la sala; salir exige clave docente; cada salida se registra.
- **Modelo central ("grafo del proceso creativo"):** colegio → taller → proyecto → versión → cuadro, con autor, rol y lugar (clase o casa).
- **Diseña la capa de datos detrás de interfaces** (repositorios) para cambiar Firebase por almacenamiento local y luego por Cloudflare sin tocar las pantallas.

## 7. Alcance

- **Nivel A:** HDU1, 3, 4, 5, 6, 7, 8, 9, 10, 11. **Nivel B:** HDU2, 12, 13, 14. **Nivel C (IGNITE):** HDU15 a 20.
- Detalle, criterios y estado actual: `docs/HISTORIAS_DE_USUARIO.md`.

## 8. Objetivo de ESTA SEMANA: demo disponible

No es el MVP: es una **demo estable y presentable** del núcleo de creación, que no exponga datos y que muestre hacia dónde va el aula.

**Debe funcionar (en orden):**
1. **Exportación corregida:** GIF y ZIP con todos los cuadros, en web y Android, con una prueba automatizada que verifique el número de cuadros. MP4 en web si es estable; si no, GIF como formato principal de la demo.
2. **Modo local para la demo:** proyectos y cuadros guardados en el dispositivo (en web, IndexedDB o equivalente), sin depender de Firebase para crear, guardar ni exportar. Entrar sin email (el modo invitado como entrada principal; ocultar o dejar en segundo plano el login con email).
3. **Línea de tiempo completa (HDU3):** reordenar, duplicar, borrar con deshacer, atajos de FPS y reproducción en bucle.
4. **Papel cebolla de 1 a 3 cuadros (HDU1).**
5. **Versiones simples (HDU5):** guardar, ver historial y restaurar.

**Si alcanza:**
6. **Sala simulada en local (HDU6 y 7 en modo demostración):** el docente "abre una sala" y muestra un QR; en la tablet aparece la lista de apodos y se entra con la clave de imágenes. Sin backend.
7. **Fijación de pantalla al entrar a la sala (HDU8)**, solo en Android.

**Qué significa "disponible":**
- Build web publicado en **Cloudflare Pages** bajo un subdominio de blackquack.cl, protegido con **Cloudflare Access**.
- APK de Android de prueba, si el tiempo alcanza.
- `docs/DEMO.md` con cómo abrir la demo y un guion de 90 segundos para el video.

**Fuera de esta semana:** migración a Cloudflare, sincronización, dashboard docente, reportes, flujo jóvenes, borrado de soportes y cámara remota.

## 9. Forma de trabajo

- **Primero protege el trabajo:** antes de cambiar nada, guarda el trabajo sin commit en una rama (`wip/borrado-soportes-y-camara-remota`) y crea una rama de trabajo para la demo (`demo/semana-1`) desde `main`.
- **Pregunta antes de** agregar dependencias, borrar módulos o cambiar la estructura.
- **Tareas pequeñas** (medio día como máximo), cada una ligada a una HDU y a sus criterios.
- **Pruebas:** todo criterio automatizable tiene su prueba. Para la exportación, una prueba que genere N cuadros y verifique que el archivo tiene N cuadros.
- **Verifica en la app real**, no solo en el código: ejecuta, exporta y abre el archivo.
- **Commits pequeños** en español con la HDU, por ejemplo `HDU4: el ZIP incluye todos los cuadros`.
- **Decisiones técnicas** en `docs/decisiones/` (qué, por qué, alternativas).
- **Al terminar cada bloque, actualiza `docs/ESTADO.md`.**
- **Datos:** solo datos de prueba inventados, nunca fotos de estudiantes. Mientras siga activo Firebase, no subas fotos con URL pública en la demo.
- **Idioma:** interfaz y documentación en español de Chile; el código puede ir en inglés.

## 10. Definición de terminado

Una HDU (o la parte acordada para la demo) está terminada cuando cumple sus criterios (o los acordados en `docs/ESTADO.md`), funciona sin internet si corresponde, tiene pruebas o una verificación manual escrita y está registrada en `docs/ESTADO.md`.
