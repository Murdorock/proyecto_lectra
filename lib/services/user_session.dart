import 'package:supabase_flutter/supabase_flutter.dart';

// Servicio para gestionar los datos del usuario logueado
class UserSession {
  static final UserSession _instance = UserSession._internal();
  
  factory UserSession() {
    return _instance;
  }
  
  UserSession._internal();
  
  String? _codigoSupAux;
  String? _nombreCompleto;
  String? _email;
  String? _rol;
  
  // Getters
  String? get codigoSupAux => _codigoSupAux;
  String? get nombreCompleto => _nombreCompleto;
  String? get email => _email;
  String? get rol => _rol;
  
  // Setters
  void setUserData({
    required String codigoSupAux,
    required String nombreCompleto,
    required String email,
    String? rol,
  }) {
    _codigoSupAux = codigoSupAux;
    _nombreCompleto = nombreCompleto;
    _email = email;
    _rol = rol;
  }
  
  // Limpiar datos al cerrar sesión
  void clear() {
    _codigoSupAux = null;
    _nombreCompleto = null;
    _email = null;
    _rol = null;
  }
  
  // Verificar si hay sesión activa sincronizada con Supabase
  bool get hasSession {
    final supabaseSession = Supabase.instance.client.auth.currentSession;
    if (supabaseSession == null) {
      // Si no hay sesión en Supabase, limpiar datos locales
      clear();
      return false;
    }
    return _codigoSupAux != null;
  }
  
  // Verificar y recargar datos del usuario si es necesario
  Future<bool> ensureSessionValid() async {
    try {
      final supabaseSession = Supabase.instance.client.auth.currentSession;
      if (supabaseSession == null) {
        clear();
        return false;
      }
      
      // Si tenemos sesión de Supabase pero no datos locales, recargarlos
      if (_codigoSupAux == null && supabaseSession.user.email != null) {
        final profileData = await Supabase.instance.client
            .from('perfiles')
            .select('email, nombre_completo, codigo_sup_aux, rol')
            .eq('email', supabaseSession.user.email!)
            .maybeSingle();
        
        if (profileData != null) {
          setUserData(
            codigoSupAux: profileData['codigo_sup_aux'] ?? '',
            nombreCompleto: profileData['nombre_completo'] ?? '',
            email: profileData['email'] ?? '',
            rol: profileData['rol'],
          );
          return true;
        }
        return false;
      }
      
      return true;
    } catch (e) {
      clear();
      return false;
    }
  }
}
