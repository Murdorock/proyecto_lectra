import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:file_picker/file_picker.dart';
import 'dart:io';
import '../main.dart';
import '../services/user_session.dart';

class EditarErrorScreen extends StatefulWidget {
  final Map<String, dynamic> error;

  const EditarErrorScreen({
    super.key,
    required this.error,
  });

  @override
  State<EditarErrorScreen> createState() => _EditarErrorScreenState();
}

class _EditarErrorScreenState extends State<EditarErrorScreen> {
  final TextEditingController _argumentoController = TextEditingController();
  final ImagePicker _picker = ImagePicker();
  
  String? _refutar;
  File? _evidencia1;
  File? _evidencia2;
  File? _archivoPdf;
  File? _archivoVideo;
  String? _evidencia1Url;
  String? _evidencia2Url;
  String? _pdfUrl;
  String? _videoUrl;
  bool _isLoading = true;
  bool _isSaving = false;
  String? _errorMessage;
  Map<String, dynamic>? _detalleError;
  
  // Lista de errores que requieren PDF
  final List<String> _erroresRequierenPdf = [
    'Error_Foto/Alfa',
    'E_Relect',
    'E_P74',
  ];

  @override
  void initState() {
    super.initState();
    _loadDetalle();
  }

  @override
  void dispose() {
    _argumentoController.dispose();
    super.dispose();
  }

  bool get _requierePdf {
    if (_detalleError == null) return false;
    final error = _detalleError!['error']?.toString() ?? '';
    return _erroresRequierenPdf.contains(error);
  }

  bool get _requiereVideo {
    if (_detalleError == null) return false;
    final error = _detalleError!['error']?.toString() ?? '';
    return error.contains('Descarga');
  }

  String _sanitizeForFileName(String value) {
    final sanitized = value
        .trim()
        .replaceAll(RegExp(r'\s+'), '_')
        .replaceAll(RegExp(r'[^a-zA-Z0-9_-]'), '');
    return sanitized.isEmpty ? 'sin_dato' : sanitized;
  }

  String _buildDateTimeStamp() {
    final now = DateTime.now();
    final year = now.year.toString().padLeft(4, '0');
    final month = now.month.toString().padLeft(2, '0');
    final day = now.day.toString().padLeft(2, '0');
    final hour = now.hour.toString().padLeft(2, '0');
    final minute = now.minute.toString().padLeft(2, '0');
    final second = now.second.toString().padLeft(2, '0');
    return '${year}${month}${day}_${hour}${minute}${second}';
  }

  String _buildFileName({
    required String tipo,
    required String extension,
    int? numeroEvidencia,
  }) {
    final instalacion = _sanitizeForFileName(
      (_detalleError?['instalacion'] ?? widget.error['instalacion'] ?? '').toString(),
    );
    final lector = _sanitizeForFileName(
      (_detalleError?['lector'] ??
              widget.error['lector'] ??
              UserSession().codigoSupAux ??
              '')
          .toString(),
    );
    final timestamp = _buildDateTimeStamp();
    final tipoConNumero = numeroEvidencia != null ? '${tipo}_$numeroEvidencia' : tipo;
    final tipoFinal = _sanitizeForFileName(tipoConNumero).toLowerCase();
    final safeExtension = _sanitizeForFileName(extension).toLowerCase();
    final finalExtension = safeExtension.isEmpty ? 'dat' : safeExtension;

    return '${timestamp}_${instalacion}_${lector}_${tipoFinal}.$finalExtension';
  }

  Future<void> _loadDetalle() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final data = await supabase
          .from('refutar_errores')
          .select('''
            direccion, instalacion, consumo, causa_observacion, adicional, 
            alfa, ciclo, supervisor_zona, foto, falta_firma, observacion, 
            debia_dejar_constancia, observacion_constancia, error,
            refutar, argumento, evidencia1, evidencia2, pdf, video, lector
          ''')
          .eq('id', widget.error['id'])
          .single();

