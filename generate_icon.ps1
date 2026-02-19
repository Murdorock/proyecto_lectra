# Script PowerShell para generar un ícono básico de LECTRA
# No requiere instalaciones adicionales

Add-Type -AssemblyName System.Drawing

# Crear directorio si no existe
$iconDir = "assets\icon"
if (-not (Test-Path $iconDir)) {
    New-Item -ItemType Directory -Path $iconDir -Force | Out-Null
}

# Configuración
$size = 1024
$outputPath = "assets\icon\app_icon.png"

# Crear bitmap
$bitmap = New-Object System.Drawing.Bitmap $size, $size
$graphics = [System.Drawing.Graphics]::FromImage($bitmap)
$graphics.SmoothingMode = [System.Drawing.Drawing2D.SmoothingMode]::AntiAlias

# Colores
$bgColor = [System.Drawing.Color]::FromArgb(255, 26, 35, 126)      # #1A237E
$white = [System.Drawing.Color]::White
$yellow = [System.Drawing.Color]::FromArgb(255, 255, 193, 7)       # #FFC107

# Fondo
$bgBrush = New-Object System.Drawing.SolidBrush $bgColor
$graphics.FillRectangle($bgBrush, 0, 0, $size, $size)

# Círculo del medidor (exterior)
$margin = 150
$circlePen = New-Object System.Drawing.Pen $white, 30
$graphics.DrawEllipse($circlePen, $margin, $margin, ($size - 2*$margin), ($size - 2*$margin))

# Círculo del medidor (interior)
$innerMargin = 180
$innerBrush = New-Object System.Drawing.SolidBrush ([System.Drawing.Color]::FromArgb(50, 255, 255, 255))
$graphics.FillEllipse($innerBrush, $innerMargin, $innerMargin, ($size - 2*$innerMargin), ($size - 2*$innerMargin))

# Marcas del medidor
$centerX = $size / 2
$centerY = $size / 2
$markPen = New-Object System.Drawing.Pen $yellow, 15

for ($i = 0; $i -lt 12; $i++) {
    $angle = ($i * 30 - 90) * [Math]::PI / 180
    $x1 = $centerX + [Math]::Cos($angle) * 300
    $y1 = $centerY + [Math]::Sin($angle) * 300
    $x2 = $centerX + [Math]::Cos($angle) * 350
    $y2 = $centerY + [Math]::Sin($angle) * 350
    $graphics.DrawLine($markPen, $x1, $y1, $x2, $y2)
}

# Aguja del medidor
$needleAngle = -45 * [Math]::PI / 180
$needleLength = 250
$needlePen = New-Object System.Drawing.Pen $yellow, 20
$needlePen.StartCap = [System.Drawing.Drawing2D.LineCap]::Round
$needlePen.EndCap = [System.Drawing.Drawing2D.LineCap]::Round

$xEnd = $centerX + [Math]::Cos($needleAngle) * $needleLength
$yEnd = $centerY + [Math]::Sin($needleAngle) * $needleLength
$graphics.DrawLine($needlePen, $centerX, $centerY, $xEnd, $yEnd)

# Centro de la aguja
$centerBrush = New-Object System.Drawing.SolidBrush $white
$graphics.FillEllipse($centerBrush, ($centerX - 30), ($centerY - 30), 60, 60)

# Texto "LECTRA"
$text = "LECTRA"
$font = New-Object System.Drawing.Font "Arial", 80, [System.Drawing.FontStyle]::Bold
$textBrush = New-Object System.Drawing.SolidBrush $white
$textSize = $graphics.MeasureString($text, $font)
$textX = ($size - $textSize.Width) / 2
$textY = $size - 200
$graphics.DrawString($text, $font, $textBrush, $textX, $textY)

# Guardar
$bitmap.Save($outputPath, [System.Drawing.Imaging.ImageFormat]::Png)

# Limpiar recursos
$graphics.Dispose()
$bitmap.Dispose()
$bgBrush.Dispose()
$circlePen.Dispose()
$innerBrush.Dispose()
$markPen.Dispose()
$needlePen.Dispose()
$centerBrush.Dispose()
$textBrush.Dispose()
$font.Dispose()

Write-Host "✅ Ícono generado exitosamente!" -ForegroundColor Green
Write-Host "   Archivo: $outputPath" -ForegroundColor Cyan
Write-Host "   Tamaño: ${size}x${size} pixels" -ForegroundColor Cyan
Write-Host ""
Write-Host "Ahora ejecuta:" -ForegroundColor Yellow
Write-Host "  flutter pub run flutter_launcher_icons" -ForegroundColor White
