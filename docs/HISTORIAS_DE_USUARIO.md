# Historias de usuario de BlackQuack Studio · con estado del prototipo

Fuente: anteproyecto BUILD v8.5 (Anexo A), cruzado con el prototipo v1.0.0 (repo black-cuack). Estado evaluado por Claude a partir del documento de contexto y de capturas de la app; **Claude Code debe verificarlo en el código y corregir esta tabla si algo no coincide.**

Nivel A = imprescindible para el piloto · B = versión simple en BUILD · C = IGNITE (no se construye ahora).

| HDU | Nivel | Estado en el prototipo | Acción |
|---|---|---|---|
| HDU1 · Captura con papel cebolla, sin internet | A | Parcial | Adaptar |
| HDU2 · Captura y exportación vertical u horizontal | B | No existe | Construir (simple) |
| HDU3 · Línea de tiempo y FPS | A | Parcial | Adaptar |
| HDU4 · Exportación MP4, GIF y ZIP | A | Roto en web | Corregir primero |
| HDU5 · Versiones de proyecto, firmadas por autor | A | No existe (hay campo "artista" de texto libre al guardar) | Construir |
| HDU6 · Perfiles de estudiante sin correo | A | Contrario al diseño | Reemplazar |
| HDU7 · Sala por QR o código de 5 dígitos | A | Parcial (concepto) | Adaptar |
| HDU8 · Kiosco ligero de sesión | A | No existe | Construir (Android) |
| HDU9 · Proyectos individuales o de grupo con roles | A | Parcial (concepto) | Adaptar |
| HDU10 · Sincronización asíncrona al guardar o exportar | A | Contrario al diseño | Reemplazar |
| HDU11 · Dashboard de trazabilidad | A | No existe | Construir |
| HDU12 · Reporte para la UTP | B | No existe | Construir (simple) |
| HDU13 · Proyección en pantalla grande | B | Verificar | Verificar |
| HDU14 · Continuidad fuera del aula con código | B | No existe | Construir (simple) |
| HDU15 · Guías de movimiento y timing chart (IGNITE) | C | Parcial | Congelar (IGNITE) |
| HDU16 · Misiones gamificadas con Blacky (IGNITE) | C | No existe | Congelar (IGNITE) |
| HDU17 · Audio y locución (IGNITE) | C | Parcial | Congelar (IGNITE) |
| HDU18 · Borrado manual de soportes (IGNITE) | C | En desarrollo, sin commit | Congelar (IGNITE): guardar en rama |
| HDU19 · Chroma key (IGNITE) | C | No existe | Congelar (IGNITE) |
| HDU20 · Composición en tres pistas (IGNITE) | C | No existe | Congelar (IGNITE) |

**Lectura rápida:** el núcleo de creación (HDU1, 3 y 4) existe y tiene una interfaz de marca muy lograda; hay que corregirlo y completarlo. La capa de aula (HDU6 a 11), que es el valor diferencial del proyecto, está casi toda por construir, y dos piezas actuales (login con email y datos en la nube con URLs públicas) van en contra del diseño y deben reemplazarse.

**Orden de recorte si el ritmo no alcanza:** 1) HDU13 queda solo con duplicar pantalla del sistema; 2) HDU12 se reemplaza por una exportación del dashboard; 3) en HDU14, lo hecho en casa se suma directo al proyecto, sin ramas; 4) HDU2 queda solo en horizontal. El nivel A no se recorta.

## HDU1 · Captura con papel cebolla, sin internet
*Nivel A · Dificultad Media · Depende de: —*

> Como estudiante, quiero fotografiar cada posición viendo la anterior en transparencia, para mover la figura con precisión.

**Estado en el prototipo:** Parcial. Captura y papel cebolla de 1 cuadro con opacidad ajustable. Faltan: 1 a 3 cuadros, fijar exposición, enfoque y balance de blancos, y guardado local inmediato (hoy la fuente de verdad es Firestore). **Acción:** Adaptar.

