import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:geolocator/geolocator.dart';
import 'dart:io';
import '../main.dart';
import '../services/user_session.dart';

class RegistroLlegadaScreen extends StatefulWidget {
  const RegistroLlegadaScreen({super.key});

  @override
  State<RegistroLlegadaScreen> createState() => _RegistroLlegadaScreenState();
}

class _RegistroLlegadaScreenState extends State<RegistroLlegadaScreen> {
  final ImagePicker _imagePicker = ImagePicker();
  XFile? _selectedImage;
  bool _isLoading = false;
  bool _isCheckingLocation = true;
  bool _isWithinRange = false;
  String? _successMessage;
  String? _errorMessage;
  Position? _currentPosition;
  String? _locationString;
  double? _distanceToBase;
  String? _savedGpsQth;

  @override
  void initState() {
    super.initState();
    _validateLocationOnInit();
  }

  Future<void> _validateLocationOnInit() async {
    try {
      // Verificar permisos
      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) {
          if (mounted) {
            setState(() {
              _isCheckingLocation = false;
              _isWithinRange = false;
              _errorMessage =
                  'Se requieren permisos de ubicación para usar esta función';
            });
          }
          return;
        }
      }

      if (permission == LocationPermission.deniedForever) {
        if (mounted) {
          setState(() {
            _isCheckingLocation = false;
            _isWithinRange = false;
            _errorMessage =
                'Los permisos de ubicación están deshabilitados. Habilítalos en configuración.';
          });
        }
        return;
      }

