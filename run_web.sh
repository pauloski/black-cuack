#!/bin/bash
# Lanza Flutter web en modo release y abre un túnel HTTPS con cloudflared.
# El QR de cámara remota usará automáticamente la URL HTTPS del túnel.

# 1. Levanta el servidor Flutter en background
echo "⏳ Compilando en modo release..."
flutter run -d web-server \
  --web-port=8080 \
  --web-hostname=0.0.0.0 \
  --release \
  "$@" &
FLUTTER_PID=$!

# 2. Espera a que el servidor esté listo
echo "⏳ Esperando que el servidor arranque..."
until curl -s -o /dev/null -w "%{http_code}" http://localhost:8080 | grep -q "200"; do
  sleep 2
done

# 3. Abre el túnel HTTPS con cloudflared
echo ""
echo "✅ Flutter corriendo en http://localhost:8080"
echo "🌐 Abriendo túnel HTTPS..."
echo "   → Copia la URL https://xxxx.trycloudflare.com que aparece abajo"
echo "   → Ábrela en el computador (no en localhost)"
echo "   → El QR del diálogo de cámara remota usará esa URL automáticamente"
echo ""
cloudflared tunnel --url http://localhost:8080

# Si cloudflared termina, mata también el server de Flutter
kill $FLUTTER_PID 2>/dev/null
