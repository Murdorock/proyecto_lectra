# MANUAL DE USUARIO - APLICACIÓN LECTRA

## Tabla de Contenidos
1. [Introducción](#introducción)
2. [Inicio de Sesión](#inicio-de-sesión)
3. [Pantalla Principal](#pantalla-principal)
4. [Módulos por Rol](#módulos-por-rol)
   - [Módulos para LECTOR](#módulos-para-lector)
   - [Módulos para SUPERVISOR](#módulos-para-supervisor)
5. [Descripción Detallada de Módulos](#descripción-detallada-de-módulos)
6. [Actualización de la Aplicación](#actualización-de-la-aplicación)
7. [Cierre de Sesión](#cierre-de-sesión)
8. [Soporte Técnico](#soporte-técnico)

---

## Introducción

**LECTRA** es una aplicación móvil diseñada para la gestión de lecturas de medidores, control de personal y supervisión de actividades en campo. La aplicación está diseñada para dos roles principales:

- **LECTOR**: Personal en campo que realiza lecturas de medidores
- **SUPERVISOR**: Personal administrativo que supervisa y controla las operaciones

### Características principales:
- Gestión de rangos de lectura
- Registro de coordenadas GPS
- Control de inconsistencias y errores
- Generación de reportes y PDF
- Sistema de firmas digitales
- Almacenamiento en la nube con Supabase

---

## Inicio de Sesión

### Pasos para iniciar sesión:

1. **Abrir la aplicación LECTRA**
   - Al abrir la app, se mostrará la pantalla de inicio de sesión

2. **Ingresar credenciales**
   - **Correo electrónico**: Digite su correo corporativo
   - **Contraseña**: Ingrese su contraseña

3. **Presionar el botón "INICIAR SESIÓN"**
   - La aplicación validará sus credenciales
   - Si son correctas, será redirigido a la pantalla principal

### Troubleshooting:
- Si olvida su contraseña, contacte al administrador del sistema
- Verifique tener conexión a internet activa
- Asegúrese de que el correo y contraseña estén escritos correctamente

---

## Pantalla Principal

La **Pantalla Principal** (Home Screen) muestra:

### Encabezado:
- **Nombre del usuario**: Muestra su nombre completo
- **Rol**: Indica si es LECTOR o SUPERVISOR
- **Botón de configuración** (⚙️): Acceso a actualizaciones de la app
- **Botón de cerrar sesión** (🚪): Para salir de la aplicación

### Menú de módulos:
Los módulos disponibles varían según su rol (ver siguiente sección)

### Botón de Configuración (⚙️):
Al presionarlo, se abre un diálogo con:
- Lista de archivos disponibles en la carpeta de actualizaciones
- Opción para descargar e instalar nuevas versiones de la app
- Archivos PDF con manuales o documentación

---

## Módulos por Rol

### Módulos para LECTOR

Los lectores tienen acceso a los siguientes módulos:

1. **RANGOS LECTURA** 📏
   - Consulta de rangos asignados de lecturas

2. **COORDENADAS** 📍
   - Registro de ubicaciones GPS durante lecturas

3. **REFUTAR ERRORES** ⚠️
   - Corrección y justificación de errores detectados

4. **CONTROLES REPARTO** 🚚
   - Control de distribución de materiales

5. **RANGOS REPARTIDA** 📊
   - Visualización de rangos distribuidos

6. **INCONSISTENCIAS** ⚠️
   - Reporte de inconsistencias encontradas

7. **CONTINGENCIA LECTURA** ⚡
   - Gestión de lecturas en modo contingencia

### Módulos para SUPERVISOR

Los supervisores tienen acceso a **TODOS** los módulos de lector más los siguientes adicionales:

8. **REPORTE TOTALES LECTURA** 📋
   - Visualización de totales y estadísticas de lecturas

9. **CONTROL DESCARGAS** 💾
   - Monitoreo de descargas de datos
   - Última actualización de datos
   - Tiempo transcurrido desde la última actualización

10. **HISTORICOS** 🕒
    - Consulta de registros históricos

11. **APROXIMADO LECTURA** 🧮
    - Cálculos y aproximaciones de lecturas

12. **LLEGADAS TARDE** 🕐
    - Registro de llegadas tardías del personal

13. **CIERRE JORNADA** 🌙
    - Cierre y registro de fin de jornada laboral

---

## Descripción Detallada de Módulos

### 1. RANGOS LECTURA 📏

**Propósito**: Consultar y gestionar los rangos asignados para realizar lecturas.

**Funcionalidades**:
- Visualización de rangos asignados
- Filtros por ciclo, correría, supervisor
- Búsqueda por código
- Visualización de resultados en tarjetas

**Cómo usar**:
1. Ingrese los filtros deseados (Ciclo, Correría, Supervisor)
2. Presione "BUSCAR"
3. Los resultados se mostrarán en tarjetas informativas
4. Toque una tarjeta para ver más detalles

---

### 2. COORDENADAS 📍

**Propósito**: Registrar las coordenadas GPS de ubicaciones durante el trabajo en campo.

**Funcionalidades**:
- Captura automática de coordenadas GPS
- Registro de instalaciones visitadas
- Almacenamiento de ubicaciones en base de datos

**Cómo usar**:
1. Asegúrese de tener GPS activado en su dispositivo
2. Permita a la app acceder a su ubicación
3. Ingrese el código de instalación
4. La app capturará automáticamente sus coordenadas
5. Presione "GUARDAR" para registrar

**Nota**: Requiere permisos de ubicación activados.

---

### 3. REFUTAR ERRORES ⚠️

**Propósito**: Permitir a los lectores justificar y corregir errores detectados en sus lecturas.

**Funcionalidades**:
- Listado de errores pendientes
- Campos para justificación
- Sistema de aprobación/rechazo
- Adjuntar evidencias fotográficas

**Cómo usar**:
1. Seleccione el error de la lista
2. Ingrese la justificación en el campo de texto
3. Si es necesario, adjunte una foto como evidencia
4. Presione "GUARDAR" para enviar la refutación

---

### 4. CONTROLES REPARTO 🚚

**Propósito**: Controlar y registrar la distribución de materiales y equipos.

**Funcionalidades**:
- Registro de ciclo y correría
- Validación automática de datos
- Consulta de materiales distribuidos

**Cómo usar**:
1. Ingrese el **CICLO** (formato: XX-XXXX, ejemplo: 12-2025)
2. Ingrese la **CORRERÍA** (código del supervisor)
3. Presione "BUSCAR"
4. Los resultados se mostrarán en pantalla

**Validaciones**:
- Ciclo y correría son obligatorios juntos
- El formato del ciclo debe ser MM-AAAA

---

### 5. RANGOS REPARTIDA 📊

**Propósito**: Visualizar los rangos que han sido distribuidos a los lectores.

**Funcionalidades**:
- Consulta de rangos por ciclo y correría
- Visualización de asignaciones
- Filtros de búsqueda

**Cómo usar**:
1. Ingrese el ciclo y correría
2. Presione "BUSCAR"
3. Revise la lista de rangos distribuidos

---

### 6. INCONSISTENCIAS ⚠️

**Propósito**: Reportar y gestionar inconsistencias encontradas durante las lecturas.

**Funcionalidades**:
- Listado ordenado por número de instalación
- Filtros por código, nombre, fechas
- Edición de inconsistencias
- Registro de observaciones

**Cómo usar**:
1. Use la barra de búsqueda para filtrar registros
2. Seleccione una inconsistencia de la lista
3. Presione el botón de editar (✏️)
4. Modifique los campos necesarios
5. Guarde los cambios

**Ordenamiento**: Los registros se muestran ordenados de menor a mayor según el número de instalación.

---

### 7. CONTINGENCIA LECTURA ⚡

**Propósito**: Gestionar lecturas en situaciones de contingencia o emergencia.

**Funcionalidades**:
- Filtros avanzados (búsqueda, tipo de consumo, estado de lectura)
- Ordenamiento por instalación y tipo de consumo
- Edición de registros de contingencia
- Botones de acción: Causa, Observación, Adicional, Alfa, Foto

**Cómo usar**:

#### Filtros disponibles:
1. **Búsqueda por texto**: Número de instalación o dirección
2. **Tipo de consumo**: Dropdown con opciones únicas
3. **Estado de lectura**: SIN LECTURA / CON LECTURA

#### Editar un registro:
1. Seleccione un registro de la lista
2. Se abrirá la pantalla de edición con los siguientes botones:

**Botón CAUSA** 🔴:
- Abre diálogo con 14 opciones de causa de no lectura
- Opciones: Predio cerrado, Medidor inaccesible, etc.
- Guarda en el campo `causanl_obs`

**Botón OBSERVACIÓN** 📝:
- Abre diálogo con 16 opciones de observación
- Opciones: Medidor dañado, Lectura ilegible, etc.
- Guarda en el campo `causanl_obs`

**Botón ADICIONAL** ➕:
- Abre diálogo con 24 opciones adicionales
- Códigos del 54 al 98
- Guarda en el campo `obs_adic`

**Botón ALFA** 🔤:
- Abre campo de texto libre
- Para ingresar observaciones alfanuméricas
- Guarda en el campo `observ_alfanum`

**Botón FOTO** 📷:
- Abre la cámara del dispositivo
- Captura evidencia fotográfica
- Sube la imagen a Supabase Storage (bucket: cold/contingencia)
- Guarda la URL en el campo `orden_agrupadora`

**Permisos necesarios**: Cámara (para el botón FOTO)

---

### 8. REPORTE TOTALES LECTURA 📋
*(Solo SUPERVISOR)*

**Propósito**: Visualizar estadísticas y totales de lecturas realizadas.

**Funcionalidades**:
- Resumen de lecturas del día/semana/mes
- Gráficos estadísticos
- Exportación de reportes
- Edición de totales

**Cómo usar**:
1. Seleccione el período deseado
2. Aplique filtros si es necesario
3. Revise las estadísticas presentadas
4. Para editar, presione el botón de editar en cada registro

---

### 9. CONTROL DESCARGAS 💾
*(Solo SUPERVISOR)*

**Propósito**: Monitorear las descargas de datos y verificar la última actualización del sistema.

**Funcionalidades**:
- Visualización de descargas por supervisor
- Filtros por código de supervisor
- **Última actualización**: Muestra la hora de la última actualización de datos en la tabla `cmlec`
- **Tiempo transcurrido**: Contador en tiempo real que muestra minutos y segundos desde la última actualización
- Totales, pendientes y descargadas por correría

**Cómo usar**:
1. Ingrese el código del supervisor
2. Presione "BUSCAR"
3. Revise la información en las siguientes secciones:
   - **Última actualización**: Hora exacta (formato HH:MM:SS)
   - **Tiempo transcurrido**: Contador dinámico (Xm Ys)
   - Tabla con: ID Correría, Código, Totales, Pendientes, Descargadas

**Información mostrada**:
- La **última actualización** se obtiene de la tabla `cmlec` consultando el campo `updated_at`
- El **tiempo transcurrido** se actualiza automáticamente cada segundo
- Los datos se convierten a la hora local de su región

---

### 10. HISTORICOS 🕒
*(Solo SUPERVISOR)*

**Propósito**: Consultar registros históricos de lecturas y actividades.

**Funcionalidades**:
- Búsqueda por fechas
- Filtros por tipo de actividad
- Visualización detallada de históricos
- Exportación de datos

**Cómo usar**:
1. Seleccione el rango de fechas
2. Aplique filtros adicionales
3. Presione "BUSCAR"
4. Revise los resultados
5. Toque un registro para ver detalles completos

---

### 11. APROXIMADO LECTURA 🧮
*(Solo SUPERVISOR)*

**Propósito**: Realizar cálculos y aproximaciones de consumos.

**Funcionalidades**:
- Cálculo automático de consumos aproximados
- Comparación con lecturas anteriores
- Detección de anomalías
- Sugerencias de lectura

**Cómo usar**:
1. Ingrese los parámetros de búsqueda
2. Presione "CALCULAR"
3. Revise los resultados aproximados
4. Utilice la información para validar lecturas

---

### 12. LLEGADAS TARDE 🕐
*(Solo SUPERVISOR)*

**Propósito**: Registrar y documentar llegadas tardías del personal con generación automática de PDF.

**Funcionalidades**:
- Búsqueda de funcionario por código o nombre (autocompletado)
- Selección de hora de llegada
- Registro de motivo de la llegada tarde
- Captura de firmas digitales (funcionario y supervisor)
- Generación automática de PDF formal
- Almacenamiento en la nube

**Cómo usar**:

#### 1. Seleccionar Funcionario:
- Escriba el código o nombre en el campo de búsqueda
- Aparecerán sugerencias automáticamente
- Seleccione el funcionario correcto de la lista
- Se mostrará un ✓ verde cuando esté seleccionado

#### 2. Seleccionar Hora de Llegada:
- Toque el campo "Hora de Llegada"
- Se abrirá el selector de hora
- Elija la hora exacta de llegada tarde
- Confirme la selección

#### 3. Escribir Motivo:
- Ingrese una descripción detallada del motivo
- Campo de texto de múltiples líneas
- Ejemplo: "Problemas de transporte público", "Emergencia familiar", etc.

#### 4. Capturar Firma del Funcionario:
- Presione "CAPTURAR FIRMA"
- Se abrirá el panel de firma
- El funcionario debe firmar en la pantalla táctil
- Opciones: Limpiar (para borrar) o Guardar
- Se mostrará un preview de la firma capturada

#### 5. Capturar Firma del Supervisor:
- Repita el proceso para la firma del supervisor
- Ambas firmas son obligatorias

#### 6. Guardar el Registro:
- Presione el botón "GUARDAR"
- El sistema:
  - Valida que todos los campos estén completos
  - Genera un PDF profesional con:
    * Logo UTIC INTEGRAL
    * Fecha y lugar
    * Información del funcionario
    * Hora programada (06:30:00 a.m.)
    * Hora real de llegada
    * Motivo detallado
    * Firmas de ambas partes
    * Cédulas y cargos
  - Nombra el archivo: `CEDULA_CODIGO_DDMMAAAA_HHMM.pdf`
    * Ejemplo: `8358404_LEC_154_25112025_0738.pdf`
  - Sube el PDF a Supabase Storage (bucket: cold/llegadas_tarde/CODIGO/)
  - Guarda el registro en la tabla `llegadas_tarde`
- Muestra mensaje de éxito
- Limpia automáticamente el formulario

#### 7. Limpiar Formulario:
- Presione "LIMPIAR" para borrar todos los campos sin guardar
- Útil para empezar un nuevo registro

**Botones disponibles**:
- **Reemplazar**: Cambiar una firma ya capturada
- **Limpiar**: Borrar una firma específica
- **LIMPIAR**: Limpiar todo el formulario
- **GUARDAR**: Procesar y guardar el registro completo

**Validaciones**:
- Funcionario seleccionado (obligatorio)
- Hora de llegada (obligatorio)
- Motivo escrito (obligatorio)
- Firma del funcionario (obligatorio)
- Firma del supervisor (obligatorio)

**Datos guardados en la tabla**:
- `codigo`: Código del funcionario
- `nombre`: Nombre completo del funcionario
- `fecha`: Fecha del incidente (formato YYYY-MM-DD)
- `hora`: Hora de llegada tarde (formato HH:MM:SS)
- `motivo`: Descripción del motivo
- `supervisor`: Código del supervisor que registra
- `pdf`: URL del PDF generado en Supabase Storage

**Ubicación del PDF**:
- Bucket: `cold`
- Carpeta: `llegadas_tarde/[CODIGO_FUNCIONARIO]/`
- Nombre: `[CEDULA]_[CODIGO]_[FECHA]_[HORA].pdf`

---

### 13. CIERRE JORNADA 🌙
*(Solo SUPERVISOR)*

**Propósito**: Registrar el cierre oficial de la jornada laboral.

**Funcionalidades**:
- Registro de hora de cierre
- Resumen de actividades del día
- Observaciones finales
- Firma digital del supervisor

**Cómo usar**:
1. Al finalizar la jornada, ingrese a este módulo
2. Revise el resumen automático
3. Agregue observaciones si es necesario
4. Firme digitalmente
5. Presione "CERRAR JORNADA"

---

## Actualización de la Aplicación

### Cómo actualizar la app:

1. **Acceder al menú de actualizaciones**:
   - En la pantalla principal, presione el botón de configuración ⚙️

2. **Revisar archivos disponibles**:
   - Se mostrará un diálogo con la lista de archivos
   - Archivos APK son versiones nuevas de la aplicación
   - Archivos PDF pueden ser manuales o documentación

3. **Descargar una actualización**:
   - Toque el archivo deseado
   - Se abrirá en el navegador o gestor de descargas
   - Para APK: Permita la instalación de fuentes desconocidas si es necesario

4. **Instalar la actualización**:
   - Una vez descargado el APK, ábralo
   - Android le pedirá confirmar la instalación
   - Presione "INSTALAR"
   - Espere a que complete
   - Presione "ABRIR" o cierre e inicie la app normalmente

**Nota importante**: Las actualizaciones pueden incluir nuevas funcionalidades, correcciones de errores y mejoras de rendimiento.

---

## Cierre de Sesión

### Cómo cerrar sesión:

1. **Desde la pantalla principal**:
   - Presione el botón de cerrar sesión (icono de puerta 🚪) en la esquina superior derecha

2. **Confirmación**:
   - Se le pedirá confirmar que desea salir
   - Presione "SÍ" para confirmar

3. **Resultado**:
   - Su sesión se cerrará
   - Será redirigido a la pantalla de inicio de sesión
   - Sus credenciales locales serán eliminadas

**Recomendación**: Siempre cierre sesión al finalizar su jornada o si va a dejar el dispositivo sin supervisión.

---

## Soporte Técnico

### Contacto:

Si experimenta problemas técnicos o tiene dudas sobre el uso de la aplicación:

- **Soporte Técnico**: Contacte al departamento de IT
- **Horario de atención**: Lunes a Viernes, 8:00 AM - 5:00 PM
- **Email**: soporte@uticintegral.com (ejemplo)

### Problemas comunes:

#### 1. **La app se cierra inesperadamente**:
- Verifique que su dispositivo tenga suficiente memoria RAM disponible
- Cierre otras aplicaciones en segundo plano
- Reinicie el dispositivo

#### 2. **No puedo iniciar sesión**:
- Verifique su conexión a internet
- Confirme que sus credenciales sean correctas
- Contacte al administrador para verificar que su cuenta esté activa

#### 3. **Los datos no se cargan**:
- Verifique su conexión a internet
- Intente cerrar y reabrir la aplicación
- Verifique que tenga los permisos necesarios para el módulo

#### 4. **El GPS no funciona** (Módulo Coordenadas):
- Verifique que el GPS esté activado en su dispositivo
- Confirme que la app tenga permisos de ubicación
- Si está en interiores, salga al exterior para mejor señal

#### 5. **La cámara no se abre** (Contingencia/Llegadas Tarde):
- Verifique que la app tenga permisos de cámara
- Configure manualmente en: Ajustes > Apps > LECTRA > Permisos

#### 6. **La firma no se guarda**:
- Asegúrese de presionar "Guardar" en el panel de firma
- No presione el botón Atrás de Android
- Verifique que la firma sea visible (no esté en blanco)

---

## Características Técnicas

### Requisitos del sistema:
- **Sistema operativo**: Android 5.0 (Lollipop) o superior
- **RAM**: Mínimo 2 GB
- **Almacenamiento**: 100 MB de espacio libre
- **Conexión**: Internet (WiFi o datos móviles)
- **Permisos requeridos**:
  - Ubicación (GPS)
  - Cámara
  - Almacenamiento
  - Internet

### Tecnologías utilizadas:
- **Framework**: Flutter
- **Base de datos**: Supabase (PostgreSQL)
- **Almacenamiento**: Supabase Storage
- **Autenticación**: Supabase Auth
- **Generación de PDF**: Package pdf
- **Firmas digitales**: Syncfusion Signature Pad
- **Geolocalización**: Geolocator

### Seguridad:
- Autenticación con tokens seguros
- Sesiones con auto-renovación
- Encriptación de datos en tránsito
- Almacenamiento seguro en la nube
- Políticas RLS (Row Level Security) en base de datos

---

## Glosario de Términos

- **Ciclo**: Período mensual de facturación (formato: MM-AAAA)
- **Correría**: Código identificador del supervisor o ruta asignada
- **Instalación**: Número único que identifica un punto de medición
- **Contingencia**: Situación excepcional que requiere procedimientos especiales
- **RLS**: Row Level Security - Seguridad a nivel de fila en la base de datos
- **Supabase**: Plataforma de backend como servicio (BaaS)
- **APK**: Android Package Kit - Archivo de instalación de Android
- **GPS**: Sistema de Posicionamiento Global
- **PDF**: Portable Document Format - Formato de documento portable

---

## Registro de Cambios

### Versión 2.0.9 (25 de noviembre de 2025)
- ✅ Corrección de formatos en nombre de archivos PDF (Llegadas Tarde)
- ✅ Mejora en limpieza de formularios
- ✅ Optimización de sincronización de campos autocompletados

### Versión 2.0.1
- ✅ Implementación completa del módulo Llegadas Tarde
- ✅ Generación automática de PDF con firmas digitales
- ✅ Botones de acción en Contingencia Lectura (Causa, Observación, Adicional, Alfa, Foto)
- ✅ Integración de cámara para evidencias fotográficas
- ✅ Corrección de auto-logout (sesión persistente)
- ✅ Ordenamiento de registros en Inconsistencias
- ✅ Filtro de tipo de consumo en Contingencia Lectura
- ✅ Botón de configuración con listado de archivos de actualización
- ✅ Simplificación de formulario en Controles Reparto
- ✅ Última actualización y tiempo transcurrido en Control Descargas

---

## Notas Finales

- **Mantenga actualizada la aplicación** para acceder a las últimas funcionalidades
- **Reporte inmediatamente** cualquier error o comportamiento inusual
- **Realice copias de seguridad** de información crítica cuando sea posible
- **Respete las políticas de uso** establecidas por la empresa
- **Proteja sus credenciales** de acceso

---

**Versión del manual**: 1.0  
**Fecha de actualización**: 25 de noviembre de 2025  
**Aplicación**: LECTRA v2.0.9

---

© 2025 UTIC INTEGRAL - Todos los derechos reservados
