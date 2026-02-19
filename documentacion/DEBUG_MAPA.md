# 🗺️ DEBUG - Mapa Estático en PDF

## Verificar descarga del mapa

Cuando guardes cambios en una inconsistencia con geolocalización, verás mensajes en la consola:

```
📍 Descargando mapa para coordenadas: 6.244747, -75.574828
🌍 Intentando con Google Maps...
✅ Mapa descargado desde Google Maps (12345 bytes)
```

O si Google Maps falla:

```
📍 Descargando mapa para coordenadas: 6.244747, -75.574828
🌍 Intentando con Google Maps...
❌ Google Maps falló: TimeoutException...
🗺️ Intentando con OpenStreetMap Export...
✅ Mapa descargado desde OSM (23456 bytes)
```

## Servicios utilizados (en orden de prioridad):

### 1. Google Maps Static API
- **URL**: `https://maps.googleapis.com/maps/api/staticmap`
- **Ventaja**: Mejor calidad, más detalles
- **Desventaja**: Puede requerir API key para uso intensivo
- **Funciona**: ✅ En la mayoría de casos sin API key

### 2. OpenStreetMap Export
- **URL**: `https://render.openstreetmap.org/cgi-bin/export`
- **Ventaja**: Completamente gratuito, sin límites
- **Desventaja**: Puede ser más lento
- **Funciona**: ✅ Siempre disponible

## Solución si el mapa no aparece:

### Opción A: Usar API Key de Google Maps (Recomendado)

1. Obtén una API key gratuita:
   - Ve a: https://console.cloud.google.com/
   - Crea un proyecto
   - Habilita "Maps Static API"
   - Crea credenciales (API Key)
   - Copia la key

2. En el código, reemplaza en `editar_inconsistencia_screen.dart` línea ~1185:
   ```dart
   final googleUrl = 'https://maps.googleapis.com/maps/api/staticmap?center=$lat,$lon&zoom=17&size=600x400&markers=color:red%7Clabel:●%7C$lat,$lon&maptype=roadmap&key=TU_API_KEY_AQUI';
   ```

### Opción B: Usar MapBox (Alternativa)

1. Crea cuenta gratuita en: https://www.mapbox.com/
2. Obtén tu token de acceso
3. Descomenta y configura en el código:
   ```dart
   final mapboxUrl = 'https://api.mapbox.com/styles/v1/mapbox/streets-v11/static/pin-s+ff0000($lon,$lat)/$lon,$lat,15,0/600x400?access_token=TU_TOKEN_AQUI';
   ```

### Opción C: Verificar conectividad

Si ningún servicio funciona, verifica:
- ✅ El dispositivo tiene conexión a internet
- ✅ No hay firewall bloqueando las URLs
- ✅ Las coordenadas son válidas (formato: "lat, lon")

## Formato esperado de coordenadas:

✅ Correcto:
- `6.244747, -75.574828`
- `6.244747 -75.574828`
- `6.244747,-75.574828`

❌ Incorrecto:
- `Lat: 6.244747, Lon: -75.574828`
- `(6.244747, -75.574828)`
- Vacío o nulo

## Probar manualmente:

Puedes probar las URLs directamente en el navegador:

**Google Maps:**
```
https://maps.googleapis.com/maps/api/staticmap?center=6.244747,-75.574828&zoom=17&size=600x400&markers=color:red%7Clabel:●%7C6.244747,-75.574828&maptype=roadmap
```

**OpenStreetMap:**
```
https://render.openstreetmap.org/cgi-bin/export?bbox=-75.579828,6.239747,-75.569828,6.249747&scale=8000&format=png
```

Si alguna URL abre un mapa en el navegador, significa que el servicio está funcionando.

## Tamaño del mapa en el PDF:

- **Descarga**: 600x400 pixels
- **Zoom**: Nivel 17 (vista de calle detallada)
- **En PDF**: 300px de altura
- **Marcador**: Punto rojo en la ubicación exacta

## Logs útiles:

Revisa la consola al guardar cambios para ver:
- ✅ Si se intentó descargar el mapa
- ✅ Qué servicio funcionó o falló
- ✅ Tamaño del archivo descargado
- ❌ Mensajes de error si algo falló

---

**Última actualización**: 11 de noviembre de 2025
