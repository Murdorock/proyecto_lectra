import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:image_picker/image_picker.dart';
import 'package:syncfusion_flutter_signaturepad/signaturepad.dart';
import 'package:geolocator/geolocator.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:http/http.dart' as http;
import 'dart:io';
import 'dart:ui' as ui;
import 'dart:math' as math;
import '../main.dart';
import '../services/user_session.dart';

class EditarInconsistenciaScreen extends StatefulWidget {
  final int inconsistenciaId;

  const EditarInconsistenciaScreen({
    super.key,
    required this.inconsistenciaId,
  });

  @override
  State<EditarInconsistenciaScreen> createState() => _EditarInconsistenciaScreenState();
}

class _EditarInconsistenciaScreenState extends State<EditarInconsistenciaScreen> {
  final _formKey = GlobalKey<FormState>();
  bool _isLoading = true;
  bool _isSaving = false;
  bool _hasChanges = false; // Bandera para indicar si hubo cambios
  Map<String, dynamic>? _data;
  String? _errorMessage;

  // Controladores para campos editables
  final Map<String, TextEditingController> _controllers = {};
  
  // ImagePicker para fotos
  final ImagePicker _picker = ImagePicker();
  
  // Archivos de imagen seleccionados
  File? _fotoFile;
  File? _foto1File;
  File? _foto2File;
  
  // Variable para la firma
  ui.Image? _firmaImagen;
  
  // Variable para el dropdown de causa_observacion
  String? _causaObservacionSeleccionada;
  
  // Variable para el dropdown de observacion_adicional_real
  String? _observacionAdicionalRealSeleccionada;
  
  // Variable para el dropdown de correcciones_en_sistema
  String? _correccionesEnSistemaSeleccionada;

  // Opciones para causa_observacion
  final List<Map<String, String>> _causasObservacion = [
    {'value': '0', 'label': '0-SIN CAUSA NI OBSERVACION'},
    {'value': '1', 'label': '1-NO EXISTE GEOGRAFICAMENTE'},
    {'value': '2', 'label': '2-IMPOSIBILIDAD DE ACCESO'},
    {'value': '3', 'label': '3-PROFUNDO O MUY ALTO'},
    {'value': '4', 'label': '4-TAPADO INTERIORMENTE'},
    {'value': '5', 'label': '5-DESTRUÍDO/DAÑADO'},
    {'value': '6', 'label': '6-VOLTEADO'},
    {'value': '7', 'label': '7-MEDIDOR CON DISPLAY DESENERGIZADO'},
    {'value': '8', 'label': '8-DEMOLIDA'},
    {'value': '9', 'label': '9-SERVICIO DIRECTO'},
    {'value': '11', 'label': '11-SIN SERVICIO SIN MEDIDOR'},
    {'value': '12', 'label': '12-NO LEIDA'},
    {'value': '13', 'label': '13-NO PERTENECE A LA CORRERIA'},
    {'value': '15', 'label': '15-MEDIDOR PREPAGO'},
    {'value': '18', 'label': '18-AGUA PROPIA O COMUNAL'},
    {'value': '19', 'label': '19-REPARÓ DAÑO O FUGA'},
    {'value': '21', 'label': '21-POSIBLE IRREGULARIDAD (EGA)'},
    {'value': '22', 'label': '22-CAMBIO DE ACTIVIDAD'},
    {'value': '23', 'label': '23-INSTALACIÓN VACÍA'},
    {'value': '25', 'label': '25-MEDIDOR PARADO O DAÑADO'},
    {'value': '26', 'label': '26-SURTE OTRAS INSTALACIONES'},
    {'value': '27', 'label': '27-SE SURTE DE OTRA INSTALACIÓN'},
    {'value': '28', 'label': '28-SIN SERVICIO CON MEDIDOR'},
    {'value': '29', 'label': '29-REGISTRO DEVOLVIENDO'},
    {'value': '30', 'label': '30-DESVIACIÓN SIGNIFICATIVA'},
    {'value': '31', 'label': '31-MEDIDOR CAMBIADO'},
    {'value': '34', 'label': '34-LECTURA MENOR'},
    {'value': '36', 'label': '36-MEDIDORES TROCADOS'},
    {'value': '39', 'label': '39- CORRECCIÓN LECTURA'},
  ];
  
  // Opciones para observacion_adicional_real
  final List<Map<String, String>> _observacionesAdicionales = [
    {'value': '54', 'label': '54-SUSPENDIDO'},
    {'value': '55', 'label': '55-VACIA/ABANDONADA'},
    {'value': '56', 'label': '56-HABITADA USAN'},
    {'value': '57', 'label': '57-HABITADA NO USAN'},
    {'value': '58', 'label': '58-LECTURA NO RECUPERABLE'},
    {'value': '60', 'label': '60-ACOMETIDA PELADA ( E )'},
    {'value': '63', 'label': '63-CAMBIO DE USO O ACTIVIDAD(EGA)'},
    {'value': '68', 'label': '68-POSIBLE IRREGULARIDAD'},
    {'value': '70', 'label': '70-FUGA PERCEPTIBLE (A)'},
    {'value': '71', 'label': '71-VER ALFANUMÉRICA (EGA)'},
    {'value': '72', 'label': '72-LTM Y REVISIÓN TÉCN LECT (EGA)'},
    {'value': '73', 'label': '73-OBSERVACION ESPECIFICA (EGA)'},
    {'value': '74', 'label': '74-OLOR A GAS (G)'},
    {'value': '75', 'label': '75-NO PERTENECE A LA CORRERÍA EGA'},
    {'value': '80', 'label': '80-SURTE OTROS INMUEBLES(EGA)'},
    {'value': '83', 'label': '83-MEDIDOR PARADO O DAÑADO (EGA)'},
    {'value': '84', 'label': '84-DISPLAY REINICIADO (E)'},
    {'value': '85', 'label': '85-DISPLAY DESCONFIGURADO (E)'},
    {'value': '90', 'label': '90-SIN PUENTE/GARRUCHA MALA (E)'},
    {'value': '91', 'label': '91-CASA SOLA'},
    {'value': '92', 'label': '92-CLIENTE NO JUSTIFICA'},
    {'value': '93', 'label': '93-REVISIÓN TÉCNICA LECT (EGA)'},
    {'value': '96', 'label': '96-MEDIDOR MAL PARAMETRIZADO (E)'},
    {'value': '98', 'label': '98-SE DEJO CONSTANCIA LECTURA'},
    {'value': 'NO EXISTE', 'label': 'NO EXISTE GEOGRÁFICAMENTE'},
    {'value': 'Vacía', 'label': 'Vacía'},
  ];
  
  // Opciones para correcciones_en_sistema
  final List<Map<String, String>> _correccionesEnSistema = [
    {'value': 'ERROR OBSERVACION', 'label': 'ERROR OBSERVACION'},
    {'value': 'ERROR CAUSA', 'label': 'ERROR CAUSA'},
    {'value': 'ERROR LECTURA', 'label': 'ERROR LECTURA'},
    {'value': 'ERROR MES ANTERIOR', 'label': 'ERROR MES ANTERIOR'},
    {'value': 'INSTALACION NORMAL', 'label': 'INSTALACION NORMAL'},
    {'value': 'NO LEIDO', 'label': 'NO LEIDO'},
    {'value': 'FALLA TECNICA DEL MEDIDOR', 'label': 'FALLA TECNICA DEL MEDIDOR'},
  ];

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  @override
  void dispose() {
    for (var controller in _controllers.values) {
      controller.dispose();
    }
    super.dispose();
  }

  Future<void> _loadData() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final data = await supabase
          .from('inconsistencias')
          .select('*')
          .eq('id', widget.inconsistenciaId)
          .single();

      // Cargar advertencia desde secuencia_lectura si existe orden
      if (data['orden'] != null && data['orden'].toString().isNotEmpty) {
        try {
          final secuenciaData = await supabase
              .from('secuencia_lectura')
              .select('advertencia_lect')
              .eq('orden_lectura', data['orden'])
              .maybeSingle();
          
          if (secuenciaData != null && secuenciaData['advertencia_lect'] != null) {
            data['advertencia'] = secuenciaData['advertencia_lect'];
          }
        } catch (e) {
          print('⚠️ Error al cargar advertencia: $e');
          // Continuar sin advertencia si hay error
        }
      }

