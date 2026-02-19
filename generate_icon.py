# Script para generar ícono básico de LECTRA
# Requiere: pip install pillow

from PIL import Image, ImageDraw, ImageFont
import os

# Crear directorio si no existe
os.makedirs('assets/icon', exist_ok=True)

# Crear imagen de 1024x1024
size = 1024
img = Image.new('RGB', (size, size), color='#1A237E')
draw = ImageDraw.Draw(img)

# Color corporativo
bg_color = (26, 35, 126)  # #1A237E
white = (255, 255, 255)
yellow = (255, 193, 7)  # #FFC107

# Dibujar círculo del medidor (exterior)
margin = 150
circle_bbox = [margin, margin, size - margin, size - margin]
draw.ellipse(circle_bbox, outline=white, width=30)

# Dibujar círculo del medidor (interior semi-transparente)
inner_margin = 180
inner_circle = [inner_margin, inner_margin, size - inner_margin, size - inner_margin]
draw.ellipse(inner_circle, fill=(255, 255, 255, 50))

# Dibujar marcas del medidor
center_x, center_y = size // 2, size // 2
import math
for i in range(12):
    angle = math.radians(i * 30 - 90)
    x1 = center_x + math.cos(angle) * 300
    y1 = center_y + math.sin(angle) * 300
    x2 = center_x + math.cos(angle) * 350
    y2 = center_y + math.sin(angle) * 350
    draw.line([(x1, y1), (x2, y2)], fill=yellow, width=15)

# Dibujar aguja
needle_angle = math.radians(-45)  # 45 grados hacia arriba-derecha
needle_length = 250
x_end = center_x + math.cos(needle_angle) * needle_length
y_end = center_y + math.sin(needle_angle) * needle_length
draw.line([(center_x, center_y), (x_end, y_end)], fill=yellow, width=20)

# Centro de la aguja
draw.ellipse([center_x - 30, center_y - 30, center_x + 30, center_y + 30], fill=white)

# Intentar agregar texto (puede fallar si no hay fuente disponible)
try:
    font = ImageFont.truetype("arial.ttf", 80)
except:
    try:
        font = ImageFont.truetype("C:/Windows/Fonts/arial.ttf", 80)
    except:
        font = ImageFont.load_default()

# Texto "LECTRA"
text = "LECTRA"
bbox = draw.textbbox((0, 0), text, font=font)
text_width = bbox[2] - bbox[0]
text_x = (size - text_width) // 2
text_y = size - 200

draw.text((text_x, text_y), text, fill=white, font=font)

# Guardar
output_path = 'assets/icon/app_icon.png'
img.save(output_path)
print(f"✅ Ícono generado: {output_path}")
print(f"   Tamaño: {size}x{size} pixels")
print(f"\nAhora ejecuta: flutter pub run flutter_launcher_icons")