      if (mounted) {
        setState(() {
          _detalleError = data;
          _refutar = data['refutar']?.toString();
          _argumentoController.text = data['argumento']?.toString() ?? '';
          _evidencia1Url = data['evidencia1']?.toString();
          _evidencia2Url = data['evidencia2']?.toString();
          _pdfUrl = data['pdf']?.toString();
          _videoUrl = data['video']?.toString();
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _errorMessage = 'Error al cargar el detalle: ${e.toString()}';
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _tomarFoto(int numeroEvidencia) async {
    try {
      final XFile? photo = await _picker.pickImage(
        source: ImageSource.camera,
        imageQuality: 85,
      );

      if (photo != null) {
        setState(() {
          if (numeroEvidencia == 1) {
            _evidencia1 = File(photo.path);
          } else {
            _evidencia2 = File(photo.path);
          }
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error al tomar la foto: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _seleccionarDeGaleria(int numeroEvidencia) async {
    try {
      final XFile? photo = await _picker.pickImage(
        source: ImageSource.gallery,
        imageQuality: 85,
      );

      if (photo != null) {
        setState(() {
          if (numeroEvidencia == 1) {
            _evidencia1 = File(photo.path);
          } else {
            _evidencia2 = File(photo.path);
          }
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error al seleccionar la foto: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<String?> _subirFoto(File foto, int numeroEvidencia) async {
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
        return null;
      }
      
      final fileName = _buildFileName(
        tipo: 'evidencia',
        extension: 'jpg',
        numeroEvidencia: numeroEvidencia,
      );
      final filePath = 'refutar_errores/$fileName';

      await supabase.storage
          .from('cold')
          .upload(filePath, foto);

      final publicUrl = supabase.storage
          .from('cold')
          .getPublicUrl(filePath);

      return publicUrl;
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error al subir la foto: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
      return null;
    }
  }

  Future<void> _seleccionarPdf() async {
    try {
      FilePickerResult? result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['pdf'],
      );

      if (result != null && result.files.single.path != null) {
        setState(() {
          _archivoPdf = File(result.files.single.path!);
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error al seleccionar el PDF: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<String?> _subirPdf(File pdf) async {
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
        return null;
      }
      
      final fileName = _buildFileName(
        tipo: 'pdf',
        extension: 'pdf',
      );
      final filePath = 'refutar_errores/$fileName';

      await supabase.storage
          .from('cold')
          .upload(filePath, pdf);

      final publicUrl = supabase.storage
          .from('cold')
          .getPublicUrl(filePath);

      return publicUrl;
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error al subir el PDF: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
      return null;
    }
  }

  Future<void> _seleccionarVideo() async {
    try {
      FilePickerResult? result = await FilePicker.platform.pickFiles(
        type: FileType.video,
      );

      if (result != null && result.files.single.path != null) {
        final file = File(result.files.single.path!);
        final fileSize = await file.length();
        final maxSize = 95 * 1024 * 1024; // 95MB en bytes

        if (fileSize > maxSize) {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('El video no debe superar los 95MB'),
                backgroundColor: Colors.red,
              ),
            );
          }
          return;
        }

        setState(() {
          _archivoVideo = file;
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error al seleccionar el video: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<String?> _subirVideo(File video) async {
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
        return null;
      }
      
      final extensionPart = video.path.split('.').last;
      final fileName = _buildFileName(
        tipo: 'video',
        extension: extensionPart,
      );
      final filePath = 'refutar_errores/$fileName';

      await supabase.storage
          .from('cold')
          .upload(filePath, video);

      final publicUrl = supabase.storage
          .from('cold')
          .getPublicUrl(filePath);

      return publicUrl;
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error al subir el video: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
      return null;
    }
  }

  Future<void> _guardar() async {
    // Validar que se haya seleccionado si refuta o no
    if (_refutar == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Debe seleccionar si refuta o no el error'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    // Validar que haya al menos una evidencia
    if (_evidencia1 == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Debe capturar al menos la primera evidencia'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    // Validar que se haya subido el PDF si el error lo requiere
    if (_requierePdf && _archivoPdf == null && _pdfUrl == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Debe subir un archivo PDF para este tipo de error'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    // Validar que se haya subido el video si el error lo requiere
    if (_requiereVideo && _archivoVideo == null && _videoUrl == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Debe subir un video para este tipo de error'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    setState(() {
      _isSaving = true;
    });

    try {
      // Subir evidencias
      String? urlEvidencia1;
      String? urlEvidencia2;
      String? urlPdf;
      String? urlVideo;

      if (_evidencia1 != null) {
        urlEvidencia1 = await _subirFoto(_evidencia1!, 1);
        if (urlEvidencia1 == null) {
          setState(() {
            _isSaving = false;
          });
          return;
        }
      }

      if (_evidencia2 != null) {
        urlEvidencia2 = await _subirFoto(_evidencia2!, 2);
      }

      // Subir PDF si existe
      if (_archivoPdf != null) {
        urlPdf = await _subirPdf(_archivoPdf!);
        if (urlPdf == null) {
          setState(() {
            _isSaving = false;
          });
          return;
        }
      }

      // Subir video si existe
      if (_archivoVideo != null) {
        urlVideo = await _subirVideo(_archivoVideo!);
        if (urlVideo == null) {
          setState(() {
            _isSaving = false;
          });
          return;
        }
      }

      // Guardar en la base de datos
      final updateData = {
        'refutar': _refutar,
        'argumento': _argumentoController.text.isNotEmpty 
            ? _argumentoController.text 
            : null,
        'evidencia1': urlEvidencia1,
        'evidencia2': urlEvidencia2,
      };

      // Agregar PDF solo si existe
      if (urlPdf != null) {
        updateData['pdf'] = urlPdf;
      }

      // Agregar video solo si existe
      if (urlVideo != null) {
        updateData['video'] = urlVideo;
      }

      await supabase
          .from('refutar_errores')
          .update(updateData)
          .eq('id', widget.error['id']);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Refutación guardada exitosamente'),
            backgroundColor: Colors.green,
          ),
        );
        Navigator.pop(context, true);
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isSaving = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error al guardar: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Detalle del Error'),
        backgroundColor: const Color(0xFF1A237E),
        foregroundColor: Colors.white,
        actions: [
          if (!_isLoading && _detalleError != null)
            IconButton(
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
              onPressed: _isSaving ? null : _guardar,
              tooltip: 'Guardar',
            ),
        ],
      ),
      body: _isLoading
          ? const Center(
              child: CircularProgressIndicator(
                valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF1A237E)),
              ),
            )
          : _errorMessage != null
              ? Center(
                  child: Padding(
                    padding: const EdgeInsets.all(24.0),
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
                          onPressed: _loadDetalle,
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
              : SingleChildScrollView(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Sección: Información No Editable
                      _buildSectionTitle('Información del Error'),
                      Card(
                        elevation: 2,
                        child: Padding(
                          padding: const EdgeInsets.all(16),
                          child: Column(
                            children: [
                              _buildReadOnlyField('Dirección', _detalleError!['direccion']),
                              _buildReadOnlyField('Instalación', _detalleError!['instalacion']),
                              _buildReadOnlyField('Consumo', _detalleError!['consumo']),
                              _buildReadOnlyField('Causa Observación', _detalleError!['causa_observacion']),
                              _buildReadOnlyField('Adicional', _detalleError!['adicional']),
                              _buildReadOnlyField('Alfa', _detalleError!['alfa']),
                              _buildReadOnlyField('Ciclo', _detalleError!['ciclo']),
                              _buildReadOnlyField('Supervisor Zona', _detalleError!['supervisor_zona']),
                              _buildReadOnlyField('Foto', _detalleError!['foto']),
                              _buildReadOnlyField('Falta Firma', _detalleError!['falta_firma']),
                              _buildReadOnlyField('Observación', _detalleError!['observacion']),
                              _buildReadOnlyField('Debía Dejar Constancia', _detalleError!['debia_dejar_constancia']),
                              _buildReadOnlyField('Observación Constancia', _detalleError!['observacion_constancia']),
                              _buildReadOnlyField('Error', _detalleError!['error']),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(height: 24),

                      // Sección: Campos Editables
                      _buildSectionTitle('Refutación'),
                      Card(
                        elevation: 2,
                        child: Padding(
                          padding: const EdgeInsets.all(16),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              // Campo Refutar
                              const Text(
                                '¿Refutar?',
                                style: TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.bold,
                                  color: Color(0xFF1A237E),
                                ),
                              ),
                              const SizedBox(height: 8),
                              DropdownButtonFormField<String>(
                                initialValue: _refutar,
                                decoration: InputDecoration(
                                  hintText: 'Seleccione una opción',
                                  prefixIcon: const Icon(
                                    Icons.check_circle_outline,
                                    color: Color(0xFF1A237E),
                                  ),
                                  filled: true,
                                  fillColor: Colors.grey.shade100,
                                  border: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                ),
                                items: const [
                                  DropdownMenuItem(value: 'Si', child: Text('Si')),
                                  DropdownMenuItem(value: 'No', child: Text('No')),
                                ],
                                onChanged: (value) {
                                  setState(() {
                                    _refutar = value;
                                  });
                                },
                              ),
                              const SizedBox(height: 16),

                              // Campo Argumento
                              const Text(
                                'Argumento',
                                style: TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.bold,
                                  color: Color(0xFF1A237E),
                                ),
                              ),
                              const SizedBox(height: 8),
                              TextField(
                                controller: _argumentoController,
                                maxLines: 4,
                                decoration: InputDecoration(
                                  hintText: 'Escriba el argumento de la refutación',
                                  filled: true,
                                  fillColor: Colors.grey.shade100,
                                  border: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                ),
                              ),
                              const SizedBox(height: 24),

                              // Botón PDF (solo si el error lo requiere)
                              if (_requierePdf) ...[
                                const Text(
                                  'Documento PDF',
                                  style: TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.bold,
                                    color: Color(0xFF1A237E),
                                  ),
                                ),
                                const SizedBox(height: 8),
                                const Text(
                                  'Este tipo de error requiere la carga de un archivo PDF',
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: Colors.red,
                                    fontStyle: FontStyle.italic,
                                  ),
                                ),
                                const SizedBox(height: 12),
                                _buildPdfCard(),
                                const SizedBox(height: 24),
                              ],

                              // Botón Video (solo si el error lo requiere)
                              if (_requiereVideo) ...[
                                const Text(
                                  'Video',
                                  style: TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.bold,
                                    color: Color(0xFF1A237E),
                                  ),
                                ),
                                const SizedBox(height: 8),
                                const Text(
                                  'Este tipo de error requiere la carga de un video (máx. 95MB)',
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: Colors.red,
                                    fontStyle: FontStyle.italic,
                                  ),
                                ),
                                const SizedBox(height: 12),
                                _buildVideoCard(),
                                const SizedBox(height: 24),
                              ],

                              // Evidencias
                              const Text(
                                'Evidencias',
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                  color: Color(0xFF1A237E),
                                ),
                              ),
                              const SizedBox(height: 12),

                              // Evidencia 1 (Obligatoria)
                              _buildEvidenciaCard(
                                numero: 1,
                                obligatoria: true,
                                foto: _evidencia1,
                                urlGuardada: _evidencia1Url,
                                onTomar: () => _tomarFoto(1),
                                onSeleccionar: () => _seleccionarDeGaleria(1),
                                onEliminar: () {
                                  setState(() {
                                    _evidencia1 = null;
                                    _evidencia1Url = null;
                                  });
                                },
                              ),
                              const SizedBox(height: 12),

                              // Evidencia 2 (Opcional)
                              _buildEvidenciaCard(
                                numero: 2,
                                obligatoria: false,
                                foto: _evidencia2,
                                urlGuardada: _evidencia2Url,
                                onTomar: () => _tomarFoto(2),
                                onSeleccionar: () => _seleccionarDeGaleria(2),
                                onEliminar: () {
                                  setState(() {
                                    _evidencia2 = null;
                                    _evidencia2Url = null;
                                  });
                                },
                              ),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(height: 24),

                      // Botón Guardar
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton.icon(
                          onPressed: _isSaving ? null : _guardar,
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
                            _isSaving ? 'GUARDANDO...' : 'GUARDAR REFUTACIÓN',
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
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Text(
        title,
        style: const TextStyle(
          fontSize: 18,
          fontWeight: FontWeight.bold,
          color: Color(0xFF1A237E),
        ),
      ),
    );
  }

  Widget _buildReadOnlyField(String label, dynamic value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            flex: 2,
            child: Text(
              '$label:',
              style: const TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 13,
                color: Colors.grey,
              ),
            ),
          ),
          Expanded(
            flex: 3,
            child: Text(
              value?.toString() ?? 'N/A',
              style: const TextStyle(
                fontSize: 13,
                color: Colors.black87,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEvidenciaCard({
    required int numero,
    required bool obligatoria,
    required File? foto,
    String? urlGuardada,
    required VoidCallback onTomar,
    required VoidCallback onSeleccionar,
    required VoidCallback onEliminar,
  }) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        border: Border.all(
          color: obligatoria ? Colors.red : Colors.grey,
          width: obligatoria ? 2 : 1,
        ),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.camera_alt,
                color: obligatoria ? Colors.red : const Color(0xFF1A237E),
              ),
              const SizedBox(width: 8),
              Text(
                'Evidencia $numero ${obligatoria ? "(Obligatoria)" : "(Opcional)"}',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  color: obligatoria ? Colors.red : const Color(0xFF1A237E),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          if (foto != null || urlGuardada != null) ...[
            ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: foto != null
                  ? Image.file(
                      foto,
                      height: 200,
                      width: double.infinity,
                      fit: BoxFit.cover,
                    )
                  : Image.network(
                      urlGuardada!,
                      height: 200,
                      width: double.infinity,
                      fit: BoxFit.cover,
                      loadingBuilder: (context, child, loadingProgress) {
                        if (loadingProgress == null) return child;
                        return Container(
                          height: 200,
                          alignment: Alignment.center,
                          child: CircularProgressIndicator(
                            value: loadingProgress.expectedTotalBytes != null
                                ? loadingProgress.cumulativeBytesLoaded /
                                    loadingProgress.expectedTotalBytes!
                                : null,
                          ),
                        );
                      },
                      errorBuilder: (context, error, stackTrace) {
                        return Container(
                          height: 200,
                          color: Colors.grey.shade200,
                          child: const Center(
                            child: Icon(Icons.error, color: Colors.red),
                          ),
                        );
                      },
                    ),
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: onTomar,
                    icon: const Icon(Icons.refresh),
                    label: const Text('Reemplazar'),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: const Color(0xFF1A237E),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: onEliminar,
                    icon: const Icon(Icons.delete),
                    label: const Text('Eliminar'),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: Colors.red,
                    ),
                  ),
                ),
              ],
            ),
          ] else ...[
            ElevatedButton.icon(
              onPressed: onTomar,
              icon: const Icon(Icons.camera_alt),
              label: const Text('TOMAR FOTO'),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF1A237E),
                foregroundColor: Colors.white,
                minimumSize: const Size(double.infinity, 48),
              ),
            ),
            const SizedBox(height: 8),
            OutlinedButton.icon(
              onPressed: onSeleccionar,
              icon: const Icon(Icons.photo_library),
              label: const Text('SELECCIONAR DE GALERÍA'),
              style: OutlinedButton.styleFrom(
                foregroundColor: const Color(0xFF1A237E),
                minimumSize: const Size(double.infinity, 48),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildPdfCard() {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        border: Border.all(
          color: Colors.red,
          width: 2,
        ),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(
                Icons.picture_as_pdf,
                color: Colors.red,
              ),
              const SizedBox(width: 8),
              const Text(
                'PDF (Obligatorio)',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  color: Colors.red,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          if (_archivoPdf != null || _pdfUrl != null) ...[
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.green.shade50,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.green),
              ),
              child: Row(
                children: [
                  const Icon(
                    Icons.check_circle,
                    color: Colors.green,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      _archivoPdf != null
                          ? _archivoPdf!.path.split('/').last
                          : 'PDF guardado anteriormente',
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  if (_pdfUrl != null && _archivoPdf == null)
                    IconButton(
                      icon: const Icon(Icons.open_in_new, color: Colors.blue),
                      onPressed: () async {
                        // Aquí podrías abrir el PDF en el navegador si lo deseas
                      },
                      tooltip: 'Ver PDF',
                    ),
                ],
              ),
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: _seleccionarPdf,
                    icon: const Icon(Icons.refresh),
                    label: const Text('Reemplazar PDF'),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: const Color(0xFF1A237E),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () {
                      setState(() {
                        _archivoPdf = null;
                        _pdfUrl = null;
                      });
                    },
                    icon: const Icon(Icons.delete),
                    label: const Text('Eliminar'),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: Colors.red,
                    ),
                  ),
                ),
              ],
            ),
          ] else ...[
            ElevatedButton.icon(
              onPressed: _seleccionarPdf,
              icon: const Icon(Icons.upload_file),
              label: const Text('SELECCIONAR PDF'),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF1A237E),
                foregroundColor: Colors.white,
                minimumSize: const Size(double.infinity, 48),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildVideoCard() {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        border: Border.all(
          color: Colors.red,
          width: 2,
        ),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(
                Icons.video_file,
                color: Colors.red,
              ),
              const SizedBox(width: 8),
              const Text(
                'Video (Obligatorio - Máx. 95MB)',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  color: Colors.red,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          if (_archivoVideo != null || _videoUrl != null) ...[
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.green.shade50,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.green),
              ),
              child: Row(
                children: [
                  const Icon(
                    Icons.check_circle,
                    color: Colors.green,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      _archivoVideo != null
                          ? _archivoVideo!.path.split('/').last
                          : 'Video guardado anteriormente',
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  if (_videoUrl != null && _archivoVideo == null)
                    IconButton(
                      icon: const Icon(Icons.play_circle_outline, color: Colors.blue),
                      onPressed: () async {
                        // Aquí podrías abrir el video en el navegador si lo deseas
                      },
                      tooltip: 'Ver Video',
                    ),
                ],
              ),
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: _seleccionarVideo,
                    icon: const Icon(Icons.refresh),
                    label: const Text('Reemplazar Video'),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: const Color(0xFF1A237E),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () {
                      setState(() {
                        _archivoVideo = null;
                        _videoUrl = null;
                      });
                    },
                    icon: const Icon(Icons.delete),
                    label: const Text('Eliminar'),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: Colors.red,
                    ),
                  ),
                ),
              ],
            ),
          ] else ...[
            ElevatedButton.icon(
              onPressed: _seleccionarVideo,
              icon: const Icon(Icons.videocam),
              label: const Text('SELECCIONAR VIDEO'),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF1A237E),
                foregroundColor: Colors.white,
                minimumSize: const Size(double.infinity, 48),
              ),
            ),
          ],
        ],
      ),
    );
  }
}
