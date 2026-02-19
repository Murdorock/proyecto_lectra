# GUÍA DE USO - ENTREGA CORRERIAS

## Descripción General
La vista **ENTREGA CORRERIAS** es una funcionalidad diseñada para registrar y gestionar la entrega de correrías a funcionarios. Utiliza escaneo de códigos de barras para facilitar la captura de datos y proporciona manejo automático de reasignaciones de entregas.

## Características Principales

### 1. **Escaneo de Correría Entregada**
- **Función:** Busca el código de correría en la tabla `correrias_reparto`
- **Campo:** Escanee o ingrese el código de la correría
- **Datos Mostrados:** 
  - Código de correría
  - Nombre de la correría
- **Validación:** El código debe existir en la tabla `correrias_reparto`

### 2. **Escaneo de Funcionario que Recibe**
- **Función:** Busca el número de cédula del funcionario en la tabla `personal`
- **Campo:** Escanee o ingrese el número de cédula
- **Datos Mostrados:** 
  - Número de cédula
  - ID Código
  - Nombre completo del funcionario
- **Validación:** La cédula debe existir en la tabla `personal`

### 3. **Guardado de Entrega**
Cuando presiona el botón **Guardar**, la aplicación realiza las siguientes acciones:

#### Datos Guardados en la tabla `entrega_correrías`:
- **id_entrega:** El código de correría escaneado
- **fecha:** La fecha actual del sistema (formato date)
- **reclamo:** El ID código del funcionario

#### Casos de Guardado:

**Caso 1: Primera entrega (correría nueva)**
- Mensaje: `"La correría [id_entrega] fue recibida por [id_codigo]"`
- La entrega se guarda automáticamente

**Caso 2: Reasignación (correría ya entregada)**
- Mensaje en diálogo: `"La correría [id_entrega] fue recibida por [id_codigo_anterior] el [fecha_anterior]"`
- Se muestra un diálogo con opciones:
  - **NO:** Cancela la reasignación
  - **SI:** Actualiza la entrega con el nuevo funcionario y fecha

### 4. **Botón Limpiar**
- Limpia todos los campos y datos capturados
- Permite iniciar un nuevo registro de entrega

## Flujo de Uso

1. **Escanee o ingrese el código de correría**
   - El sistema busca automáticamente
   - Se muestran los datos si encuentra coincidencia

2. **Escanee o ingrese la cédula del funcionario**
   - El sistema busca automáticamente
   - Se muestran los datos personales del funcionario

3. **Presione Guardar**
   - Si es la primera entrega: se guarda automáticamente
   - Si ya existe: se muestra diálogo de confirmación

4. **Confirme o cancele según sea necesario**
   - SI: Se reasigna la entrega
   - NO: Se cancela la operación

5. **Presione Limpiar para registrar otra entrega**

## Requisitos de Base de Datos

### Tabla: `correrias_reparto`
Debe contener las siguientes columnas:
- `correria` (text) - Código de la correría (clave para búsqueda)
- `nombre_correria` (text) - Nombre descriptivo
- `fecha` (date) - Fecha asociada (opcional para mostrar)

### Tabla: `personal`
Debe contener las siguientes columnas:
- `numero_cedula` (text) - Número de cédula (clave para búsqueda)
- `id_codigo` (text) - Código de identificación
- `nombre_completo` (text) - Nombre completo del funcionario

### Tabla: `entrega_correrías`
Debe contener las siguientes columnas:
- `id_entrega` (text) - Código de correría (clave primaria)
- `fecha` (date) - Fecha de entrega
- `reclamo` (text) - ID código del funcionario que recibe

## Mensajes de Error

| Error | Solución |
|-------|----------|
| "Por favor escanee o ingrese el código de la correría" | Escanee un código válido |
| "No se encontró la correría: [codigo]" | Verifique que el código existe en `correrias_reparto` |
| "Por favor escanee o ingrese el número de cédula del funcionario" | Escanee un número de cédula válido |
| "No se encontró el funcionario: [cedula]" | Verifique que la cédula existe en `personal` |
| "Debe escanear una correría primero" | Complete el campo de correría antes de guardar |
| "Debe escanear un funcionario primero" | Complete el campo de funcionario antes de guardar |

## Notas Técnicas

- La vista utiliza Supabase para acceder a las tablas
- Las fechas se guardan en formato ISO 8601 (YYYY-MM-DD)
- Se requiere conexión a internet para el funcionamiento
- Los mensajes de éxito se limpian automáticamente después de 3 segundos
- Los campos distinguen entre mayúsculas y minúsculas en la búsqueda

## Integración en Home Screen

El botón "ENTREGA CORRERIAS" aparece en el menú principal solo para usuarios con rol **ADMINISTRADOR** y navega automáticamente a esta vista cuando se presiona.

