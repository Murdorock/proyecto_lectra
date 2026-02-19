#!/bin/bash
# Script para descargar un ícono temporal para LECTRA

echo "🎨 Configurando ícono temporal para LECTRA..."

# Crear directorio si no existe
mkdir -p assets/icon

# Opción 1: Usar ImageMagick para crear un ícono simple
# Requiere: choco install imagemagick (en Windows con Chocolatey)
# O descarga desde: https://imagemagick.org/

echo "📝 Para crear tu ícono personalizado, tienes 3 opciones:"
echo ""
echo "OPCIÓN 1 - Usar Canva (Recomendado para principiantes):"
echo "  1. Ve a https://www.canva.com"
echo "  2. Crea un diseño de 1024x1024 px"
echo "  3. Usa fondo #1A237E (azul oscuro)"
echo "  4. Agrega elementos: medidor, rayo, letras LECTRA"
echo "  5. Descarga como PNG"
echo "  6. Guarda en: assets/icon/app_icon.png"
echo ""
echo "OPCIÓN 2 - Usar un generador online:"
echo "  1. Ve a https://www.appicon.co/"
echo "  2. Sube una imagen o crea una nueva"
echo "  3. Descarga el PNG de 1024x1024"
echo "  4. Guarda en: assets/icon/app_icon.png"
echo ""
echo "OPCIÓN 3 - Usar íconos de stock:"
echo "  1. Ve a https://www.flaticon.com"
echo "  2. Busca 'meter reading' o 'utility gauge'"
echo "  3. Descarga PNG 1024x1024"
echo "  4. Edita el color en https://www.photopea.com (gratis)"
echo "  5. Guarda en: assets/icon/app_icon.png"
echo ""
echo "Una vez tengas tu ícono, ejecuta:"
echo "  flutter pub get"
echo "  flutter pub run flutter_launcher_icons"
echo ""
