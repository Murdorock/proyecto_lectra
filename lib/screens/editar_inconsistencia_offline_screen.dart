import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'dart:convert';
import 'dart:io';
import 'dart:ui' as ui;
import 'dart:typed_data';
import 'dart:math' as math;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:geolocator/geolocator.dart';
import 'package:image_picker/image_picker.dart';
import 'package:syncfusion_flutter_signaturepad/signaturepad.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:path_provider/path_provider.dart';
import 'package:http/http.dart' as http;
import 'package:url_launcher/url_launcher.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../services/offline_sync_service.dart';
import '../services/user_session.dart';

class EditarInconsistenciaOfflineScreen extends StatefulWidget {
  final int inconsistenciaId;
  const EditarInconsistenciaOfflineScreen({super.key, required this.inconsistenciaId});

  @override
  State<EditarInconsistenciaOfflineScreen> createState() => _EditarInconsistenciaOfflineScreenState();
}

class _EditarInconsistenciaOfflineScreenState extends State<EditarInconsistenciaOfflineScreen> {
  Map<String, dynamic>? _data;
  bool _isLoading = true;
  bool _isSaving = false;
  bool _isGeneratingPDF = false; // Bloquea pantalla mientras se genera PDF
  String? _errorMessage;
  
  // ImagePicker para fotos
  final ImagePicker _picker = ImagePicker();
  
  // Archivos de imagen seleccionados
  File? _fotoFile;
  File? _foto1File;
  File? _foto2File;
  
  // Metadata de fotos para identificación única
  Map<String, String> _fotoMetadata = {}; // Almacena metadata de fotos por tipo (instalacion_tipo_fecha_timestamp.jpg)
  
  // Variable para la firma
  ui.Image? _firmaImagen;
  
  // Controlador para campo de texto
  final TextEditingController _alfanumericaRevisorController = TextEditingController();
  final TextEditingController _lecturaRealController = TextEditingController();
  final TextEditingController _advertenciaController = TextEditingController();
  final TextEditingController _geolocalizacionController = TextEditingController();
  
