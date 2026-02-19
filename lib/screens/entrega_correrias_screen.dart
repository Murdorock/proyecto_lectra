import 'package:flutter/material.dart';
import '../main.dart';
import 'package:intl/intl.dart';
import 'package:mobile_scanner/mobile_scanner.dart';

class EntregaCorreriasScreen extends StatefulWidget {
  const EntregaCorreriasScreen({super.key});

  @override
  State<EntregaCorreriasScreen> createState() => _EntregaCorreriasScreenState();
}

class _EntregaCorreriasScreenState extends State<EntregaCorreriasScreen> {
  // Controladores
  final TextEditingController _correriaScannedController = TextEditingController();
  final TextEditingController _funcionarioScannedController = TextEditingController();

  // Variables de estado
  Map<String, dynamic>? _correriaData;
  Map<String, dynamic>? _funcionarioData;
  bool _isLoadingCorreria = false;
  bool _isLoadingFuncionario = false;
  bool _isSaving = false;
  String? _errorMessage;
  String? _successMessage;

  @override
  void dispose() {
    _correriaScannedController.dispose();
    _funcionarioScannedController.dispose();
    super.dispose();
  }

  /// Abre la cámara para escanear la correría
  Future<void> _abrirScannerCorreria() async {
    try {
      final result = await Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => BarcodeScannerScreen(
            title: 'Escanear Correría',
          ),
        ),
      );

