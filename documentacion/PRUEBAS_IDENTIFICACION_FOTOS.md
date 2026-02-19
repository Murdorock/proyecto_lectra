# 🧪 GUÍA DE PRUEBAS - Sistema de Identificación de Fotos

## ✅ Checklist de Pruebas

### Prueba 1: Captura Básica de Fotos
**Objetivo:** Verificar que las fotos se guardan con nombres únicos por instalación

**Pasos:**
1. [ ] Abrir pantalla "Editar Inconsistencia Offline" para instalación **A001**
2. [ ] Capturar foto principal
   - Verificar mensaje: "✅ Foto guardada: A001_foto_..."
   - Revisar logs para: `📷 Foto guardada con identificación`
3. [ ] Capturar foto 1
   - Verificar: "A001_foto1_..."
4. [ ] Capturar foto 2
   - Verificar: "A001_foto2_..."
5. [ ] Guardar cambios
   - Verificar que se guardan las rutas y metadata

**Resultado esperado:** ✅
```
A001_foto_2026-01-20_14-30-00_1705759000000.jpg
A001_foto1_2026-01-20_14-30-10_1705759010000.jpg
A001_foto2_2026-01-20_14-30-20_1705759020000000.jpg
```

---

### Prueba 2: No Conflicto Entre Instalaciones
**Objetivo:** Verificar que fotos de diferentes instalaciones no se mezclan

**Pasos:**
1. [ ] Abrir inconsistencia para instalación **A001**
   - Capturar foto
   - Guardar
2. [ ] Abrir inconsistencia para instalación **B002**
   - Capturar foto DIFERENTE
   - Guardar
3. [ ] Volver a abrir **A001**
   - Verificar que carga la foto ORIGINAL (no la de B002)
   - Verificar logs: `✅ Foto principal cargada: ...A001_foto_...`
4. [ ] Volver a abrir **B002**
   - Verificar que carga la foto CORRECTA (no la de A001)
   - Verificar logs: `✅ Foto principal cargada: ...B002_foto_...`

**Resultado esperado:** ✅
- A001 siempre muestra la foto de A001
- B002 siempre muestra la foto de B002
- Sin conflictos ni confusiones

---

### Prueba 3: Validación en PDF
**Objetivo:** Verificar que las fotos son validadas antes de generar PDF

**Pasos:**
1. [ ] Abrir inconsistencia para instalación **A001**
2. [ ] Llenar todos los campos obligatorios
3. [ ] Generar PDF
4. [ ] Revisar logs antes de generar:
   ```
   ✅ Foto principal validada para instalación: A001
      Metadata: A001_foto_2026-01-20_14-30-00_1705759000000.jpg
   ```
5. [ ] Verificar que PDF se generó correctamente

**Resultado esperado:** ✅
- Logs muestran validación exitosa
- PDF contiene la foto correcta
- Se menciona el nombre de archivo en logs

---

### Prueba 4: Múltiples Fotos Misma Instalación
**Objetivo:** Verificar que se usa la foto más reciente

**Pasos:**
1. [ ] Abrir inconsistencia **A001**
2. [ ] Capturar foto principal (FOTO V1)
   - Guardar
3. [ ] Volver a editar **A001**
4. [ ] Capturar foto principal nuevamente (FOTO V2, diferente)
   - Guardar
5. [ ] Volver a editar **A001**
   - Verificar que carga FOTO V2 (la más reciente)
   - Revisar logs: debe cargar el archivo más reciente

**Resultado esperado:** ✅
```
Archivos en /fotos_offline/:
- A001_foto_2026-01-20_14-30-00_1705759000000.jpg (V1 - antiguo)
- A001_foto_2026-01-20_14-35-00_1705759300000.jpg (V2 - nuevo) ← CARGA ESTE
```

---

### Prueba 5: Persistencia de Datos
**Objetivo:** Verificar que metadata se guarda y restaura correctamente

**Pasos:**
1. [ ] Abrir inconsistencia **A001**
2. [ ] Capturar foto y guardar
3. [ ] Cerrar la app completamente
4. [ ] Abrir la app nuevamente
5. [ ] Navegar a **A001** nuevamente
   - Verificar que la foto sigue cargada
   - Verificar logs de carga

**Resultado esperado:** ✅
- Foto persiste después de cerrar app
- Metadata se recupera correctamente

---

### Prueba 6: Logs de Auditoría
**Objetivo:** Verificar que se generan logs suficientes para auditoría

**Acciones durante pruebas:**
- [ ] Capturar foto
- [ ] Guardar cambios
- [ ] Generar PDF

**Buscar en logs:**
```
💾 Foto guardada en: ...
📋 Metadata: ...
📷 Foto guardada con identificación: ...
✅ Foto ... validada para instalación: ...
```

**Resultado esperado:** ✅
- Al menos 4 líneas de log por foto
- Cada acción deja rastro claro
- Posible auditar qué pasó en cada momento

---

## 📱 Cómo Revisar Logs

### En Android Studio
```bash
# Terminal en Android Studio
adb logcat | grep "Foto\|Validada\|Metadata"

# O filtrar por app
adb logcat com.lectra.app:V *:S
```

### En VS Code (si está configurado)
```bash
# En terminal Flutter
flutter logs
```

### En Xcode (si es iOS)
- Device > View Device Logs
- Filtrar por "Foto" o "Metadata"

---

## 🐛 Debugging Tips

### Si las fotos se mezclan:
1. Verificar nombre del archivo en directorio:
   ```
   /data/data/com.lectra.app/app_documents/fotos_offline/
   ```
2. Buscar en logs: `Metadata:`
3. Verificar que instalación está en el nombre

### Si no carga la foto:
1. Buscar error: `Error cargando foto`
2. Verificar que archivo existe con `ls`
3. Revisar permisos de directorio

### Si validación falla en PDF:
1. Buscar: `ADVERTENCIA: Foto NO pertenece`
2. Comparar nombre del archivo vs nombre de instalación
3. Verificar que metadata coincide

---

## ✨ Test Completo Automático (Pseudocódigo)

```
PARA CADA instalación EN [A001, A002, B001, B002]:
  ABRIR inconsistencia
  CAPTURAR foto
  GUARDAR cambios
  
  ABRIR misma inconsistencia
  VERIFICAR que carga la foto CORRECTA
  
  GENERAR PDF
  VERIFICAR logs de validación
  
  REVISAR archivo PDF contiene foto correcta

RESULTADO: ✅ EXITOSO si todas las verificaciones pasan
```

---

## 📊 Métricas de Éxito

| Métrica | Umbral | Cómo Medir |
|---------|--------|-----------|
| **Unicidad de nombres** | 100% | Verificar que no hay duplicados |
| **Identificación correcta** | 100% | Instancia A siempre usa fotos de A |
| **Trazabilidad** | 100% | Todos los archivos tienen instalación en nombre |
| **Validación en PDF** | 100% | Todos los PDFs validan fotos |
| **Logs detallados** | 4+ por foto | Contar líneas de log por operación |

---

## 🎉 Una Vez Que Todo Funcione

1. [ ] Documentar cualquier caso especial encontrado
2. [ ] Probar con usuarios reales en el campo
3. [ ] Monitorear logs en producción por 1-2 semanas
4. [ ] Implementar limpieza automática de fotos antiguas (opcional)
5. [ ] Considerar compresión de fotos si es necesario

---

## 📝 Notas

- Todas las pruebas deben tener conexión offline (sin red)
- Los timestamps son críticos para la unicidad
- La metadata es el componente más importante para la trazabilidad
