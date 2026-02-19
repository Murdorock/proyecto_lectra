# DOCUMENTACIÓN TÉCNICA - LECTRA
## Aplicación de Monitoreo Operativo para Kiosco de Aplicaciones

**Versión:** 2.2.1  
**Fecha:** Diciembre 2025  
**Desarrollador:** Diego M.

---

## ÍNDICE
1. [Resumen Ejecutivo](#resumen-ejecutivo)
2. [Seguridad Digital (RN-160)](#seguridad-digital-rn-160)
3. [Repositorios Electrónicos (RN-211)](#repositorios-electrónicos-rn-211)
4. [Condiciones Contractuales](#condiciones-contractuales)
5. [Arquitectura Técnica](#arquitectura-técnica)
6. [Plan de Pruebas y Validación](#plan-de-pruebas-y-validación)

---

## RESUMEN EJECUTIVO

**LECTRA** es una aplicación móvil empresarial desarrollada en Flutter para la gestión integral de operaciones de campo, enfocada en:
- Reportes de lectura de medidores
- Control de descargas y programaciones
- Gestión de inconsistencias y errores
- Generación de documentos PDF con firmas digitales
- Trazabilidad completa de operaciones

**Plataforma:** Android (Android 5.0+)  
**Stack Tecnológico:** Flutter 3.x, Supabase (PostgreSQL + Storage)  
**Tipo de Despliegue:** Aplicación nativa Android (APK)

---

## SEGURIDAD DIGITAL (RN-160)

### 1. Autenticación Robusta

#### 1.1 Sistema de Autenticación Implementado
**Proveedor:** Supabase Authentication (basado en PostgreSQL + GoTrue)

**Características:**
- ✅ **Autenticación por correo electrónico y contraseña**
- ✅ **Validación de formato de email con expresiones regulares**
- ✅ **Cifrado de contraseñas con bcrypt (algoritmo de hashing)**
- ✅ **Tokens JWT (JSON Web Tokens) con firma HMAC-SHA256**
- ✅ **Flujo de autenticación PKCE (Proof Key for Code Exchange)**
- ✅ **Refresh tokens automáticos para renovación de sesión**
- ✅ **Detección automática de sesiones expiradas**

#### 1.2 Código de Implementación
```dart
// Configuración de autenticación (lib/main.dart)
await Supabase.initialize(
  url: SupabaseConfig.supabaseUrl,
  anonKey: SupabaseConfig.supabaseAnonKey,
  authOptions: const FlutterAuthClientOptions(
    authFlowType: AuthFlowType.pkce,  // PKCE para mayor seguridad
    autoRefreshToken: true,            // Renovación automática
  ),
);

// Validación de sesión antes de operaciones críticas
final sessionValid = await UserSession().ensureSessionValid();
if (!sessionValid) {
  // Redirigir a login automáticamente
  Navigator.of(context).pushReplacementNamed('/login');
}
```

#### 1.3 Multi-Factor Authentication (MFA)

**Estado actual:** NO implementado en la versión 2.2.1

**Justificación técnica:**
- La aplicación opera en un entorno empresarial controlado
- Los usuarios son empleados verificados con credenciales corporativas
- La autenticación está vinculada a la tabla `perfiles` con validación de roles

**Propuesta de implementación (si es requerido):**

```dart
// Opción 1: MFA vía código OTP por SMS/Email (Supabase soporta esto)
await supabase.auth.signInWithPassword(
  email: email,
  password: password,
);
// Luego solicitar código MFA
await supabase.auth.verifyOtp(
  email: email,
  token: otpCode,
  type: OtpType.sms,
);

// Opción 2: Integración con Google Authenticator (TOTP)
// Requiere configuración adicional en Supabase
```

**Tiempo de implementación estimado:** 2-3 semanas  
**Dependencias:** Configuración en panel de Supabase + actualización de la app

### 2. Cifrado de Datos

#### 2.1 Cifrado en Tránsito
- ✅ **HTTPS/TLS 1.3** para todas las comunicaciones con Supabase
- ✅ Endpoint: `https://txeuzsypnwesscganktp.supabase.co`
- ✅ Certificados SSL/TLS administrados por Supabase (Let's Encrypt)

#### 2.2 Cifrado en Reposo
- ✅ **Base de datos PostgreSQL cifrada** (AES-256) en Supabase
- ✅ **Storage cifrado** para archivos (PDFs, fotos, firmas)
- ✅ Backups automáticos cifrados

#### 2.3 Cifrado Local (Dispositivo)
- ⚠️ **Sesión en memoria** (no persistente en disco sin cifrar)
- ⚠️ **SharedPreferences sin cifrado** (si se usa)

**Recomendación de mejora:**
```dart
// Implementar flutter_secure_storage para credenciales
final storage = FlutterSecureStorage();
await storage.write(key: 'session_token', value: token);
```

### 3. Trazabilidad Completa

#### 3.1 Registro de Auditoría Implementado

**Tablas con trazabilidad:**
- ✅ `perfiles`: Gestión de usuarios (email, rol, codigo_sup_aux)
- ✅ `programacion_lectura`: Registro de lecturas con timestamp
- ✅ `refutar_errores`: Errores reportados con usuario y fecha
- ✅ `llegadas_tarde`: PDFs generados con firmas y cédulas
- ✅ `inconsistencias`: Cambios registrados con `fecha_revision`
- ✅ `control_descargas`: Descargas por usuario y fecha

**Información rastreada:**
```sql
-- Ejemplo de trazabilidad en tabla llegadas_tarde
CREATE TABLE llegadas_tarde (
  id SERIAL PRIMARY KEY,
  codigo_lector VARCHAR,
  codigo_supervisor VARCHAR,  -- Quién registró
  fecha_registro DATE,         -- Cuándo
  hora_registro TIME,          -- Hora exacta
  motivo TEXT,                 -- Qué pasó
  firma_funcionario BYTEA,     -- Evidencia digital
  firma_supervisor BYTEA,      -- Validación
  pdf_url TEXT                 -- Documento generado
);
```

#### 3.2 Logs de Aplicación

**Implementado:**
- ✅ Excepciones capturadas en bloques try-catch
- ✅ Mensajes de error mostrados al usuario (SnackBar)

**No implementado:**
- ❌ Sistema de logging centralizado (Sentry, Firebase Crashlytics)
- ❌ Analytics de uso

**Propuesta de mejora:**
```dart
// Integrar Sentry para trazabilidad avanzada
import 'package:sentry_flutter/sentry_flutter.dart';

await SentryFlutter.init(
  (options) => options.dsn = 'YOUR_DSN',
  appRunner: () => runApp(LectraApp()),
);
```

### 4. Control de Acceso Basado en Roles (RBAC)

```dart
// Roles implementados
enum UserRole {
  LECTOR,      // Acceso limitado
  SUPERVISOR,  // Acceso completo
}

// Ejemplo de control de acceso en home_screen.dart
List<Widget> _getMenuButtons(BuildContext context) {
  if (_userRole.toUpperCase() == 'LECTOR') {
    return lectorButtons;  // 7 botones
  } else {
    return supervisorButtons;  // 13 botones
  }
}
```

### 5. Gestión de Sesiones

- ✅ **Timeout automático** cuando Supabase invalida el token
- ✅ **Listener de estado de autenticación** que detecta cierre de sesión
- ✅ **Validación de sesión** antes de operaciones críticas
- ✅ **Cierre manual** con confirmación del usuario

```dart
// Listener implementado en main.dart
supabase.auth.onAuthStateChange.listen((data) {
  if (data.event == AuthChangeEvent.signedOut) {
    UserSession().clear();
    navigatorKey.currentState?.pushReplacementNamed('/login');
  }
});
```

---

## REPOSITORIOS ELECTRÓNICOS (RN-211)

### 1. Almacenamiento de Datos

#### 1.1 Base de Datos
**Proveedor:** Supabase (PostgreSQL 15)  
**Ubicación:** AWS us-east-1 (Virginia, USA)  
**Tipo:** Cloud Database (SaaS)

**Tablas principales:**
- `perfiles` - Usuarios del sistema
- `programacion_lectura` - Lecturas programadas
- `refutar_errores` - Errores reportados
- `llegadas_tarde` - Registros de tardanza
- `inconsistencias` - Gestión de inconsistencias
- `control_descargas` - Control de descargas
- `personal` - Información de empleados

#### 1.2 Almacenamiento de Archivos (Storage)
**Bucket:** `cold` (configurado en Supabase Storage)

**Estructura de carpetas:**
```
cold/
├── actualizaciones/          # APKs de la app
├── llegadas_tarde/           # PDFs de tardanzas
│   └── {codigo_lector}/
│       └── {cedula}_{codigo}_{fecha}_{hora}.pdf
├── inconsistencias/
│   ├── fotos/                # Fotos de evidencia
│   │   └── {instalacion}_foto_{timestamp}.jpg
│   └── pdfs/                 # PDFs generados
│       └── {fecha}_{correria}_{instalacion}_{codigo}_{tipo}.pdf
└── refutar_errores/          # Evidencias de errores
    └── {codigo_sup_aux}/
        └── evidencia{n}_{timestamp}.jpg
```

**Características:**
- ✅ URLs públicas para descarga (autenticadas)
- ✅ Versionamiento automático de archivos
- ✅ Compresión de imágenes antes de subida
- ✅ Límite de tamaño configurable

### 2. Cumplimiento con Lineamientos Organizacionales

#### 2.1 Repositorios Autorizados

**Estado actual:** ⚠️ **PENDIENTE DE VALIDACIÓN**

La aplicación utiliza **Supabase** como repositorio cloud externo. Para cumplir con RN-211, es necesario confirmar:

**Opción A: Migrar a infraestructura corporativa**
- Desplegar Supabase self-hosted en servidores de la empresa
- Configurar PostgreSQL en infraestructura on-premise
- Ajustar URLs y credenciales en la app

**Opción B: Homologar Supabase como proveedor autorizado**
- Validar contrato de Supabase con políticas de la empresa
- Verificar cumplimiento de GDPR, SOC2, ISO 27001
- Configurar región de datos en país requerido

**Opción C: Migración a Azure/AWS corporativo**
- Reconfigurar backend a Azure SQL Database
- Migrar Storage a Azure Blob Storage o AWS S3
- Tiempo estimado: 4-6 semanas

#### 2.2 Certificaciones de Supabase

Supabase cuenta con:
- ✅ **SOC 2 Type II** certificado
- ✅ **GDPR** compliant
- ✅ **ISO 27001** en proceso
- ✅ **HIPAA** compatible (con plan Enterprise)
- ✅ Backups diarios automáticos
- ✅ Cifrado AES-256 en reposo

### 3. Política de Retención de Datos

**Configuración recomendada:**
```sql
-- Retención de logs por 90 días
DELETE FROM logs WHERE created_at < NOW() - INTERVAL '90 days';

-- Archivado de PDFs antiguos (1 año)
-- Mover de 'cold' a 'archive' después de 365 días
```

### 4. Backup y Recuperación

**Supabase automático:**
- ✅ Backups diarios (últimos 7 días en plan gratuito)
- ✅ Point-in-time recovery (plan Pro)
- ✅ Replicación en múltiples zonas de disponibilidad

**Recomendación:**
- Implementar backups adicionales a repositorio corporativo
- Exportación semanal de datos críticos a CSV/SQL

---

## CONDICIONES CONTRACTUALES

### 1. Modelo de Soporte Actual

**Desarrollador:** Diego M. (Desarrollador independiente)

**Cobertura actual:**
- ✅ Actualizaciones de funcionalidades
- ✅ Corrección de bugs críticos
- ✅ Soporte vía correo/WhatsApp
- ⚠️ **SLA no formalizado**
- ⚠️ **Horario limitado** (no 24/7)

### 2. Propuesta de Soporte Formal

#### Plan Básico (Recomendado para PYME)
- **Horario:** Lunes a Viernes, 8:00 AM - 6:00 PM
- **Canales:** Email, Ticket System, Teams
- **Tiempo de respuesta:**
  - Crítico (app no funciona): 4 horas
  - Alto (funcionalidad afectada): 24 horas
  - Medio (bug menor): 72 horas
  - Bajo (mejora): Siguiente release

#### Plan Empresarial (Opcional)
- **Horario:** 24/7/365
- **SLA:** 99.5% uptime
- **Soporte:** Telefónico + Email + Chat
- **Tiempo de respuesta:**
  - Crítico: 1 hora
  - Alto: 8 horas
  - Medio: 24 horas

### 3. Plan de Actualizaciones

**Releases mensuales:**
- 1 actualización mayor por trimestre (nuevas funcionalidades)
- 1 actualización menor mensual (bugs, mejoras)
- Parches de seguridad: según sea necesario

**Historial reciente:**
- v2.2.1 (actual): Mejora de gestión de sesiones
- v2.2.0: Integración de contingencia de lectura
- v2.1.0: Sistema de rangos repartida
- v2.0.0: Refactorización completa de autenticación

### 4. Mantenimiento

#### Mantenimiento Correctivo
- Corrección de bugs reportados
- Parches de seguridad
- Actualizaciones de dependencias críticas

#### Mantenimiento Evolutivo
- Nuevas funcionalidades según roadmap
- Mejoras de UX/UI
- Optimización de rendimiento

#### Mantenimiento Preventivo
- Actualización de librerías Flutter
- Migración a nuevas versiones de Android
- Monitoreo de logs de error (si se implementa Sentry)

### 5. Costos Estimados (Referencial)

**Desarrollo y Licencias:**
- Desarrollo inicial: [COMPLETADO]
- Licencia Supabase: $0/mes (Free tier) o $25/mes (Pro)
- Publicación Google Play Store: $25 (pago único)

**Mantenimiento mensual (estimado):**
- Soporte Básico: $XXX/mes
- Actualizaciones incluidas: 2 releases/mes
- Soporte Empresarial: $XXX/mes (si requerido)

**Costos adicionales (si aplica):**
- Migración a infraestructura corporativa: $XXX (una vez)
- Implementación de MFA: $XXX (una vez)
- Integración con SSO corporativo: $XXX (una vez)

---

## ARQUITECTURA TÉCNICA

### 1. Diagrama de Arquitectura

```
┌─────────────────────────────────────────────────────────────┐
│                    USUARIO MÓVIL (Android)                  │
└────────────────────────┬────────────────────────────────────┘
                         │
                         │ HTTPS/TLS 1.3
                         │
┌────────────────────────▼────────────────────────────────────┐
│              LECTRA App (Flutter/Dart)                      │
│  ┌──────────────────────────────────────────────────────┐   │
│  │ Capa de Presentación (Screens)                       │   │
│  │  - login_screen.dart                                 │   │
│  │  - home_screen.dart                                  │   │
│  │  - reporte_totales_lectura_screen.dart               │   │
│  │  - llegadas_tarde_screen.dart                        │   │
│  │  - inconsistencias_screen.dart                       │   │
│  └──────────────────────┬───────────────────────────────┘   │
│                         │                                    │
│  ┌──────────────────────▼───────────────────────────────┐   │
│  │ Capa de Servicios                                    │   │
│  │  - user_session.dart (Gestión de sesión)             │   │
│  │  - supabase_config.dart (Configuración)              │   │
│  └──────────────────────┬───────────────────────────────┘   │
└────────────────────────┬┴───────────────────────────────────┘
                         │
                         │ REST API (JSON)
                         │
┌────────────────────────▼────────────────────────────────────┐
│                   SUPABASE BACKEND                          │
│  ┌─────────────────────────────────────────────────────┐    │
│  │ Supabase Auth (GoTrue)                              │    │
│  │  - JWT Tokens                                       │    │
│  │  - PKCE Flow                                        │    │
│  │  - Session Management                               │    │
│  └─────────────────────────────────────────────────────┘    │
│                                                              │
│  ┌─────────────────────────────────────────────────────┐    │
│  │ PostgreSQL 15 (Base de Datos)                       │    │
│  │  - perfiles, programacion_lectura                   │    │
│  │  - refutar_errores, llegadas_tarde                  │    │
│  │  - inconsistencias, control_descargas               │    │
│  │  - Row Level Security (RLS) activado                │    │
│  └─────────────────────────────────────────────────────┘    │
│                                                              │
│  ┌─────────────────────────────────────────────────────┐    │
│  │ Supabase Storage                                    │    │
│  │  Bucket: cold                                       │    │
│  │  - PDFs (llegadas_tarde, inconsistencias)           │    │
│  │  - Fotos (evidencias, inconsistencias)              │    │
│  │  - APKs (actualizaciones)                           │    │
│  └─────────────────────────────────────────────────────┘    │
└─────────────────────────────────────────────────────────────┘
                         │
                         │ AWS Infrastructure
                         │
┌────────────────────────▼────────────────────────────────────┐
│                    AWS Cloud (us-east-1)                    │
│  - EC2 instances (Supabase)                                 │
│  - RDS PostgreSQL (cifrado AES-256)                         │
│  - S3 Storage (backups)                                     │
│  - CloudFront CDN                                           │
└─────────────────────────────────────────────────────────────┘
```

### 2. Stack Tecnológico Detallado

#### Frontend (Móvil)
- **Framework:** Flutter 3.x (Dart)
- **UI:** Material Design 3
- **Librerías principales:**
  - `supabase_flutter: ^2.5.0` - Cliente de Supabase
  - `pdf: ^3.11.3` - Generación de PDFs
  - `image_picker: ^1.2.0` - Captura de fotos
  - `syncfusion_flutter_signaturepad: ^31.2.5` - Firmas digitales
  - `geolocator: ^11.0.0` - Geolocalización
  - `flutter_map: ^6.1.0` - Mapas
  - `http: ^1.1.0` - Peticiones HTTP

#### Backend (Supabase)
- **Base de datos:** PostgreSQL 15
- **Autenticación:** GoTrue (basado en JWT)
- **Storage:** S3-compatible
- **API:** REST auto-generada (PostgREST)
- **Realtime:** WebSockets (no utilizado actualmente)

#### Seguridad en BD
```sql
-- Row Level Security (RLS) habilitado
ALTER TABLE perfiles ENABLE ROW LEVEL SECURITY;

-- Políticas de acceso
CREATE POLICY "Usuarios ven solo su perfil"
ON perfiles FOR SELECT
USING (auth.uid() = id);
```

### 3. Flujo de Autenticación

```
Usuario Ingresa Credenciales
         │
         ▼
┌──────────────────────┐
│ Validación de Email  │
│ (Regex Frontend)     │
└─────────┬────────────┘
          │
          ▼
┌──────────────────────┐
│ Supabase Auth        │
│ signInWithPassword() │
└─────────┬────────────┘
          │
          ▼
     ┌────────┐
     │ Token  │◄─── JWT firmado con HMAC-SHA256
     │  JWT   │     Expiración: 1 hora
     └────┬───┘     Refresh: 24 horas
          │
          ▼
┌──────────────────────┐
│ Validar en tabla     │
│ 'perfiles'           │
│ (email, rol, código) │
└─────────┬────────────┘
          │
          ▼
┌──────────────────────┐
│ UserSession().       │
│ setUserData()        │
│ (Memoria local)      │
└─────────┬────────────┘
          │
          ▼
┌──────────────────────┐
│ Navigator ->         │
│ HomeScreen           │
└──────────────────────┘
```

### 4. Modelo de Datos (Esquema Simplificado)

```sql
-- Tabla de usuarios
CREATE TABLE perfiles (
  id UUID PRIMARY KEY REFERENCES auth.users,
  email VARCHAR UNIQUE NOT NULL,
  nombre_completo VARCHAR,
  codigo_sup_aux VARCHAR,
  rol VARCHAR CHECK (rol IN ('LECTOR', 'SUPERVISOR')),
  created_at TIMESTAMP DEFAULT NOW()
);

-- Tabla de llegadas tarde (con trazabilidad completa)
CREATE TABLE llegadas_tarde (
  id SERIAL PRIMARY KEY,
  codigo_lector VARCHAR NOT NULL,
  codigo_supervisor VARCHAR NOT NULL,
  fecha_registro DATE NOT NULL,
  hora_registro TIME NOT NULL,
  motivo TEXT,
  firma_funcionario BYTEA,
  firma_supervisor BYTEA,
  cedula_funcionario VARCHAR,
  cedula_supervisor VARCHAR,
  pdf_url TEXT,
  created_at TIMESTAMP DEFAULT NOW()
);

-- Índices para optimización
CREATE INDEX idx_llegadas_tarde_codigo ON llegadas_tarde(codigo_lector);
CREATE INDEX idx_llegadas_tarde_fecha ON llegadas_tarde(fecha_registro);
```

### 5. Seguridad de la API

**Autenticación de requests:**
```dart
// Cada petición incluye el token JWT en el header
headers: {
  'Authorization': 'Bearer ${session.accessToken}',
  'apikey': SupabaseConfig.supabaseAnonKey,
}
```

**Rate Limiting (Supabase):**
- 100 requests/segundo en plan gratuito
- 500 requests/segundo en plan Pro

### 6. Gestión de Errores

```dart
try {
  final data = await supabase.from('tabla').select();
} on PostgrestException catch (e) {
  // Error de base de datos
  print('Error DB: ${e.message}');
} on StorageException catch (e) {
  // Error de almacenamiento
  print('Error Storage: ${e.message}');
} on AuthException catch (e) {
  // Error de autenticación
  if (e.message.contains('Invalid login')) {
    showSnackBar('Credenciales incorrectas');
  }
} catch (e) {
  // Error genérico
  showSnackBar('Error de conexión');
}
```

---

## PLAN DE PRUEBAS Y VALIDACIÓN

### 1. Pruebas de Seguridad Realizadas

#### 1.1 Pruebas de Autenticación
- ✅ Login con credenciales válidas
- ✅ Login con credenciales inválidas
- ✅ Validación de formato de email
- ✅ Manejo de sesión expirada
- ✅ Cierre de sesión manual
- ✅ Prevención de acceso sin autenticación

#### 1.2 Pruebas de Autorización
- ✅ Menú diferenciado por rol (LECTOR vs SUPERVISOR)
- ✅ Restricción de acceso a pantallas según rol
- ✅ Validación de permisos antes de operaciones críticas

#### 1.3 Pruebas de Inyección SQL
- ✅ **Protección nativa de Supabase** (prepared statements)
- ✅ Validación de entrada en campos de texto
- ✅ Escape de caracteres especiales

**Ejemplo de prueba:**
```dart
// Input malicioso
final input = "'; DROP TABLE perfiles; --";
// Supabase lo trata como string literal, no ejecuta SQL
```

### 2. Pruebas Funcionales

#### 2.1 Módulos Probados
- ✅ Login y autenticación
- ✅ Generación de PDF con firmas
- ✅ Carga y visualización de fotos
- ✅ Subida de archivos a Storage
- ✅ Actualización de registros en BD
- ✅ Descarga de actualizaciones de app

#### 2.2 Casos de Uso Críticos
| Caso de Uso | Estado | Notas |
|-------------|--------|-------|
| Usuario se loguea y ve su menú | ✅ | OK |
| Supervisor genera PDF de llegada tarde | ✅ | OK |
| Lector reporta error con foto | ✅ | OK |
| App detecta sesión expirada y redirige | ✅ | Implementado recientemente |
| Usuario descarga actualización de app | ✅ | OK |
| Sincronización offline | ❌ | No implementado |

### 3. Pruebas de Rendimiento

#### 3.1 Métricas Actuales (Estimadas)
- **Tiempo de login:** < 2 segundos (con conexión 4G)
- **Carga de lista (100 registros):** < 1 segundo
- **Generación de PDF:** 2-3 segundos
- **Subida de foto (2MB):** 3-5 segundos (4G)

#### 3.2 Optimizaciones Implementadas
- ✅ Paginación en listas grandes
- ✅ Compresión de imágenes antes de subir
- ✅ Caché de datos en memoria (UserSession)
- ⚠️ No hay caché persistente

### 4. Pruebas de Compatibilidad

#### 4.1 Versiones de Android Soportadas
- ✅ Android 5.0 (Lollipop) - API 21
- ✅ Android 6.0 (Marshmallow) - API 23
- ✅ Android 7.0 (Nougat) - API 24
- ✅ Android 8.0 (Oreo) - API 26
- ✅ Android 9.0 (Pie) - API 28
- ✅ Android 10 - API 29
- ✅ Android 11 - API 30
- ✅ Android 12 - API 31
- ✅ Android 13 - API 33
- ✅ Android 14 - API 34 (última probada)

#### 4.2 Dispositivos Probados
- Samsung Galaxy A Series (A10, A20, A50)
- Xiaomi Redmi Note Series
- Motorola Moto G Series
- Emuladores Android Studio

### 5. Documentación Disponible

#### 5.1 Documentación Técnica
- ✅ `README.md` - Descripción general
- ✅ `MANUAL_USUARIO_LECTRA.md` - Manual de usuario
- ✅ `SESSION_PERSISTENCE_GUIDE.md` - Guía de persistencia de sesión
- ✅ `ICON_SETUP_GUIDE.md` - Configuración de iconos
- ✅ `OPEN_CAMERA_SETUP.md` - Configuración de cámara
- ✅ `DEBUG_MAPA.md` - Debug de mapas

#### 5.2 Documentación Faltante (Propuesta)
- ❌ Diagrama de arquitectura formal (este documento lo incluye)
- ❌ Manual de despliegue
- ❌ Guía de troubleshooting
- ❌ API Reference (si se expone API propia)

### 6. Plan de Pruebas para Seguridad Digital

**Propuesta de validación por equipo de Seguridad:**

#### Fase 1: Análisis Estático (1 semana)
- [ ] Revisión de código fuente (lib/)
- [ ] Análisis de dependencias (pubspec.yaml)
- [ ] Verificación de secrets (no deben estar hardcoded)
- [ ] Escaneo con herramientas SAST (ej: SonarQube)

#### Fase 2: Análisis Dinámico (1 semana)
- [ ] Pruebas de penetración (pentesting)
- [ ] Interceptación de tráfico (Burp Suite, mitmproxy)
- [ ] Análisis de APK (decompilación con apktool)
- [ ] Verificación de certificados SSL

#### Fase 3: Validación de Infraestructura (1 semana)
- [ ] Auditoría de configuración de Supabase
- [ ] Revisión de políticas RLS en PostgreSQL
- [ ] Verificación de backups y recuperación
- [ ] Pruebas de failover

#### Fase 4: Validación de Cumplimiento (1 semana)
- [ ] Checklist RN-160 (Seguridad Digital)
- [ ] Checklist RN-211 (Repositorios Electrónicos)
- [ ] Revisión de contratos con Supabase
- [ ] Evaluación de proveedores (Supabase vs alternativas)

### 7. Herramientas de Testing Propuestas

```yaml
# Agregar a pubspec.yaml
dev_dependencies:
  flutter_test:
    sdk: flutter
  integration_test:
    sdk: flutter
  mockito: ^5.4.0
  bloc_test: ^9.1.0
```

**Ejemplo de test unitario:**
```dart
void main() {
  test('Validación de email funciona correctamente', () {
    expect(isValidEmail('test@empresa.com'), true);
    expect(isValidEmail('invalid'), false);
    expect(isValidEmail(''), false);
  });
  
  test('UserSession guarda datos correctamente', () {
    UserSession().setUserData(
      codigoSupAux: '123',
      nombreCompleto: 'Test User',
      email: 'test@test.com',
    );
    expect(UserSession().codigoSupAux, '123');
    expect(UserSession().hasSession, true);
  });
}
```

---

## RECOMENDACIONES PARA APROBACIÓN

### Acción Inmediata Requerida

1. **Validar Supabase como proveedor autorizado**
   - Revisar contrato con equipo legal
   - Verificar cumplimiento de RN-211
   - Evaluar migración a infraestructura corporativa (si necesario)

2. **Definir SLA de soporte**
   - Formalizar contrato de mantenimiento
   - Establecer tiempos de respuesta
   - Asignar presupuesto

3. **Implementar mejoras de seguridad (si requerido)**
   - MFA (2-3 semanas)
   - Logging centralizado con Sentry (1 semana)
   - Flutter Secure Storage (1 semana)

### Riesgos Identificados

| Riesgo | Probabilidad | Impacto | Mitigación |
|--------|--------------|---------|------------|
| Supabase no cumple RN-211 | Media | Alto | Migrar a Azure/AWS corporativo |
| Desarrollador único (single point of failure) | Alta | Medio | Documentar código + capacitar equipo interno |
| Sin MFA | Baja | Medio | Implementar MFA si es mandatorio |
| Dependencia de servicio externo | Media | Alto | Plan de contingencia + backups locales |

### Timeline de Implementación (si se aprueban mejoras)

**Mes 1:**
- Semana 1-2: Implementación de MFA
- Semana 3-4: Integración de Sentry + logging

**Mes 2:**
- Semana 1-2: Migración a infraestructura corporativa (si aplica)
- Semana 3-4: Pruebas de seguridad por equipo de TI

**Mes 3:**
- Semana 1-2: Correcciones según feedback
- Semana 3-4: Documentación final + capacitación

---

## CONTACTO Y SOPORTE

**Desarrollador:**  
Diego M.  
Email: [TU_EMAIL]  
Teléfono: [TU_TELÉFONO]

**Repositorio de Código:**  
[GitHub/GitLab URL si aplica]

**Versión de este documento:** 1.0  
**Fecha:** Diciembre 2025

---

## ANEXOS

### Anexo A: Certificaciones de Supabase
- [SOC 2 Type II Report](https://supabase.com/security)
- [GDPR Compliance](https://supabase.com/privacy)

### Anexo B: Checklist de Seguridad RN-160

| Requisito | Cumple | Observaciones |
|-----------|--------|---------------|
| Autenticación por usuario único | ✅ | Email + password |
| Contraseñas cifradas | ✅ | Bcrypt |
| Comunicación cifrada (HTTPS) | ✅ | TLS 1.3 |
| Trazabilidad de acciones | ✅ | Logs en BD |
| Control de sesiones | ✅ | JWT + refresh tokens |
| MFA | ❌ | No implementado (puede agregarse) |
| Gestión de permisos por rol | ✅ | LECTOR, SUPERVISOR |
| Auditoría de accesos | ⚠️ | Parcial (en BD, no centralizado) |

### Anexo C: Checklist de Repositorios RN-211

| Requisito | Cumple | Observaciones |
|-----------|--------|---------------|
| Repositorio autorizado | ⚠️ | Pendiente validar Supabase |
| Backups automáticos | ✅ | Diarios (Supabase) |
| Cifrado en reposo | ✅ | AES-256 |
| Política de retención | ⚠️ | No formalizada |
| Ubicación de datos | ⚠️ | AWS us-east-1 (verificar si cumple) |
| Acceso restringido | ✅ | RLS + autenticación |

---

**FIN DEL DOCUMENTO**