      if (mounted) {
        setState(() {
          _data = data;
          _isLoading = false;
        });
        _initializeControllers();
        
        // Cargar fotos existentes desde el bucket si están guardadas
        await _cargarFotosExistentes();
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _errorMessage = 'Error al cargar los datos: ${e.toString()}';
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _cargarFotosExistentes() async {
    if (_data == null) return;

    try {
      // Cargar foto principal
      final fotoPath = _data!['foto']?.toString();
      if (fotoPath != null && fotoPath.isNotEmpty) {
        await _descargarFotoDelBucket(fotoPath, 'foto');
      }

      // Cargar foto1
      final foto1Path = _data!['foto1']?.toString();
      if (foto1Path != null && foto1Path.isNotEmpty) {
        await _descargarFotoDelBucket(foto1Path, 'foto1');
      }

      // Cargar foto2
      final foto2Path = _data!['foto2']?.toString();
      if (foto2Path != null && foto2Path.isNotEmpty) {
        await _descargarFotoDelBucket(foto2Path, 'foto2');
      }
    } catch (e) {
      print('⚠️ Error al cargar fotos existentes: $e');
      // No mostramos error al usuario, simplemente no se cargan las fotos
    }
  }

  Future<void> _descargarFotoDelBucket(String path, String campoFoto) async {
    try {
      print('📥 Descargando foto desde: $path');
      
      // Descargar la foto desde Supabase Storage
      final bytes = await supabase.storage.from('cold').download(path);
      
      // Crear un archivo temporal para guardar la imagen
      final tempDir = await Directory.systemTemp.createTemp('lectra_fotos_');
      final fileName = path.split('/').last;
      final tempFile = File('${tempDir.path}/$fileName');
      
      // Escribir los bytes en el archivo temporal
      await tempFile.writeAsBytes(bytes);
      
      // Actualizar el estado con la foto cargada
      if (mounted) {
        setState(() {
          switch (campoFoto) {
            case 'foto':
              _fotoFile = tempFile;
              _controllers['foto']?.text = fileName;
              break;
            case 'foto1':
              _foto1File = tempFile;
              _controllers['foto1']?.text = fileName;
              break;
            case 'foto2':
              _foto2File = tempFile;
              _controllers['foto2']?.text = fileName;
              break;
          }
        });
      }
      
      print('✅ Foto cargada exitosamente: $fileName');
    } catch (e) {
      print('❌ Error al descargar foto desde $path: $e');
    }
  }

  void _initializeControllers() {
    if (_data == null) return;

    // Inicializar causa_observacion del dropdown
    _causaObservacionSeleccionada = _data!['causa_observacion']?.toString();
    
    // Inicializar observacion_adicional_real del dropdown
    _observacionAdicionalRealSeleccionada = _data!['observacion_adicional_real']?.toString();
    
    // Inicializar correcciones_en_sistema del dropdown
    _correccionesEnSistemaSeleccionada = _data!['correcciones_en_sistema']?.toString();

    // Campos editables específicos (excluyendo dropdowns)
    final editableFields = {
      'alfanumerica_revisor',
      'lectura_real',
      'foto',
      'foto1',
      'foto2',
      'geolocalizacion',
      'firma_revisor',
      'advertencia_revisor',
    };

    // Crear controladores solo para campos editables
    _data!.forEach((key, value) {
      if (editableFields.contains(key)) {
        _controllers[key] = TextEditingController(text: value?.toString() ?? '');
      }
    });
  }

  Future<void> _guardarCambios() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    setState(() {
      _isSaving = true;
    });

    try {
      // Verificar que la sesión sea válida antes de proceder
      final sessionValid = await UserSession().ensureSessionValid();
      
      if (!sessionValid) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Sesión expirada. Por favor inicie sesión nuevamente.'),
              backgroundColor: Colors.red,
            ),
          );
          Navigator.of(context).pushReplacementNamed('/login');
        }
        return;
      }
      
      // Construir objeto con datos actualizados
      final Map<String, dynamic> updates = {};
      
      // Agregar causa_observacion del dropdown
      updates['causa_observacion'] = _causaObservacionSeleccionada;
      
      // Agregar observacion_adicional_real del dropdown
      updates['observacion_adicional_real'] = _observacionAdicionalRealSeleccionada;
      
      // Agregar correcciones_en_sistema del dropdown
      updates['correcciones_en_sistema'] = _correccionesEnSistemaSeleccionada;
      
      // Agregar campos de texto (sin las fotos y firma, se manejan aparte)
      _controllers.forEach((key, controller) {
        if (key != 'foto' && key != 'foto1' && key != 'foto2' && key != 'firma_revisor') {
          updates[key] = controller.text.isEmpty ? null : controller.text;
        }
      });

      // PASO 1: Subir fotos al bucket si existen
      final instalacion = _data!['instalacion']?.toString() ?? 'sin_instalacion';
      final timestamp = DateTime.now().millisecondsSinceEpoch;

      if (_fotoFile != null) {
        final fotoPath = 'inconsistencias/fotos/${instalacion}_foto_$timestamp.jpg';
        await supabase.storage.from('cold').upload(
          fotoPath,
          _fotoFile!,
        );
        updates['foto'] = fotoPath;
      }

      if (_foto1File != null) {
        final foto1Path = 'inconsistencias/fotos/${instalacion}_foto1_$timestamp.jpg';
        await supabase.storage.from('cold').upload(
          foto1Path,
          _foto1File!,
        );
        updates['foto1'] = foto1Path;
      }

      if (_foto2File != null) {
        final foto2Path = 'inconsistencias/fotos/${instalacion}_foto2_$timestamp.jpg';
        await supabase.storage.from('cold').upload(
          foto2Path,
          _foto2File!,
        );
        updates['foto2'] = foto2Path;
      }

      // Subir firma como imagen si existe
      if (_firmaImagen != null) {
        final firmaPngBytes = await _convertirFirmaAPng(_firmaImagen!);
        final firmaPath = 'inconsistencias/fotos/${instalacion}_firma_$timestamp.png';
        await supabase.storage.from('cold').uploadBinary(
          firmaPath,
          firmaPngBytes,
        );
        updates['firma_revisor'] = firmaPath;
      }

      // PASO 2: Actualizar registro en la tabla inconsistencias
      await supabase
          .from('inconsistencias')
          .update(updates)
          .eq('id', widget.inconsistenciaId);

      // Recargar datos actualizados
      await _loadData();

      // Marcar que hubo cambios
      _hasChanges = true;

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Cambios guardados exitosamente'),
            backgroundColor: Colors.green,
            duration: Duration(seconds: 3),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error al guardar: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isSaving = false;
        });
      }
    }
  }

  Future<void> _generarPDF() async {
    // Validar que haya datos guardados
    if (_data == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('No hay datos para generar el PDF'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    // Validar campos obligatorios
    List<String> camposFaltantes = [];

    // Validar Causa Observación
    if (_causaObservacionSeleccionada == null || _causaObservacionSeleccionada!.isEmpty) {
      camposFaltantes.add('Causa de No Lectura u Observación');
    }

    // Validar Observación Adicional
    if (_observacionAdicionalRealSeleccionada == null || _observacionAdicionalRealSeleccionada!.isEmpty) {
      camposFaltantes.add('Observación Adicional');
    }

    // Validar Correcciones en Sistema
    if (_correccionesEnSistemaSeleccionada == null || _correccionesEnSistemaSeleccionada!.isEmpty) {
      camposFaltantes.add('Correcciones en Sistema');
    }

    // Validar Alfanumérica Revisor
    if (_controllers['alfanumerica_revisor']?.text.isEmpty ?? true) {
      camposFaltantes.add('Alfanumérica Revisor');
    }

    // Validar Lectura Real
    if (_controllers['lectura_real']?.text.isEmpty ?? true) {
      camposFaltantes.add('Lectura Real');
    }

    // Validar Geolocalización
    if (_controllers['geolocalizacion']?.text.isEmpty ?? true) {
      camposFaltantes.add('Geolocalización');
    }

    // Validar Foto principal (obligatoria)
    if (_fotoFile == null) {
      camposFaltantes.add('Foto principal');
    }

    // Validar Firma
    if (_firmaImagen == null) {
      camposFaltantes.add('Firma del Operativo');
    }

    // Si hay campos faltantes, mostrar mensaje de error
    if (camposFaltantes.isNotEmpty) {
      final mensaje = camposFaltantes.length == 1
          ? 'El siguiente campo es obligatorio:\n• ${camposFaltantes[0]}'
          : 'Los siguientes campos son obligatorios:\n${camposFaltantes.map((c) => '• $c').join('\n')}';
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(mensaje),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 5),
          ),
        );
      }
      return;
    }

    setState(() {
      _isSaving = true;
    });

    try {
      final instalacion = _data!['instalacion']?.toString() ?? 'sin_instalacion';
      final timestamp = DateTime.now().millisecondsSinceEpoch;

      // ===== PASO 1: GUARDAR TODOS LOS CAMBIOS (igual que _guardarCambios) =====
      
      // Construir objeto con datos actualizados
      final Map<String, dynamic> updates = {};
      
      // Agregar causa_observacion del dropdown
      updates['causa_observacion'] = _causaObservacionSeleccionada;
      
      // Agregar observacion_adicional_real del dropdown
      updates['observacion_adicional_real'] = _observacionAdicionalRealSeleccionada;
      
      // Agregar correcciones_en_sistema del dropdown
      updates['correcciones_en_sistema'] = _correccionesEnSistemaSeleccionada;
      
      // Agregar campos de texto (sin las fotos y firma, se manejan aparte)
      _controllers.forEach((key, controller) {
        if (key != 'foto' && key != 'foto1' && key != 'foto2' && key != 'firma_revisor') {
          updates[key] = controller.text.isEmpty ? null : controller.text;
        }
      });

      // Subir fotos al bucket si existen o son nuevas
      if (_fotoFile != null) {
        // Verificar si es una foto nueva (no viene del bucket)
        final fotoActual = _data!['foto']?.toString();
        final esFotoNueva = fotoActual == null || !_fotoFile!.path.contains(fotoActual);
        
        if (esFotoNueva) {
          final fotoPath = 'inconsistencias/fotos/${instalacion}_foto_$timestamp.jpg';
          await supabase.storage.from('cold').upload(
            fotoPath,
            _fotoFile!,
          );
          updates['foto'] = fotoPath;
          print('📸 Foto principal subida: $fotoPath');
        } else {
          print('📸 Foto principal ya existe: $fotoActual');
        }
      }

      if (_foto1File != null) {
        final foto1Actual = _data!['foto1']?.toString();
        final esFoto1Nueva = foto1Actual == null || !_foto1File!.path.contains(foto1Actual);
        
        if (esFoto1Nueva) {
          final foto1Path = 'inconsistencias/fotos/${instalacion}_foto1_$timestamp.jpg';
          await supabase.storage.from('cold').upload(
            foto1Path,
            _foto1File!,
          );
          updates['foto1'] = foto1Path;
          print('📸 Foto 1 subida: $foto1Path');
        } else {
          print('📸 Foto 1 ya existe: $foto1Actual');
        }
      }

      if (_foto2File != null) {
        final foto2Actual = _data!['foto2']?.toString();
        final esFoto2Nueva = foto2Actual == null || !_foto2File!.path.contains(foto2Actual);
        
        if (esFoto2Nueva) {
          final foto2Path = 'inconsistencias/fotos/${instalacion}_foto2_$timestamp.jpg';
          await supabase.storage.from('cold').upload(
            foto2Path,
            _foto2File!,
          );
          updates['foto2'] = foto2Path;
          print('📸 Foto 2 subida: $foto2Path');
        } else {
          print('📸 Foto 2 ya existe: $foto2Actual');
        }
      }

      // Subir firma como imagen si existe y es nueva
      if (_firmaImagen != null) {
        final firmaActual = _data!['firma_revisor']?.toString();
        final esFirmaNueva = firmaActual == null || firmaActual.isEmpty;
        
        if (esFirmaNueva) {
          final firmaPngBytes = await _convertirFirmaAPng(_firmaImagen!);
          final firmaPath = 'inconsistencias/fotos/${instalacion}_firma_$timestamp.png';
          await supabase.storage.from('cold').uploadBinary(
            firmaPath,
            firmaPngBytes,
          );
          updates['firma_revisor'] = firmaPath;
          print('✍️ Firma subida: $firmaPath');
        } else {
          print('✍️ Firma ya existe: $firmaActual');
        }
      }

      // ===== PASO 2: AGREGAR FECHA Y COORDENADAS =====
      
      // Guardar fecha de revisión en formato dd-MM-yyyy
      final now = DateTime.now();
      final fechaRevision = '${now.day.toString().padLeft(2, '0')}-${now.month.toString().padLeft(2, '0')}-${now.year}';
      updates['fecha_revision'] = fechaRevision;
      
      // Guardar coordenadas de geolocalización
      final coordenadas = _controllers['geolocalizacion']?.text;
      if (coordenadas != null && coordenadas.isNotEmpty) {
        updates['coordenada_instalacion'] = coordenadas;
      }

      // ===== PASO 3: ACTUALIZAR LA TABLA DE INCONSISTENCIAS =====
      await supabase
          .from('inconsistencias')
          .update(updates)
          .eq('id', widget.inconsistenciaId);

      print('✅ Fecha de revisión guardada: $fechaRevision');
      print('✅ Todos los cambios guardados en la base de datos');
      if (coordenadas != null && coordenadas.isNotEmpty) {
        print('✅ Coordenadas guardadas: $coordenadas');
      }

      // ===== PASO 4: GENERAR Y SUBIR PDF =====
      await _generarYSubirPDF(instalacion, timestamp);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Cambios guardados y PDF generado exitosamente'),
            backgroundColor: Colors.green,
            duration: Duration(seconds: 3),
          ),
        );
        Navigator.pop(context, true); // Retornar true para indicar que se completó
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error al generar PDF: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isSaving = false;
        });
      }
    }
  }

  // Método para mostrar opciones de selección de foto
  Future<void> _mostrarOpcionesFoto(String campoFoto) async {
    showModalBottomSheet(
      context: context,
      builder: (BuildContext context) {
        return SafeArea(
          child: Wrap(
            children: [
              ListTile(
                leading: const Icon(Icons.photo_camera, color: Color(0xFF1A237E)),
                title: const Text('Tomar foto'),
                onTap: () {
                  Navigator.pop(context);
                  _seleccionarFoto(campoFoto, ImageSource.camera);
                },
              ),
              ListTile(
                leading: const Icon(Icons.photo_library, color: Color(0xFF1A237E)),
                title: const Text('Seleccionar de galería'),
                onTap: () {
                  Navigator.pop(context);
                  _seleccionarFoto(campoFoto, ImageSource.gallery);
                },
              ),
              if (_obtenerArchivoFoto(campoFoto) != null)
                ListTile(
                  leading: const Icon(Icons.delete, color: Colors.red),
                  title: const Text('Eliminar foto'),
                  onTap: () {
                    Navigator.pop(context);
                    _eliminarFoto(campoFoto);
                  },
                ),
            ],
          ),
        );
      },
    );
  }

  // Método para seleccionar foto desde cámara o galería
  Future<void> _seleccionarFoto(String campoFoto, ImageSource source) async {
    try {
      XFile? pickedFile;
      
      // Si es cámara, intentar abrir Open Camera primero
      if (source == ImageSource.camera) {
        try {
          // Intentar abrir Open Camera mediante intent de Android
          const platform = MethodChannel('com.lectra.app/camera');
          final String? imagePath = await platform.invokeMethod('openCamera');
          
          if (imagePath != null && imagePath.isNotEmpty) {
            pickedFile = XFile(imagePath);
          }
        } catch (e) {
          print('Open Camera no disponible, usando cámara nativa: $e');
          // Si falla Open Camera, usar la cámara nativa
          pickedFile = await _picker.pickImage(
            source: source,
            maxWidth: 1920,
            maxHeight: 1080,
            imageQuality: 85,
          );
        }
      } else {
        // Para galería, usar el selector normal
        pickedFile = await _picker.pickImage(
          source: source,
          maxWidth: 1920,
          maxHeight: 1080,
          imageQuality: 85,
        );
      }

      if (pickedFile != null) {
        setState(() {
          switch (campoFoto) {
            case 'foto':
              _fotoFile = File(pickedFile!.path);
              _controllers['foto']?.text = pickedFile.name;
              break;
            case 'foto1':
              _foto1File = File(pickedFile!.path);
              _controllers['foto1']?.text = pickedFile.name;
              break;
            case 'foto2':
              _foto2File = File(pickedFile!.path);
              _controllers['foto2']?.text = pickedFile.name;
              break;
          }
        });

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Foto seleccionada correctamente'),
              backgroundColor: Colors.green,
              duration: Duration(seconds: 2),
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error al seleccionar foto: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  // Método para eliminar foto
  void _eliminarFoto(String campoFoto) {
    setState(() {
      switch (campoFoto) {
        case 'foto':
          _fotoFile = null;
          _controllers['foto']?.clear();
          break;
        case 'foto1':
          _foto1File = null;
          _controllers['foto1']?.clear();
          break;
        case 'foto2':
          _foto2File = null;
          _controllers['foto2']?.clear();
          break;
      }
    });

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Foto eliminada'),
        duration: Duration(seconds: 2),
      ),
    );
  }

  // Método helper para obtener el archivo de foto correspondiente
  File? _obtenerArchivoFoto(String campoFoto) {
    switch (campoFoto) {
      case 'foto':
        return _fotoFile;
      case 'foto1':
        return _foto1File;
      case 'foto2':
        return _foto2File;
      default:
        return null;
    }
  }

  // Método para mostrar el diálogo de captura de firma
  Future<void> _mostrarDialogoFirma() async {
    final GlobalKey<SfSignaturePadState> signatureKey = GlobalKey();
    
    await showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text(
            'Capturar Firma',
            style: TextStyle(
              color: Color(0xFF1A237E),
              fontWeight: FontWeight.bold,
            ),
          ),
          content: SizedBox(
            width: double.maxFinite,
            height: 300,
            child: Column(
              children: [
                Expanded(
                  child: Container(
                    decoration: BoxDecoration(
                      border: Border.all(color: Colors.grey),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: SfSignaturePad(
                      key: signatureKey,
                      backgroundColor: Colors.white,
                      strokeColor: Colors.black,
                      minimumStrokeWidth: 1.0,
                      maximumStrokeWidth: 3.0,
                    ),
                  ),
                ),
                const SizedBox(height: 8),
                const Text(
                  'Dibuje su firma en el área superior',
                  style: TextStyle(fontSize: 12, color: Colors.grey),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () {
                signatureKey.currentState?.clear();
              },
              child: const Text('LIMPIAR'),
            ),
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('CANCELAR'),
            ),
            ElevatedButton(
              onPressed: () async {
                final signatureData = await signatureKey.currentState?.toImage();
                if (signatureData != null) {
                  Navigator.pop(context, signatureData);
                } else {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Por favor, dibuje una firma antes de guardar'),
                      backgroundColor: Colors.orange,
                    ),
                  );
                }
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF1A237E),
                foregroundColor: Colors.white,
              ),
              child: const Text('GUARDAR'),
            ),
          ],
        );
      },
    ).then((firma) {
      if (firma != null && firma is ui.Image) {
        setState(() {
          _firmaImagen = firma;
          _controllers['firma_revisor']?.text = 'Firma capturada';
        });
        
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Firma guardada correctamente'),
            backgroundColor: Colors.green,
            duration: Duration(seconds: 2),
          ),
        );
      }
    });
  }

  // Método para eliminar firma
  void _eliminarFirma() {
    setState(() {
      _firmaImagen = null;
      _controllers['firma_revisor']?.clear();
    });
    
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Firma eliminada'),
        duration: Duration(seconds: 2),
      ),
    );
  }

  // Método para capturar geolocalización
  Future<void> _capturarGeolocalizacion() async {
    try {
      // Verificar si el servicio de ubicación está habilitado
      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Por favor, habilite el servicio de ubicación en su dispositivo'),
              backgroundColor: Colors.orange,
              duration: Duration(seconds: 3),
            ),
          );
        }
        return;
      }

      // Verificar permisos de ubicación
      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('Permiso de ubicación denegado'),
                backgroundColor: Colors.red,
              ),
            );
          }
          return;
        }
      }

      if (permission == LocationPermission.deniedForever) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Permiso de ubicación denegado permanentemente. Por favor, habilítelo en la configuración de la aplicación'),
              backgroundColor: Colors.red,
              duration: Duration(seconds: 4),
            ),
          );
        }
        return;
      }

      // Mostrar indicador de carga
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Row(
              children: [
                SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                  ),
                ),
                SizedBox(width: 16),
                Text('Obteniendo ubicación...'),
              ],
            ),
            duration: Duration(seconds: 30),
          ),
        );
      }

      // Obtener la posición actual
      Position position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
        timeLimit: const Duration(seconds: 30),
      );

      // Formatear las coordenadas
      String coordenadas = '${position.latitude}, ${position.longitude}';
      
      setState(() {
        _controllers['geolocalizacion']?.text = coordenadas;
      });

      if (mounted) {
        ScaffoldMessenger.of(context).clearSnackBars();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Ubicación capturada: $coordenadas'),
            backgroundColor: Colors.green,
            duration: const Duration(seconds: 3),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).clearSnackBars();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error al obtener ubicación: ${e.toString()}'),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 3),
          ),
        );
      }
    }
  }

  // Método para abrir Google Maps con la ubicación de la instalación
  Future<void> _abrirGoogleMaps() async {
    try {
      final instalacion = _data!['instalacion']?.toString();
      
      if (instalacion == null || instalacion.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('No hay número de instalación disponible'),
            backgroundColor: Colors.orange,
          ),
        );
        return;
      }

      // Buscar coordenadas en la tabla coordenadas
      final response = await supabase
          .from('coordenadas')
          .select('coordenada')
          .eq('instalacion', instalacion)
          .maybeSingle();

      if (response == null || response['coordenada'] == null) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('No se encontraron coordenadas para esta instalación'),
              backgroundColor: Colors.orange,
              duration: Duration(seconds: 3),
            ),
          );
        }
        return;
      }

      final coordenada = response['coordenada'].toString();
      
      // Parsear coordenadas - soporta formatos: "latitud longitud" o "latitud, longitud" o "latitud,longitud"
      List<String> partes;
      
      if (coordenada.contains(',')) {
        // Formato con coma: "6.27592288, -75.61314146" o "6.27592288,-75.61314146"
        partes = coordenada.split(',').map((e) => e.trim()).toList();
      } else {
        // Formato con espacio: "6.27592288 -75.61314146"
        partes = coordenada.split(' ').where((e) => e.isNotEmpty).toList();
      }
      
      if (partes.length != 2) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Formato de coordenadas inválido: $coordenada'),
              backgroundColor: Colors.red,
            ),
          );
        }
        return;
      }

      final latitud = partes[0];
      final longitud = partes[1];

      // Crear URL de Google Maps
      final url = Uri.parse('https://www.google.com/maps/search/?api=1&query=$latitud,$longitud');

      // Intentar abrir Google Maps
      if (await canLaunchUrl(url)) {
        await launchUrl(url, mode: LaunchMode.externalApplication);
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('No se pudo abrir Google Maps'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error al buscar coordenadas: ${e.toString()}'),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 3),
          ),
        );
      }
    }
  }

  // Método para convertir firma (ui.Image) a PNG bytes
  Future<Uint8List> _convertirFirmaAPng(ui.Image imagen) async {
    final byteData = await imagen.toByteData(format: ui.ImageByteFormat.png);
    return byteData!.buffer.asUint8List();
  }

  // Método para generar PDF y subirlo al storage
  Future<void> _generarYSubirPDF(String instalacion, int timestamp) async {
    final pdf = pw.Document();

    // Cargar imágenes de fotos si existen
    pw.ImageProvider? fotoImage;
    pw.ImageProvider? foto1Image;
    pw.ImageProvider? foto2Image;
    
    if (_fotoFile != null) {
      final bytes = await _fotoFile!.readAsBytes();
      fotoImage = pw.MemoryImage(bytes);
    }
    
    if (_foto1File != null) {
      final bytes = await _foto1File!.readAsBytes();
      foto1Image = pw.MemoryImage(bytes);
    }
    
    if (_foto2File != null) {
      final bytes = await _foto2File!.readAsBytes();
      foto2Image = pw.MemoryImage(bytes);
    }

    // Cargar imagen de la firma si existe
    pw.ImageProvider? firmaPdfImage;
    if (_firmaImagen != null) {
      final firmaPngBytes = await _convertirFirmaAPng(_firmaImagen!);
      firmaPdfImage = pw.MemoryImage(firmaPngBytes);
    }

    // Cargar imagen del mapa estático si hay geolocalización
    pw.ImageProvider? mapaImage;
    final geolocalizacion = _controllers['geolocalizacion']?.text;
    if (geolocalizacion != null && geolocalizacion.isNotEmpty) {
      try {
        final mapaBytes = await _descargarMapaEstatico(geolocalizacion);
        if (mapaBytes != null) {
          mapaImage = pw.MemoryImage(mapaBytes);
        }
      } catch (e) {
        print('Error al descargar mapa: $e');
      }
    }

    pdf.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(20),
        build: (pw.Context context) {
          return [
            // ENCABEZADO CON LOGO
            _buildPdfHeader(),
            pw.SizedBox(height: 5),
            
            // LÍNEA FIJA DE CONTROL DE CALIDAD
            pw.Container(
              width: double.infinity,
              padding: const pw.EdgeInsets.symmetric(vertical: 4, horizontal: 8),
              decoration: pw.BoxDecoration(
                border: pw.Border.all(color: PdfColors.black, width: 1),
              ),
              child: pw.Text(
                '15.3.3.8 Control de calidad a las solicitudes de servicio de lectura realizadas:',
                style: pw.TextStyle(fontSize: 10, fontWeight: pw.FontWeight.bold),
              ),
            ),
            pw.SizedBox(height: 15),

            // DATOS DE LA INSTALACIÓN A INSPECCIONAR
            _buildPdfTituloSeccion('DATOS DE LA INSTALACIÓN A INSPECCIONAR'),
            pw.SizedBox(height: 10),
            _buildPdfTabla([
              ['CICLO', _data!['ciclo']?.toString() ?? ''],
              ['MOTIVO DE LA INSPECCIÓN', _data!['motivo_revision']?.toString() ?? ''],
              ['ORDEN', _data!['orden']?.toString() ?? ''],
              ['CORRERÍA', _data!['correria']?.toString() ?? ''],
              ['MUNICIPIO', _data!['municipio']?.toString() ?? ''],
              ['DIRECCIÓN', _data!['direccion']?.toString() ?? ''],
              ['INSTALACIÓN', _data!['instalacion']?.toString() ?? ''],
              ['TIPO DE SERVICIO', _data!['tipo_consumo']?.toString() ?? ''],
              ['CATEGORÍA', _data!['categoria']?.toString() ?? ''],
              ['LECTURA ANTERIOR', _data!['lectura_anterior']?.toString() ?? ''],
              ['FECHA LECTURA ANTERIOR', _data!['fecha_lectura_anterior']?.toString() ?? ''],
              ['LECTURA ACTUAL', _data!['lectura_actual']?.toString() ?? ''],
              ['FECHA LECTURA ACTUAL', _data!['fecha_lectura_actual']?.toString() ?? ''],
              ['PERIODO DE FACTURACIÓN', _data!['periodo_facturacion']?.toString() ?? ''],
              ['CAUSA DE NO LECTURA U OBSERVACIÓN', _data!['causa_lectura_observacion']?.toString() ?? ''],
              ['OBSERVACIÓN ADICIONAL', _data!['observacion_adicional']?.toString() ?? ''],
              ['ALFANUMÉRICA', _data!['alfanumerica_lector']?.toString() ?? ''],
              ['SERIE MEDIDOR', _data!['serie']?.toString() ?? ''],
              ['UNIDAD OPERATIVA', _data!['lector']?.toString() ?? ''],
            ]),
            pw.SizedBox(height: 20),

            // RESULTADOS DE LA INSPECCIÓN
            _buildPdfTituloSeccion('RESULTADOS DE LA INSPECCIÓN'),
            pw.SizedBox(height: 10),
            _buildPdfTabla([
              ['FECHA DE LA INSPECCIÓN', DateTime.now().toString().substring(0, 10)],
              ['OPERATIVO QUE REALIZA LA INSPECCIÓN', UserSession().codigoSupAux ?? 'N/A'],
              ['LECTURA ENCONTRADA', _controllers['lectura_real']?.text ?? ''],
              ['CAUSA DE NO LECTURA U OBSERVACIÓN', _getFullCausaObservacion()],
              ['OBSERVACIÓN ADICIONAL', _getFullObservacionAdicional()],
            ]),
            pw.SizedBox(height: 10),
            
            // RESULTADO DE LA INSPECCIÓN (Campo grande)
            _buildPdfCampoGrande(
              'RESULTADO DE LA INSPECCIÓN',
              'OBSERVACIONES DEL RESULTADO DE LA INSPECCIÓN:',
              _controllers['alfanumerica_revisor']?.text ?? '',
            ),
            pw.SizedBox(height: 10),
            _buildPdfCampoTexto('Correcciones en Sistema: ${_correccionesEnSistemaSeleccionada ?? "N/A"}'),
            pw.SizedBox(height: 20),

            // GEOLOCALIZACIÓN
            _buildPdfTituloSeccion('GEOLOCALIZACIÓN'),
            pw.SizedBox(height: 10),
            _buildPdfCampoTexto(_controllers['geolocalizacion']?.text ?? 'No capturada'),
            pw.SizedBox(height: 10),
            // Mapa estático si está disponible
            if (mapaImage != null)
              pw.Container(
                height: 300,
                width: double.infinity,
                decoration: pw.BoxDecoration(
                  border: pw.Border.all(color: PdfColors.black, width: 0.5),
                ),
                child: pw.Column(
                  children: [
                    pw.Container(
                      padding: const pw.EdgeInsets.all(4),
                      color: PdfColors.grey300,
                      child: pw.Text(
                        'Mapa de Ubicación',
                        style: pw.TextStyle(fontSize: 9, fontWeight: pw.FontWeight.bold),
                      ),
                    ),
                    pw.Expanded(
                      child: pw.Image(mapaImage, fit: pw.BoxFit.contain),
                    ),
                  ],
                ),
              )
            else if (_controllers['geolocalizacion']?.text != null && _controllers['geolocalizacion']!.text.isNotEmpty)
              pw.Container(
                padding: const pw.EdgeInsets.all(8),
                decoration: pw.BoxDecoration(
                  border: pw.Border.all(color: PdfColors.grey400),
                  borderRadius: const pw.BorderRadius.all(pw.Radius.circular(4)),
                ),
                child: pw.Column(
                  crossAxisAlignment: pw.CrossAxisAlignment.start,
                  children: [
                    pw.Text(
                      'Ubicación en Google Maps:',
                      style: pw.TextStyle(fontSize: 9, fontWeight: pw.FontWeight.bold),
                    ),
                    pw.SizedBox(height: 4),
                    pw.Text(
                      _buildGoogleMapsUrl(_controllers['geolocalizacion']!.text),
                      style: const pw.TextStyle(fontSize: 8, color: PdfColors.blue),
                    ),
                  ],
                ),
              ),
            pw.SizedBox(height: 20),

            // EVIDENCIAS FOTOGRÁFICAS
            _buildPdfTituloSeccion('EVIDENCIAS FOTOGRÁFICAS DE LA INSPECCIÓN:'),
            pw.SizedBox(height: 10),
            _buildPdfFotos(fotoImage, foto1Image, foto2Image),
            pw.SizedBox(height: 20),

            // FIRMA DEL OPERATIVO
            pw.Row(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                pw.Text(
                  'FIRMA DEL OPERATIVO:',
                  style: pw.TextStyle(fontSize: 10, fontWeight: pw.FontWeight.bold),
                ),
                pw.SizedBox(width: 10),
                if (firmaPdfImage != null)
                  pw.Container(
                    height: 60,
                    width: 150,
                    decoration: pw.BoxDecoration(
                      border: pw.Border(
                        bottom: pw.BorderSide(color: PdfColors.black, width: 1),
                      ),
                    ),
                    child: pw.Image(firmaPdfImage, fit: pw.BoxFit.contain),
                  )
                else
                  pw.Container(
                    height: 60,
                    width: 150,
                    decoration: pw.BoxDecoration(
                      border: pw.Border(
                        bottom: pw.BorderSide(color: PdfColors.black, width: 1),
                      ),
                    ),
                  ),
              ],
            ),
          ];
        },
      ),
    );

    // Guardar PDF
    final pdfBytes = await pdf.save();
    
    // Construir nombre del archivo según estructura:
    // fecha_correria_instalacion_codigoLogueado_tipoConsumo.pdf
    // Ejemplo: 20251001_10001228094_205623201000820000_LEC_325_7.pdf
    final fechaFormateada = DateTime.now().toString().substring(0, 10).replaceAll('-', '');
    final correria = _data!['correria']?.toString() ?? '';
    final codigoLogueado = UserSession().codigoSupAux ?? 'UNKNOWN';
    final tipoConsumo = _data!['cod_tipo_consumo']?.toString() ?? '';
    
    final nombreArchivo = '${fechaFormateada}_${correria}_${instalacion}_${codigoLogueado}_$tipoConsumo.pdf';
    final pdfPath = 'inconsistencias/pdfs/$nombreArchivo';
    
    print('📄 Generando PDF: $nombreArchivo');
    
    await supabase.storage.from('cold').uploadBinary(
      pdfPath,
      pdfBytes,
    );
    
    // Actualizar la columna pdf con la ruta del archivo
    await supabase
        .from('inconsistencias')
        .update({'pdf': pdfPath})
        .eq('id', widget.inconsistenciaId);
    
    print('✅ Ruta del PDF guardada en BD: $pdfPath');
  }

  // Helper para construir encabezado del PDF
  pw.Widget _buildPdfHeader() {
    return pw.Container(
      decoration: pw.BoxDecoration(
        border: pw.Border.all(color: PdfColors.black, width: 1),
      ),
      child: pw.Row(
        children: [
          // Columna izquierda
          pw.Expanded(
            flex: 5,
            child: pw.Container(
              padding: const pw.EdgeInsets.all(8),
              decoration: pw.BoxDecoration(
                border: pw.Border(right: pw.BorderSide(color: PdfColors.black)),
              ),
              child: pw.Column(
                crossAxisAlignment: pw.CrossAxisAlignment.start,
                children: [
                  pw.Text(
                    'Inspección en campo',
                    style: pw.TextStyle(fontSize: 10, fontWeight: pw.FontWeight.bold),
                  ),
                  pw.Text(
                    'Contrato CW-280698',
                    style: const pw.TextStyle(fontSize: 9),
                  ),
                ],
              ),
            ),
          ),
          // Columna central
          pw.Expanded(
            flex: 5,
            child: pw.Container(
              padding: const pw.EdgeInsets.all(8),
              decoration: pw.BoxDecoration(
                border: pw.Border(right: pw.BorderSide(color: PdfColors.black)),
              ),
              child: pw.Column(
                crossAxisAlignment: pw.CrossAxisAlignment.start,
                children: [
                  pw.Text(
                    'UTIC SAS',
                    style: pw.TextStyle(fontSize: 10, fontWeight: pw.FontWeight.bold),
                  ),
                  pw.Text(
                    'NIT: 901.777.536',
                    style: const pw.TextStyle(fontSize: 9),
                  ),
                ],
              ),
            ),
          ),
          // Columna derecha - Logo
          pw.Expanded(
            flex: 3,
            child: pw.Container(
              padding: const pw.EdgeInsets.all(4),
              child: pw.Center(
                child: pw.Text(
                  'UTIC',
                  style: pw.TextStyle(
                    fontSize: 16,
                    fontWeight: pw.FontWeight.bold,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // Helper para construir título de sección centrado
  pw.Widget _buildPdfTituloSeccion(String titulo) {
    return pw.Center(
      child: pw.Text(
        titulo,
        style: pw.TextStyle(fontSize: 11, fontWeight: pw.FontWeight.bold),
        textAlign: pw.TextAlign.center,
      ),
    );
  }

  // Helper para construir tabla con bordes
  pw.Widget _buildPdfTabla(List<List<String>> filas) {
    return pw.Table(
      border: pw.TableBorder.all(color: PdfColors.black, width: 0.5),
      columnWidths: {
        0: const pw.FlexColumnWidth(2),
        1: const pw.FlexColumnWidth(3),
      },
      children: filas.map((fila) {
        return pw.TableRow(
          children: [
            pw.Padding(
              padding: const pw.EdgeInsets.all(4),
              child: pw.Text(
                fila[0],
                style: const pw.TextStyle(fontSize: 8),
              ),
            ),
            pw.Padding(
              padding: const pw.EdgeInsets.all(4),
              child: pw.Text(
                fila[1],
                style: const pw.TextStyle(fontSize: 8),
              ),
            ),
          ],
        );
      }).toList(),
    );
  }

  // Helper para construir campo de texto grande
  pw.Widget _buildPdfCampoGrande(String titulo, String subtitulo, String contenido) {
    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        pw.Container(
          width: double.infinity,
          padding: const pw.EdgeInsets.all(4),
          decoration: pw.BoxDecoration(
            border: pw.Border.all(color: PdfColors.black, width: 0.5),
          ),
          child: pw.Text(
            titulo,
            style: const pw.TextStyle(fontSize: 8),
          ),
        ),
        pw.Container(
          width: double.infinity,
          padding: const pw.EdgeInsets.all(4),
          decoration: pw.BoxDecoration(
            border: pw.Border.all(color: PdfColors.black, width: 0.5),
          ),
          child: pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              pw.Text(
                subtitulo,
                style: const pw.TextStyle(fontSize: 8),
              ),
              pw.SizedBox(height: 40),
              pw.Text(
                contenido,
                style: const pw.TextStyle(fontSize: 8),
              ),
            ],
          ),
        ),
      ],
    );
  }

  String _getFullCausaObservacion() {
    if (_causaObservacionSeleccionada == null || _causaObservacionSeleccionada!.isEmpty) {
      return 'N/A';
    }
    final causa = _causasObservacion.firstWhere(
      (c) => c['value'] == _causaObservacionSeleccionada,
      orElse: () => {'value': '', 'label': _causaObservacionSeleccionada!},
    );
    return causa['label'] ?? _causaObservacionSeleccionada!;
  }

  String _getFullObservacionAdicional() {
    if (_observacionAdicionalRealSeleccionada == null || _observacionAdicionalRealSeleccionada!.isEmpty) {
      return 'N/A';
    }
    final obs = _observacionesAdicionales.firstWhere(
      (o) => o['value'] == _observacionAdicionalRealSeleccionada,
      orElse: () => {'value': '', 'label': _observacionAdicionalRealSeleccionada!},
    );
    return obs['label'] ?? _observacionAdicionalRealSeleccionada!;
  }

  Future<Uint8List?> _descargarMapaEstatico(String coordenadas) async {
    try {
      // Parsear coordenadas
      final coords = coordenadas.replaceAll(',', ' ').trim().split(RegExp(r'\s+'));
      if (coords.length < 2) return null;
      
      final lat = double.tryParse(coords[0]);
      final lon = double.tryParse(coords[1]);
      
      if (lat == null || lon == null) return null;
      
      print('📍 Generando mapa para coordenadas: $lat, $lon');
      
      // Generar imagen del mapa usando Canvas de Flutter
      return await _generarImagenMapa(lat, lon, coordenadas);
    } catch (e) {
      print('❌ Error generando mapa: $e');
      return null;
    }
  }

  // Convertir coordenadas geográficas a coordenadas de tile
  ({int x, int y}) _latLonToTile(double lat, double lon, int zoom) {
    final n = math.pow(2, zoom);
    final xTile = ((lon + 180.0) / 360.0 * n).floor();
    final latRad = lat * math.pi / 180.0;
    final yTile = ((1.0 - math.log(math.tan(latRad) + 1.0 / math.cos(latRad)) / math.pi) / 2.0 * n).floor();
    return (x: xTile, y: yTile);
  }

  // Descargar tile de OpenStreetMap
  Future<ui.Image?> _descargarTile(int x, int y, int zoom) async {
    try {
      final url = 'https://tile.openstreetmap.org/$zoom/$x/$y.png';
      print('📥 Descargando tile: $url');
      
      final response = await http.get(
        Uri.parse(url),
        headers: {
          'User-Agent': 'LECTRA App/1.0',
        },
      ).timeout(const Duration(seconds: 10));
      
      if (response.statusCode == 200) {
        final bytes = response.bodyBytes;
        final codec = await ui.instantiateImageCodec(bytes);
        final frame = await codec.getNextFrame();
        print('✅ Tile descargado: ${bytes.length} bytes');
        return frame.image;
      } else {
        print('❌ Error al descargar tile: ${response.statusCode}');
        return null;
      }
    } catch (e) {
      print('❌ Error al descargar tile: $e');
      return null;
    }
  }

  Future<Uint8List?> _generarImagenMapa(double lat, double lon, String coordenadasTexto) async {
    try {
      const width = 600.0;
      const height = 400.0;
      const zoom = 17; // Zoom 17 para ver calles con detalle
      
      final recorder = ui.PictureRecorder();
      final canvas = ui.Canvas(recorder);
      
      // Fondo blanco mientras cargan los tiles
      final bgPaint = ui.Paint()..color = const ui.Color(0xFFFFFFFF);
      canvas.drawRect(const ui.Rect.fromLTWH(0, 0, width, height), bgPaint);
      
      // Calcular el tile central donde está la ubicación
      final centerTile = _latLonToTile(lat, lon, zoom);
      print('📍 Tile central: x=${centerTile.x}, y=${centerTile.y}, zoom=$zoom');
      
      // Descargar tiles en un área 3x3 alrededor del punto central
      final tiles = <({int x, int y, ui.Image? image})>[];
      
      for (int dx = -1; dx <= 1; dx++) {
        for (int dy = -1; dy <= 1; dy++) {
          final tileX = centerTile.x + dx;
          final tileY = centerTile.y + dy;
          final tileImage = await _descargarTile(tileX, tileY, zoom);
          tiles.add((x: tileX, y: tileY, image: tileImage));
        }
      }
      
      // Calcular posición del punto en coordenadas de píxeles dentro del tile
      final n = math.pow(2, zoom);
      final xTileFloat = (lon + 180.0) / 360.0 * n;
      final latRad = lat * math.pi / 180.0;
      final yTileFloat = (1.0 - math.log(math.tan(latRad) + 1.0 / math.cos(latRad)) / math.pi) / 2.0 * n;
      
      // Posición dentro del tile (0-256)
      final xInTile = (xTileFloat - centerTile.x) * 256;
      final yInTile = (yTileFloat - centerTile.y) * 256;
      
      // Calcular offset para centrar el mapa en el punto
      final offsetX = width / 2 - xInTile;
      final offsetY = height / 2 - yInTile;
      
      // Dibujar todos los tiles
      for (final tile in tiles) {
        if (tile.image != null) {
          final dx = (tile.x - centerTile.x) * 256.0 + offsetX;
          final dy = (tile.y - centerTile.y) * 256.0 + offsetY;
          
          canvas.drawImage(
            tile.image!,
            ui.Offset(dx, dy),
            ui.Paint(),
          );
        }
      }
      
      // Dibujar marcador de ubicación (pin rojo) en el centro
      const centerX = width / 2;
      const centerY = height / 2;
      
      // Sombra del pin
      final shadowPaint = ui.Paint()
        ..color = const ui.Color(0x4D000000)
        ..maskFilter = const ui.MaskFilter.blur(ui.BlurStyle.normal, 3);
      canvas.drawCircle(const ui.Offset(centerX, centerY + 35), 15, shadowPaint);
      
      // Pin rojo (forma de gota)
      final pinPath = ui.Path();
      pinPath.moveTo(centerX, centerY - 30);
      pinPath.quadraticBezierTo(centerX - 20, centerY - 30, centerX - 20, centerY - 10);
      pinPath.quadraticBezierTo(centerX - 20, centerY + 5, centerX, centerY + 25);
      pinPath.quadraticBezierTo(centerX + 20, centerY + 5, centerX + 20, centerY - 10);
      pinPath.quadraticBezierTo(centerX + 20, centerY - 30, centerX, centerY - 30);
      pinPath.close();
      
      final pinPaint = ui.Paint()
        ..color = const ui.Color(0xFFF44336)
        ..style = ui.PaintingStyle.fill;
      canvas.drawPath(pinPath, pinPaint);
      
      final pinBorderPaint = ui.Paint()
        ..color = const ui.Color(0xFFFFFFFF)
        ..style = ui.PaintingStyle.stroke
        ..strokeWidth = 2;
      canvas.drawPath(pinPath, pinBorderPaint);
      
      final centerDotPaint = ui.Paint()
        ..color = const ui.Color(0xFFFFFFFF)
        ..style = ui.PaintingStyle.fill;
      canvas.drawCircle(const ui.Offset(centerX, centerY - 15), 8, centerDotPaint);
      
      // Dibujar coordenadas en la parte superior
      final coordBgPaint = ui.Paint()
        ..color = const ui.Color(0xE6FFFFFF);
      canvas.drawRect(const ui.Rect.fromLTWH(0, 0, width, 35), coordBgPaint);
      
      final textPainter = TextPainter(
        textDirection: ui.TextDirection.ltr,
        text: TextSpan(
          text: '📍 $coordenadasTexto',
          style: const TextStyle(
            color: Color(0xFF000000),
            fontSize: 14,
            fontWeight: FontWeight.bold,
          ),
        ),
      );
      textPainter.layout();
      textPainter.paint(canvas, const ui.Offset(10, 10));
      
      // Agregar atribución de OpenStreetMap
      final attributionBgPaint = ui.Paint()
        ..color = const ui.Color(0xE6FFFFFF);
      canvas.drawRect(ui.Rect.fromLTWH(width - 160, height - 25, 160, 25), attributionBgPaint);
      
      final attributionText = TextPainter(
        textDirection: ui.TextDirection.ltr,
        text: const TextSpan(
          text: '© OpenStreetMap',
          style: TextStyle(
            color: Color(0xFF000000),
            fontSize: 10,
          ),
        ),
      );
      attributionText.layout();
      attributionText.paint(canvas, ui.Offset(width - 155, height - 20));
      
      // Convertir a imagen
      final picture = recorder.endRecording();
      final img = await picture.toImage(width.toInt(), height.toInt());
      final byteData = await img.toByteData(format: ui.ImageByteFormat.png);
      
      if (byteData == null) return null;
      
      final bytes = byteData.buffer.asUint8List();
      print('✅ Mapa con tiles reales generado exitosamente (${bytes.length} bytes)');
      
      return bytes;
    } catch (e) {
      print('❌ Error al generar imagen del mapa: $e');
      return null;
    }
  }

  String _buildGoogleMapsUrl(String coordenadas) {
    // Parsear coordenadas en formato "lat, lon" o "lat lon"
    final coords = coordenadas.replaceAll(',', ' ').trim().split(RegExp(r'\s+'));
    if (coords.length >= 2) {
      final lat = coords[0];
      final lon = coords[1];
      return 'https://www.google.com/maps?q=$lat,$lon';
    }
    return coordenadas;
  }

  // Helper para construir campo de texto simple
  pw.Widget _buildPdfCampoTexto(String contenido) {
    return pw.Container(
      width: double.infinity,
      height: 80,
      padding: const pw.EdgeInsets.all(8),
      decoration: pw.BoxDecoration(
        border: pw.Border.all(color: PdfColors.black, width: 0.5),
      ),
      child: pw.Text(
        contenido,
        style: const pw.TextStyle(fontSize: 8),
      ),
    );
  }

  // Helper para construir sección de fotos
  pw.Widget _buildPdfFotos(
    pw.ImageProvider? foto,
    pw.ImageProvider? foto1,
    pw.ImageProvider? foto2,
  ) {
    return pw.Container(
      height: 200,
      decoration: pw.BoxDecoration(
        border: pw.Border.all(color: PdfColors.black, width: 0.5),
      ),
      child: pw.Row(
        children: [
          // Foto 1
          pw.Expanded(
            child: pw.Container(
              decoration: pw.BoxDecoration(
                border: pw.Border(right: pw.BorderSide(color: PdfColors.black, width: 0.5)),
              ),
              child: foto != null
                  ? pw.Image(foto, fit: pw.BoxFit.contain)
                  : pw.Center(
                      child: pw.Text(
                        '<<Foto>>',
                        style: const pw.TextStyle(fontSize: 8, color: PdfColors.grey),
                      ),
                    ),
            ),
          ),
          // Foto 2
          pw.Expanded(
            child: pw.Container(
              decoration: pw.BoxDecoration(
                border: pw.Border(right: pw.BorderSide(color: PdfColors.black, width: 0.5)),
              ),
              child: foto1 != null
                  ? pw.Image(foto1, fit: pw.BoxFit.contain)
                  : pw.Center(
                      child: pw.Text(
                        '<<Foto1>>',
                        style: const pw.TextStyle(fontSize: 8, color: PdfColors.grey),
                      ),
                    ),
            ),
          ),
          // Foto 3
          pw.Expanded(
            child: pw.Container(
              child: foto2 != null
                  ? pw.Image(foto2, fit: pw.BoxFit.contain)
                  : pw.Center(
                      child: pw.Text(
                        '<<Foto_1>>',
                        style: const pw.TextStyle(fontSize: 8, color: PdfColors.grey),
                      ),
                    ),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: true,
      onPopInvokedWithResult: (didPop, result) {
        if (didPop && _hasChanges) {
          // Si ya hizo pop y hubo cambios, retornar true
          // Esto se maneja automáticamente por el Navigator
        }
      },
      child: Scaffold(
        appBar: AppBar(
          title: const Text(
            'Editar Inconsistencia',
            style: TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.bold,
            ),
          ),
          backgroundColor: const Color(0xFF1A237E),
          iconTheme: const IconThemeData(color: Colors.white),
          leading: IconButton(
            icon: const Icon(Icons.arrow_back),
            onPressed: () {
              Navigator.pop(context, _hasChanges);
            },
          ),
        ),
      body: _isLoading
          ? const Center(
              child: CircularProgressIndicator(
                color: Color(0xFF1A237E),
              ),
            )
          : _errorMessage != null
              ? Center(
                  child: Padding(
                    padding: const EdgeInsets.all(24),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.error_outline,
                          size: 64,
                          color: Colors.red.shade300,
                        ),
                        const SizedBox(height: 16),
                        Text(
                          _errorMessage!,
                          textAlign: TextAlign.center,
                          style: const TextStyle(fontSize: 16),
                        ),
                        const SizedBox(height: 24),
                        ElevatedButton.icon(
                          onPressed: _loadData,
                          icon: const Icon(Icons.refresh),
                          label: const Text('Reintentar'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF1A237E),
                            foregroundColor: Colors.white,
                          ),
                        ),
                      ],
                    ),
                  ),
                )
              : Form(
                  key: _formKey,
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // SECCIÓN: INFORMACIÓN BÁSICA (Solo lectura)
                        _buildSectionTitle('INFORMACIÓN BÁSICA', Icons.info_outline),
                        _buildReadOnlyField('Dirección', _data!['direccion']),
                        _buildReadOnlyFieldConBoton('Instalación', _data!['instalacion'], 'IR', _abrirGoogleMaps),
                        _buildReadOnlyField('Serie', _data!['serie']),
                        _buildReadOnlyField('Municipio', _data!['municipio']),
                        _buildReadOnlyField('Categoría', _data!['categoria']),
                        const SizedBox(height: 24),

                        // SECCIÓN: LECTURAS (Solo lectura)
                        _buildSectionTitle('LECTURAS', Icons.analytics_outlined),
                        _buildReadOnlyField('Lectura Actual', _data!['lectura_actual']),
                        _buildReadOnlyField('Lectura Anterior', _data!['lectura_anterior']),
                        _buildReadOnlyField('Lectura 3 Meses', _data!['lectura_tres_meses']),
                        _buildReadOnlyField('Lectura 4 Meses', _data!['lectura_cuatro_meses']),
                        const SizedBox(height: 24),

                        // SECCIÓN: CONSUMO Y TIPO (Solo lectura)
                        _buildSectionTitle('CONSUMO Y TIPO', Icons.water_drop_outlined),
                        _buildReadOnlyField('Tipo Consumo', _data!['tipo_consumo']),
                        _buildReadOnlyField('Código Tipo Consumo', _data!['cod_tipo_consumo']),
                        _buildReadOnlyField('Servicio Suscrito', _data!['servicio_suscrito']),
                        const SizedBox(height: 24),

                        // SECCIÓN: FECHAS Y CICLO (Solo lectura)
                        _buildSectionTitle('FECHAS Y CICLO', Icons.calendar_today_outlined),
                        _buildReadOnlyField('Fecha Lectura Anterior', _data!['fecha_lectura_anterior']),
                        _buildReadOnlyField('Fecha Lectura Actual', _data!['fecha_lectura_actual']),
                        _buildReadOnlyField('Periodo Facturación', _data!['periodo_facturacion']),
                        _buildReadOnlyField('Ciclo', _data!['ciclo']),
                        _buildReadOnlyField('Correría', _data!['correria']),
                        _buildReadOnlyField('Orden', _data!['orden']),
                        const SizedBox(height: 24),

                        // SECCIÓN: OBSERVACIONES (Solo lectura)
                        _buildSectionTitle('OBSERVACIONES', Icons.note_outlined),
                        _buildReadOnlyField('Motivo Revisión', _data!['motivo_revision']),
                        _buildReadOnlyField('Causa Lectura/Observación', _data!['causa_lectura_observacion']),
                        _buildReadOnlyField('Observación Adicional', _data!['observacion_adicional']),
                        _buildReadOnlyField('Advertencia', _data!['advertencia']),
                        const SizedBox(height: 24),

                        // SECCIÓN: PERSONAL (Solo lectura)
                        _buildSectionTitle('PERSONAL', Icons.people_outline),
                        _buildReadOnlyField('Lector', _data!['lector']),
                        _buildReadOnlyField('Alfanumérica Lector', _data!['alfanumerica_lector']),
                        const SizedBox(height: 24),

                        // SECCIÓN: CAMPOS EDITABLES
                        _buildSectionTitle('DATOS DE REVISIÓN - EDITABLES', Icons.edit_outlined, color: Colors.orange),
                        
                        // Dropdown para Causa Observación
                        Padding(
                          padding: const EdgeInsets.only(bottom: 16),
                          child: DropdownButtonFormField<String>(
                            initialValue: _causaObservacionSeleccionada,
                            decoration: InputDecoration(
                              labelText: 'Causa Observación',
                              labelStyle: const TextStyle(
                                color: Color(0xFF1A237E),
                                fontWeight: FontWeight.bold,
                              ),
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(8),
                              ),
                              enabledBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(8),
                                borderSide: const BorderSide(color: Colors.orange, width: 2),
                              ),
                              focusedBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(8),
                                borderSide: const BorderSide(color: Color(0xFF1A237E), width: 2),
                              ),
                              filled: true,
                              fillColor: Colors.orange.shade50,
                            ),
                            items: _causasObservacion.map((causa) {
                              return DropdownMenuItem<String>(
                                value: causa['value'],
                                child: Text(
                                  causa['label']!,
                                  style: const TextStyle(fontSize: 14),
                                ),
                              );
                            }).toList(),
                            onChanged: (value) {
                              setState(() {
                                _causaObservacionSeleccionada = value;
                              });
                            },
                          ),
                        ),
                        
                        // Observación Adicional Real - Dropdown
                        Padding(
                          padding: const EdgeInsets.only(bottom: 12),
                          child: DropdownButtonFormField<String>(
                            key: const ValueKey('observacion_adicional_real_dropdown'),
                            initialValue: _observacionAdicionalRealSeleccionada,
                            decoration: InputDecoration(
                              labelText: 'Observación Adicional Real',
                              border: OutlineInputBorder(
                                borderSide: BorderSide(color: Colors.orange.shade700, width: 2),
                              ),
                              enabledBorder: OutlineInputBorder(
                                borderSide: BorderSide(color: Colors.orange.shade700, width: 2),
                              ),
                              focusedBorder: OutlineInputBorder(
                                borderSide: BorderSide(color: Colors.orange.shade700, width: 2),
                              ),
                              filled: true,
                              fillColor: Colors.orange.shade50,
                            ),
                            items: _observacionesAdicionales.map((obs) {
                              return DropdownMenuItem<String>(
                                value: obs['value'],
                                child: Text(
                                  obs['label']!,
                                  style: const TextStyle(fontSize: 14),
                                ),
                              );
                            }).toList(),
                            onChanged: (value) {
                              setState(() {
                                _observacionAdicionalRealSeleccionada = value;
                              });
                            },
                          ),
                        ),
                        
                        _buildEditableField(
                          'alfanumerica_revisor', 
                          'Alfanumérica Revisor',
                          textCapitalization: TextCapitalization.none,
                        ),
                        _buildEditableField(
                          'lectura_real', 
                          'Lectura Real', 
                          keyboardType: TextInputType.number,
                          inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                        ),
                        
                        // Correcciones en Sistema - Dropdown
                        Padding(
                          padding: const EdgeInsets.only(bottom: 12),
                          child: DropdownButtonFormField<String>(
                            key: const ValueKey('correcciones_en_sistema_dropdown'),
                            initialValue: _correccionesEnSistemaSeleccionada,
                            decoration: InputDecoration(
                              labelText: 'Correcciones en Sistema',
                              border: OutlineInputBorder(
                                borderSide: BorderSide(color: Colors.orange.shade700, width: 2),
                              ),
                              enabledBorder: OutlineInputBorder(
                                borderSide: BorderSide(color: Colors.orange.shade700, width: 2),
                              ),
                              focusedBorder: OutlineInputBorder(
                                borderSide: BorderSide(color: Colors.orange.shade700, width: 2),
                              ),
                              filled: true,
                              fillColor: Colors.orange.shade50,
                            ),
                            items: _correccionesEnSistema.map((corr) {
                              return DropdownMenuItem<String>(
                                value: corr['value'],
                                child: Text(
                                  corr['label']!,
                                  style: const TextStyle(fontSize: 14),
                                ),
                              );
                            }).toList(),
                            onChanged: (value) {
                              setState(() {
                                _correccionesEnSistemaSeleccionada = value;
                              });
                            },
                          ),
                        ),
                        
                        _buildEditableField(
                          'advertencia_revisor', 
                          'Advertencia',
                          textCapitalization: TextCapitalization.sentences,
                          maxLines: 3,
                        ),
                        
                        _buildCampoGeolocalizacion(),
                        const SizedBox(height: 16),
                        
                        // Subsección: Fotos
                        Padding(
                          padding: const EdgeInsets.only(bottom: 12, top: 8),
                          child: Row(
                            children: [
                              Icon(Icons.photo_camera, color: Colors.orange.shade700, size: 20),
                              const SizedBox(width: 8),
                              Text(
                                'FOTOS',
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.orange.shade700,
                                ),
                              ),
                            ],
                          ),
                        ),
                        _buildCampoFoto('foto', 'Foto'),
                        _buildCampoFoto('foto1', 'Foto 1'),
                        _buildCampoFoto('foto2', 'Foto 2'),
                        const SizedBox(height: 16),
                        
                        // Subsección: Firma
                        Padding(
                          padding: const EdgeInsets.only(bottom: 12, top: 8),
                          child: Row(
                            children: [
                              Icon(Icons.draw, color: Colors.orange.shade700, size: 20),
                              const SizedBox(width: 8),
                              Text(
                                'FIRMA',
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.orange.shade700,
                                ),
                              ),
                            ],
                          ),
                        ),
                        _buildCampoFirma(),
                        const SizedBox(height: 24),

                        // Botón guardar cambios
                        SizedBox(
                          width: double.infinity,
                          child: ElevatedButton.icon(
                            onPressed: _isSaving ? null : _guardarCambios,
                            icon: _isSaving
                                ? const SizedBox(
                                    width: 20,
                                    height: 20,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                      valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                                    ),
                                  )
                                : const Icon(Icons.save),
                            label: Text(
                              _isSaving ? 'GUARDANDO...' : 'GUARDAR CAMBIOS',
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 16,
                              ),
                            ),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFF1A237E),
                              foregroundColor: Colors.white,
                              padding: const EdgeInsets.symmetric(vertical: 16),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(8),
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(height: 12),

                        // Botón generar PDF
                        SizedBox(
                          width: double.infinity,
                          child: ElevatedButton.icon(
                            onPressed: _isSaving ? null : _generarPDF,
                            icon: _isSaving
                                ? const SizedBox(
                                    width: 20,
                                    height: 20,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                      valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                                    ),
                                  )
                                : const Icon(Icons.picture_as_pdf),
                            label: Text(
                              _isSaving ? 'GENERANDO PDF...' : 'GENERAR PDF',
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 16,
                              ),
                            ),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.orange.shade700,
                              foregroundColor: Colors.white,
                              padding: const EdgeInsets.symmetric(vertical: 16),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(8),
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(height: 24),
                      ],
                    ),
                  ),
                ),
      ),
    );
  }

  Widget _buildSectionTitle(String title, IconData icon, {Color? color}) {
    final titleColor = color ?? const Color(0xFF1A237E);
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Row(
        children: [
          Icon(icon, color: titleColor, size: 24),
          const SizedBox(width: 8),
          Text(
            title,
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: titleColor,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildReadOnlyField(String label, dynamic value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Colors.grey.shade100,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: Colors.grey.shade300),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              flex: 2,
              child: Text(
                '$label:',
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 14,
                  color: Colors.black87,
                ),
              ),
            ),
            Expanded(
              flex: 3,
              child: Text(
                value?.toString() ?? 'N/A',
                style: TextStyle(
                  fontSize: 14,
                  color: Colors.grey.shade700,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildReadOnlyFieldConBoton(String label, dynamic value, String textoBoton, VoidCallback onPressed) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Colors.grey.shade100,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: Colors.grey.shade300),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              flex: 2,
              child: Text(
                '$label:',
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 14,
                  color: Colors.black87,
                ),
              ),
            ),
            Expanded(
              flex: 3,
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      value?.toString() ?? 'N/A',
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.grey.shade700,
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  ElevatedButton(
                    onPressed: onPressed,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF1A237E),
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                      minimumSize: const Size(40, 30),
                      textStyle: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    child: Text(textoBoton),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEditableField(
    String fieldKey,
    String label, {
    int maxLines = 1,
    TextInputType? keyboardType,
    List<TextInputFormatter>? inputFormatters,
    TextCapitalization textCapitalization = TextCapitalization.characters,
  }) {
    final controller = _controllers[fieldKey];
    if (controller == null) {
      return const SizedBox.shrink();
    }

    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: TextFormField(
        controller: controller,
        maxLines: maxLines,
        keyboardType: keyboardType,
        inputFormatters: inputFormatters,
        textCapitalization: textCapitalization,
        decoration: InputDecoration(
          labelText: label,
          labelStyle: const TextStyle(
            color: Color(0xFF1A237E),
            fontWeight: FontWeight.bold,
          ),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(8),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(8),
            borderSide: const BorderSide(color: Colors.orange, width: 2),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(8),
            borderSide: const BorderSide(color: Color(0xFF1A237E), width: 2),
          ),
          filled: true,
          fillColor: Colors.orange.shade50,
        ),
      ),
    );
  }

  // Widget personalizado para campos de foto con cámara/galería
  Widget _buildCampoFoto(String campoFoto, String label) {
    final File? archivoFoto = _obtenerArchivoFoto(campoFoto);
    
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Container(
        decoration: BoxDecoration(
          border: Border.all(color: Colors.orange, width: 2),
          borderRadius: BorderRadius.circular(8),
          color: Colors.orange.shade50,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Encabezado con label y botón
            Padding(
              padding: const EdgeInsets.all(12),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      label,
                      style: const TextStyle(
                        color: Color(0xFF1A237E),
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
                  ),
                  ElevatedButton.icon(
                    onPressed: () => _mostrarOpcionesFoto(campoFoto),
                    icon: const Icon(Icons.add_a_photo, size: 18),
                    label: Text(archivoFoto == null ? 'Agregar' : 'Cambiar'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF1A237E),
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    ),
                  ),
                ],
              ),
            ),
            
            // Vista previa de la imagen si existe
            if (archivoFoto != null)
              Padding(
                padding: const EdgeInsets.fromLTRB(12, 0, 12, 12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    ClipRRect(
                      borderRadius: BorderRadius.circular(8),
                      child: Image.file(
                        archivoFoto,
                        height: 200,
                        width: double.infinity,
                        fit: BoxFit.cover,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        const Icon(Icons.check_circle, color: Colors.green, size: 16),
                        const SizedBox(width: 4),
                        Expanded(
                          child: Text(
                            'Foto seleccionada',
                            style: TextStyle(
                              color: Colors.grey.shade700,
                              fontSize: 12,
                            ),
                          ),
                        ),
                        TextButton.icon(
                          onPressed: () => _eliminarFoto(campoFoto),
                          icon: const Icon(Icons.delete, size: 16, color: Colors.red),
                          label: const Text('Eliminar', style: TextStyle(color: Colors.red, fontSize: 12)),
                          style: TextButton.styleFrom(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              )
            else
              Padding(
                padding: const EdgeInsets.fromLTRB(12, 0, 12, 12),
                child: Row(
                  children: [
                    Icon(Icons.info_outline, color: Colors.grey.shade600, size: 16),
                    const SizedBox(width: 4),
                    Text(
                      'Sin foto seleccionada',
                      style: TextStyle(
                        color: Colors.grey.shade600,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ),
          ],
        ),
      ),
    );
  }

  // Widget personalizado para el campo de geolocalización
  Widget _buildCampoGeolocalizacion() {
    final controller = _controllers['geolocalizacion'];
    final tieneCoordenadas = controller?.text.isNotEmpty ?? false;
    
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Container(
        decoration: BoxDecoration(
          border: Border.all(color: Colors.orange, width: 2),
          borderRadius: BorderRadius.circular(8),
          color: Colors.orange.shade50,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Encabezado con label y botón
            Padding(
              padding: const EdgeInsets.all(12),
              child: Row(
                children: [
                  Expanded(
                    child: const Text(
                      'Geolocalización',
                      style: TextStyle(
                        color: Color(0xFF1A237E),
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
                  ),
                  ElevatedButton.icon(
                    onPressed: _capturarGeolocalizacion,
                    icon: const Icon(Icons.my_location, size: 18),
                    label: Text(tieneCoordenadas ? 'Actualizar' : 'Capturar'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF1A237E),
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    ),
                  ),
                ],
              ),
            ),
            
            // Campo de texto con las coordenadas
            Padding(
              padding: const EdgeInsets.fromLTRB(12, 0, 12, 12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  TextFormField(
                    controller: controller,
                    readOnly: true,
                    maxLines: 2,
                    decoration: InputDecoration(
                      hintText: 'Presione "Capturar" para obtener coordenadas',
                      hintStyle: TextStyle(
                        color: Colors.grey.shade600,
                        fontSize: 14,
                      ),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                        borderSide: BorderSide(color: Colors.grey.shade400, width: 1),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                        borderSide: const BorderSide(color: Color(0xFF1A237E), width: 2),
                      ),
                      filled: true,
                      fillColor: Colors.white,
                      contentPadding: const EdgeInsets.all(12),
                      prefixIcon: Icon(
                        Icons.location_on,
                        color: tieneCoordenadas ? Colors.green : Colors.grey.shade600,
                      ),
                    ),
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  if (tieneCoordenadas) ...[
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        const Icon(Icons.check_circle, color: Colors.green, size: 16),
                        const SizedBox(width: 4),
                        Expanded(
                          child: Text(
                            'Coordenadas capturadas',
                            style: TextStyle(
                              color: Colors.grey.shade700,
                              fontSize: 12,
                            ),
                          ),
                        ),
                        TextButton.icon(
                          onPressed: () {
                            setState(() {
                              controller?.clear();
                            });
                          },
                          icon: const Icon(Icons.clear, size: 16, color: Colors.red),
                          label: const Text('Limpiar', style: TextStyle(color: Colors.red, fontSize: 12)),
                          style: TextButton.styleFrom(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                          ),
                        ),
                      ],
                    ),
                  ] else
                    Padding(
                      padding: const EdgeInsets.only(top: 8),
                      child: Row(
                        children: [
                          Icon(Icons.info_outline, color: Colors.grey.shade600, size: 16),
                          const SizedBox(width: 4),
                          Text(
                            'Sin coordenadas capturadas',
                            style: TextStyle(
                              color: Colors.grey.shade600,
                              fontSize: 12,
                            ),
                          ),
                        ],
                      ),
                    ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  // Widget personalizado para el campo de firma
  Widget _buildCampoFirma() {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Container(
        decoration: BoxDecoration(
          border: Border.all(color: Colors.orange, width: 2),
          borderRadius: BorderRadius.circular(8),
          color: Colors.orange.shade50,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Encabezado con label y botón
            Padding(
              padding: const EdgeInsets.all(12),
              child: Row(
                children: [
                  Expanded(
                    child: const Text(
                      'Firma Revisor',
                      style: TextStyle(
                        color: Color(0xFF1A237E),
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
                  ),
                  ElevatedButton.icon(
                    onPressed: _mostrarDialogoFirma,
                    icon: const Icon(Icons.edit, size: 18),
                    label: Text(_firmaImagen == null ? 'Capturar' : 'Cambiar'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF1A237E),
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    ),
                  ),
                ],
              ),
            ),
            
            // Vista previa de la firma si existe
            if (_firmaImagen != null)
              Padding(
                padding: const EdgeInsets.fromLTRB(12, 0, 12, 12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      height: 150,
                      width: double.infinity,
                      decoration: BoxDecoration(
                        border: Border.all(color: Colors.grey.shade300),
                        borderRadius: BorderRadius.circular(8),
                        color: Colors.white,
                      ),
                      child: CustomPaint(
                        painter: _FirmaPainter(_firmaImagen!),
                      ),
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        const Icon(Icons.check_circle, color: Colors.green, size: 16),
                        const SizedBox(width: 4),
                        Expanded(
                          child: Text(
                            'Firma capturada',
                            style: TextStyle(
                              color: Colors.grey.shade700,
                              fontSize: 12,
                            ),
                          ),
                        ),
                        TextButton.icon(
                          onPressed: _eliminarFirma,
                          icon: const Icon(Icons.delete, size: 16, color: Colors.red),
                          label: const Text('Eliminar', style: TextStyle(color: Colors.red, fontSize: 12)),
                          style: TextButton.styleFrom(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              )
            else
              Padding(
                padding: const EdgeInsets.fromLTRB(12, 0, 12, 12),
                child: Row(
                  children: [
                    Icon(Icons.info_outline, color: Colors.grey.shade600, size: 16),
                    const SizedBox(width: 4),
                    Text(
                      'Sin firma capturada',
                      style: TextStyle(
                        color: Colors.grey.shade600,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ),
          ],
        ),
      ),
    );
  }
}

// CustomPainter para dibujar la firma capturada
class _FirmaPainter extends CustomPainter {
  final ui.Image image;
  
  _FirmaPainter(this.image);
  
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..filterQuality = FilterQuality.high;
    
    // Calcular el ratio para mantener la proporción de la imagen
    final imageRatio = image.width / image.height;
    final containerRatio = size.width / size.height;
    
    double renderWidth = size.width;
    double renderHeight = size.height;
    double offsetX = 0;
    double offsetY = 0;
    
    if (imageRatio > containerRatio) {
      // La imagen es más ancha proporcionalmente
      renderHeight = size.width / imageRatio;
      offsetY = (size.height - renderHeight) / 2;
    } else {
      // La imagen es más alta proporcionalmente
      renderWidth = size.height * imageRatio;
      offsetX = (size.width - renderWidth) / 2;
    }
    
    final srcRect = Rect.fromLTWH(0, 0, image.width.toDouble(), image.height.toDouble());
    final dstRect = Rect.fromLTWH(offsetX, offsetY, renderWidth, renderHeight);
    
    canvas.drawImageRect(image, srcRect, dstRect, paint);
  }
  
  @override
  bool shouldRepaint(_FirmaPainter oldDelegate) {
    return oldDelegate.image != image;
  }
}

