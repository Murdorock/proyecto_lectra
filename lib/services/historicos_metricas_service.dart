import '../main.dart';
import 'user_session.dart';
import 'package:device_info_plus/device_info_plus.dart';
import 'package:flutter/foundation.dart' show kIsWeb;

class HistoricosMetricasService {
  static const String _tabla = 'historicos_metricas';
  static String? _dispositivoId;
  static String? _dispositivoModelo;
  static String? _dispositivoPlataforma;

  static Future<void> _obtenerInfoDispositivo() async {
    if (_dispositivoId != null) return;
    
    try {
      final deviceInfo = DeviceInfoPlugin();
      
      if (kIsWeb) {
        final webInfo = await deviceInfo.webBrowserInfo;
        _dispositivoId = webInfo.userAgent ?? 'web_sin_id';
        _dispositivoModelo = '${webInfo.browserName.name} ${webInfo.appVersion}';
        _dispositivoPlataforma = 'Web';
      } else {
        // Intentar obtener info de Android
        try {
          final androidInfo = await deviceInfo.androidInfo;
          _dispositivoId = androidInfo.fingerprint;
          _dispositivoModelo = '${androidInfo.manufacturer} ${androidInfo.model}';
          _dispositivoPlataforma = 'Android ${androidInfo.version.release}';
          return;
        } catch (_) {}
        
        // Si falla Android, intentar iOS
        try {
          final iosInfo = await deviceInfo.iosInfo;
          _dispositivoId = iosInfo.identifierForVendor ?? iosInfo.model;
          _dispositivoModelo = '${iosInfo.name} ${iosInfo.model}';
          _dispositivoPlataforma = 'iOS ${iosInfo.systemVersion}';
          return;
        } catch (_) {}
        
        // Si ambos fallan, es otra plataforma
        _dispositivoId = 'plataforma_desconocida';
        _dispositivoModelo = 'desconocido';
        _dispositivoPlataforma = 'desconocido';
      }
    } catch (e) {
      // Si falla todo, usar valores por defecto
      _dispositivoId = 'no_disponible';
      _dispositivoModelo = 'no_disponible';
      _dispositivoPlataforma = 'no_disponible';
    }
  }

  static Future<void> registrarEvento({
    required String accion,
    String? criterio,
    String? valor,
    Map<String, dynamic>? metadatos,
  }) async {
    try {
      await _obtenerInfoDispositivo();
      
      final user = supabase.auth.currentUser;
      final codigoSupAux = UserSession().codigoSupAux;

      final payload = <String, dynamic>{
        'usuario_id': user?.id,
        'codigo_sup_aux': codigoSupAux,
        'accion': accion,
        'criterio': criterio,
        'valor': valor,
        'fecha_evento': DateTime.now().toIso8601String(),
        'metadatos': {
          'pantalla': 'historicos',
          'plataforma': _dispositivoPlataforma ?? 'movil',
          'dispositivo_id': _dispositivoId,
          'dispositivo_modelo': _dispositivoModelo,
          if (metadatos != null) ...metadatos,
        },
      };

      await supabase.from(_tabla).insert(payload);
    } catch (_) {
      // No bloquear la operacion principal si falla la metrica.
    }
  }

  static Future<void> registrarVistaAbierta() async {
    await registrarEvento(accion: 'abrir_vista');
  }

  static Future<void> registrarConsulta({
    required String criterio,
    required String valor,
  }) async {
    await registrarEvento(
      accion: 'consulta_historicos',
      criterio: criterio,
      valor: valor,
    );
  }

  static Future<void> registrarIntentofallido({
    required String tipo,
    required String mensaje,
  }) async {
    await registrarEvento(
      accion: 'intento_fallido',
      criterio: tipo,
      valor: mensaje,
    );
  }

  static Future<void> registrarTiempoVista(int segundos) async {
    await registrarEvento(
      accion: 'tiempo_vista',
      criterio: 'segundos',
      valor: segundos.toString(),
    );
  }

  static Future<void> registrarBusquedaSinResultados({
    required String criterio,
    required String valor,
  }) async {
    await registrarEvento(
      accion: 'busqueda_sin_resultados',
      criterio: criterio,
      valor: valor,
    );
  }
}
