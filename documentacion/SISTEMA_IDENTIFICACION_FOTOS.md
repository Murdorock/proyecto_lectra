# Sistema de Identificación de Fotos por Instalación

## Problema Original
Las fotos tomadas para diferentes instalaciones se estaban mezclando al generar PDFs, causando que a veces se usara una foto incorrecta para una instalación específica.

## Solución Implementada

### 1. **Nombramiento Único de Archivos**
Cada foto ahora se guarda con un nombre que identifica inequívocamente a qué instalación pertenece:

```
FORMAT: {instalacion}_{tipo}_{fecha_hora}_{timestamp}.jpg

EJEMPLO: 
- 12345_foto_2026-01-20_14-35-42_1705759542000.jpg
- 12345_foto1_2026-01-20_14-35-50_1705759550000.jpg
- 12345_foto2_2026-01-20_14-35-58_1705759558000.jpg
```

**Componentes:**
- `instalacion`: ID de la instalación (ej: 12345)
- `tipo`: Tipo de foto (foto, foto1, foto2)
- `fecha_hora`: Fecha y hora exacta de captura
- `timestamp`: Milisegundos desde epoch para garantizar unicidad

### 2. **Almacenamiento en Directorio Dedicado**
- **Ruta:** `/data/data/com.lectra.app/app_documents/fotos_offline/`
- Todas las fotos se guardan en un único directorio centralizado
- Se evita mezcla de fotos de diferentes instalaciones

### 3. **Metadata de Fotos**
Se almacena metadata en dos lugares para garantizar trazabilidad:

```dart
// En memoria (durante la edición)
Map<String, String> _fotoMetadata = {
  'foto': '12345_foto_2026-01-20_14-35-42_1705759542000.jpg',
  'foto1': '12345_foto1_2026-01-20_14-35-50_1705759550000.jpg',
  'foto2': '12345_foto2_2026-01-20_14-35-58_1705759558000.jpg',
};

// En OfflineSyncService (persistencia)
all[idx]['foto_metadata'] = '12345_foto_2026-01-20_14-35-42_1705759542000.jpg';
all[idx]['foto1_metadata'] = '12345_foto1_2026-01-20_14-35-50_1705759550000.jpg';
all[idx]['foto2_metadata'] = '12345_foto2_2026-01-20_14-35-58_1705759558000.jpg';
```

### 4. **Carga de Fotos por Instalación**
Cuando se abre un registro para edición, el sistema busca SOLO las fotos que pertenecen a esa instalación:

```dart
// Busca archivos que contengan el nombre de la instalación
final files = fotosDir
    .listSync()
    .whereType<File>()
    .where((f) => f.path.contains('${instalacion}_$tipo'))
    .toList();

// Toma la más reciente si hay varias
files.sort((a, b) => b.statSync().modified.compareTo(a.statSync().modified));
```

### 5. **Validación en PDF**
Al generar el PDF, se valida que cada foto realmente pertenece a la instalación:

```dart
// Validar que la foto pertenece a esta instalación
final fotoMetadata = _fotoMetadata['foto'] ?? '';
if (fotoMetadata.contains(instalacion)) {
  // Usar la foto
  print('✅ Foto principal validada para instalación: $instalacion');
} else {
  print('⚠️ ADVERTENCIA: Foto NO pertenece a instalación $instalacion');
}
```

## Flujo Completo

### Captura de Foto
1. Usuario toma foto desde cámara o galería
2. Sistema genera nombre único con instalación + timestamp
3. Foto se guarda en `/fotos_offline/` con nombre identificable
4. Metadata se guarda en `_fotoMetadata`
5. Al guardar cambios, metadata se persiste en `OfflineSyncService`

### Carga de Foto
1. Se abre registro de inconsistencia
2. Sistema busca fotos en `/fotos_offline/` que contengan el ID de instalación
3. Toma la más reciente por tipo (foto, foto1, foto2)
4. Carga metadata para trazabilidad

### Generación de PDF
1. Se valida que CADA foto pertenece a la instalación actual
2. Se imprime en logs la validación realizada
3. Se genera PDF solo con fotos correctas
4. Se registra en logs qué fotos se usaron

## Logs Generados

```
📷 Foto guardada con identificación: 12345_foto_2026-01-20_14-35-42_1705759542000.jpg
💾 Foto guardada en: /data/.../fotos_offline/12345_foto_2026-01-20_14-35-42_1705759542000.jpg
📋 Metadata: 12345_foto_2026-01-20_14-35-42_1705759542000.jpg

✅ Foto principal validada para instalación: 12345
   Metadata: 12345_foto_2026-01-20_14-35-42_1705759542000.jpg
```

## Beneficios

✅ **Identificación clara**: Cada foto tiene identificador único por instalación  
✅ **Sin mezcla de fotos**: Imposible confundir fotos de diferentes instalaciones  
✅ **Trazabilidad**: Logs detallados de qué foto se usó para qué PDF  
✅ **Persistencia**: Metadata se guarda para reconstruir el historial  
✅ **Tolerancia a errores**: Sistema valida antes de usar en PDF  

## Cambios en Base de Datos

Se agregaron dos campos nuevos a la tabla de inconsistencias:
- `foto_metadata`: Metadata de identificación de foto principal
- `foto1_metadata`: Metadata de identificación de foto 1
- `foto2_metadata`: Metadata de identificación de foto 2

(Opcional: También se pueden agregar en `observacion_adicional_real` y `correcciones_en_sistema`)

## Testing

Para verificar que funciona correctamente:

1. **Tomar múltiples fotos**
   - Tomar foto para instalación A
   - Tomar foto para instalación B
   - Tomar foto nuevamente para instalación A

2. **Verificar nombres en directorio**
   ```
   /fotos_offline/
   ├── A_foto_2026-01-20_14-30-00_1705759000000.jpg
   ├── B_foto_2026-01-20_14-31-00_1705759060000.jpg
   └── A_foto_2026-01-20_14-32-00_1705759120000.jpg
   ```

3. **Generar PDFs**
   - Generar PDF para instalación A → Usar foto de A
   - Generar PDF para instalación B → Usar foto de B
   - Generar PDF para instalación A (nuevamente) → Usar foto correcta de A

4. **Revisar logs**
   - Buscar "✅ Foto ... validada para instalación"
   - Verificar que la instalación coincide con la esperada