      // Obtener ubicación actual
      final position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
      );

      // Obtener la ubicación guardada del usuario
      final user = supabase.auth.currentUser;
      if (user?.email == null) {
        if (mounted) {
          setState(() {
            _isCheckingLocation = false;
            _isWithinRange = false;
            _errorMessage = 'No hay usuario autenticado.';
          });
        }
        return;
      }

      // Buscar codigo_sup_aux en la tabla perfiles usando el email
      final profileResponse = await supabase
          .from('perfiles')
          .select('codigo_sup_aux')
          .eq('email', user!.email!)
          .maybeSingle();

      if (profileResponse == null || profileResponse['codigo_sup_aux'] == null) {
        if (mounted) {
          setState(() {
            _isCheckingLocation = false;
            _isWithinRange = false;
            _errorMessage = 'No hay código de usuario registrado.';
          });
        }
        return;
      }

      final codigoSupAux = profileResponse['codigo_sup_aux'] as String;

      // Buscar el gps_qth en la tabla base usando id_lector
      final baseResponse = await supabase
          .from('base')
          .select('gps_qth')
          .eq('id_lector', codigoSupAux)
          .order('inicio_jornada', ascending: false)
          .limit(1)
          .maybeSingle();

      if (baseResponse == null || baseResponse['gps_qth'] == null) {
        if (mounted) {
          setState(() {
            _isCheckingLocation = false;
            _isWithinRange = false;
            _errorMessage =
                'No hay ubicación base registrada para tu usuario.';
          });
        }
        return;
      }

      final gpsQth = baseResponse['gps_qth'] as String;
      final parts = gpsQth.split(',');

      if (parts.length != 2) {
        if (mounted) {
          setState(() {
            _isCheckingLocation = false;
            _isWithinRange = false;
            _errorMessage = 'Formato de coordenadas inválido.';
          });
        }
        return;
      }

      final savedLat = double.parse(parts[0].trim());
      final savedLng = double.parse(parts[1].trim());

      // Calcular distancia
      final distance = Geolocator.distanceBetween(
        savedLat,
        savedLng,
        position.latitude,
        position.longitude,
      );

      if (mounted) {
        setState(() {
          _isCheckingLocation = false;
          _currentPosition = position;
          _savedGpsQth = gpsQth;
          _distanceToBase = distance;
          _isWithinRange = distance <= 10; // 10 metros

          if (_isWithinRange) {
            _successMessage =
                'Ubicación validada. Estás a ${distance.toStringAsFixed(2)}m de la base.';
          } else {
            _errorMessage =
                'Estás a ${distance.toStringAsFixed(2)}m de la ubicación base. Acércate a menos de 10m.';
          }
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isCheckingLocation = false;
          _isWithinRange = false;
          _errorMessage = 'Error al validar ubicación: ${e.toString()}';
        });
      }
    }
  }

  Future<void> _captureOrSelectPhoto() async {
    try {
      final XFile? photo = await _imagePicker.pickImage(
        source: ImageSource.camera,
      );

      if (photo != null) {
        setState(() {
          _selectedImage = photo;
          _errorMessage = null;
          _successMessage = null;
        });
      }
    } catch (e) {
      setState(() {
        _errorMessage = 'Error al capturar la foto: ${e.toString()}';
      });
    }
  }

  Future<void> _captureLocation() async {
    try {
      setState(() {
        _isLoading = true;
        _errorMessage = null;
        _successMessage = null;
      });

      // Verificar permisos
      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) {
          throw Exception('Permisos de ubicación denegados');
        }
      }

      if (permission == LocationPermission.deniedForever) {
        throw Exception(
            'Los permisos de ubicación están deshabilitados permanentemente');
      }

      // Obtener ubicación actual
      final position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
      );

      final locationString =
          '${position.latitude},${position.longitude}';

      // Guardar en la tabla base
      final user = supabase.auth.currentUser;
      final userSession = UserSession();
      final codigoSupAux = userSession.codigoSupAux;
      final nombreCompleto = userSession.nombreCompleto;

      await supabase.from('base').insert({
        'codigo_sup_aux': codigoSupAux,
        'nombre_completo': nombreCompleto,
        'email': user?.email,
        'dir_llegada': locationString,
        'tipo_registro': 'UBICACION_LLEGADA',
        'inicio_jornada': DateTime.now().toIso8601String(),
      });

      if (!mounted) return;

      setState(() {
        _isLoading = false;
        _currentPosition = position;
        _locationString = locationString;
        _successMessage =
            'Ubicación registrada: ${position.latitude.toStringAsFixed(4)}, ${position.longitude.toStringAsFixed(4)}';
      });

      // Limpiar mensaje de éxito después de 3 segundos
      Future.delayed(const Duration(seconds: 3), () {
        if (mounted) {
          setState(() {
            _successMessage = null;
          });
        }
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
        _errorMessage = 'Error al capturar la ubicación: ${e.toString()}';
      });
    }
  }

  Future<void> _uploadPhoto() async {
    if (_selectedImage == null) {
      setState(() {
        _errorMessage = 'Por favor, captura una foto primero';
      });
      return;
    }

    setState(() {
      _isLoading = true;
      _errorMessage = null;
      _successMessage = null;
    });

    try {
      // Obtener datos del usuario logueado
      final user = supabase.auth.currentUser;
      if (user == null) {
        throw Exception('No hay usuario logueado');
      }

      // Obtener información del usuario
      final userSession = UserSession();
      final codigoSupAux = userSession.codigoSupAux;
      final nombreCompleto = userSession.nombreCompleto;

      // Crear nombre único para la foto
      final timestamp = DateTime.now().millisecondsSinceEpoch;
      final fileName =
          '${codigoSupAux}_${nombreCompleto?.replaceAll(' ', '_') ?? 'usuario'}_$timestamp.jpg';

      // Leer el archivo
      final bytes = await File(_selectedImage!.path).readAsBytes();

      // Subir a Supabase Storage
      await supabase.storage.from('cold').uploadBinary(
            'registro_llegadas/$fileName',
            bytes,
            fileOptions: FileOptions(
              cacheControl: '3600',
              upsert: false,
            ),
          );

      // Obtener URL pública
      final photoUrl = supabase.storage
          .from('cold')
          .getPublicUrl('registro_llegadas/$fileName');

      // Guardar en la tabla base
      await supabase.from('base').insert({
        'codigo_sup_aux': codigoSupAux,
        'nombre_completo': nombreCompleto,
        'email': user.email,
        'evidencia': photoUrl,
        'tipo_registro': 'REGISTRO_LLEGADA',
        'inicio_jornada': DateTime.now().toIso8601String(),
      });

      if (!mounted) return;

      setState(() {
        _isLoading = false;
        _successMessage = '¡Foto registrada exitosamente!';
        _selectedImage = null;
      });

      // Limpiar mensaje de éxito después de 3 segundos
      Future.delayed(const Duration(seconds: 3), () {
        if (mounted) {
          setState(() {
            _successMessage = null;
          });
        }
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
        _errorMessage = 'Error al guardar la foto: ${e.toString()}';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Registro de Llegada'),
        backgroundColor: const Color(0xFF1A237E),
        foregroundColor: Colors.white,
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Mensajes de estado
              if (_successMessage != null)
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.green.shade100,
                    border: Border.all(color: Colors.green.shade400),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    _successMessage!,
                    style: TextStyle(
                      color: Colors.green.shade700,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              if (_errorMessage != null)
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.red.shade100,
                    border: Border.all(color: Colors.red.shade400),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    _errorMessage!,
                    style: TextStyle(
                      color: Colors.red.shade700,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              const SizedBox(height: 24),

              // Estado de validación de ubicación
              if (_isCheckingLocation)
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.blue.shade100,
                    border: Border.all(color: Colors.blue.shade400),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    children: [
                      const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          valueColor:
                              AlwaysStoppedAnimation<Color>(Color(0xFF1A237E)),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Text(
                        'Validando ubicación...',
                        style: TextStyle(
                          color: Colors.blue.shade700,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),
              if (!_isCheckingLocation && _isWithinRange)
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.green.shade100,
                    border: Border.all(color: Colors.green.shade400),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    children: [
                      Icon(Icons.check_circle, color: Colors.green.shade700),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          'Ubicación validada. Distancia: ${_distanceToBase?.toStringAsFixed(2) ?? '0'}m',
                          style: TextStyle(
                            color: Colors.green.shade700,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              if (!_isCheckingLocation && !_isWithinRange)
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.red.shade100,
                    border: Border.all(color: Colors.red.shade400),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    children: [
                      Icon(Icons.warning, color: Colors.red.shade700),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          'Fuera de rango. Distancia: ${_distanceToBase?.toStringAsFixed(2) ?? '0'}m',
                          style: TextStyle(
                            color: Colors.red.shade700,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              const SizedBox(height: 24),

              // Área de foto
              Container(
                decoration: BoxDecoration(
                  border: Border.all(
                    color: const Color(0xFF1A237E).withValues(alpha: 0.3),
                    width: 2,
                  ),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: _selectedImage != null
                    ? ClipRRect(
                        borderRadius: BorderRadius.circular(10),
                        child: Image.file(
                          File(_selectedImage!.path),
                          fit: BoxFit.cover,
                          height: 300,
                        ),
                      )
                    : Container(
                        height: 300,
                        decoration: BoxDecoration(
                          color: const Color(0xFF1A237E).withValues(alpha: 0.05),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.camera_alt,
                              size: 64,
                              color: const Color(0xFF1A237E).withValues(alpha: 0.4),
                            ),
                            const SizedBox(height: 16),
                            Text(
                              'Sin foto capturada',
                              style: TextStyle(
                                color: Colors.grey.shade600,
                                fontSize: 16,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ],
                        ),
                      ),
              ),
              const SizedBox(height: 24),

              // Botón para capturar foto
              ElevatedButton.icon(
                onPressed: (_isLoading || _isCheckingLocation || !_isWithinRange)
                    ? null
                    : _captureOrSelectPhoto,
                icon: const Icon(Icons.camera_alt),
                label: const Text('Capturar Selfie'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF1A237E),
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  disabledBackgroundColor: Colors.grey.shade400,
                ),
              ),
              if (!_isWithinRange && !_isCheckingLocation)
                Padding(
                  padding: const EdgeInsets.only(top: 8),
                  child: Text(
                    'Debes estar a menos de 10m de la ubicación base para capturar',
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.red.shade600,
                      fontWeight: FontWeight.w500,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ),
              const SizedBox(height: 16),

              // Botón para guardar
              ElevatedButton.icon(
                onPressed: _isLoading ? null : _uploadPhoto,
                icon: _isLoading
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                        ),
                      )
                    : const Icon(Icons.save),
                label: Text(_isLoading ? 'Guardando...' : 'Guardar Foto'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.green.shade600,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  disabledBackgroundColor: Colors.grey.shade400,
                ),
              ),
              const SizedBox(height: 24),

              // Botón para capturar ubicación
              ElevatedButton.icon(
                onPressed: (_isLoading || _isCheckingLocation || !_isWithinRange)
                    ? null
                    : _captureLocation,
                icon: _isLoading
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                        ),
                      )
                    : const Icon(Icons.location_on),
                label: Text(_isLoading ? 'Capturando...' : 'Captura de Ubicación'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.orange.shade600,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  disabledBackgroundColor: Colors.grey.shade400,
                ),
              ),
              if (!_isWithinRange && !_isCheckingLocation)
                Padding(
                  padding: const EdgeInsets.only(top: 8),
                  child: Text(
                    'Debes estar a menos de 10m de la ubicación base para capturar',
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.red.shade600,
                      fontWeight: FontWeight.w500,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ),
              const SizedBox(height: 8),
              if (_locationString != null)
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.orange.shade50,
                    border: Border.all(color: Colors.orange.shade300),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    children: [
                      Icon(Icons.location_on, color: Colors.orange.shade600),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          'Ubicación: $_locationString',
                          style: TextStyle(
                            color: Colors.orange.shade700,
                            fontWeight: FontWeight.w500,
                            fontSize: 13,
                          ),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                ),
              const SizedBox(height: 24),

              // Información
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.blue.shade50,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.blue.shade200),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(Icons.info, color: Colors.blue.shade700),
                        const SizedBox(width: 8),
                        Text(
                          'Información',
                          style: TextStyle(
                            color: Colors.blue.shade700,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Text(
                      '• Captura una selfie clara con tu cara visible\n'
                      '• La foto se guardará en el registro de llegadas\n'
                      '• Solo se puede registrar una foto por sesión',
                      style: TextStyle(
                        color: Colors.blue.shade700,
                        fontSize: 13,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
