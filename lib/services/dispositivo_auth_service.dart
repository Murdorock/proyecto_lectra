import 'package:android_id/android_id.dart';
import 'package:device_info_plus/device_info_plus.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:supabase_flutter/supabase_flutter.dart';

import '../main.dart';

class DispositivoInfo {
  final String id;
  final String modelo;
  final String plataforma;
  final String? legacyId;

  const DispositivoInfo({
    required this.id,
    required this.modelo,
    required this.plataforma,
    this.legacyId,
  });
}

class DispositivoAuthResultado {
  final bool autorizado;
  final String? motivo;
  final DispositivoInfo dispositivo;

  const DispositivoAuthResultado({
    required this.autorizado,
    required this.dispositivo,
    this.motivo,
  });
}

class DispositivoAuthService {
  static const String _tabla = 'dispositivos_autorizados';
  static const AndroidId _androidId = AndroidId();
  static DispositivoInfo? _cacheDispositivo;

  static String _fechaHoraLocalIsoSinZona() {
    return DateTime.now().toIso8601String();
  }

  static Future<DispositivoInfo> obtenerDispositivoActual() async {
    if (_cacheDispositivo != null) return _cacheDispositivo!;

    final deviceInfo = DeviceInfoPlugin();

    try {
      if (kIsWeb) {
        final webInfo = await deviceInfo.webBrowserInfo;
        _cacheDispositivo = DispositivoInfo(
          id: webInfo.userAgent ?? 'web_sin_id',
          modelo: '${webInfo.browserName.name} ${webInfo.appVersion ?? ''}'.trim(),
          plataforma: 'Web',
        );
        return _cacheDispositivo!;
      }

      try {
        final androidInfo = await deviceInfo.androidInfo;
        final androidId = await _androidId.getId();
        final idUnico = (androidId != null && androidId.trim().isNotEmpty)
            ? 'android:$androidId'
            : 'android_fallback:${androidInfo.fingerprint}';

        _cacheDispositivo = DispositivoInfo(
          id: idUnico,
          modelo: '${androidInfo.manufacturer} ${androidInfo.model}',
          plataforma: 'Android ${androidInfo.version.release}',
          legacyId: androidInfo.fingerprint,
        );
        return _cacheDispositivo!;
      } catch (_) {}

      try {
        final iosInfo = await deviceInfo.iosInfo;
        _cacheDispositivo = DispositivoInfo(
          id: iosInfo.identifierForVendor ?? iosInfo.model,
          modelo: '${iosInfo.name} ${iosInfo.model}',
          plataforma: 'iOS ${iosInfo.systemVersion}',
        );
        return _cacheDispositivo!;
      } catch (_) {}

      _cacheDispositivo = const DispositivoInfo(
        id: 'plataforma_desconocida',
        modelo: 'desconocido',
        plataforma: 'desconocido',
      );
      return _cacheDispositivo!;
    } catch (_) {
      _cacheDispositivo = const DispositivoInfo(
        id: 'no_disponible',
        modelo: 'no_disponible',
        plataforma: 'no_disponible',
      );
      return _cacheDispositivo!;
    }
  }

  static Future<DispositivoAuthResultado> validarDispositivoAutorizado({
    required String email,
  }) async {
    final dispositivo = await obtenerDispositivoActual();

    try {
      var data = await supabase
          .from(_tabla)
          .select('id')
          .eq('email', email)
          .eq('dispositivo_id', dispositivo.id)
          .eq('activo', true)
          .limit(1);

        if (data.isEmpty &&
          dispositivo.legacyId != null &&
          dispositivo.legacyId!.isNotEmpty) {
        data = await supabase
            .from(_tabla)
            .select('id')
            .eq('email', email)
            .eq('dispositivo_id', dispositivo.legacyId!)
            .eq('activo', true)
            .limit(1);
      }

      final autorizado = data.isNotEmpty;

      return DispositivoAuthResultado(
        autorizado: autorizado,
        dispositivo: dispositivo,
        motivo: autorizado ? null : 'Dispositivo no autorizado para este usuario',
      );
    } on PostgrestException catch (e) {
      if (e.code == '42P01') {
        return DispositivoAuthResultado(
          autorizado: false,
          dispositivo: dispositivo,
          motivo: 'No existe la tabla dispositivos_autorizados',
        );
      }

      return DispositivoAuthResultado(
        autorizado: false,
        dispositivo: dispositivo,
        motivo: 'No se pudo validar el dispositivo',
      );
    } catch (_) {
      return DispositivoAuthResultado(
        autorizado: false,
        dispositivo: dispositivo,
        motivo: 'Error inesperado validando dispositivo',
      );
    }
  }

  static Future<bool> usuarioTieneDispositivosAutorizados({
    required String email,
  }) async {
    try {
      final data = await supabase
          .from(_tabla)
          .select('id')
          .eq('email', email)
          .eq('activo', true)
          .limit(1);

      return data.isNotEmpty;
    } catch (_) {
      return false;
    }
  }

  static Future<bool> autorizarDispositivoActual({
    required String email,
  }) async {
    final dispositivo = await obtenerDispositivoActual();

    try {
      var existente = await supabase
          .from(_tabla)
          .select('id')
          .eq('email', email)
          .eq('dispositivo_id', dispositivo.id)
          .maybeSingle();

      if (existente == null &&
          dispositivo.legacyId != null &&
          dispositivo.legacyId!.isNotEmpty) {
        existente = await supabase
            .from(_tabla)
            .select('id')
            .eq('email', email)
            .eq('dispositivo_id', dispositivo.legacyId!)
            .maybeSingle();
      }

      if (existente != null) {
        await supabase
            .from(_tabla)
            .update({
              'dispositivo_id': dispositivo.id,
              'dispositivo_modelo': dispositivo.modelo,
              'plataforma': dispositivo.plataforma,
              'activo': true,
            })
            .eq('id', existente['id']);
      } else {
        await supabase.from(_tabla).insert({
          'email': email,
          'dispositivo_id': dispositivo.id,
          'dispositivo_modelo': dispositivo.modelo,
          'plataforma': dispositivo.plataforma,
          'activo': true,
          'created_at': _fechaHoraLocalIsoSinZona(),
        });
      }
      return true;
    } catch (_) {
      return false;
    }
  }
}