      if (result != null && result.isNotEmpty) {
        setState(() {
          _correriaScannedController.text = result;
        });
        await _buscarCorreria(result);
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _errorMessage = 'Error al abrir escáner: ${e.toString()}';
        });
      }
    }
  }

  /// Busca la correría escaneada en la tabla correrias_reparto
  Future<void> _buscarCorreria(String barcodeValue) async {
    if (barcodeValue.isEmpty) {
      setState(() {
        _errorMessage = 'Por favor escanee un código válido';
      });
      return;
    }

    setState(() {
      _isLoadingCorreria = true;
      _errorMessage = null;
      _correriaData = null;
    });

    try {
      final data = await supabase
          .from('correrias_reparto')
          .select('correria, nombre_correria')
          .eq('correria', barcodeValue)
          .maybeSingle();

      if (mounted) {
        if (data != null) {
          setState(() {
            _correriaData = data;
            _isLoadingCorreria = false;
          });
        } else {
          setState(() {
            _errorMessage = 'No se encontró la correría: $barcodeValue';
            _isLoadingCorreria = false;
          });
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _errorMessage = 'Error al buscar correría: ${e.toString()}';
          _isLoadingCorreria = false;
        });
      }
    }
  }

  /// Abre la cámara para escanear el funcionario
  Future<void> _abrirScannerFuncionario() async {
    try {
      final result = await Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => BarcodeScannerScreen(
            title: 'Escanear Cédula del Funcionario',
          ),
        ),
      );

      if (result != null && result.isNotEmpty) {
        setState(() {
          _funcionarioScannedController.text = result;
        });
        await _buscarFuncionario(result);
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _errorMessage = 'Error al abrir escáner: ${e.toString()}';
        });
      }
    }
  }

  /// Busca el funcionario escaneado en la tabla personal
  Future<void> _buscarFuncionario(String barcodeValue) async {
    if (barcodeValue.isEmpty) {
      setState(() {
        _errorMessage = 'Por favor escanee un código válido';
      });
      return;
    }

    setState(() {
      _isLoadingFuncionario = true;
      _errorMessage = null;
      _funcionarioData = null;
    });

    try {
      final data = await supabase
          .from('personal')
          .select('numero_cedula, id_codigo, nombre_completo')
          .eq('numero_cedula', barcodeValue)
          .maybeSingle();

      if (mounted) {
        if (data != null) {
          setState(() {
            _funcionarioData = data;
            _isLoadingFuncionario = false;
          });
        } else {
          setState(() {
            _errorMessage = 'No se encontró el funcionario: $barcodeValue';
            _isLoadingFuncionario = false;
          });
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _errorMessage = 'Error al buscar funcionario: ${e.toString()}';
          _isLoadingFuncionario = false;
        });
      }
    }
  }

  /// Guarda la entrega en la tabla entrega_correrías
  Future<void> _guardarEntrega() async {
    // Validaciones
    if (_correriaData == null) {
      setState(() {
        _errorMessage = 'Debe escanear una correría primero';
      });
      return;
    }

    if (_funcionarioData == null) {
      setState(() {
        _errorMessage = 'Debe escanear un funcionario primero';
      });
      return;
    }

    setState(() {
      _isSaving = true;
      _errorMessage = null;
      _successMessage = null;
    });

    try {
      final idEntrega = _correriaScannedController.text.trim(); // Código escaneado
      final idCodigo = _funcionarioData!['id_codigo'];
      final fechaHoy = DateTime.now();
      final reclamo = '$idCodigo';

      // Verificar si ya existe una entrega para esta correría
        final existingDelivery = await supabase
          .from('entrega_correrias')
          .select('id_entrega, fecha, reclamo')
          .eq('id_entrega', idEntrega)
          .maybeSingle();

      if (mounted) {
        if (existingDelivery != null) {
          // Mostrar diálogo de reasignación
          _showReassignmentDialog(
            idEntrega,
            idCodigo,
            fechaHoy,
            reclamo,
            existingDelivery,
          );
        } else {
          // Guardar nueva entrega
          await _insertDelivery(idEntrega, fechaHoy, reclamo);
          _showSuccessMessage(idEntrega, idCodigo, null);
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _errorMessage = 'Error al guardar: ${e.toString()}';
          _isSaving = false;
        });
      }
    }
  }

  /// Inserta una nueva entrega en la tabla
  Future<void> _insertDelivery(
    String idEntrega,
    DateTime fecha,
    String reclamo,
  ) async {
    await supabase.from('entrega_correrias').insert({
      'id_entrega': idEntrega,
      'fecha': DateFormat('yyyy-MM-dd').format(fecha),
      'reclamo': reclamo,
    });
  }

  /// Muestra el diálogo de reasignación
  void _showReassignmentDialog(
    String idEntrega,
    String idCodigo,
    DateTime fechaHoy,
    String reclamo,
    Map<String, dynamic> existingDelivery,
  ) async {
    // Usar la fecha del existingDelivery (fecha de la entrega anterior)
    String fechaPrevia = existingDelivery['fecha'] ?? 'Sin fecha';

    final funcionarioAnterior = existingDelivery['reclamo'] ?? 'Desconocido';

    if (mounted) {
      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('Reasignar Entrega'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'La correría $idEntrega fue recibida por $funcionarioAnterior el $fechaPrevia.',
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 16),
              const Text('¿Desea reasignar la entrega?'),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(context);
                setState(() {
                  _isSaving = false;
                });
              },
              child: const Text('NO'),
            ),
            ElevatedButton(
              onPressed: () async {
                Navigator.pop(context);
                try {
                  // Actualizar la entrega existente
                    await supabase
                      .from('entrega_correrias')
                      .update({
                        'reclamo': reclamo,
                        'fecha': DateFormat('yyyy-MM-dd').format(fechaHoy),
                      })
                      .eq('id_entrega', idEntrega);

                  if (mounted) {
                    _showSuccessMessage(idEntrega, idCodigo, fechaPrevia);
                  }
                } catch (e) {
                  if (mounted) {
                    setState(() {
                      _errorMessage = 'Error al reasignar: ${e.toString()}';
                      _isSaving = false;
                    });
                  }
                }
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF1A237E),
              ),
              child: const Text(
                'SI',
                style: TextStyle(color: Colors.white),
              ),
            ),
          ],
        ),
      );
    }
  }

  /// Muestra el mensaje de éxito
  void _showSuccessMessage(
    String idEntrega,
    String idCodigo,
    String? fechaPrevia,
  ) {
    String mensaje;
    if (fechaPrevia != null && fechaPrevia != 'Sin fecha') {
      mensaje =
          'La correría $idEntrega fue recibida por $idCodigo el $fechaPrevia, quiere reasignar la entrega.';
    } else {
      mensaje = 'La correría $idEntrega fue recibida por $idCodigo';
    }

    setState(() {
      _successMessage = mensaje;
      _isSaving = false;
    });

    // Limpiar después de 3 segundos
    Future.delayed(const Duration(seconds: 3), () {
      if (mounted) {
        _limpiar();
      }
    });
  }

  /// Limpia todos los campos
  void _limpiar() {
    setState(() {
      _correriaScannedController.clear();
      _funcionarioScannedController.clear();
      _correriaData = null;
      _funcionarioData = null;
      _errorMessage = null;
      _successMessage = null;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Entrega Correrías'),
        backgroundColor: const Color(0xFF1A237E),
        foregroundColor: Colors.white,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Mensaje de error
            if (_errorMessage != null)
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.red.shade100,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.red),
                ),
                child: Text(
                  _errorMessage!,
                  style: TextStyle(
                    color: Colors.red.shade900,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),

            // Mensaje de éxito
            if (_successMessage != null)
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.green.shade100,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.green),
                ),
                child: Text(
                  _successMessage!,
                  style: TextStyle(
                    color: Colors.green.shade900,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),

            const SizedBox(height: 24),

            // Sección: Correría Entregada
            Text(
              'Correría Entregada',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: const Color(0xFF1A237E),
                  ),
            ),
            const SizedBox(height: 12),

            // Campo de entrada para correría
            TextField(
              controller: _correriaScannedController,
              decoration: InputDecoration(
                hintText: 'Escanee o ingrese el código de correría',
                prefixIcon:
                    const Icon(Icons.qr_code_2, color: Color(0xFF1A237E)),
                suffixIcon: _correriaScannedController.text.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.clear),
                        onPressed: () {
                          _correriaScannedController.clear();
                          setState(() {
                            _correriaData = null;
                          });
                        },
                      )
                    : null,
                filled: true,
                fillColor: Colors.grey.shade100,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide: const BorderSide(color: Color(0xFF1A237E)),
                ),
              ),
              onChanged: (_) => setState(() {}),
            ),
            const SizedBox(height: 12),

            // Botón: Correría Entregada
            ElevatedButton.icon(
              onPressed: _isLoadingCorreria ? null : _abrirScannerCorreria,
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF1A237E),
                padding: const EdgeInsets.symmetric(vertical: 16),
              ),
              icon: _isLoadingCorreria
                  ? const SizedBox(
                      width: 24,
                      height: 24,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        valueColor:
                            AlwaysStoppedAnimation<Color>(Colors.white),
                      ),
                    )
                  : const Icon(Icons.barcode_reader),
              label: Text(
                _isLoadingCorreria ? 'Buscando...' : 'Correría Entregada',
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
            ),

            // Datos de correría encontrada
            if (_correriaData != null)
              Container(
                margin: const EdgeInsets.only(top: 12),
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.green.shade50,
                  border: Border.all(color: Colors.green),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Correría: ${_correriaData!['correria']}',
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                    Text(
                      'Nombre: ${_correriaData!['nombre_correria']}',
                    ),
                  ],
                ),
              ),

            const SizedBox(height: 32),

            // Sección: Funcionario que Recibe
            Text(
              'Funcionario que Recibe',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: const Color(0xFF1A237E),
                  ),
            ),
            const SizedBox(height: 12),

            // Campo de entrada para funcionario
            TextField(
              controller: _funcionarioScannedController,
              decoration: InputDecoration(
                hintText: 'Escanee o ingrese el número de cédula',
                prefixIcon:
                    const Icon(Icons.qr_code_2, color: Color(0xFF1A237E)),
                suffixIcon: _funcionarioScannedController.text.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.clear),
                        onPressed: () {
                          _funcionarioScannedController.clear();
                          setState(() {
                            _funcionarioData = null;
                          });
                        },
                      )
                    : null,
                filled: true,
                fillColor: Colors.grey.shade100,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide: const BorderSide(color: Color(0xFF1A237E)),
                ),
              ),
              onChanged: (_) => setState(() {}),
            ),
            const SizedBox(height: 12),

            // Botón: Funcionario que Recibe
            ElevatedButton.icon(
              onPressed: _isLoadingFuncionario ? null : _abrirScannerFuncionario,
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF1A237E),
                padding: const EdgeInsets.symmetric(vertical: 16),
              ),
              icon: _isLoadingFuncionario
                  ? const SizedBox(
                      width: 24,
                      height: 24,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        valueColor:
                            AlwaysStoppedAnimation<Color>(Colors.white),
                      ),
                    )
                  : const Icon(Icons.barcode_reader),
              label: Text(
                _isLoadingFuncionario ? 'Buscando...' : 'Funcionario que Recibe',
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
            ),

            // Datos de funcionario encontrado
            if (_funcionarioData != null)
              Container(
                margin: const EdgeInsets.only(top: 12),
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.green.shade50,
                  border: Border.all(color: Colors.green),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Cédula: ${_funcionarioData!['numero_cedula']}',
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                    Text(
                      'Código: ${_funcionarioData!['id_codigo']}',
                    ),
                    Text(
                      'Nombre: ${_funcionarioData!['nombre_completo']}',
                    ),
                  ],
                ),
              ),

            const SizedBox(height: 32),

            // Botones de acción
            Row(
              children: [
                // Botón Guardar
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: _isSaving || _correriaData == null || _funcionarioData == null
                        ? null
                        : _guardarEntrega,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.green,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      disabledBackgroundColor: Colors.grey,
                    ),
                    icon: _isSaving
                        ? const SizedBox(
                            width: 24,
                            height: 24,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              valueColor: AlwaysStoppedAnimation<Color>(
                                  Colors.white),
                            ),
                          )
                        : const Icon(Icons.save),
                    label: Text(
                      _isSaving ? 'Guardando...' : 'Guardar',
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 12),

                // Botón Limpiar
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: _limpiar,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.orange,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                    ),
                    icon: const Icon(Icons.clear_all),
                    label: const Text(
                      'Limpiar',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

/// Pantalla personalizada de escaneo de código de barras
class BarcodeScannerScreen extends StatefulWidget {
  final String title;

  const BarcodeScannerScreen({super.key, required this.title});

  @override
  State<BarcodeScannerScreen> createState() => _BarcodeScannerScreenState();
}

class _BarcodeScannerScreenState extends State<BarcodeScannerScreen> {
  MobileScannerController cameraController = MobileScannerController();
  bool _isProcessing = false;

  @override
  void dispose() {
    cameraController.dispose();
    super.dispose();
  }

  void _onDetect(BarcodeCapture capture) {
    if (_isProcessing) return;
    
    final List<Barcode> barcodes = capture.barcodes;
    if (barcodes.isEmpty) return;

    final barcode = barcodes.first;
    if (barcode.rawValue != null && barcode.rawValue!.isNotEmpty) {
      _isProcessing = true;
      final String valorCompleto = barcode.rawValue!;
      String valorProcesado = valorCompleto;

      // Extrae desde el dígito 13 hasta el penúltimo si hay longitud suficiente.
      if (valorCompleto.length >= 14) {
        valorProcesado = valorCompleto.substring(12, valorCompleto.length - 1);
      }

      Navigator.pop(context, valorProcesado);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.title),
        backgroundColor: const Color(0xFF1A237E),
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: const Icon(Icons.flash_on, color: Colors.white),
            onPressed: () => cameraController.toggleTorch(),
          ),
        ],
      ),
      body: Stack(
        children: [
          MobileScanner(
            controller: cameraController,
            onDetect: _onDetect,
          ),
          // Overlay con línea de escaneo
          CustomPaint(
            painter: ScannerOverlay(),
            child: Container(),
          ),
          // Instrucciones
          Positioned(
            bottom: 100,
            left: 0,
            right: 0,
            child: Container(
              padding: const EdgeInsets.all(16),
              color: Colors.black54,
              child: const Text(
                'Apunte la cámara hacia el código de barras',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
                textAlign: TextAlign.center,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Dibuja el overlay del escáner con línea central
class ScannerOverlay extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final double scanAreaWidth = size.width * 0.8;
    final double scanAreaHeight = size.height * 0.4;
    final double left = (size.width - scanAreaWidth) / 2;
    final double top = (size.height - scanAreaHeight) / 2;
    final Rect scanArea = Rect.fromLTWH(left, top, scanAreaWidth, scanAreaHeight);

    // Fondo semi-transparente
    final Paint backgroundPaint = Paint()
      ..color = Colors.black.withValues(alpha: 0.5);
    canvas.drawPath(
      Path.combine(
        PathOperation.difference,
        Path()..addRect(Rect.fromLTWH(0, 0, size.width, size.height)),
        Path()..addRect(scanArea),
      ),
      backgroundPaint,
    );

    // Bordes del área de escaneo
    final Paint borderPaint = Paint()
      ..color = const Color(0xFF1A237E)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3;

    canvas.drawRect(scanArea, borderPaint);

    // Línea de escaneo central
    final Paint linePaint = Paint()
      ..color = const Color(0xFF1A237E)
      ..strokeWidth = 2;

    canvas.drawLine(
      Offset(left, scanArea.center.dy),
      Offset(left + scanAreaWidth, scanArea.center.dy),
      linePaint,
    );

    // Esquinas decorativas
    final Paint cornerPaint = Paint()
      ..color = const Color(0xFF1A237E)
      ..strokeWidth = 5
      ..strokeCap = StrokeCap.round;

    const double cornerLength = 30;

    // Esquina superior izquierda
    canvas.drawLine(Offset(left, top), Offset(left + cornerLength, top), cornerPaint);
    canvas.drawLine(Offset(left, top), Offset(left, top + cornerLength), cornerPaint);

    // Esquina superior derecha
    canvas.drawLine(Offset(left + scanAreaWidth, top), Offset(left + scanAreaWidth - cornerLength, top), cornerPaint);
    canvas.drawLine(Offset(left + scanAreaWidth, top), Offset(left + scanAreaWidth, top + cornerLength), cornerPaint);

    // Esquina inferior izquierda
    canvas.drawLine(Offset(left, top + scanAreaHeight), Offset(left + cornerLength, top + scanAreaHeight), cornerPaint);
    canvas.drawLine(Offset(left, top + scanAreaHeight), Offset(left, top + scanAreaHeight - cornerLength), cornerPaint);

    // Esquina inferior derecha
    canvas.drawLine(Offset(left + scanAreaWidth, top + scanAreaHeight), Offset(left + scanAreaWidth - cornerLength, top + scanAreaHeight), cornerPaint);
    canvas.drawLine(Offset(left + scanAreaWidth, top + scanAreaHeight), Offset(left + scanAreaWidth, top + scanAreaHeight - cornerLength), cornerPaint);
  }

  @override
  bool shouldRepaint(CustomPainter oldDelegate) => false;
}
