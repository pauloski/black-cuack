#!/usr/bin/env bash
# Publica la LANDING de BlackQuack en Cloudflare Pages (Direct Upload).
#
# Reglas (no negociables):
#   - Proyecto Pages NUEVO y separado: "blackquack-landing".
#   - NO toca "blackquack-demo" (la app), ni "black-cuack-studio", ni el apex blackquack.cl.
#   - Direct Upload con wrangler; sin conectar el repo.
#
# Uso:   ./scripts/deploy_landing.sh
# Requisitos: wrangler autenticado.

set -euo pipefail

PROJECT_NAME="blackquack-landing"
LANDING_DIR="landing"

cd "$(dirname "$0")/.."

echo "==> Guardia: este script solo publica en '$PROJECT_NAME' (nunca la app ni el apex)."

# 1) version.json desde la fuente única (pubspec.yaml), para que landing y app nunca
#    queden desalineadas.
VERSION="$(grep '^version:' pubspec.yaml | head -1 | sed 's/version:[[:space:]]*//; s/+.*//')"
if [ -z "$VERSION" ]; then
  echo "ERROR: no se pudo leer la versión de pubspec.yaml" >&2
  exit 1
fi
printf '{ "version": "%s" }\n' "$VERSION" > "$LANDING_DIR/version.json"
echo "==> version.json → v$VERSION"

if [ ! -f "$LANDING_DIR/index.html" ]; then
  echo "ERROR: no se encontró $LANDING_DIR/index.html" >&2
  exit 1
fi

echo "==> wrangler pages deploy ($PROJECT_NAME, Direct Upload, rama main)"
npx --yes wrangler@latest pages deploy "$LANDING_DIR" --project-name "$PROJECT_NAME" --branch main

echo "==> Listo. Revisa la URL *.pages.dev y el subdominio build.blackquack.cl (tras configurar DNS)."
