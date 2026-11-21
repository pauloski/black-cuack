#!/usr/bin/env bash
# Publica la demo web de BlackQuack en Cloudflare Pages (Direct Upload).
#
# Reglas (no negociables):
#   - Proyecto Pages NUEVO y separado: "blackquack-demo".
#   - NO toca el proyecto "black-cuack-studio" ni el dominio raíz blackquack.cl.
#   - Direct Upload con wrangler; sin conectar el repo (sin despliegues automáticos).
#
# Uso:
#   ./scripts/deploy_demo.sh
#
# Requisitos:
#   - Flutter en el PATH.
#   - wrangler autenticado (npx wrangler login) con permisos sobre Cloudflare Pages.

set -euo pipefail

PROJECT_NAME="blackquack-demo"
BUILD_DIR="build/web"

# Ubicarse en la raíz del repo (este script vive en scripts/).
cd "$(dirname "$0")/.."

echo "==> Guardia: este script solo publica en '$PROJECT_NAME'."
echo "    Nunca en 'black-cuack-studio' ni en el apex blackquack.cl."

echo "==> 1/2  flutter build web --release (--no-tree-shake-icons)"
# --no-tree-shake-icons: el subsetter dejaba fuera los glifos de las variantes
# `_rounded` (íconos vacíos en inicio, cámara y exportar). Enviamos la fuente
# completa de MaterialIcons para que se vean todos.
flutter build web --release --no-tree-shake-icons

if [ ! -f "$BUILD_DIR/index.html" ]; then
  echo "ERROR: no se encontró $BUILD_DIR/index.html tras el build." >&2
  exit 1
fi

echo "==> 1.5/2  Neutralizar el service worker (anti-caché para la demo)"
# El SW de Flutter sirve el build anterior en la primera carga tras un deploy
# (y los evaluadores que ya visitaron conservan el SW viejo sirviendo contenido
# obsoleto). Lo reemplazamos por un "kill-switch": al activarse borra todas las
# cachés y se da de baja, y NO intercepta fetch (todo va a la red). Así cada carga
# trae el build más reciente sin recargar. (El modo offline del MVP vive en Android.)
cat > "$BUILD_DIR/flutter_service_worker.js" <<'SW'
// Kill-switch: limpia cachés viejas y se da de baja. Sin intercepción de red.
self.addEventListener('install', () => self.skipWaiting());
self.addEventListener('activate', (event) => {
  event.waitUntil((async () => {
    try {
      const keys = await caches.keys();
      await Promise.all(keys.map((k) => caches.delete(k)));
      await self.registration.unregister();
    } catch (e) { /* no-op */ }
  })());
});
// Sin 'fetch' handler: las peticiones van directo a la red (sin caché del SW).
SW

# Asegurar que _headers viaja al deploy (Flutter copia web/ a build/web/, pero lo
# reponemos por si acaso).
if [ -f "web/_headers" ]; then
  cp -f "web/_headers" "$BUILD_DIR/_headers"
fi

echo "==> 2/2  wrangler pages deploy ($PROJECT_NAME, Direct Upload, rama main)"
npx --yes wrangler@latest pages deploy "$BUILD_DIR" --project-name "$PROJECT_NAME" --branch main

echo "==> Listo. Revisa la URL *.pages.dev y el subdominio demo.blackquack.cl."