Criterios de aceptación:
- [ ] Muestra 1 a 3 cuadros anteriores en transparencia, con opacidad ajustable.
- [ ] Fija exposición, enfoque y balance de blancos para que la luz no parpadee entre cuadros.
- [ ] Cada cuadro se guarda al instante en el dispositivo; en modo avión no se pierde ninguno.
- [ ] Si la app se cierra o el equipo se apaga, el proyecto reabre en el último cuadro guardado.

## HDU2 · Captura y exportación vertical u horizontal
*Nivel B · Dificultad Baja · Depende de: HDU1*

> Como estudiante, quiero elegir si mi animación es vertical u horizontal, para crearla pensando en dónde se verá.

**Estado en el prototipo:** No existe. Sin elección de orientación por proyecto. **Acción:** Construir (simple).

Criterios de aceptación:
- [ ] Al crear el proyecto se elige vertical (9:16) u horizontal (16:9); la orientación queda fija.
- [ ] Cámara, papel cebolla y línea de tiempo respetan esa orientación aunque el equipo gire.
- [ ] La exportación conserva la orientación y la relación de aspecto.

## HDU3 · Línea de tiempo y FPS
*Nivel A · Dificultad Baja · Depende de: HDU1*

> Como estudiante, quiero ordenar mis cuadros y elegir la velocidad, para ver mi animación como la imaginé.

**Estado en el prototipo:** Parcial. Línea de tiempo con miniaturas, borrar cuadros, FPS por slider, reproducción y deshacer. Faltan: reordenar, duplicar, atajos de FPS y bucle desde cualquier cuadro (verificar). **Acción:** Adaptar.

Criterios de aceptación:
- [ ] Reordenar, duplicar y borrar cuadros, con deshacer.
- [ ] Velocidad de 1 a 30 FPS, con atajos 6, 8, 12, 15 y 24.
- [ ] Reproducción en bucle desde cualquier cuadro.

## HDU4 · Exportación MP4, GIF y ZIP
*Nivel A · Dificultad Media · Depende de: HDU2, HDU3*

> Como estudiante, quiero exportar mi animación, para mostrarla y compartirla fuera de la app.

**Estado en el prototipo:** Roto en web. GIF, MP4 y ZIP existen, pero el ZIP exportado en web pesa 22 bytes: es un ZIP vacío, sin cuadros. MP4 web depende de FFmpeg.wasm (~30 MB) y MP4 móvil de FFmpegKit, que está descontinuado. Faltan marca de agua y quitar metadatos. **Acción:** Corregir primero.

Criterios de aceptación:
- [ ] Exporta MP4, GIF y ZIP de fotogramas en el dispositivo, sin internet.
- [ ] 720p con marca de agua en el plan gratis; 1080p sin marca en Personal pago y Educativa.
- [ ] Las imágenes exportadas no llevan ubicación ni metadatos de la cámara.
- [ ] En el modo aula, exportar a un destino fuera de la app lo habilita el docente.

## HDU5 · Versiones de proyecto, firmadas por autor
*Nivel A · Dificultad Media · Depende de: HDU3*

> Como estudiante, quiero guardar versiones de mi proyecto, para probar cambios sin perder lo que ya funcionaba.

**Estado en el prototipo:** No existe. Hay guardar y continuar un proyecto, pero no versiones con autor. **Acción:** Construir.

Criterios de aceptación:
- [ ] Guardar una versión con un toque; cada versión registra fecha, autor, número de cuadros y origen (clase o casa).
- [ ] Historial: abrir, restaurar o duplicar una versión como punto de partida de otra.
- [ ] Las versiones comparten los fotogramas que no cambian, para no duplicar espacio.
- [ ] Además de versiones, se pueden guardar ejercicios de práctica asociados al proyecto.

## HDU6 · Perfiles de estudiante sin correo
*Nivel A · Dificultad Media · Depende de: —*

> Como docente, quiero crear perfiles para mis estudiantes sin pedirles correo ni datos personales, para que entren rápido y sin exponer su identidad.

**Estado en el prototipo:** Contrario al diseño. Login con email y contraseña, e invitado anónimo de Firebase. El diseño pide perfiles sin correo: apodo, avatar y clave de imágenes. **Acción:** Reemplazar.

