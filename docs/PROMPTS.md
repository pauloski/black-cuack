# Prompts para Claude Code · BlackQuack Studio (versión calibrada al prototipo)

Antes de usarlos, en la raíz del repositorio `black-cuack`:
- Reemplaza o crea `CLAUDE.md` con el de esta carpeta.
- Copia `docs/HISTORIAS_DE_USUARIO.md`.

---

## Prompt 1 · Recalibración y plan de la semana

Pégalo al iniciar la sesión.

```
Hola. Actualicé CLAUDE.md y docs/HISTORIAS_DE_USUARIO.md con la dirección real del proyecto BlackQuack Studio. Hasta ahora el prototipo creció como una app de animación colaborativa; a partir de hoy lo orientamos a una herramienta de aula para colegios. Léelos completos antes de hacer nada.

Luego, en este orden:

1. Protege el trabajo actual:
   - Guarda el trabajo sin commit (borrado de soportes, cámara remota, ajustes de exportación web) en una rama llamada wip/borrado-soportes-y-camara-remota y haz commit ahí.
   - Vuelve a main, crea la etiqueta v1.0.0 si no existe y crea la rama demo/semana-1.
   - Confírmame qué quedó en cada rama.

2. Verifica la tabla de estado de docs/HISTORIAS_DE_USUARIO.md contra el código real:
   - Para cada HDU de nivel A y B, confirma o corrige el estado y la acción, indicando el archivo donde lo comprobaste.
   - Revisa en especial HDU13: ¿el "proyector" es un modo de proyección a pantalla completa o solo el reproductor?
   - Actualiza la tabla en el archivo con tus correcciones.

3. Diagnostica el bug de exportación antes de corregirlo:
   - En web, el ZIP exportado pesa 22 bytes: es un ZIP vacío. Encuentra por qué los cuadros no llegan al exportador (¿URLs blob, URLs de Storage, lectura asíncrona sin esperar, errores silenciados?).
   - Revisa si el mismo problema afecta al GIF y al MP4, y si ocurre también en Android.
   - Revisa también por qué las miniaturas de "Mis proyectos" aparecen vacías (tarjetas negras). Sospecho la misma causa: cuadros guardados como URLs blob o de Storage en vez de como datos.
   - Verifica si en modo invitado cada sesión crea un usuario anónimo nuevo y por eso los proyectos guardados "desaparecen" al volver a entrar.
   - Explícame cada causa con el archivo y la línea, y propón las correcciones. No las apliques todavía.

4. Propón el plan de la semana según la sección 8 de CLAUDE.md:
   - Tareas de medio día como máximo, en orden, cada una con su HDU, los criterios que cumple y cómo se verifica.
   - Cómo dejar los proyectos y cuadros en el dispositivo para la demo sin depender de Firebase, detrás de una interfaz de repositorio que luego nos permita pasar a Cloudflare.
   - Qué entra seguro, qué entra si alcanza y qué queda fuera.
   - Cómo publicar el build web en Cloudflare Pages protegido con Cloudflare Access, paso a paso.

5. Escribe la auditoría, el diagnóstico y el plan en docs/ESTADO.md, y una nota en docs/decisiones/ sobre el modo local de la demo.

6. Espera mi aprobación antes de modificar código. Si necesitas decisiones mías, déjalas al final, numeradas y con tu recomendación.
```

---

## Prompt 2 · Estado del proyecto

Úsalo al final de cada día o antes de una reunión.

```
Dame el estado del proyecto. Antes de responder, revisa el código, ejecuta las pruebas, ejecuta la app y mira los commits desde el último estado en docs/ESTADO.md. No respondas de memoria.

Formato:

1. Resumen en 3 líneas: dónde estamos frente a la demo de la semana y si llegamos a tiempo.

2. Tabla de historias de usuario (nivel A, B y las que estén en la demo):
   HDU | Estado (no iniciada / en curso / hecha / bloqueada) | Criterios cumplidos / total | Evidencia (prueba, archivo o verificación manual)

3. Exportación: resultado de exportar un proyecto de prueba de 12 cuadros en GIF, ZIP y MP4, en web y en Android si aplica. Para cada archivo, su tamaño y si se abre correctamente.

4. Qué se hizo desde el último estado, con los commits relevantes.

5. Demo: qué se puede mostrar hoy, la URL o el APK, y qué falla todavía.

6. Pruebas: cuántas hay, cuántas pasan y qué no está cubierto.

7. Deuda contra el diseño: qué sigue dependiendo de Firebase, del login con email o de URLs públicas.

8. Bloqueos y decisiones que necesito tomar, numerados y con tu recomendación.

9. Próximos pasos: las 3 a 5 tareas siguientes, en orden.

Luego actualiza docs/ESTADO.md con este reporte y la fecha.
```

---

## Prompts cortos para la semana

- **Aprobar y avanzar:** `Plan aprobado. Empieza por la tarea 1. Al terminar cada tarea, corre las pruebas, verifica en la app, haz commit y dime qué hiciste antes de seguir.`
- **Mantener el foco:** `Prioriza solo lo que se ve en la demo. Lo demás, anótalo en docs/ESTADO.md como pendiente.`
- **Si se desvía hacia funciones nuevas:** `Eso es de IGNITE según CLAUDE.md. Déjalo anotado y vuelve a la tarea del plan.`
- **Antes de grabar el video:** `Prepara la demo para grabar: un proyecto de ejemplo con una pelota de plasticina que rebota (12 cuadros), sin errores en pantalla, y revisa el guion de docs/DEMO.md.`