  // Variable para almacenar advertencia desde Supabase (tabla secuencia_lectura)
  String? _advertenciaSupabase;
  
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
    _loadDataOffline();
  }

  @override
  void dispose() {
    _alfanumericaRevisorController.dispose();
    _lecturaRealController.dispose();
    _advertenciaController.dispose();
    _geolocalizacionController.dispose();
    super.dispose();
  }

  Future<void> _loadDataOffline() async {
    setState(() { _isLoading = true; _errorMessage = null; });
    try {
      final prefs = await SharedPreferences.getInstance();
      final inconsistenciasStr = prefs.getString('inconsistencias_offline') ?? '[]';
      final inconsistencias = List<Map<String, dynamic>>.from(json.decode(inconsistenciasStr));
      final data = inconsistencias.firstWhere((e) => e['id'] == widget.inconsistenciaId, orElse: () => {});
      if (data.isEmpty) {
        setState(() { _errorMessage = 'No se encontró la inconsistencia offline.'; _isLoading = false; });
        return;
      }
      _data = Map<String, dynamic>.from(data);
      // Inicializar causa_observacion del dropdown
      _causaObservacionSeleccionada = _data!['causa_observacion']?.toString();
      // Inicializar observacion_adicional_real del dropdown
      _observacionAdicionalRealSeleccionada = _data!['observacion_adicional_real']?.toString();
      // Inicializar correcciones_en_sistema del dropdown
      _correccionesEnSistemaSeleccionada = _data!['correcciones_en_sistema']?.toString();
      // Inicializar alfanumerica_revisor
      _alfanumericaRevisorController.text = _data!['alfanumerica_revisor']?.toString() ?? '';
      // Inicializar lectura_real
      _lecturaRealController.text = _data!['lectura_real']?.toString() ?? '';
      // Inicializar advertencia_revisor
      _advertenciaController.text = _data!['advertencia_revisor']?.toString() ?? '';
      // Inicializar geolocalizacion
      _geolocalizacionController.text = _data!['geolocalizacion']?.toString() ?? '';
      
      // Cargar advertencia desde Supabase (tabla secuencia_lectura)
      await _cargarAdvertenciaDesdeSupabase();
      
      // Cargar fotos existentes si hay rutas locales
      await _cargarFotosExistentes();
      
      // Cargar firma existente si hay ruta local
      if (_data!['firma_revisor'] != null && _data!['firma_revisor'].toString().isNotEmpty) {
        final firmaPath = _data!['firma_revisor'].toString();
        final file = File(firmaPath);
        if (await file.exists()) {
          final bytes = await file.readAsBytes();
          // Convertir bytes a ui.Image
          final codec = await ui.instantiateImageCodec(bytes);
          final frame = await codec.getNextFrame();
          setState(() {
            _firmaImagen = frame.image;
          });
          print('✍️ Firma cargada: $firmaPath');
        }
      }
      
      setState(() { _isLoading = false; });
    } catch (e) {
      setState(() { _errorMessage = 'Error al cargar datos offline: $e'; _isLoading = false; });
    }
  }

  // Método para cargar fotos existentes usando ID único del registro
  Future<void> _cargarFotosExistentes() async {
    try {
      final recordId = _data!['id']?.toString() ?? 'sin_id';
      final directory = await getApplicationDocumentsDirectory();
      final fotosDir = Directory('${directory.path}/fotos_offline');
      
      if (!await fotosDir.exists()) {
        print('📷 Directorio de fotos no existe');
        return;
      }
      
      // Cargar fotos por tipo (foto, foto1, foto2)
      for (final tipo in ['foto', 'foto1', 'foto2']) {
        // Buscar archivos de foto para este registro específico por ID
        try {
          final files = fotosDir
              .listSync()
              .whereType<File>()
              .where((f) => f.path.contains('record_${recordId}_${tipo}_'))
              .toList();
          
          if (files.isNotEmpty) {
            // Tomar el archivo más reciente
            files.sort((a, b) => b.statSync().modified.compareTo(a.statSync().modified));
            final fotoFile = files.first;
            
            // Extraer metadata del nombre
            final nombreArchivo = fotoFile.path.split('/').last;
            _fotoMetadata[tipo] = nombreArchivo;
            
            setState(() {
              switch (tipo) {
                case 'foto':
                  _fotoFile = fotoFile;
                  print('📷 Foto principal cargada: ${fotoFile.path}');
                case 'foto1':
                  _foto1File = fotoFile;
                  print('📷 Foto 1 cargada: ${fotoFile.path}');
                case 'foto2':
                  _foto2File = fotoFile;
                  print('📷 Foto 2 cargada: ${fotoFile.path}');
              }
            });
          }
        } catch (e) {
          print('❌ Error cargando foto $tipo: $e');
        }
      }
    } catch (e) {
      print('❌ Error cargando fotos existentes: $e');
    }
  }

  // Método para cargar advertencia desde Supabase (tabla secuencia_lectura)
  Future<void> _cargarAdvertenciaDesdeSupabase() async {
    try {
      if (_data == null) return;
      
      final servicioSuscrito = _data!['servicio_suscrito']?.toString();
      if (servicioSuscrito == null || servicioSuscrito.isEmpty) {
        print('⚠️ No hay servicio suscrito para buscar advertencia');
        return;
      }

      // Buscar en Supabase tabla secuencia_lectura
      final supabase = Supabase.instance.client;
      final response = await supabase
          .from('secuencia_lectura')
          .select('advertencia_lect')
          .eq('servicio_suscrito', servicioSuscrito)
          .limit(1);

      if (response.isNotEmpty) {
        final advertencia = response[0]['advertencia_lect']?.toString();
        if (advertencia != null && advertencia.isNotEmpty) {
          setState(() {
            _advertenciaSupabase = advertencia;
          });
          print('✅ Advertencia cargada desde Supabase (tabla OBSERVACIONES): $advertencia');
          print('   Servicio Suscrito: $servicioSuscrito');
        } else {
          print('⚠️ Advertencia vacía para servicio suscrito: $servicioSuscrito');
        }
      } else {
        print('⚠️ No se encontró registro en secuencia_lectura para servicio suscrito: $servicioSuscrito');
      }
    } catch (e) {
      print('❌ Error cargando advertencia desde Supabase: $e');
      // No mostrar error al usuario, solo registrar en logs
      // Ya que es una consulta auxiliar
    }
  }


  Future<void> _guardarCambiosOffline() async {
    if (_data == null) return;
    setState(() { _isSaving = true; });
    try {
      final all = await OfflineSyncService.getAll();
      final idx = all.indexWhere((e) => e['id'] == widget.inconsistenciaId);
      if (idx == -1) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('No se encontró la inconsistencia para guardar'),
              backgroundColor: Colors.red,
            ),
          );
        }
        setState(() { _isSaving = false; });
        return;
      }
      
      // Actualizar causa_observacion del dropdown
      all[idx]['causa_observacion'] = _causaObservacionSeleccionada;
      
      // Actualizar observacion_adicional_real del dropdown
      all[idx]['observacion_adicional_real'] = _observacionAdicionalRealSeleccionada;
      
      // Actualizar correcciones_en_sistema del dropdown
      all[idx]['correcciones_en_sistema'] = _correccionesEnSistemaSeleccionada;
      
      // Actualizar alfanumerica_revisor
      all[idx]['alfanumerica_revisor'] = _alfanumericaRevisorController.text.isEmpty ? null : _alfanumericaRevisorController.text;
      
      // Actualizar lectura_real
      all[idx]['lectura_real'] = _lecturaRealController.text.isEmpty ? null : _lecturaRealController.text;
      
      // Actualizar advertencia_revisor
      all[idx]['advertencia_revisor'] = _advertenciaController.text.isEmpty ? null : _advertenciaController.text;
      
      // Actualizar geolocalizacion
      all[idx]['geolocalizacion'] = _geolocalizacionController.text.isEmpty ? null : _geolocalizacionController.text;
      
      // Guardar fecha de revisión si hay cambios
      if (_causaObservacionSeleccionada != null || _lecturaRealController.text.isNotEmpty) {
        final now = DateTime.now();
        final fechaRevision = '${now.day.toString().padLeft(2, '0')}-${now.month.toString().padLeft(2, '0')}-${now.year}';
        all[idx]['fecha_revision'] = fechaRevision;
      }
      
      // Guardar coordenadas de geolocalización en coordenada_instalacion también
      if (_geolocalizacionController.text.isNotEmpty) {
        all[idx]['coordenada_instalacion'] = _geolocalizacionController.text;
      }
      
      // Guardar rutas locales de archivos de fotos
      if (_fotoFile != null) {
        all[idx]['foto'] = _fotoFile!.path;
        all[idx]['foto_metadata'] = _fotoMetadata['foto'] ?? ''; // Guardar metadata para identificación
      }
      if (_foto1File != null) {
        all[idx]['foto1'] = _foto1File!.path;
        all[idx]['foto1_metadata'] = _fotoMetadata['foto1'] ?? ''; // Guardar metadata para identificación
      }
      if (_foto2File != null) {
        all[idx]['foto2'] = _foto2File!.path;
        all[idx]['foto2_metadata'] = _fotoMetadata['foto2'] ?? ''; // Guardar metadata para identificación
      }
      
      // Guardar firma como archivo temporal si existe
      if (_firmaImagen != null) {
        try {
          final firmaPngBytes = await _convertirFirmaAPng(_firmaImagen!);
          final directory = await getApplicationDocumentsDirectory();
          final firmasDir = Directory('${directory.path}/firmas_offline');
          
          // Crear directorio si no existe
          if (!await firmasDir.exists()) {
            await firmasDir.create(recursive: true);
          }
          
          final instalacion = _data!['instalacion']?.toString() ?? 'sin_instalacion';
          final timestamp = DateTime.now().millisecondsSinceEpoch;
          final firmaFile = File('${firmasDir.path}/firma_${instalacion}_$timestamp.png');
          await firmaFile.writeAsBytes(firmaPngBytes);
          all[idx]['firma_revisor'] = firmaFile.path;
          
          print('✍️ Firma guardada offline: ${firmaFile.path}');
        } catch (e) {
          print('❌ Error al guardar firma: $e');
        }
      }
      
      // Guardar en OfflineSyncService
      await OfflineSyncService.saveAll(all);
      
      // También guardar en SharedPreferences como respaldo
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('inconsistencias_offline', json.encode(all));
      
      setState(() { _isSaving = false; });
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Cambios guardados offline exitosamente'),
            backgroundColor: Colors.green,
            duration: Duration(seconds: 2),
          ),
        );
      }
      
      print('✅ Datos guardados offline para inconsistencia ID: ${widget.inconsistenciaId}');
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error al guardar offline: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
      setState(() { _isSaving = false; });
      print('❌ Error al guardar offline: $e');
    }
  }

  // Guardar cambios y cerrar la pantalla
  Future<void> _guardarYCerrar() async {
    await _guardarCambiosOffline();
    if (mounted) {
      Navigator.pop(context, true); // Retorna true para recargar la lista
    }
  }

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
        _geolocalizacionController.text = coordenadas;
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

  // Método para buscar coordenadas en Supabase
  Future<void> _irAMapa() async {
    if (_data == null) return;
    
    final instalacion = _data!['instalacion']?.toString();
    if (instalacion == null || instalacion.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('No hay instalación para buscar'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    try {
      // Mostrar indicador de carga
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
              Text('Buscando coordenadas...'),
            ],
          ),
          duration: Duration(seconds: 10),
        ),
      );

      // Buscar en Supabase
      final supabase = Supabase.instance.client;
      final response = await supabase
          .from('coordenadas')
          .select('coordenada')
          .eq('instalacion', instalacion)
          .limit(1);

      if (response.isEmpty) {
        if (mounted) {
          ScaffoldMessenger.of(context).clearSnackBars();
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('No se encontró coordenada para esta instalación'),
              backgroundColor: Colors.orange,
            ),
          );
        }
        return;
      }

      // Obtener la coordenada
      final coordenada = response[0]['coordenada']?.toString();
      if (coordenada == null || coordenada.isEmpty) {
        if (mounted) {
          ScaffoldMessenger.of(context).clearSnackBars();
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('La coordenada no tiene valor'),
              backgroundColor: Colors.orange,
            ),
          );
        }
        return;
      }

      // Parsear coordenadas (formato: "lat,lon")
      final coords = coordenada.replaceAll(',', ' ').trim().split(RegExp(r'\s+'));
      if (coords.length < 2) {
        if (mounted) {
          ScaffoldMessenger.of(context).clearSnackBars();
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Formato de coordenada inválido'),
              backgroundColor: Colors.red,
            ),
          );
        }
        return;
      }

      final lat = double.tryParse(coords[0]);
      final lon = double.tryParse(coords[1]);

      if (lat == null || lon == null) {
        if (mounted) {
          ScaffoldMessenger.of(context).clearSnackBars();
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('No se pudieron parsear las coordenadas'),
              backgroundColor: Colors.red,
            ),
          );
        }
        return;
      }

      // Abrir Google Maps
      await _abrirGoogleMaps(lat, lon, instalacion);

      if (mounted) {
        ScaffoldMessenger.of(context).clearSnackBars();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).clearSnackBars();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error al buscar coordenadas: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
      print('❌ Error buscando coordenadas: $e');
    }
  }

  // Método para abrir Google Maps
  Future<void> _abrirGoogleMaps(double lat, double lon, String label) async {
    try {
      final googleMapsUrl = 'https://www.google.com/maps/search/?api=1&query=$lat,$lon';
      
      if (await canLaunch(googleMapsUrl)) {
        await launch(googleMapsUrl);
        print('✅ Google Maps abierto para: $lat, $lon');
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('No se pudo abrir Google Maps'),
              backgroundColor: Colors.red,
            ),
          );
        }
        print('❌ No se puede lanzar Google Maps');
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error al abrir Google Maps: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
      print('❌ Error abriendo Google Maps: $e');
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

  // Método para guardar foto con identificación única por instalación
  Future<Map<String, dynamic>?> _guardarFotoConIdentificacion(XFile pickedFile, String tipo) async {
    try {
      if (_data == null) return null;
      
      final timestamp = DateTime.now().millisecondsSinceEpoch;
      final fechaHora = DateTime.now().toString().substring(0, 19).replaceAll(' ', '_').replaceAll(':', '-');
      
      // Crear directorio para fotos
      final directory = await getApplicationDocumentsDirectory();
      final fotosDir = Directory('${directory.path}/fotos_offline');
      if (!await fotosDir.exists()) {
        await fotosDir.create(recursive: true);
      }
      
      // Generar nombre único: record_id_tipo_fecha_hora_timestamp.jpg (sin usar instalacion para evitar confusiones)
      final recordId = _data!['id']?.toString() ?? 'unknown';
      final nombreArchivo = 'record_${recordId}_${tipo}_${fechaHora}_$timestamp.jpg';
      final archivoPath = '${fotosDir.path}/$nombreArchivo';
      
      // Leer archivo original
      final imageBytes = await File(pickedFile.path).readAsBytes();
      
      // Guardar en el directorio designado
      final archivoGuardado = File(archivoPath);
      await archivoGuardado.writeAsBytes(imageBytes);
      
      print('💾 Foto guardada en: $archivoPath');
      print('📋 Metadata: $nombreArchivo');
      
      return {
        'file': archivoGuardado,
        'metadata': nombreArchivo,
        'path': archivoPath,
        'timestamp': timestamp,
        'tipo': tipo,
        'recordId': recordId,
      };
    } catch (e) {
      print('❌ Error guardando foto: $e');
      return null;
    }
  }

  // Método para seleccionar foto desde cámara o galería CON IDENTIFICACIÓN ÚNICA
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
        // GUARDAR FOTO CON NOMBRE ÚNICO IDENTIFICABLE
        final archivoGuardado = await _guardarFotoConIdentificacion(pickedFile, campoFoto);
        
        if (archivoGuardado != null) {
          setState(() {
            switch (campoFoto) {
              case 'foto':
                _fotoFile = archivoGuardado['file'];
                _fotoMetadata['foto'] = archivoGuardado['metadata'];
                break;
              case 'foto1':
                _foto1File = archivoGuardado['file'];
                _fotoMetadata['foto1'] = archivoGuardado['metadata'];
                break;
              case 'foto2':
                _foto2File = archivoGuardado['file'];
                _fotoMetadata['foto2'] = archivoGuardado['metadata'];
                break;
            }
          });

          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text('✅ Foto guardada: ${archivoGuardado['metadata']}'),
                backgroundColor: Colors.green,
                duration: Duration(seconds: 2),
              ),
            );
          }
          print('📷 Foto guardada con identificación: ${archivoGuardado['metadata']}');
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
      print('❌ Error: $e');
    }
  }

  // Método para eliminar foto (incluyendo archivo físico)
  Future<void> _eliminarFoto(String campoFoto) async {
    // Obtener referencia del archivo antes de eliminar
    File? archivoAEliminar;
    switch (campoFoto) {
      case 'foto':
        archivoAEliminar = _fotoFile;
      case 'foto1':
        archivoAEliminar = _foto1File;
      case 'foto2':
        archivoAEliminar = _foto2File;
    }

    // Eliminar el archivo físico si existe
    if (archivoAEliminar != null && await archivoAEliminar.exists()) {
      try {
        await archivoAEliminar.delete();
        print('🗑️ Archivo eliminado: ${archivoAEliminar.path}');
      } catch (e) {
        print('❌ Error al eliminar archivo: $e');
      }
    }

    // Eliminar referencias en memoria
    setState(() {
      switch (campoFoto) {
        case 'foto':
          _fotoFile = null;
          _fotoMetadata.remove('foto');
          break;
        case 'foto1':
          _foto1File = null;
          _fotoMetadata.remove('foto1');
          break;
        case 'foto2':
          _foto2File = null;
          _fotoMetadata.remove('foto2');
          break;
      }
    });

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Foto eliminada'),
          duration: Duration(seconds: 2),
        ),
      );
    }

    print('📷 Foto $campoFoto eliminada completamente');
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

  // Método para mostrar foto a pantalla completa
  Future<void> _mostrarFotoCompleta(File fotoFile, String tipo) async {
    await showDialog(
      context: context,
      builder: (BuildContext context) {
        return Dialog(
          backgroundColor: Colors.black,
          insetPadding: const EdgeInsets.all(0),
          child: GestureDetector(
            onTap: () => Navigator.pop(context),
            child: Stack(
              fit: StackFit.expand,
              children: [
                // Imagen a pantalla completa con zoom
                InteractiveViewer(
                  maxScale: 4.0,
                  minScale: 1.0,
                  child: Image.file(
                    fotoFile,
                    fit: BoxFit.contain,
                  ),
                ),
                // Botón para cerrar
                Positioned(
                  top: 16,
                  right: 16,
                  child: GestureDetector(
                    onTap: () => Navigator.pop(context),
                    child: Container(
                      decoration: BoxDecoration(
                        color: Colors.black54,
                        shape: BoxShape.circle,
                      ),
                      padding: const EdgeInsets.all(8),
                      child: const Icon(
                        Icons.close,
                        color: Colors.white,
                        size: 28,
                      ),
                    ),
                  ),
                ),
                // Información de la foto
                Positioned(
                  bottom: 16,
                  left: 16,
                  right: 16,
                  child: Container(
                    decoration: BoxDecoration(
                      color: Colors.black54,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    padding: const EdgeInsets.all(12),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          'Foto: $tipo',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 14,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'Toca la imagen para hacer zoom',
                          style: const TextStyle(
                            color: Colors.grey,
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
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
    });
    
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Firma eliminada'),
        duration: Duration(seconds: 2),
      ),
    );
  }

  // Método para convertir firma (ui.Image) a PNG bytes
  Future<Uint8List> _convertirFirmaAPng(ui.Image imagen) async {
    final byteData = await imagen.toByteData(format: ui.ImageByteFormat.png);
    return byteData!.buffer.asUint8List();
  }

  // Verifica conectividad básica para asegurar que se pueda descargar el mapa
  Future<bool> _hayConexionInternet() async {
    try {
      final result = await InternetAddress.lookup('example.com').timeout(const Duration(seconds: 3));
      return result.isNotEmpty && result.first.rawAddress.isNotEmpty;
    } catch (_) {
      return false;
    }
  }

  // Método para generar PDF (offline) - REQUIERE VALIDACIÓN DE CAMPOS OBLIGATORIOS
  Future<void> _generarPDF() async {
    // Mostrar diálogo bloqueador
    if (mounted) {
      showDialog(
        context: context,
        barrierDismissible: false, // Evita que se cierre tocando fuera
        builder: (BuildContext dialogContext) => WillPopScope(
          onWillPop: () async => false, // Bloquea botón atrás
          child: AlertDialog(
            elevation: 8,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: const [
                CircularProgressIndicator(color: Color(0xFF1A237E)),
                SizedBox(height: 16),
                Text(
                  'Generando PDF...\n\nNo cierres esta pantalla',
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 14, color: Colors.black87),
                ),
              ],
            ),
          ),
        ),
      );
    }

    setState(() { _isGeneratingPDF = true; });

    try {
      // Verificar que hay conexión a internet
      final tieneInternet = await _hayConexionInternet();
      if (!tieneInternet) {
        if (mounted) {
          Navigator.of(context).pop(); // Cerrar diálogo de carga
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('❌ Se requiere conexión a internet para generar el PDF'),
              backgroundColor: Colors.red,
              duration: Duration(seconds: 4),
            ),
          );
        }
        setState(() { _isGeneratingPDF = false; });
        return;
      }

      // Validar que haya datos guardados
      if (_data == null) {
        if (mounted) {
          Navigator.of(context).pop(); // Cerrar diálogo
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('No hay datos para generar el PDF'),
              backgroundColor: Colors.orange,
            ),
          );
        }
        setState(() { _isGeneratingPDF = false; });
        return;
      }

      // Validar campos obligatorios para PDF
      List<String> camposFaltantes = [];

      if (_causaObservacionSeleccionada == null || _causaObservacionSeleccionada!.isEmpty) {
        camposFaltantes.add('Causa de No Lectura u Observación');
      }

      if (_observacionAdicionalRealSeleccionada == null || _observacionAdicionalRealSeleccionada!.isEmpty) {
        camposFaltantes.add('Observación Adicional');
      }

      if (_correccionesEnSistemaSeleccionada == null || _correccionesEnSistemaSeleccionada!.isEmpty) {
        camposFaltantes.add('Correcciones en Sistema');
      }

      if (_alfanumericaRevisorController.text.isEmpty) {
        camposFaltantes.add('Alfanumérica Revisor');
      }

      if (_lecturaRealController.text.isEmpty) {
        camposFaltantes.add('Lectura Real');
      }

      if (_geolocalizacionController.text.isEmpty) {
        camposFaltantes.add('Geolocalización');
      }

      if (_fotoFile == null) {
        camposFaltantes.add('Foto principal');
      }

      if (_firmaImagen == null) {
        camposFaltantes.add('Firma del Operativo');
      }

      if (camposFaltantes.isNotEmpty) {
        final mensaje = camposFaltantes.length == 1
            ? 'El siguiente campo es obligatorio:\n• ${camposFaltantes[0]}'
            : 'Los siguientes campos son obligatorios:\n${camposFaltantes.map((c) => '• $c').join('\n')}';
        
        if (mounted) {
          Navigator.of(context).pop(); // Cerrar diálogo de carga
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(mensaje),
              backgroundColor: Colors.red,
              duration: const Duration(seconds: 5),
            ),
          );
        }
        setState(() { _isGeneratingPDF = false; });
        return;
      }

      try {
        // PASO 1: Guardar todos los cambios antes de generar PDF
        print('💾 Guardando cambios antes de generar PDF...');
        await _guardarCambiosOffline();
        
        final instalacion = _data!['instalacion']?.toString() ?? 'sin_instalacion';
        final timestamp = DateTime.now().millisecondsSinceEpoch;

        // PASO 2: Generar el PDF localmente
        print('📄 Generando PDF...');
        await _generarPDFLocal(instalacion, timestamp);

        if (mounted) {
          // Cerrar diálogo de carga
          Navigator.of(context).pop();
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('✅ PDF generado exitosamente en modo offline'),
              backgroundColor: Colors.green,
              duration: Duration(seconds: 3),
            ),
          );
        }
        
        // Retornar true para que la pantalla anterior se actualice
        if (mounted) {
          Navigator.pop(context, true);
        }
      } catch (e) {
        if (mounted) {
          // Cerrar diálogo de carga
          Navigator.of(context).pop();
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('❌ Error al generar PDF: ${e.toString()}'),
              backgroundColor: Colors.red,
            ),
          );
        }
        print('❌ Error generando PDF: $e');
      } finally {
        if (mounted) {
          setState(() { _isGeneratingPDF = false; });
        }
      }
    } finally {
      setState(() { _isGeneratingPDF = false; });
    }
  }

  // Método para generar PDF localmente
  Future<void> _generarPDFLocal(String instalacion, int timestamp) async {
    final pdf = pw.Document();

    // Validar y cargar imágenes de fotos locales si existen
    // IMPORTANTE: Las fotos ya fueron capturadas, simplemente incluirlas en el PDF
    pw.ImageProvider? fotoImage;
    pw.ImageProvider? foto1Image;
    pw.ImageProvider? foto2Image;
    
    if (_fotoFile != null && await _fotoFile!.exists()) {
      final bytes = await _fotoFile!.readAsBytes();
      fotoImage = pw.MemoryImage(bytes);
      print('✅ Foto principal cargada en PDF');
    }
    
    if (_foto1File != null && await _foto1File!.exists()) {
      final bytes = await _foto1File!.readAsBytes();
      foto1Image = pw.MemoryImage(bytes);
      print('✅ Foto 1 cargada en PDF');
    }
    
    if (_foto2File != null && await _foto2File!.exists()) {
      final bytes = await _foto2File!.readAsBytes();
      foto2Image = pw.MemoryImage(bytes);
      print('✅ Foto 2 cargada en PDF');
    }

    // Cargar imagen de la firma si existe
    pw.ImageProvider? firmaPdfImage;
    if (_firmaImagen != null) {
      final firmaPngBytes = await _convertirFirmaAPng(_firmaImagen!);
      firmaPdfImage = pw.MemoryImage(firmaPngBytes);
    }

    // Cargar imagen del mapa estático si hay geolocalización
    pw.ImageProvider? mapaImage;
    final geolocalizacion = _geolocalizacionController.text;
    if (geolocalizacion.isNotEmpty) {
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
              ['LECTURA ENCONTRADA', _lecturaRealController.text],
              ['CAUSA DE NO LECTURA U OBSERVACIÓN', _getFullCausaObservacion()],
              ['OBSERVACIÓN ADICIONAL', _getFullObservacionAdicional()],
            ]),
            pw.SizedBox(height: 10),
            
            // RESULTADO DE LA INSPECCIÓN (Campo grande)
            _buildPdfCampoGrande(
              'RESULTADO DE LA INSPECCIÓN',
              'OBSERVACIONES DEL RESULTADO DE LA INSPECCIÓN:',
              _alfanumericaRevisorController.text,
            ),
            pw.SizedBox(height: 10),
            _buildPdfCampoTexto('Correcciones en Sistema: ${_correccionesEnSistemaSeleccionada ?? "N/A"}'),
            pw.SizedBox(height: 20),

            // GEOLOCALIZACIÓN
            _buildPdfTituloSeccion('GEOLOCALIZACIÓN'),
            pw.SizedBox(height: 10),
            _buildPdfCampoTexto(_geolocalizacionController.text.isNotEmpty ? _geolocalizacionController.text : 'No capturada'),
            pw.SizedBox(height: 10),
            // Mapa estático si está disponible
            if (mapaImage != null)
              pw.Container(
                height: 200,
                decoration: pw.BoxDecoration(
                  border: pw.Border.all(color: PdfColors.grey),
                ),
                child: pw.Image(mapaImage, fit: pw.BoxFit.cover),
              )
            else if (_geolocalizacionController.text.isNotEmpty)
              pw.Container(
                padding: const pw.EdgeInsets.all(8),
                decoration: pw.BoxDecoration(
                  border: pw.Border.all(color: PdfColors.grey),
                  color: PdfColors.grey100,
                ),
                child: pw.Text(
                  'No se pudo generar el mapa. Coordenadas: ${_geolocalizacionController.text}',
                  style: const pw.TextStyle(fontSize: 10),
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
              mainAxisAlignment: pw.MainAxisAlignment.center,
              children: [
                pw.Container(
                  width: 250,
                  child: pw.Column(
                    children: [
                      if (firmaPdfImage != null)
                        pw.Container(
                          height: 80,
                          decoration: pw.BoxDecoration(
                            border: pw.Border.all(color: PdfColors.black, width: 0.5),
                          ),
                          child: pw.Image(firmaPdfImage, fit: pw.BoxFit.contain),
                        )
                      else
                        pw.Container(
                          height: 80,
                          decoration: pw.BoxDecoration(
                            border: pw.Border.all(color: PdfColors.black, width: 0.5),
                          ),
                        ),
                      pw.SizedBox(height: 5),
                      pw.Container(
                        padding: const pw.EdgeInsets.symmetric(vertical: 2),
                        decoration: const pw.BoxDecoration(
                          border: pw.Border(top: pw.BorderSide(color: PdfColors.black, width: 1)),
                        ),
                        child: pw.Text(
                          'FIRMA DEL OPERATIVO',
                          style: pw.TextStyle(fontSize: 9, fontWeight: pw.FontWeight.bold),
                          textAlign: pw.TextAlign.center,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ];
        },
      ),
    );

    // Guardar PDF localmente
    final pdfBytes = await pdf.save();
    
    // Construir nombre del archivo según estructura:
    // fecha_correria_instalacion_codigoLogueado_tipoConsumo.pdf
    final fechaFormateada = DateTime.now().toString().substring(0, 10).replaceAll('-', '');
    final correria = _data!['correria']?.toString() ?? '';
    final codigoLogueado = UserSession().codigoSupAux ?? 'UNKNOWN';
    final tipoConsumo = _data!['cod_tipo_consumo']?.toString() ?? '';
    
    final nombreArchivo = '${fechaFormateada}_${correria}_${instalacion}_${codigoLogueado}_$tipoConsumo.pdf';
    
    // Obtener directorio de documentos del dispositivo
    final directory = await getApplicationDocumentsDirectory();
    final pdfDirectory = Directory('${directory.path}/pdfs_offline');
    
    // Crear directorio si no existe
    if (!await pdfDirectory.exists()) {
      await pdfDirectory.create(recursive: true);
    }
    
    // Guardar archivo PDF
    final file = File('${pdfDirectory.path}/$nombreArchivo');
    await file.writeAsBytes(pdfBytes);
    
    print('📄 PDF generado offline: ${file.path}');
    print('✅ Nombre del archivo: $nombreArchivo');
    
    // Guardar la ruta del PDF en OfflineSyncService y SharedPreferences
    final all = await OfflineSyncService.getAll();
    final idx = all.indexWhere((e) => e['id'] == widget.inconsistenciaId);
    
    if (idx != -1) {
      // Guardar ruta del PDF
      all[idx]['pdf'] = file.path;
      
      // Guardar fecha de revisión si no está ya guardada
      if (all[idx]['fecha_revision'] == null || all[idx]['fecha_revision'].toString().isEmpty) {
        final now = DateTime.now();
        final fechaRevision = '${now.day.toString().padLeft(2, '0')}-${now.month.toString().padLeft(2, '0')}-${now.year}';
        all[idx]['fecha_revision'] = fechaRevision;
      }
      
      // Actualizar en OfflineSyncService
      await OfflineSyncService.saveAll(all);
      
      // También guardar en SharedPreferences como respaldo
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('inconsistencias_offline', json.encode(all));
      
      print('✅ Ruta del PDF guardada en datos offline');
      print('✅ Datos actualizados para sincronización');
    }
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
              padding: const pw.EdgeInsets.all(4),
              child: pw.Column(
                crossAxisAlignment: pw.CrossAxisAlignment.start,
                children: [
                  pw.Text('Inspección en campo', style: pw.TextStyle(fontSize: 8, fontWeight: pw.FontWeight.bold)),
                  pw.Text('Contrato CW-280698', style: const pw.TextStyle(fontSize: 7)),
                ],
              ),
            ),
          ),
          // Columna central
          pw.Expanded(
            flex: 4,
            child: pw.Container(
              padding: const pw.EdgeInsets.all(4),
              decoration: const pw.BoxDecoration(
                border: pw.Border(left: pw.BorderSide(color: PdfColors.black, width: 1)),
              ),
              child: pw.Column(
                crossAxisAlignment: pw.CrossAxisAlignment.start,
                children: [
                  pw.Text('UTIC SAS', style: pw.TextStyle(fontSize: 8, fontWeight: pw.FontWeight.bold)),
                  pw.Text('NIT: 901.777.536', style: pw.TextStyle(fontSize: 8, fontWeight: pw.FontWeight.bold)),
                ],
              ),
            ),
          ),
          // Columna derecha - Logo
          pw.Expanded(
            flex: 3,
            child: pw.Container(
              padding: const pw.EdgeInsets.all(4),
              decoration: const pw.BoxDecoration(
                border: pw.Border(left: pw.BorderSide(color: PdfColors.black, width: 1)),
              ),
              child: pw.Center(
                child: pw.Text('UTIC', style: pw.TextStyle(fontSize: 10, fontWeight: pw.FontWeight.bold)),
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
            pw.Container(
              padding: const pw.EdgeInsets.all(4),
              child: pw.Text(fila[0], style: pw.TextStyle(fontSize: 8, fontWeight: pw.FontWeight.bold)),
            ),
            pw.Container(
              padding: const pw.EdgeInsets.all(4),
              child: pw.Text(fila[1], style: const pw.TextStyle(fontSize: 8)),
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
            '$titulo\n$subtitulo',
            style: const pw.TextStyle(fontSize: 8),
          ),
        ),
        pw.Container(
          width: double.infinity,
          padding: const pw.EdgeInsets.all(4),
          decoration: pw.BoxDecoration(
            border: pw.Border.all(color: PdfColors.black, width: 0.5),
          ),
          child: pw.Text(
            contenido,
            style: const pw.TextStyle(fontSize: 8),
          ),
        ),
      ],
    );
  }

  // Helper para obtener el label completo de causa observación
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

  // Helper para obtener el label completo de observación adicional
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

  // Método para descargar mapa estático basado en coordenadas
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

  // Generar imagen del mapa usando tiles de OpenStreetMap
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
        ..color = const ui.Color(0x50000000)
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
        ..color = const ui.Color(0xFFE53935)
        ..style = ui.PaintingStyle.fill;
      canvas.drawPath(pinPath, pinPaint);
      
      final pinBorderPaint = ui.Paint()
        ..color = const ui.Color(0xFFB71C1C)
        ..style = ui.PaintingStyle.stroke
        ..strokeWidth = 2;
      canvas.drawPath(pinPath, pinBorderPaint);
      
      // Círculo blanco en el centro del pin
      final innerCirclePaint = ui.Paint()
        ..color = const ui.Color(0xFFFFFFFF)
        ..style = ui.PaintingStyle.fill;
      canvas.drawCircle(const ui.Offset(centerX, centerY - 10), 6, innerCirclePaint);
      
      // Borde del texto de coordenadas
      final textPainter = ui.ParagraphBuilder(
        ui.ParagraphStyle(
          textAlign: TextAlign.center,
          fontSize: 12,
          fontWeight: FontWeight.bold,
        ),
      )
        ..pushStyle(ui.TextStyle(color: const ui.Color(0xFFFFFFFF)))
        ..addText(coordenadasTexto)
        ..pop();
      
      final paragraph = textPainter.build()
        ..layout(const ui.ParagraphConstraints(width: width - 20));
      
      // Fondo semitransparente para el texto
      final textBgPaint = ui.Paint()
        ..color = const ui.Color(0xCC000000)
        ..style = ui.PaintingStyle.fill;
      canvas.drawRRect(
        ui.RRect.fromRectAndRadius(
          ui.Rect.fromLTWH(
            10,
            height - 40,
            width - 20,
            30,
          ),
          const ui.Radius.circular(5),
        ),
        textBgPaint,
      );
      
      // Dibujar texto de coordenadas
      canvas.drawParagraph(paragraph, const ui.Offset(10, height - 35));
      
      // Finalizar el canvas y convertir a bytes
      final picture = recorder.endRecording();
      final image = await picture.toImage(width.toInt(), height.toInt());
      final byteData = await image.toByteData(format: ui.ImageByteFormat.png);
      final bytes = byteData!.buffer.asUint8List();
      
      print('✅ Mapa generado: ${bytes.length} bytes');
      return bytes;
    } catch (e) {
      print('❌ Error generando imagen de mapa: $e');
      return null;
    }
  }

  // Helper para construir campo de texto simple
  pw.Widget _buildPdfCampoTexto(String contenido) {
    return pw.Container(
      width: double.infinity,
      padding: const pw.EdgeInsets.all(8),
      decoration: pw.BoxDecoration(
        border: pw.Border.all(color: PdfColors.black, width: 0.5),
      ),
      child: pw.Text(contenido, style: const pw.TextStyle(fontSize: 8)),
    );
  }

  // Helper para construir sección de fotos
  pw.Widget _buildPdfFotos(
    pw.ImageProvider? foto,
    pw.ImageProvider? foto1,
    pw.ImageProvider? foto2,
  ) {
    return pw.Container(
      decoration: pw.BoxDecoration(
        border: pw.Border.all(color: PdfColors.black, width: 0.5),
      ),
      child: pw.Column(
        children: [
          // Primera fila - Foto principal
          if (foto != null)
            pw.Container(
              height: 180,
              decoration: const pw.BoxDecoration(
                border: pw.Border(bottom: pw.BorderSide(color: PdfColors.black, width: 0.5)),
              ),
              child: pw.Row(
                children: [
                  pw.Expanded(
                    child: pw.Container(
                      padding: const pw.EdgeInsets.all(4),
                      child: pw.Image(foto, fit: pw.BoxFit.contain),
                    ),
                  ),
                ],
              ),
            ),
          
          // Segunda fila - Fotos adicionales
          if (foto1 != null || foto2 != null)
            pw.Container(
              height: 160,
              child: pw.Row(
                children: [
                  if (foto1 != null)
                    pw.Expanded(
                      child: pw.Container(
                        padding: const pw.EdgeInsets.all(4),
                        decoration: foto2 != null
                            ? const pw.BoxDecoration(
                                border: pw.Border(right: pw.BorderSide(color: PdfColors.black, width: 0.5)),
                              )
                            : null,
                        child: pw.Image(foto1, fit: pw.BoxFit.contain),
                      ),
                    ),
                  if (foto2 != null)
                    pw.Expanded(
                      child: pw.Container(
                        padding: const pw.EdgeInsets.all(4),
                        child: pw.Image(foto2, fit: pw.BoxFit.contain),
                      ),
                    ),
                ],
              ),
            ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }
    if (_errorMessage != null) {
      return Scaffold(appBar: AppBar(title: const Text('Editar Inconsistencia Offline')), body: Center(child: Text(_errorMessage!)));
    }
    return WillPopScope(
      onWillPop: () async {
        // Al presionar el botón atrás, simplemente cierra sin guardar
        return true;
      },
      child: Scaffold(
        appBar: AppBar(title: const Text('Editar Inconsistencia Offline')),
        body: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
                        // Tarjeta de OBSERVACIONES (no editable)
                        Card(
                          elevation: 2,
                          margin: const EdgeInsets.only(bottom: 16),
                          child: Padding(
                            padding: const EdgeInsets.all(16),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text(
                                  'OBSERVACIONES',
                                  style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 16,
                                    color: Color(0xFF1A237E),
                                  ),
                                ),
                                SizedBox(height: 12),
                                _buildInfoRow('Motivo Revisión', _data?['motivo_revision']),
                                _buildInfoRow('Causa y Observación', _data?['causa_lectura_observacion']),
                                _buildInfoRow('Observación Adicional', _data?['observacion_adicional']),
                                _buildInfoRow('Advertencia', _advertenciaSupabase ?? 'No encontrada'),
                              ],
                            ),
                          ),
                        ),
                        // Tarjeta de PERSONAL (no editable)
                        Card(
                          elevation: 2,
                          margin: const EdgeInsets.only(bottom: 16),
                          child: Padding(
                            padding: const EdgeInsets.all(16),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text(
                                  'PERSONAL',
                                  style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 16,
                                    color: Color(0xFF1A237E),
                                  ),
                                ),
                                SizedBox(height: 12),
                                _buildInfoRow('Lector', _data?['lector']),
                                _buildInfoRow('Alfanumérica Lector', _data?['alfanumerica_lector']),
                              ],
                            ),
                          ),
                        ),
            // Tarjeta de INFORMACIÓN BÁSICA (no editable)
            Card(
              elevation: 2,
              margin: const EdgeInsets.only(bottom: 16),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'INFORMACIÓN BÁSICA',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                        color: Color(0xFF1A237E),
                      ),
                    ),
                    SizedBox(height: 12),
                    _buildInfoRow('Dirección', _data?['direccion']),
                    _buildInfoRow('Instalación', _data?['instalacion'], isInstalacion: true),
                    _buildInfoRow('Serie', _data?['serie']),
                    _buildInfoRow('Municipio', _data?['municipio']),
                    _buildInfoRow('Categoría', _data?['categoria']),
                  ],
                ),
              ),
            ),
            // Tarjeta de LECTURAS (no editable)
            Card(
              elevation: 2,
              margin: const EdgeInsets.only(bottom: 16),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'LECTURAS',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                        color: Color(0xFF1A237E),
                      ),
                    ),
                    SizedBox(height: 12),
                    _buildInfoRow('Lectura Actual', _data?['lectura_actual']),
                    _buildInfoRow('Lectura Anterior', _data?['lectura_anterior']),
                    _buildInfoRow('Lectura 3 Meses', _data?['lectura_tres_meses']),
                    _buildInfoRow('Lectura 4 Meses', _data?['lectura_cuatro_meses']),
                  ],
                ),
              ),
            ),
            // Tarjeta de CONSUMO Y TIPO (no editable)
            Card(
              elevation: 2,
              margin: const EdgeInsets.only(bottom: 16),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'CONSUMO Y TIPO',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                        color: Color(0xFF1A237E),
                      ),
                    ),
                    SizedBox(height: 12),
                    _buildInfoRow('Tipo Consumo', _data?['tipo_consumo']),
                    _buildInfoRow('Código Tipo Consumo', _data?['cod_tipo_consumo']),
                    _buildInfoRow('Servicio Suscrito', _data?['servicio_suscrito']),
                  ],
                ),
              ),
            ),
            // Tarjeta de FECHAS Y CICLO (no editable)
            Card(
              elevation: 2,
              margin: const EdgeInsets.only(bottom: 16),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'FECHAS Y CICLO',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                        color: Color(0xFF1A237E),
                      ),
                    ),
                    SizedBox(height: 12),
                    _buildInfoRow('Fecha Lectura Anterior', _data?['fecha_lectura_anterior']),
                    _buildInfoRow('Fecha Lectura Actual', _data?['fecha_lectura_actual']),
                    _buildInfoRow('Periodo Facturación', _data?['periodo_facturacion']),
                    _buildInfoRow('Ciclo', _data?['ciclo']),
                    _buildInfoRow('Correría', _data?['correria']),
                    _buildInfoRow('Orden', _data?['orden']),
                  ],
                ),
              ),
            ),
            // CAMPO EDITABLE: Causa Observación
            Card(
              elevation: 2,
              margin: const EdgeInsets.only(bottom: 16),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'CAUSA OBSERVACIÓN',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                        color: Color(0xFF1A237E),
                      ),
                    ),
                    const SizedBox(height: 12),
                    DropdownButtonFormField<String>(
                      value: _causaObservacionSeleccionada,
                      decoration: const InputDecoration(
                        labelText: 'Seleccione una causa',
                        border: OutlineInputBorder(),
                        contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                      ),
                      isExpanded: true,
                      items: _causasObservacion.map((causa) {
                        return DropdownMenuItem<String>(
                          value: causa['value'],
                          child: Text(
                            causa['label']!,
                            style: const TextStyle(fontSize: 14),
                          ),
                        );
                      }).toList(),
                      onChanged: (String? newValue) {
                        setState(() {
                          _causaObservacionSeleccionada = newValue;
                        });
                      },
                    ),
                  ],
                ),
              ),
            ),
            // CAMPO EDITABLE: Observación Adicional Real
            Card(
              elevation: 2,
              margin: const EdgeInsets.only(bottom: 16),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'OBSERVACIÓN ADICIONAL REAL',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                        color: Color(0xFF1A237E),
                      ),
                    ),
                    const SizedBox(height: 12),
                    DropdownButtonFormField<String>(
                      value: _observacionAdicionalRealSeleccionada,
                      decoration: const InputDecoration(
                        labelText: 'Seleccione una observación',
                        border: OutlineInputBorder(),
                        contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                      ),
                      isExpanded: true,
                      items: _observacionesAdicionales.map((obs) {
                        return DropdownMenuItem<String>(
                          value: obs['value'],
                          child: Text(
                            obs['label']!,
                            style: const TextStyle(fontSize: 14),
                          ),
                        );
                      }).toList(),
                      onChanged: (String? newValue) {
                        setState(() {
                          _observacionAdicionalRealSeleccionada = newValue;
                        });
                      },
                    ),
                  ],
                ),
              ),
            ),
            // CAMPO EDITABLE: Alfanumérica Revisor
            Card(
              elevation: 2,
              margin: const EdgeInsets.only(bottom: 16),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'ALFANUMÉRICA REVISOR',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                        color: Color(0xFF1A237E),
                      ),
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: _alfanumericaRevisorController,
                      decoration: const InputDecoration(
                        labelText: 'Ingrese información alfanumérica',
                        border: OutlineInputBorder(),
                        contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                      ),
                      maxLines: 3,
                      textCapitalization: TextCapitalization.characters,
                    ),
                  ],
                ),
              ),
            ),
            // CAMPO EDITABLE: Lectura Real
            Card(
              elevation: 2,
              margin: const EdgeInsets.only(bottom: 16),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'LECTURA REAL',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                        color: Color(0xFF1A237E),
                      ),
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: _lecturaRealController,
                      decoration: const InputDecoration(
                        labelText: 'Ingrese la lectura',
                        border: OutlineInputBorder(),
                        contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                        prefixIcon: Icon(Icons.numbers),
                      ),
                      keyboardType: TextInputType.number,
                      inputFormatters: [
                        FilteringTextInputFormatter.digitsOnly,
                      ],
                    ),
                  ],
                ),
              ),
            ),
            // CAMPO EDITABLE: Correcciones en Sistema
            Card(
              elevation: 2,
              margin: const EdgeInsets.only(bottom: 16),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'CORRECCIONES EN SISTEMA',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                        color: Color(0xFF1A237E),
                      ),
                    ),
                    const SizedBox(height: 12),
                    DropdownButtonFormField<String>(
                      value: _correccionesEnSistemaSeleccionada,
                      decoration: const InputDecoration(
                        labelText: 'Seleccione una corrección',
                        border: OutlineInputBorder(),
                        contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                      ),
                      isExpanded: true,
                      items: _correccionesEnSistema.map((corr) {
                        return DropdownMenuItem<String>(
                          value: corr['value'],
                          child: Text(
                            corr['label']!,
                            style: const TextStyle(fontSize: 14),
                          ),
                        );
                      }).toList(),
                      onChanged: (String? newValue) {
                        setState(() {
                          _correccionesEnSistemaSeleccionada = newValue;
                        });
                      },
                    ),
                  ],
                ),
              ),
            ),
            // CAMPO EDITABLE: Advertencia
            Card(
              elevation: 2,
              margin: const EdgeInsets.only(bottom: 16),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'ADVERTENCIA',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                        color: Color(0xFF1A237E),
                      ),
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: _advertenciaController,
                      decoration: const InputDecoration(
                        labelText: 'Ingrese advertencia',
                        border: OutlineInputBorder(),
                        contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                      ),
                      maxLines: 3,
                      textCapitalization: TextCapitalization.sentences,
                    ),
                  ],
                ),
              ),
            ),
            // CAMPO EDITABLE: Geolocalización
            Card(
              elevation: 2,
              margin: const EdgeInsets.only(bottom: 16),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'GEOLOCALIZACIÓN',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                        color: Color(0xFF1A237E),
                      ),
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: _geolocalizacionController,
                      decoration: const InputDecoration(
                        labelText: 'Coordenadas',
                        border: OutlineInputBorder(),
                        contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                        prefixIcon: Icon(Icons.location_on),
                      ),
                      readOnly: true,
                    ),
                    const SizedBox(height: 12),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton.icon(
                        onPressed: _capturarGeolocalizacion,
                        icon: const Icon(Icons.my_location),
                        label: const Text('CAPTURAR UBICACIÓN'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF1A237E),
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 12),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            // CAMPO EDITABLE: Foto Principal (OBLIGATORIA)
            Card(
              elevation: 2,
              margin: const EdgeInsets.only(bottom: 16),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        const Text(
                          'FOTO PRINCIPAL',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                            color: Color(0xFF1A237E),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                          decoration: BoxDecoration(
                            color: Colors.red,
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: const Text(
                            'OBLIGATORIA',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 10,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton.icon(
                        onPressed: () => _mostrarOpcionesFoto('foto'),
                        icon: const Icon(Icons.camera_alt),
                        label: Text(_fotoFile == null ? 'CAPTURAR FOTO' : 'CAMBIAR FOTO'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF1A237E),
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 12),
                        ),
                      ),
                    ),
                    if (_fotoFile != null) ...[
                      const SizedBox(height: 12),
                      GestureDetector(
                        onTap: () => _mostrarFotoCompleta(_fotoFile!, 'Principal'),
                        child: Container(
                          height: 200,
                          width: double.infinity,
                          decoration: BoxDecoration(
                            border: Border.all(color: Colors.grey),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(8),
                            child: Stack(
                              fit: StackFit.expand,
                              children: [
                                Image.file(
                                  _fotoFile!,
                                  fit: BoxFit.cover,
                                ),
                                // Indicador de que es clickeable
                                Center(
                                  child: Container(
                                    decoration: BoxDecoration(
                                      color: Colors.black54,
                                      shape: BoxShape.circle,
                                    ),
                                    padding: const EdgeInsets.all(12),
                                    child: const Icon(
                                      Icons.zoom_in,
                                      color: Colors.white,
                                      size: 28,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Archivo: ${_fotoFile!.path.split('/').last}',
                        style: const TextStyle(fontSize: 12, color: Colors.grey),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Toca la imagen para verla completa',
                        style: const TextStyle(fontSize: 11, color: Colors.blue),
                      ),
                    ],
                  ],
                ),
              ),
            ),
            // CAMPO EDITABLE: Foto 1 (Opcional)
            Card(
              elevation: 2,
              margin: const EdgeInsets.only(bottom: 16),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'FOTO 1 (Opcional)',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                        color: Color(0xFF1A237E),
                      ),
                    ),
                    const SizedBox(height: 12),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton.icon(
                        onPressed: () => _mostrarOpcionesFoto('foto1'),
                        icon: const Icon(Icons.camera_alt),
                        label: Text(_foto1File == null ? 'CAPTURAR FOTO' : 'CAMBIAR FOTO'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF1A237E),
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 12),
                        ),
                      ),
                    ),
                    if (_foto1File != null) ...[
                      const SizedBox(height: 12),
                      GestureDetector(
                        onTap: () => _mostrarFotoCompleta(_foto1File!, 'Foto 1'),
                        child: Container(
                          height: 200,
                          width: double.infinity,
                          decoration: BoxDecoration(
                            border: Border.all(color: Colors.grey),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(8),
                            child: Stack(
                              fit: StackFit.expand,
                              children: [
                                Image.file(
                                  _foto1File!,
                                  fit: BoxFit.cover,
                                ),
                                Center(
                                  child: Container(
                                    decoration: BoxDecoration(
                                      color: Colors.black54,
                                      shape: BoxShape.circle,
                                    ),
                                    padding: const EdgeInsets.all(12),
                                    child: const Icon(
                                      Icons.zoom_in,
                                      color: Colors.white,
                                      size: 28,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Archivo: ${_foto1File!.path.split('/').last}',
                        style: const TextStyle(fontSize: 12, color: Colors.grey),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Toca la imagen para verla completa',
                        style: const TextStyle(fontSize: 11, color: Colors.blue),
                      ),
                    ],
                  ],
                ),
              ),
            ),
            // CAMPO EDITABLE: Foto 2 (Opcional)
            Card(
              elevation: 2,
              margin: const EdgeInsets.only(bottom: 16),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'FOTO 2 (Opcional)',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                        color: Color(0xFF1A237E),
                      ),
                    ),
                    const SizedBox(height: 12),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton.icon(
                        onPressed: () => _mostrarOpcionesFoto('foto2'),
                        icon: const Icon(Icons.camera_alt),
                        label: Text(_foto2File == null ? 'CAPTURAR FOTO' : 'CAMBIAR FOTO'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF1A237E),
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 12),
                        ),
                      ),
                    ),
                    if (_foto2File != null) ...[
                      const SizedBox(height: 12),
                      GestureDetector(
                        onTap: () => _mostrarFotoCompleta(_foto2File!, 'Foto 2'),
                        child: Container(
                          height: 200,
                          width: double.infinity,
                          decoration: BoxDecoration(
                            border: Border.all(color: Colors.grey),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(8),
                            child: Stack(
                              fit: StackFit.expand,
                              children: [
                                Image.file(
                                  _foto2File!,
                                  fit: BoxFit.cover,
                                ),
                                Center(
                                  child: Container(
                                    decoration: BoxDecoration(
                                      color: Colors.black54,
                                      shape: BoxShape.circle,
                                    ),
                                    padding: const EdgeInsets.all(12),
                                    child: const Icon(
                                      Icons.zoom_in,
                                      color: Colors.white,
                                      size: 28,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Archivo: ${_foto2File!.path.split('/').last}',
                        style: const TextStyle(fontSize: 12, color: Colors.grey),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Toca la imagen para verla completa',
                        style: const TextStyle(fontSize: 11, color: Colors.blue),
                      ),
                    ],
                  ],
                ),
              ),
            ),
            // CAMPO EDITABLE: Firma del Operativo
            Card(
              elevation: 2,
              margin: const EdgeInsets.only(bottom: 16),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'FIRMA DEL OPERATIVO',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                        color: Color(0xFF1A237E),
                      ),
                    ),
                    const SizedBox(height: 12),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton.icon(
                        onPressed: _mostrarDialogoFirma,
                        icon: const Icon(Icons.draw),
                        label: Text(_firmaImagen == null ? 'CAPTURAR FIRMA' : 'CAMBIAR FIRMA'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF1A237E),
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 12),
                        ),
                      ),
                    ),
                    if (_firmaImagen != null) ...[
                      const SizedBox(height: 12),
                      Container(
                        height: 150,
                        width: double.infinity,
                        decoration: BoxDecoration(
                          border: Border.all(color: Colors.grey),
                          borderRadius: BorderRadius.circular(8),
                          color: Colors.white,
                        ),
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(8),
                          child: CustomPaint(
                            painter: _FirmaPainter(_firmaImagen!),
                          ),
                        ),
                      ),
                      const SizedBox(height: 8),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text(
                            'Firma capturada',
                            style: TextStyle(fontSize: 12, color: Colors.green, fontWeight: FontWeight.bold),
                          ),
                          TextButton.icon(
                            onPressed: _eliminarFirma,
                            icon: const Icon(Icons.delete, size: 16, color: Colors.red),
                            label: const Text('Eliminar', style: TextStyle(color: Colors.red)),
                          ),
                        ],
                      ),
                    ],
                  ],
                ),
              ),
            ),
            const SizedBox(height: 24),
            if (_isSaving) const CircularProgressIndicator(),
            if (!_isSaving) Column(
              children: [
                Row(
                  children: [
                    Expanded(
                      child: ElevatedButton(
                        onPressed: _guardarYCerrar,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF1A237E),
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 16),
                        ),
                        child: const Text('Guardar Offline', style: TextStyle(fontSize: 16)),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: ElevatedButton.icon(
                        onPressed: _isGeneratingPDF ? null : _generarPDF,
                        icon: _isGeneratingPDF 
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
                          _isGeneratingPDF ? 'Generando PDF...' : 'Generar PDF',
                          style: const TextStyle(fontSize: 16),
                        ),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: _isGeneratingPDF ? Colors.grey : Colors.green,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 16),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),

            ],
          ),
        ),
      ),
    );
  }

  // Helper para mostrar fila de información no editable
  Widget _buildInfoRow(String label, dynamic value, {bool isInstalacion = false}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          SizedBox(
            width: 110,
            child: Text(
              label,
              style: const TextStyle(fontWeight: FontWeight.w600),
            ),
          ),
          Expanded(
            child: Text(
              value?.toString() ?? '-',
              style: const TextStyle(color: Colors.black87),
            ),
          ),
          if (isInstalacion)
            SizedBox(
              height: 36,
              child: ElevatedButton.icon(
                onPressed: _irAMapa,
                icon: const Icon(Icons.map, size: 18),
                label: const Text('IR'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF1A237E),
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  visualDensity: VisualDensity.compact,
                ),
              ),
            ),
        ],
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
