# Instrucciones para Configurar el Ícono de LECTRA

## Opción 1: Diseño Recomendado (Más Fácil)

### Concepto del Ícono:
Un diseño profesional que combina:
- 📊 **Medidor circular** (representando medidores de agua, luz y gas)
- ⚡ **Rayo estilizado** (representando "LECTRA" y energía)
- 📄 **Documento/factura** (representando la repartida de facturas)
- 🔵 **Color azul oscuro** (#1A237E) como fondo (tu color corporativo)
- ⚪ **Elementos blancos/amarillos** para contraste

### Pasos para Crear el Ícono:

#### 1. Usar Herramienta en Línea (Recomendado):
   - Ve a: https://www.canva.com (gratis) o https://www.figma.com
   - Crea un diseño de 1024x1024 px
   - Fondo: Color sólido #1A237E (azul oscuro)
   - Agrega:
     * Un círculo blanco/amarillo en el centro (representando un medidor)
     * Un rayo o símbolo de energía
     * Las letras "LECTRA" estilizadas o simplemente "L"
     * Opcional: pequeño ícono de documento/factura

#### 2. Usar Generador de IA:
   - Prompt sugerido: "App icon for utility meter reading application called LECTRA, dark blue background #1A237E, white circular meter gauge, lightning bolt symbol, modern minimalist design, professional"
   - Herramientas: DALL-E, Midjourney, o https://www.appicon.co/

#### 3. Descargar Ícono Pre-diseñado:
   - Busca en: https://www.flaticon.com o https://www.iconfinder.com
   - Términos de búsqueda: "meter reading", "utility gauge", "electric meter"
   - Personaliza el color a #1A237E

### Guardar los Archivos:

1. **app_icon.png** (1024x1024 px):
   - Ícono completo con fondo
   - Guardar en: `assets/icon/app_icon.png`

2. **app_icon_foreground.png** (1024x1024 px):
   - Solo el símbolo/logo sin fondo (fondo transparente)
   - Guardar en: `assets/icon/app_icon_foreground.png`

## Opción 2: Usar un Ícono Temporal Simple

Si necesitas algo rápido para empezar, puedo ayudarte a crear un ícono básico con texto.

## Generar los Íconos para la App:

Una vez tengas las imágenes PNG en la carpeta `assets/icon/`, ejecuta:

```bash
flutter pub get
flutter pub run flutter_launcher_icons
```

Esto generará automáticamente todos los tamaños de íconos para Android e iOS.

## Concepto Visual Sugerido:

```
┌─────────────────────┐
│   [Fondo #1A237E]   │
│                     │
│      ╔═══════╗      │
│      ║   ⚡  ║      │  <- Medidor con rayo
│      ║  LECTRA ║    │
│      ╚═══════╝      │
│         📄          │  <- Pequeño ícono de factura
│                     │
└─────────────────────┘
```

## Colores Recomendados:
- Fondo: #1A237E (azul oscuro corporativo)
- Símbolos: #FFFFFF (blanco) o #FFC107 (amarillo/ámbar)
- Acentos: #4CAF50 (verde para datos completados)
