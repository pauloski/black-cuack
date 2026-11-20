# DEMO — BlackQuack Studio (semana 1)

Demo estable del núcleo de creación, **local-first** (crear, guardar y exportar sin internet). No es el MVP.

## Cómo abrir la demo

- **Web publicada:** https://demo.blackquack.cl (protegida con Cloudflare Access; entra con el correo autorizado de Paulo o Karen).
- **Local (desarrollo):** `flutter run -d chrome` desde la raíz del repo, en la rama `demo/semana-1`.

## Publicar (Direct Upload, bajo demanda)

Cada publicación se hace a mano y se aprueba antes. Un solo comando:

```bash
./scripts/deploy_demo.sh
```

Hace `flutter build web --release` y `wrangler pages deploy build/web --project-name blackquack-demo`.

**Reglas:** proyecto Pages **nuevo** `blackquack-demo`; **no** se toca `black-cuack-studio` ni el apex `blackquack.cl`; sin conectar el repo (sin despliegues automáticos).

### Configuración inicial (una vez)

1. Autenticar wrangler: `npx wrangler login` (cuenta con acceso a Pages).
2. Crear el proyecto: `npx wrangler pages project create blackquack-demo --production-branch main`.
3. Primer deploy: `./scripts/deploy_demo.sh` → entrega una URL `*.pages.dev`.
4. Subdominio: en Cloudflare → Pages → `blackquack-demo` → Custom domains → agregar `demo.blackquack.cl` (la zona ya está en Cloudflare; el registro se crea solo). No se modifican otros registros.
5. Cloudflare Access (Zero Trust → Access → Applications → Add → Self-hosted): aplicación para `demo.blackquack.cl`, política **Allow** solo a los correos de Paulo y Karen. Probar en incógnito: debe pedir login antes de servir la app.

## Guion de 90 segundos (video)

1. **(0:00–0:10) Entrada sin correo.** Abrir la app → "Entrar" directo, sin email. "Las tablets del colegio entran a crear en segundos, sin cuentas ni datos personales."
2. **(0:10–0:35) Captura con papel cebolla.** Crear un Quack, capturar 4–5 cuadros moviendo una figura; mostrar el papel cebolla (1–3 cuadros en transparencia). "La app no dibuja ni anima: captura lo que hacen las manos."
3. **(0:35–0:55) Línea de tiempo.** Reordenar un cuadro, duplicar otro, borrar y deshacer; subir el FPS con un atajo; reproducir en bucle. "Ordenar y ajustar el ritmo es parte de pensar el movimiento."
4. **(0:55–1:10) Sin internet.** Activar modo avión → seguir capturando y guardando. Recargar la página → el proyecto y sus miniaturas siguen ahí. "Todo vive en el dispositivo; nada se pierde sin conexión."
5. **(1:10–1:25) Exportar.** Exportar GIF y ZIP; abrir el archivo y mostrar los N cuadros. "Se comparte fuera de la app cuando el docente lo decide."
6. **(1:25–1:30) Hacia dónde va.** Mostrar la sala simulada con QR (si está) o cerrar con el lema. *"Crear requiere tiempo. La tecnología debe hacerlo posible."*