Criterios de aceptación:
- [ ] El docente crea el taller y carga la lista de apodos; si el colegio quiere, asocia cada apodo a su nómina dentro de su espacio.
- [ ] Cada perfil tiene apodo, avatar y una clave de imágenes (tres dibujos en orden) fácil de recordar para un niño de 9 años.
- [ ] El identificador interno es aleatorio y no se deriva de ningún dato personal.
- [ ] En una tablet compartida, al cerrar la sesión el siguiente estudiante no ve el trabajo del anterior.
- [ ] El docente puede restablecer la clave de un estudiante desde su celular.

## HDU7 · Sala por QR o código de 5 dígitos
*Nivel A · Dificultad Media · Depende de: HDU6*

> Como docente, quiero abrir una sala con un QR, para que todo el curso empiece a animar sin configurar cada equipo.

**Estado en el prototipo:** Parcial (concepto). "Mi Charca": grupo con código de 5 caracteres y unión por código. Faltan QR, asignatura, curso y OA, unión sin internet y lista de apodos. **Acción:** Adaptar.

Criterios de aceptación:
- [ ] El docente crea la sala desde su celular, que muestra un QR y un código de 5 dígitos.
- [ ] Elige asignatura, curso y objetivos desde las Bases Curriculares (Artes Visuales y Tecnología en el MVP).
- [ ] La sala define orientación y FPS iniciales.
- [ ] El QR trae los datos de la sala: unirse no requiere internet.
- [ ] La tablet muestra la lista de apodos; cada estudiante entra con su clave de imágenes.

## HDU8 · Kiosco ligero de sesión
*Nivel A · Dificultad Media · Depende de: HDU7*

> Como docente, quiero dejar las tablets del colegio en modo aula segura desde mi celular, para evitar redes y juegos sin reconfigurar los equipos de forma permanente.

**Estado en el prototipo:** No existe. Sin fijación de pantalla. **Acción:** Construir (Android).

Criterios de aceptación:
- [ ] Al entrar a la sala, la app activa la fijación de pantalla de Android y muestra un distintivo visible de lejos.
- [ ] Salir de la sesión desde la app exige la clave del docente.
- [ ] En equipos con PIN de bloqueo, dejar de fijar por el gesto del sistema también exige ese PIN.
- [ ] Cada salida queda registrada con su hora y aparece en el dashboard.
- [ ] No requiere restablecer equipos ni instalar perfiles; con gestor de dispositivos, el colegio puede activar el modo dedicado completo.

## HDU9 · Proyectos individuales o de grupo con roles
*Nivel A · Dificultad Media · Depende de: HDU5, HDU6*

> Como docente, quiero que los estudiantes trabajen solos o en grupo en un mismo proyecto, para adaptar el taller a las tablets disponibles sin perder el registro de cada uno.

**Estado en el prototipo:** Parcial (concepto). Galería compartida de grupo. Falta el proyecto de grupo con integrantes, roles y autoría por versión. **Acción:** Adaptar.

Criterios de aceptación:
- [ ] Al crear un proyecto se elige modo individual o grupal; en grupal se suman integrantes desde la lista.
- [ ] La app sugiere roles (animador, camarógrafo, escenógrafo, sonidista, director); un integrante puede tener varios, rotan entre sesiones y el docente puede crear otros.
- [ ] Los roles no bloquean funciones: ordenan el trabajo y quedan registrados en cada versión.
- [ ] En una sola tablet, cada uno elige quién está capturando antes de empezar.
- [ ] El docente puede mover integrantes o dividir un grupo sin perder la historia del proyecto.

## HDU10 · Sincronización asíncrona al guardar o exportar
*Nivel A · Dificultad Media · Depende de: HDU5, HDU7*

> Como docente, quiero que el avance de cada proyecto llegue a mi panel, para no depender de una conexión estable durante la clase.

**Estado en el prototipo:** Contrario al diseño. Sincronización en tiempo real con Firestore; Storage con URLs públicas de las fotos. El diseño pide local-first con cola de paquetes livianos y vistas previas privadas en Cloudflare. **Acción:** Reemplazar.

