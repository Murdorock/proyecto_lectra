import 'dart:convert';
import 'dart:io';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../main.dart';

class CertificacionesRepartoOfflineSyncService {
  static const String key = 'certificaciones_reparto_offline';

  static Future<void> saveAll(List<Map<String, dynamic>> certificaciones) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(key, json.encode(certificaciones));
  }

  static Future<List<Map<String, dynamic>>> getAll() async {
    final prefs = await SharedPreferences.getInstance();
    final str = prefs.getString(key) ?? '[]';
    return List<Map<String, dynamic>>.from(json.decode(str));
  }

  static Future<void> markSynced(String id) async {
    final all = await getAll();
    final idx = all.indexWhere((e) => _rowId(e) == id);

    if (idx != -1) {
      all[idx]['sincronizado'] = true;
      await saveAll(all);
    }
  }

  static Future<List<String>> syncAllToCloud() async {
    final all = await getAll();

    final pendientes = all.where((e) {
      final sincronizado = e['sincronizado'] == true;
      return !sincronizado;
    }).toList();

    if (pendientes.isEmpty) {
      return ['ℹ️ No hay certificaciones pendientes para sincronizar'];
    }

    final resultados = <String>[];

    for (final item in pendientes) {
      try {
        final rowId = _rowId(item);
        if (rowId == null) {
          throw Exception('ID inválido: ${item['id_certificacion'] ?? item['id']}');
        }

        final pkColumn = _pkColumn(item);
        final pkValue = item[pkColumn];
        if (pkValue == null) {
          throw Exception('No se encontró valor para clave primaria $pkColumn');
        }

        final payload = await _buildUpdatePayload(item);

        await supabase
            .from('certificaciones_reparto')
            .update(payload)
            .eq(pkColumn, pkValue);

        await markSynced(rowId);
        final instalacion = item['instalacion']?.toString() ?? 'sin instalación';
        resultados.add('✅ OK: Instalación $instalacion (ID: $rowId) sincronizada');
      } catch (e) {
        final instalacion = item['instalacion']?.toString() ?? 'desconocida';
        final rowId = _rowId(item) ?? 'sin_id';
        resultados.add('❌ ERROR: Instalación $instalacion (ID: $rowId) - $e');
      }
    }

    return resultados;
  }

  static String? _rowId(Map<String, dynamic> item) {
    final raw = item['id_certificacion'] ?? item['id'];
    if (raw == null) return null;
    final value = raw.toString().trim();
    return value.isEmpty ? null : value;
  }

  static String _pkColumn(Map<String, dynamic> item) {
    if (item.containsKey('id_certificacion')) return 'id_certificacion';
    return 'id';
  }

  static Future<Map<String, dynamic>> _buildUpdatePayload(Map<String, dynamic> item) async {
    final payload = <String, dynamic>{};

    for (final entry in item.entries) {
      final key = entry.key;
      final value = entry.value;

      if (_excludedKeys.contains(key)) {
        continue;
      }

      if (value == null) {
        continue;
      }

      if (value is String && value.isEmpty) {
        continue;
      }

      if (_fileLikeKeys.contains(key) && value is String && value.startsWith('/')) {
        final uploadedPath = await _uploadLocalFile(value, key);
        payload[key] = uploadedPath;
      } else {
        payload[key] = value;
      }
    }

    if (payload.isEmpty) {
      throw Exception('No hay campos válidos para actualizar');
    }

    return payload;
  }

  static Future<String> _uploadLocalFile(String localPath, String fieldKey) async {
    final file = File(localPath);
    if (!await file.exists()) {
      throw Exception('Archivo no encontrado: $localPath');
    }

    final bytes = await file.readAsBytes();
    final filename = localPath.split('/').last;
    final bucketPath = 'certificaciones_reparto/$fieldKey/$filename';

    await supabase.storage.from('cold').uploadBinary(
      bucketPath,
      bytes,
      fileOptions: const FileOptions(upsert: true),
    );

    return bucketPath;
  }

  static const Set<String> _excludedKeys = {
    'id_certificacion',
    'id',
    'created_at',
    'updated_at',
    'sincronizado',
  };

  static const Set<String> _fileLikeKeys = {
    'pdf',
    'foto',
    'foto1',
    'foto2',
    'firma',
    'firma_revisor',
    'archivo',
    'soporte',
    'adjunto',
  };
}
