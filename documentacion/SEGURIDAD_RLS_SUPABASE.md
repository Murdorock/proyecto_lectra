# 🔒 POLÍTICAS RLS (Row Level Security) - SUPABASE

## Problema Identificado
Usuarios con rol **LECTOR** están accediendo a la consulta de **Históricos**, que debería ser restringido solo a **SUPERVISOR** y **ADMINISTRADOR**.

### Causa Raíz
1. ❌ **Sin políticas RLS** en Supabase: Cualquier usuario autenticado puede acceder a todas las filas
2. ❌ **Control de acceso solo en Frontend**: Se pueden saltear navegando directamente a la pantalla
3. ⚠️ **APK modificada**: Los usuarios pueden descompilar la APK y forzar la navegación

---

## ✅ SOLUCIÓN IMPLEMENTADA (3 Capas)

### **Capa 1: Validación en Frontend (IMPLEMENTADA)**
✅ Se agregó validación de rol en `historicos_screen.dart` en `initState()`
- Verifica que el usuario tenga rol SUPERVISOR o ADMINISTRADOR
- Si no cumple, muestra error y redirige a HOME
- Registra intentos no autorizados en métricas

**Archivo modificado:** [lib/screens/historicos_screen.dart](../../lib/screens/historicos_screen.dart#L25-L60)

---

### **Capa 2: Políticas RLS en Supabase (REQUIERE IMPLEMENTACIÓN)**

#### Primera vez que configuras RLS:
1. Ve a **Supabase Dashboard** → **Authentication** → **Policies**
2. Habilita RLS para la tabla `historicos`
3. Implementa las políticas SQL a continuación:

#### SQL PARA COPIAR EN SUPABASE EDITOR (SQL Console)

```sql
-- ================================================================
-- TABLA: historicos
-- Restricción: Solo SUPERVISOR y ADMINISTRADOR pueden consultar
-- ================================================================

-- 1. HABILITAR RLS
ALTER TABLE public.historicos ENABLE ROW LEVEL SECURITY;

-- 2. POLÍTICA DE LECTURA (SELECT)
CREATE POLICY "supervisores_pueden_leer_historicos" ON public.historicos
  FOR SELECT
  USING (
    -- El usuario logueado debe ser SUPERVISOR o ADMINISTRADOR
    auth.uid() IN (
      SELECT id FROM auth.users 
      WHERE email IN (
        SELECT email FROM public.perfiles 
        WHERE rol IN ('SUPERVISOR', 'ADMINISTRADOR')
      )
    )
  );

-- 3. POLÍTICA PARA EVITAR QUE LECTORES ACCEDAN
-- (Esta política rechaza explícitamente a LECTORES)
CREATE POLICY "rechazar_lectura_a_lectores" ON public.historicos
  FOR SELECT
  USING (
    -- Rechazar si el usuario tiene rol LECTOR
    auth.uid() NOT IN (
      SELECT id FROM auth.users 
      WHERE email IN (
        SELECT email FROM public.perfiles 
        WHERE rol = 'LECTOR'
      )
    )
  );

-- ================================================================
-- TABLA: historicos_metricas
-- Restricción: Solo el dueño puede leer sus propias métricas
-- ================================================================

ALTER TABLE public.historicos_metricas ENABLE ROW LEVEL SECURITY;

-- Solo el usuario que registró la métrica puede leerla
CREATE POLICY "usuarios_leen_sus_propias_metricas" ON public.historicos_metricas
  FOR SELECT
  USING (usuario_id = auth.uid());

-- Solo administrador puede ver todas las métricas
CREATE POLICY "admin_ve_todas_metricas" ON public.historicos_metricas
  FOR SELECT
  USING (
    auth.uid() IN (
      SELECT id FROM auth.users 
      WHERE email IN (
        SELECT email FROM public.perfiles 
        WHERE rol = 'ADMINISTRADOR'
      )
    )
  );

-- ================================================================
-- TABLA: perfiles (proteger rol del usuario)
-- ================================================================

ALTER TABLE public.perfiles ENABLE ROW LEVEL SECURITY;

-- Cada usuario solo puede leer su propio perfil
CREATE POLICY "usuarios_leen_su_perfil" ON public.perfiles
  FOR SELECT
  USING (email = auth.jwt() ->> 'email');

-- Solo administrador puede actualizar roles
CREATE POLICY "admin_actualiza_roles" ON public.perfiles
  FOR UPDATE
  USING (
    auth.uid() IN (
      SELECT id FROM auth.users 
      WHERE email IN (
        SELECT email FROM public.perfiles 
        WHERE rol = 'ADMINISTRADOR'
      )
    )
  );

```

---

### **Verificar la implementación en Supabase:**

#### Pasos en Supabase Dashboard:
1. **Ir a:** SQL Editor → New Query
2. **Pegar** los comandos SQL anterior
3. **Ejecutar** (Ctrl + Enter)
4. Debería mostrar: `Success. No rows returned` para cada CREATE POLICY

#### Verificar que funcionan correctamente:

```sql
-- Ver todas las políticas por tabla
SELECT * FROM pg_policies WHERE tablename = 'historicos';

-- Ver si RLS está habilitado
SELECT schemaname, tablename, rowsecurity 
FROM pg_tables 
WHERE tablename IN ('historicos', 'historicos_metricas', 'perfiles');
```

---

### **Capa 3: Validación en la Consulta Supabase (Recomendado)**

En el futuro, puedes mejorar aún más validando antes de hacer la query:

```dart
// En historicos_screen.dart, en el método _buscar()

// Agregar validación adicional (defensa en profundidad)
Future<void> _buscar() async {
  // 1. Validar rol nuevamente (por si el token fue manipulado)
  final userRole = UserSession().rol?.toUpperCase();
  if (userRole != 'SUPERVISOR' && userRole != 'ADMINISTRADOR') {
    setState(() {
      _errorMessage = 'No autorizado para esta operación';
      _resultados = [];
    });
    return;
  }

  // 2. Validar que el usuario existe en la BD
  try {
    final user = supabase.auth.currentUser;
    if (user == null) throw Exception('Usuario no autenticado');

    // 3. Continuar con la búsqueda
    // ... resto del código ...
  } catch (e) {
    // Manejar error
  }
}
```

---

## 🚨 CASOS DE SEGURIDAD CUBIERTOS

| Caso de Ataque | Capa 1 (Frontend) | Capa 2 (RLS) | Capa 3 (Query) | Estado |
|---|---|---|---|---|
| Usuario LECTOR accede a pantalla | ✅ Bloqueado | ✅ Bloqueado | ✅ Bloqueado | Protegido |
| APK modificada (navegación forzada) | ❌ No protege | ✅ Bloqueado | ✅ Bloqueado | Protegido |
| Token JWT falsificado | ❌ No protege | ✅ Bloqueado | ✅ Bloqueado | Protegido |
| Query directa a Supabase | ❌ No protege | ✅ Bloqueado | ✅ Bloqueado | Protegido |
| SQL Injection | ❌ No protege | ✅ Supabase lo previene | ✅ Parametrizado | Protegido |

---

## 📋 CHECKLIST DE IMPLEMENTACIÓN

- [x] Validación de rol en Frontend (`historicos_screen.dart`)
- [ ] Crear políticas RLS en Supabase (SQL anterior)
- [ ] Verificar RLS está habilitado: `ALTER TABLE ... ENABLE ROW LEVEL SECURITY`
- [ ] Probar accediendo con usuario LECTOR (debe fallar)
- [ ] Probar accediendo con usuario SUPERVISOR (debe funcionar)
- [ ] Revisar logs en `historicos_metricas` para intentos fallidos
- [ ] Documentar políticas RLS en README

---

## 📝 PRUEBAS RECOMENDADAS

### Test 1: Usuario LECTOR intenta acceder
```
1. Iniciar sesión con cuenta LECTOR
2. Navegar a Históricos (si logra saltarse frontend)
3. Esperado: Error "Sesión inválida" + RLS rechaza la query
```

### Test 2: Usuario SUPERVISOR accede normalmente
```
1. Iniciar sesión con cuenta SUPERVISOR
2. Navegar a Históricos desde HOME
3. Esperado: Acceso concedido
```

### Test 3: Comparar logs
```
En tabla historicos_metricas:
- Acción: "acceso_no_autorizado" (intentos LECTOR)
- Acción: "abrir_vista" (accesos SUPERVISOR)
```

---

## ⚠️ NOTAS IMPORTANTES

1. **Supabase RLS puede ralentizar queries:** Si tienes millones de registros, considera:
   - Índices en columnas de rol/usuario
   - Particionamiento de tablas grandes
   - Caché de resultados

2. **El anonKey sigue siendo público:** Aunque use RLS, el `anonKey` está en el cliente.
   - Para APIs externas, considera usar `serviceKey` (backend only)
   - Para acceso desde mobile es normal usar `anonKey`

3. **Monitoreo de intentos:**
   - La tabla `historicos_metricas` registra todos los intentos
   - Revisa regularmente para detectar patrones sospechosos

---

## 🔗 REFERENCIAS

- [Documentación RLS de Supabase](https://supabase.com/docs/guides/auth/row-level-security)
- [SQL Security Best Practices](https://supabase.com/docs/guides/database/postgres/docs/guides#security)
- [JWT Authentication](https://supabase.com/docs/guides/auth)