Criterios de aceptación:
- [ ] Al guardar una versión o exportar, la app prepara un paquete liviano: metadatos, autor y vista previa de baja resolución.
- [ ] Sin internet, el paquete queda en cola y se envía solo cuando vuelve la conexión.
- [ ] La cola sobrevive a cierres de la app y apagados del equipo.
- [ ] Los datos se guardan en el espacio aislado del colegio (una base de datos por colegio).

## HDU11 · Dashboard de trazabilidad
*Nivel A · Dificultad Media · Depende de: HDU9, HDU10*

> Como docente, quiero ver el avance de cada proyecto y de cada integrante, dentro y fuera del aula, para acompañar a todo el curso y evaluar el proceso.

**Estado en el prototipo:** No existe. La galería no es un dashboard: falta avance por proyecto e integrante, clase/casa, salidas del kiosco y notas. **Acción:** Construir.

Criterios de aceptación:
- [ ] Por proyecto: versiones, fotogramas, ejercicios, exportaciones y vista previa.
- [ ] Por integrante: tiempo de uso, fotogramas, versiones y ejercicios propios, roles y salidas del kiosco.
- [ ] Cada dato distingue lo hecho en clase de lo hecho fuera del aula.
- [ ] Acceso a todo lo capturado, con opción de ocultar o eliminar; esa acción queda registrada.
- [ ] Notas privadas del docente por estudiante o por grupo.

## HDU12 · Reporte para la UTP
*Nivel B · Dificultad Baja · Depende de: HDU11*

> Como jefatura de UTP, quiero un reporte del taller, para hacer seguimiento pedagógico y respaldar el uso autorizado de pantallas.

**Estado en el prototipo:** No existe. — **Acción:** Construir (simple).

Criterios de aceptación:
- [ ] PDF por sesión o por periodo: asignatura y OA, participación, fotogramas, tiempo activo, versiones, exportaciones y salidas del kiosco.
- [ ] Avance por grupo y por integrante, separando clase y fuera del aula.
- [ ] Las notas privadas no se incluyen, salvo que el docente lo elija.
- [ ] Los estudiantes aparecen por apodo o por nómina, si el colegio la carga.

## HDU13 · Proyección en pantalla grande
*Nivel B · Dificultad Baja · Depende de: HDU3*

> Como docente, quiero mostrar en un televisor o proyector lo que se anima, para que todo el curso vea avances y exhibiciones.

**Estado en el prototipo:** Verificar. El historial menciona un "proyector stop-motion"; confirmar si es un modo de proyección a pantalla completa o solo el reproductor. **Acción:** Verificar.

Criterios de aceptación:
- [ ] Modo proyección a pantalla completa, sin botones ni menús.
- [ ] En BUILD usa las vías de Android: cable USB-C a HDMI o duplicar pantalla a un smart TV o Chromecast.
- [ ] La vía por cable exige un equipo con salida de video por USB-C; se verifica al elegirlo.
- [ ] En IGNITE se integra Google Cast.

## HDU14 · Continuidad fuera del aula con código
*Nivel B · Dificultad Media · Depende de: HDU6, HDU9, HDU10*

> Como estudiante, quiero seguir trabajando en casa en mi proyecto o en el de mi grupo, para terminarlo y practicar.

**Estado en el prototipo:** No existe. — **Acción:** Construir (simple).

Criterios de aceptación:
- [ ] El docente entrega a cada estudiante un código personal; puede revocarlo o regenerarlo y vence al cerrar el taller.
- [ ] En la app gratuita, el estudiante ingresa su código y su clave de imágenes, sin cuenta ni correo.
- [ ] Puede crear versiones o ejercicios; cada uno queda firmado y se suma al proyecto.
- [ ] Versión completa (si el ritmo lo permite): el trabajo de cada integrante queda en una rama que el grupo puede incorporar.
- [ ] Lo hecho en casa se sincroniza y el docente lo ve marcado como «fuera del aula».
- [ ] Si el colegio no autoriza el trabajo en casa, los códigos no se emiten.

