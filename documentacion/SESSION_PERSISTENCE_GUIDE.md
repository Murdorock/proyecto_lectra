# Guía de Persistencia de Sesión - LECTRA

## Cambios Implementados (v2.2.1)

### 1. Configuración de Supabase (main.dart)
Se ha configurado Supabase para mantener la sesión activa de manera persistente:

```dart
await Supabase.initialize(
  url: SupabaseConfig.supabaseUrl,
  anonKey: SupabaseConfig.supabaseAnonKey,
  authOptions: const FlutterAuthClientOptions(
    authFlowType: AuthFlowType.pkce,
    autoRefreshToken: true,  // Refresca automáticamente el token
  ),
);
```

### 2. Gestión Inteligente de Navegación Inicial
La aplicación ahora verifica automáticamente si existe una sesión activa al iniciar:

- **Sesión activa** → Redirige automáticamente a `HomeScreen`
- **Sin sesión** → Muestra `LoginScreen`

### 3. Cierre de Sesión Manual
La sesión **SOLO** se cierra cuando el usuario presiona el botón "Cerrar sesión" en el `HomeScreen`.

## Comportamiento Esperado

### ✅ La sesión SE MANTIENE cuando:
- La aplicación se cierra y se vuelve a abrir
- El dispositivo cambia de red WiFi
- El dispositivo cambia de datos móviles a WiFi (o viceversa)
- Hay pérdida temporal de conexión a Internet
- El dispositivo se reinicia
- Pasan días o semanas sin usar la app

### ❌ La sesión SE CIERRA cuando:
- El usuario presiona el botón de "Cerrar sesión" manualmente
- Se desinstala la aplicación
- Se borran los datos de la aplicación desde configuración del sistema

## Configuración Adicional en Supabase (Dashboard)

Para asegurar la persistencia completa, verifica estas configuraciones en tu dashboard de Supabase:

### Authentication Settings

1. **JWT Expiry**: Recomendado `31536000` (1 año en segundos)
   - Ruta: `Authentication > Settings > JWT Expiry`

2. **Refresh Token Rotation**: Habilitado
   - Ruta: `Authentication > Settings > Security`

3. **Session Timeout**: Deshabilitado o valor muy alto
   - Esto evita que la sesión expire por inactividad

### Ejemplo de configuración SQL (si necesitas ajustar desde SQL):

```sql
-- Configurar tiempo de expiración del token (1 año)
ALTER DATABASE postgres SET "app.jwt_exp" = 31536000;

-- Verificar configuración actual
SHOW "app.jwt_exp";
```

## Notas Técnicas

### Auto Refresh Token
El parámetro `autoRefreshToken: true` hace que el SDK de Supabase:
- Monitoree automáticamente la expiración del token
- Refresque el token antes de que expire
- Maneje errores de red sin cerrar la sesión
- Guarde el token actualizado en el almacenamiento local

### Almacenamiento de Sesión
Flutter usa `SharedPreferences` (Android) para almacenar:
- Access Token
- Refresh Token
- Session metadata

Este almacenamiento persiste incluso cuando:
- La app se cierra
- El dispositivo se apaga
- Cambia la conectividad

## Resolución de Problemas

### Si la sesión sigue cerrándose:

1. **Verificar versión de supabase_flutter**:
   ```yaml
   dependencies:
     supabase_flutter: ^2.5.0  # O superior
   ```

2. **Limpiar caché y reconstruir**:
   ```bash
   flutter clean
   flutter pub get
   flutter run
   ```

3. **Verificar logs de Supabase**:
   - Dashboard > Logs > Auth logs
   - Buscar errores de token refresh

4. **Verificar configuración de red**:
   - Algunos firewalls corporativos bloquean WebSocket
   - Probar con datos móviles para descartar problemas de WiFi

### Debug Mode
Para ver logs de autenticación en desarrollo, puedes agregar:

```dart
// En main.dart, después de Supabase.initialize()
supabase.auth.onAuthStateChange.listen((data) {
  print('Auth State Changed: ${data.event}');
  print('Session: ${data.session?.user.email}');
});
```

## Mejoras Futuras (Opcionales)

### 1. Manejo de Errores de Red
Agregar un interceptor para manejar errores de red sin afectar la sesión:

```dart
// Ejemplo de manejo robusto
try {
  final response = await supabase.from('tabla').select();
} on SocketException {
  // Error de red, pero la sesión persiste
  showSnackBar('Sin conexión. Reintentando...');
} catch (e) {
  // Otros errores
  print('Error: $e');
}
```

### 2. Indicador de Estado de Conexión
Mostrar en la UI cuando hay problemas de red pero la sesión sigue activa.

### 3. Sincronización Offline
Implementar caché local para operaciones que fallan por red.

## Resumen de Cambios en el Código

| Archivo | Cambio | Propósito |
|---------|--------|-----------|
| `main.dart` | Agregado `autoRefreshToken: true` | Mantener sesión activa automáticamente |
| `main.dart` | Convertido a StatefulWidget | Verificar sesión al iniciar |
| `main.dart` | Agregado `_getInitialScreen()` | Navegar automáticamente según sesión |
| `pubspec.yaml` | Versión 2.2.1+10 | Nueva versión con persistencia mejorada |
| `login_screen.dart` | Actualizada versión UI | Mostrar versión correcta |

## Conclusión

Con estos cambios, la sesión del usuario permanecerá activa indefinidamente hasta que el usuario decida cerrarla manualmente. El sistema es robusto ante cambios de red, pérdida temporal de conexión, y cierres de aplicación.

**Versión de implementación**: 2.2.1  
**Fecha**: 30 de noviembre de 2025  
**Desarrollador**: Diego M.
