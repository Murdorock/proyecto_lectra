import '../main.dart';
import 'user_session.dart';

class ConsultaRetenidosMetricasService {
  static const String _tabla = 'consulta_retenidos_metricas';

  static Future<void> registrarEvento({
    required String accion,
    String? criterio,
    String? valor,
    Map<String, dynamic>? metadatos,
  }) async {
    try {
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
          'pantalla': 'consulta_retenidos',
          'plataforma': 'movil',
          'dispositivo': 'android/ios',
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
      accion: 'consulta_retenidos',
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