## HDU15 · Guías de movimiento y timing chart (IGNITE)
*Nivel C · Dificultad Media · Depende de: HDU3*

> Como estudiante, quiero ver guías de arco y espaciado, para planificar movimientos más fluidos.

**Estado en el prototipo:** Parcial. Cuadrícula de tercios activable (base de las guías). **Acción:** Congelar (IGNITE).

Criterios de aceptación:
- [ ] Guías de arco, cuadrícula y trayectoria sobre la cámara.
- [ ] Un timing chart marca los cuadros clave y los intermedios.
- [ ] Las guías no aparecen en la exportación.

## HDU16 · Misiones gamificadas con Blacky (IGNITE)
*Nivel C · Dificultad Media · Depende de: HDU7*

> Como estudiante, quiero misiones cortas guiadas por Blacky, para aprender técnicas paso a paso.

**Estado en el prototipo:** No existe. — **Acción:** Congelar (IGNITE).

Criterios de aceptación:
- [ ] Cada misión enseña una técnica con un objetivo y una entrega.
- [ ] El docente asigna misiones y ve quién las completó.
- [ ] La app no califica el movimiento: la revisión es del docente.
- [ ] En BUILD se prueba un prototipo en papel durante el piloto.

## HDU17 · Audio y locución (IGNITE)
*Nivel C · Dificultad Media · Depende de: HDU4*

> Como estudiante, quiero grabar mi voz o agregar sonidos, para contar mi historia con audio.

**Estado en el prototipo:** Parcial. Pide permiso de micrófono; hay referencias a audio. No priorizar. **Acción:** Congelar (IGNITE).

Criterios de aceptación:
- [ ] Grabar voz o importar audio y ubicarlo en la línea de tiempo.
- [ ] Forma de onda para sincronizar.
- [ ] El audio se incluye en la exportación MP4.

## HDU18 · Borrado manual de soportes (IGNITE)
*Nivel C · Dificultad Media · Depende de: HDU1*

> Como estudiante, quiero borrar los soportes que sostienen mi figura, para que parezca que vuela o salta.

**Estado en el prototipo:** En desarrollo, sin commit. "Borrar soporte" con máscara pintada, desenfoque gaussiano y corrección de color. **Acción:** Congelar (IGNITE): guardar en rama.

Criterios de aceptación:
- [ ] Se captura el set vacío como fondo limpio.
- [ ] Se pinta con el dedo sobre el soporte y la app lo reemplaza por el fondo.
- [ ] El borrado se puede copiar al cuadro siguiente y deshacer.

## HDU19 · Chroma key (IGNITE)
*Nivel C · Dificultad Alta · Depende de: HDU1*

> Como estudiante, quiero reemplazar un fondo verde o azul, para llevar a mi personaje a otros mundos.

**Estado en el prototipo:** No existe. — **Acción:** Congelar (IGNITE).

Criterios de aceptación:
- [ ] Se elige el color con un toque y se ajustan tolerancia y suavizado.
- [ ] Vista previa del recorte en la cámara.
- [ ] El resultado conserva su transparencia para la composición.

## HDU20 · Composición en tres pistas (IGNITE)
*Nivel C · Dificultad Alta · Depende de: HDU4, HDU19*

> Como estudiante, quiero superponer clips con transparencia en capas, para combinar mi animación con fondos y elementos en primer plano.

**Estado en el prototipo:** No existe. — **Acción:** Congelar (IGNITE).

Criterios de aceptación:
- [ ] Tres pistas fijas: fondo, central y primer plano; el límite cuida el rendimiento en gama media.
- [ ] Cada pista acepta cuadros, video o imagen; los clips con chroma key conservan su transparencia.
- [ ] Cada clip se puede mover, escalar, desplazar en el tiempo y cambiar de opacidad.

**Fuera de las HDU, ya existente:** cámara remota (un segundo dispositivo como cámara estable, vinculado por QR). Es una buena idea, pero no está en el alcance de BUILD: congelar en una rama y evaluar en IGNITE.
