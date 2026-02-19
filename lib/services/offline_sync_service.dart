import 'dart:convert';
import 'dart:io';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../main.dart';

class OfflineSyncService {
  static const String key = 'inconsistencias_offline';

  /// Guarda la lista completa de inconsistencias offline
  static Future<void> saveAll(List<Map<String, dynamic>> inconsistencias) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(key, json.encode(inconsistencias));
  }

  /// Obtiene todas las inconsistencias offline
  static Future<List<Map<String, dynamic>>> getAll() async {
    final prefs = await SharedPreferences.getInstance();
    final str = prefs.getString(key) ?? '[]';
    return List<Map<String, dynamic>>.from(json.decode(str));
  }

  /// Actualiza una inconsistencia por id
  static Future<void> updateById(int id, Map<String, dynamic> newData) async {
    final all = await getAll();
    final idx = all.indexWhere((e) => e['id'] == id);
    if (idx != -1) {
      all[idx] = newData;
      await saveAll(all);
    }
  }

  /// Marca una inconsistencia como sincronizada (opcional)
  static Future<void> markSynced(int id) async {
    final all = await getAll();
    final idx = all.indexWhere((e) {
      final eid = e['id'];
      if (eid is int) return eid == id;
      if (eid is String) return int.tryParse(eid) == id;
      return false;
    });
    if (idx != -1) {
      all[idx]['sincronizado'] = true;
      await saveAll(all);
    }
  }

  /// Sube todas las inconsistencias no sincronizadas a la nube
  static Future<List<String>> syncAllToCloud() async {
    final all = await getAll();
    
    // Filtrar solo las que tienen PDF generado y no están sincronizadas
    final pendientes = all.where((e) {
      final sincronizado = e['sincronizado'] == true;
      final tienePdf = e['pdf'] != null && e['pdf'].toString().isNotEmpty;
      return !sincronizado && tienePdf;
    }).toList();
    
    List<String> resultados = [];
    
    if (pendientes.isEmpty) {
      resultados.add('ℹ️ No hay inconsistencias con PDF generado para sincronizar');
      return resultados;
    }
    
    for (final inc in pendientes) {
      try {
        // Asegurar que el id sea int
        dynamic rawId = inc['id'];
        int? idInt;
        if (rawId is int) {
          idInt = rawId;
        } else if (rawId is String) {
          idInt = int.tryParse(rawId);
        }
        if (idInt == null) throw Exception('ID inválido: ${inc['id']}');
        
        final instalacion = inc['instalacion']?.toString() ?? 'sin_instalacion';
        
        // ===== PASO 1: SUBIR PDF AL BUCKET =====
        String pdfUrl;
        final pdfPath = inc['pdf']?.toString();
        
        if (pdfPath != null && pdfPath.startsWith('/')) {
          final file = File(pdfPath);
          if (await file.exists()) {
            try {
              final bytes = await file.readAsBytes();
              final fileName = pdfPath.split('/').last; // Usar el nombre original generado
              final bucketPath = 'inconsistencias/pdfs/$fileName';
              
              await supabase.storage.from('cold').uploadBinary(
                bucketPath,
                bytes,
                fileOptions: const FileOptions(upsert: true),
              );
              
              pdfUrl = bucketPath;
              print('📄 PDF subido: $bucketPath');
            } catch (e) {
              print('❌ Error al subir PDF: $e');
              throw Exception('Error al subir PDF: $e');
            }
          } else {
            throw Exception('Archivo PDF no encontrado: $pdfPath');
          }
        } else {
          throw Exception('No hay ruta de PDF válida para sincronizar');
        }
        
        // ===== PASO 2: PREPARAR DATOS PARA ACTUALIZAR EN SUPABASE =====
        final Map<String, dynamic> updates = {};
        
        // Log para ver todos los datos del objeto inc
        print('🔍 Objeto completo inc (ID $idInt):');
        print('   - fecha_revision: ${inc['fecha_revision']}');
        print('   - geolocalizacion: ${inc['geolocalizacion']}');
        print('   - coordenada_instalacion: ${inc['coordenada_instalacion']}');
        print('   - causa_observacion: ${inc['causa_observacion']}');
        print('   - observacion_adicional_real: ${inc['observacion_adicional_real']}');
        print('   - alfanumerica_revisor: ${inc['alfanumerica_revisor']}');
        print('   - lectura_real: ${inc['lectura_real']}');
        print('   - correcciones_en_sistema: ${inc['correcciones_en_sistema']}');
        print('   - advertencia_revisor: ${inc['advertencia_revisor']}');
        
        final fechaRevision = inc['fecha_revision'];
        final geolocalizacion = inc['geolocalizacion'];
        final causaObservacion = inc['causa_observacion'];
        final observacionAdicionalReal = inc['observacion_adicional_real'];
        final alfanumericaRevisor = inc['alfanumerica_revisor'];
        final lecturaReal = inc['lectura_real'];
        final correccionesEnSistema = inc['correcciones_en_sistema'];
        final advertenciaRevisor = inc['advertencia_revisor'];
        final coordenadaInstalacion = inc['coordenada_instalacion'];

        // Fecha de revisión
        if (fechaRevision != null) {
          updates['fecha_revision'] = fechaRevision;
        }

        // Coordenada de instalación desde geolocalización (prioridad) o valor existente
        final coordFromGeo = geolocalizacion ?? coordenadaInstalacion;
        if (coordFromGeo != null) {
          updates['coordenada_instalacion'] = coordFromGeo;
        }

        // Causa observación
        if (causaObservacion != null) {
          updates['causa_observacion'] = causaObservacion;
        }

        // Observación adicional real
        if (observacionAdicionalReal != null) {
          updates['observacion_adicional_real'] = observacionAdicionalReal;
        }

        // Alfanumérica revisor
        if (alfanumericaRevisor != null) {
          updates['alfanumerica_revisor'] = alfanumericaRevisor;
        }

        // Lectura real
        if (lecturaReal != null) {
          updates['lectura_real'] = lecturaReal;
        }

        // Correcciones en sistema
        if (correccionesEnSistema != null) {
          updates['correcciones_en_sistema'] = correccionesEnSistema;
        }

        // Geolocalización guardada automáticamente al subir
        if (geolocalizacion != null) {
          updates['geolocalizacion'] = geolocalizacion;
        }

        // Advertencia revisor
        if (advertenciaRevisor != null) {
          updates['advertencia_revisor'] = advertenciaRevisor;
        }

        // PDF (URL en el bucket)
        updates['pdf'] = pdfUrl;

        // Log de depuración para verificar payload enviado
        print('📦 Payload a actualizar (ID $idInt): $updates');
        
        // ===== PASO 3: ACTUALIZAR EN SUPABASE =====
        print('📤 Actualizando inconsistencia $idInt en Supabase...');
        print('   Datos a actualizar: $updates');
        
        await supabase
            .from('inconsistencias')
            .update(updates)
            .eq('id', idInt);
        
        // ===== PASO 4: VERIFICAR EN SUPABASE QUE SE GUARDÓ CORRECTAMENTE =====
        try {
          final verificado = await supabase
              .from('inconsistencias')
              .select('id,pdf')
              .eq('id', idInt)
              .maybeSingle();

          if (verificado == null) {
            throw Exception('Verificación fallida: registro no encontrado en Supabase');
          }

          final pdfGuardado = verificado['pdf']?.toString() ?? '';
          if (pdfGuardado != pdfUrl) {
            throw Exception('Verificación fallida: PDF guardado "$pdfGuardado" no coincide con "$pdfUrl"');
          }

          // ===== PASO 5: MARCAR COMO SINCRONIZADO LOCALMENTE =====
          await markSynced(idInt);
          resultados.add('✅ OK: Instalación $instalacion (ID: $idInt) - PDF y datos sincronizados y verificados');
          print('✅ Inconsistencia $idInt verificada exitosamente');
        } catch (verErr) {
          resultados.add('❌ ERROR VERIFICACIÓN: Instalación $instalacion (ID: $idInt) - $verErr');
          print('❌ Error de verificación para $idInt: $verErr');
        }
        
      } catch (e) {
        final instalacion = inc['instalacion']?.toString() ?? 'desconocida';
        resultados.add('❌ ERROR: Instalación $instalacion (ID: ${inc['id']}) - $e');
        print('❌ Error sincronizando ${inc['id']}: $e');
      }
    }
    
    return resultados;
  }}