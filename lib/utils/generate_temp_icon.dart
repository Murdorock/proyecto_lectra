import 'dart:ui' as ui;
import 'dart:io';
import 'dart:math' as math;
import 'package:flutter/material.dart';

/// Script para generar íconos temporales de LECTRA
/// Ejecutar con: dart run lib/utils/generate_temp_icon.dart

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  print('Generando ícono temporal de LECTRA...');
  
  // Generar ícono principal
  await _generateIcon('app_icon.png', includeBackground: true);
  
  // Generar ícono foreground (sin fondo)
  await _generateIcon('app_icon_foreground.png', includeBackground: false);
  
  print('✅ Íconos generados exitosamente en assets/icon/');
  print('Ejecuta: flutter pub run flutter_launcher_icons');
}

Future<void> _generateIcon(String filename, {required bool includeBackground}) async {
  final recorder = ui.PictureRecorder();
  final canvas = Canvas(recorder);
  final size = 1024.0;
  
  // Fondo azul oscuro
  if (includeBackground) {
    final bgPaint = Paint()..color = const Color(0xFF1A237E);
    canvas.drawRect(Rect.fromLTWH(0, 0, size, size), bgPaint);
  }
  
  // Medidor circular (exterior)
  final meterPaint = Paint()
    ..color = Colors.white
    ..style = PaintingStyle.stroke
    ..strokeWidth = 30;
  
  canvas.drawCircle(
    Offset(size / 2, size / 2),
    size * 0.32,
    meterPaint,
  );
  
  // Medidor circular (relleno semi-transparente)
  final meterFillPaint = Paint()
    ..color = Colors.white.withValues(alpha: 0.1)
    ..style = PaintingStyle.fill;
  
  canvas.drawCircle(
    Offset(size / 2, size / 2),
    size * 0.32,
    meterFillPaint,
  );
  
  // Aguja del medidor
  final needlePaint = Paint()
    ..color = const Color(0xFFFFC107) // Amarillo/ámbar
    ..strokeWidth = 20
    ..strokeCap = StrokeCap.round;
  
  final centerX = size / 2;
  final centerY = size / 2;
  final needleLength = size * 0.25;
  final angle = -math.pi / 4; // 45 grados
  
  canvas.drawLine(
    Offset(centerX, centerY),
    Offset(
      centerX + needleLength * math.cos(angle),
      centerY + needleLength * math.sin(angle),
    ),
    needlePaint,
  );
  
  // Centro del medidor
  final centerPaint = Paint()..color = Colors.white;
  canvas.drawCircle(Offset(centerX, centerY), 25, centerPaint);
  
  // Rayo (símbolo de energía)
  final boltPaint = Paint()
    ..color = const Color(0xFFFFC107)
    ..style = PaintingStyle.fill;
  
  final boltPath = Path();
  final boltCenterX = size * 0.75;
  final boltCenterY = size * 0.25;
  final boltSize = 80.0;
  
  // Forma de rayo simplificada
  boltPath.moveTo(boltCenterX, boltCenterY - boltSize);
  boltPath.lineTo(boltCenterX - boltSize * 0.3, boltCenterY);
  boltPath.lineTo(boltCenterX + boltSize * 0.1, boltCenterY);
  boltPath.lineTo(boltCenterX - boltSize * 0.3, boltCenterY + boltSize);
  boltPath.lineTo(boltCenterX + boltSize * 0.3, boltCenterY + boltSize * 0.3);
  boltPath.lineTo(boltCenterX, boltCenterY + boltSize * 0.3);
  boltPath.close();
  
  canvas.drawPath(boltPath, boltPaint);
  
  // Documento/factura (esquina inferior)
  final docPaint = Paint()
    ..color = Colors.white70
    ..style = PaintingStyle.fill;
  
  final docX = size * 0.25;
  final docY = size * 0.72;
  final docWidth = 100.0;
  final docHeight = 120.0;
  
  canvas.drawRRect(
    RRect.fromRectAndRadius(
      Rect.fromLTWH(docX, docY, docWidth, docHeight),
      const Radius.circular(8),
    ),
    docPaint,
  );
  
  // Líneas del documento
  final linePaint = Paint()
    ..color = const Color(0xFF1A237E)
    ..strokeWidth = 4;
  
  for (var i = 0; i < 3; i++) {
    final y = docY + 30 + (i * 25);
    canvas.drawLine(
      Offset(docX + 15, y),
      Offset(docX + docWidth - 15, y),
      linePaint,
    );
  }
  
  // Convertir a imagen
  final picture = recorder.endRecording();
  final img = await picture.toImage(size.toInt(), size.toInt());
  final byteData = await img.toByteData(format: ui.ImageByteFormat.png);
  final bytes = byteData!.buffer.asUint8List();
  
  // Guardar archivo
  final file = File('assets/icon/$filename');
  await file.writeAsBytes(bytes);
  
  print('✓ Generado: $filename');
}
