import 'package:flutter/material.dart';
import 'dart:typed_data';
import 'dart:ui' as ui;
import 'package:syncfusion_flutter_signaturepad/signaturepad.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import '../main.dart';
import '../services/user_session.dart';

class LlegadasTardeScreen extends StatefulWidget {
  final String? codigoInicial;
  final String? nombreInicial;
  final TimeOfDay? horaInicial;

  const LlegadasTardeScreen({
    super.key,
    this.codigoInicial,
    this.nombreInicial,
    this.horaInicial,
  });

  @override
  State<LlegadasTardeScreen> createState() => _LlegadasTardeScreenState();
}

class _LlegadasTardeScreenState extends State<LlegadasTardeScreen> {
  final TextEditingController _codigoController = TextEditingController();
  final TextEditingController _motivoController = TextEditingController();
  
  List<Map<String, dynamic>> _personal = [];
  String? _codigoSeleccionado;
  String? _nombreSeleccionado;
  TimeOfDay? _horaSeleccionada;
  Uint8List? _firmaFuncionario;
  Uint8List? _firmaSupervisor;
  bool _isLoading = true;
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    _loadPersonal();
    
    // Establecer valores iniciales si se pasaron parámetros
    if (widget.codigoInicial != null && widget.nombreInicial != null) {
      _codigoSeleccionado = widget.codigoInicial;
      _nombreSeleccionado = widget.nombreInicial;
      _codigoController.text = '${widget.codigoInicial} - ${widget.nombreInicial}';
    }
    
    if (widget.horaInicial != null) {
      _horaSeleccionada = widget.horaInicial;
    }
  }

  @override
  void dispose() {
    _codigoController.dispose();
    _motivoController.dispose();
    super.dispose();
  }

  Future<void> _loadPersonal() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final data = await supabase
          .from('personal')
          .select('id_codigo, nombre_completo')
          .order('id_codigo', ascending: true);

      if (mounted) {
        setState(() {
          _personal = List<Map<String, dynamic>>.from(data);
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error al cargar personal: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  void _limpiarFormulario() {
    // Forzar limpieza del campo de autocompletado
    _codigoController.clear();
    
    setState(() {
      _motivoController.clear();
      _codigoSeleccionado = null;
      _nombreSeleccionado = null;
      _horaSeleccionada = null;
      _firmaFuncionario = null;
      _firmaSupervisor = null;
    });

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Formulario limpiado'),
        backgroundColor: Colors.green,
        duration: Duration(seconds: 2),
      ),
    );
  }

  Future<void> _seleccionarHora() async {
    final TimeOfDay? picked = await showTimePicker(
      context: context,
      initialTime: _horaSeleccionada ?? TimeOfDay.now(),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: const ColorScheme.light(
              primary: Color(0xFF1A237E),
              onPrimary: Colors.white,
              onSurface: Colors.black,
            ),
          ),
          child: child!,
        );
      },
    );

    if (picked != null) {
      setState(() {
        _horaSeleccionada = picked;
      });
    }
  }

  void _mostrarPanelFirma(bool esFuncionario) {
    final GlobalKey<SfSignaturePadState> signatureKey = GlobalKey();

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return Dialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          child: Container(
            padding: const EdgeInsets.all(16),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  'Firma ${esFuncionario ? 'del Funcionario' : 'del Supervisor'}',
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF1A237E),
                  ),
                ),
                const SizedBox(height: 16),
                Container(
                  height: 250,
                  decoration: BoxDecoration(
                    border: Border.all(
                      color: Colors.grey.shade300,
                      width: 2,
                    ),
                    borderRadius: BorderRadius.circular(8),
                    color: Colors.white,
                  ),
                  child: SfSignaturePad(
                    key: signatureKey,
                    backgroundColor: Colors.white,
                    strokeColor: Colors.black,
                    minimumStrokeWidth: 1.5,
                    maximumStrokeWidth: 3.0,
                  ),
                ),
                const SizedBox(height: 16),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    TextButton.icon(
                      onPressed: () {
                        signatureKey.currentState?.clear();
                      },
                      icon: const Icon(Icons.clear),
                      label: const Text('Limpiar'),
                      style: TextButton.styleFrom(
                        foregroundColor: Colors.red,
                      ),
                    ),
                    ElevatedButton.icon(
                      onPressed: () async {
                        final data = await signatureKey.currentState?.toImage();
                        if (data != null) {
                          final bytes = await data.toByteData(
                            format: ui.ImageByteFormat.png,
                          );
                          if (bytes != null) {
                            setState(() {
                              if (esFuncionario) {
                                _firmaFuncionario = bytes.buffer.asUint8List();
                              } else {
                                _firmaSupervisor = bytes.buffer.asUint8List();
                              }
                            });
                            if (mounted) {
                              Navigator.pop(context);
                            }
                          }
                        }
                      },
                      icon: const Icon(Icons.check),
                      label: const Text('Guardar'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF1A237E),
                        foregroundColor: Colors.white,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Future<Uint8List> _generarPDF({
    required String codigo,
    required String nombre,
    required String fecha,
    required String hora,
    required String motivo,
    required String supervisor,
    required String cedulaFuncionario,
    required String cedulaSupervisor,
    required Uint8List firmaFuncionario,
    required Uint8List firmaSupervisor,
  }) async {
    final pdf = pw.Document();

    // Formatear fecha para mostrar en el documento
    final partesFecha = fecha.split('-');
    final fechaFormateada = '${partesFecha[0]}/${partesFecha[1]}/${partesFecha[2]}';

    pdf.addPage(
      pw.Page(
        pageFormat: PdfPageFormat.letter,
        margin: const pw.EdgeInsets.all(40),
        build: (pw.Context context) {
          return pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              // Logo y fecha (esquina superior derecha)
              pw.Row(
                mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                children: [
                  pw.SizedBox(width: 100),
                  pw.Column(
                    crossAxisAlignment: pw.CrossAxisAlignment.end,
                    children: [
                      pw.Text(
                        'UTIC',
                        style: pw.TextStyle(
                          fontSize: 32,
                          fontWeight: pw.FontWeight.bold,
                          color: PdfColors.grey700,
                        ),
                      ),
                      pw.Text(
                        'INTEGRAL',
                        style: pw.TextStyle(
                          fontSize: 10,
                          color: PdfColors.grey600,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
              pw.SizedBox(height: 20),

              // Ubicación y fecha
              pw.Text(
                'Medellín $fechaFormateada',
                style: const pw.TextStyle(fontSize: 11),
              ),
              pw.SizedBox(height: 30),

              // Destinatario
              pw.Text(
                'Señor (a)',
                style: const pw.TextStyle(fontSize: 11),
              ),
              pw.Text(
                nombre.toUpperCase(),
                style: pw.TextStyle(
                  fontSize: 11,
                  fontWeight: pw.FontWeight.bold,
                ),
              ),
              pw.SizedBox(height: 20),

              // Asunto
              pw.Text(
                'Asunto: Notificación de llegada tarde',
                style: const pw.TextStyle(fontSize: 11),
              ),
              pw.SizedBox(height: 20),

              // Cuerpo del documento
              pw.Text(
                'Por medio de la presente se le informa que el día ${partesFecha[0]} del mes de ${_obtenerNombreMes(int.parse(partesFecha[1]))} del presente año, '
                'usted ha incurrido en una falta al llegar tarde a la empresa o al punto de encuentro '
                'estipulado por el supervisor $supervisor',
                style: const pw.TextStyle(fontSize: 11),
                textAlign: pw.TextAlign.justify,
              ),
              pw.SizedBox(height: 15),

              pw.Text(
                'Se le recuerda al Sr(a).',
                style: const pw.TextStyle(fontSize: 11),
              ),
              pw.SizedBox(height: 10),

              // Información de llegada
              pw.Padding(
                padding: const pw.EdgeInsets.only(left: 40),
                child: pw.Column(
                  crossAxisAlignment: pw.CrossAxisAlignment.start,
                  children: [
                    pw.Text(
                      'Hora de llegada programada: 06:30:00 a. m.',
                      style: const pw.TextStyle(fontSize: 11),
                    ),
                    pw.Text(
                      'Hora de llegada real: $hora:00',
                      style: const pw.TextStyle(fontSize: 11),
                    ),
                    pw.Text(
                      'Motivo de la llegada tarde: $motivo',
                      style: const pw.TextStyle(fontSize: 11),
                    ),
                  ],
                ),
              ),
              pw.SizedBox(height: 15),

              pw.Text(
                'Se le recuerda que la puntualidad es un requisito fundamental en nuestra empresa y '
                'que cualquier falta en este sentido será objeto de seguimiento y corrección.',
                style: const pw.TextStyle(fontSize: 11),
                textAlign: pw.TextAlign.justify,
              ),
              pw.SizedBox(height: 10),

              pw.Text(
                'Se le pide que tome medidas para evitar futuras llegadas tardes y que informe al '
                'supervisor sobre cualquier circunstancia que pueda afectar su puntualidad.',
                style: const pw.TextStyle(fontSize: 11),
                textAlign: pw.TextAlign.justify,
              ),
              pw.SizedBox(height: 20),

              pw.Text(
                'Atentamente,',
                style: const pw.TextStyle(fontSize: 11),
              ),
              pw.SizedBox(height: 40),

              // Firmas
              pw.Row(
                mainAxisAlignment: pw.MainAxisAlignment.spaceAround,
                children: [
                  // Firma Supervisor
                  pw.Column(
                    children: [
                      pw.Container(
                        width: 180,
                        height: 80,
                        child: pw.Image(
                          pw.MemoryImage(firmaSupervisor),
                          fit: pw.BoxFit.contain,
                        ),
                      ),
                      pw.Container(
                        width: 180,
                        decoration: const pw.BoxDecoration(
                          border: pw.Border(
                            top: pw.BorderSide(width: 1),
                          ),
                        ),
                        padding: const pw.EdgeInsets.only(top: 5),
                        child: pw.Column(
                          children: [
                            pw.Text(
                              supervisor.toUpperCase(),
                              style: pw.TextStyle(
                                fontSize: 9,
                                fontWeight: pw.FontWeight.bold,
                              ),
                              textAlign: pw.TextAlign.center,
                            ),
                            pw.Text(
                              'C.C. $cedulaSupervisor',
                              style: const pw.TextStyle(fontSize: 8),
                              textAlign: pw.TextAlign.center,
                            ),
                            pw.Text(
                              'SUPERVISOR',
                              style: const pw.TextStyle(fontSize: 8),
                              textAlign: pw.TextAlign.center,
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  // Firma Funcionario
                  pw.Column(
                    children: [
                      pw.Container(
                        width: 180,
                        height: 80,
                        child: pw.Image(
                          pw.MemoryImage(firmaFuncionario),
                          fit: pw.BoxFit.contain,
                        ),
                      ),
                      pw.Container(
                        width: 180,
                        decoration: const pw.BoxDecoration(
                          border: pw.Border(
                            top: pw.BorderSide(width: 1),
                          ),
                        ),
                        padding: const pw.EdgeInsets.only(top: 5),
                        child: pw.Column(
                          children: [
                            pw.Text(
                              nombre.toUpperCase(),
                              style: pw.TextStyle(
                                fontSize: 9,
                                fontWeight: pw.FontWeight.bold,
                              ),
                              textAlign: pw.TextAlign.center,
                            ),
                            pw.Text(
                              'C.C. $cedulaFuncionario',
                              style: const pw.TextStyle(fontSize: 8),
                              textAlign: pw.TextAlign.center,
                            ),
                            pw.Text(
                              codigo,
                              style: const pw.TextStyle(fontSize: 8),
                              textAlign: pw.TextAlign.center,
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ],
          );
        },
      ),
    );

    return pdf.save();
  }

  String _obtenerNombreMes(int mes) {
    const meses = [
      'enero', 'febrero', 'marzo', 'abril', 'mayo', 'junio',
      'julio', 'agosto', 'septiembre', 'octubre', 'noviembre', 'diciembre'
    ];
    return meses[mes - 1];
  }

  Future<void> _guardar() async {
    // Validaciones
    if (_codigoSeleccionado == null || _nombreSeleccionado == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Debe seleccionar un código de funcionario'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    if (_horaSeleccionada == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Debe seleccionar la hora de llegada'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    if (_motivoController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Debe escribir el motivo de la llegada tarde'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    if (_firmaFuncionario == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Debe capturar la firma del funcionario'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    if (_firmaSupervisor == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Debe capturar la firma del supervisor'),
          backgroundColor: Colors.orange,
        ),
      );
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
      
      // Obtener el código del supervisor logueado
      final codigoSupAux = UserSession().codigoSupAux;

      if (codigoSupAux == null || codigoSupAux.isEmpty) {
        throw Exception('No se pudo obtener el código del supervisor');
      }

      // Obtener el nombre completo del supervisor desde la tabla perfiles
      final perfilSupervisorData = await supabase
          .from('perfiles')
          .select('nombre_completo')
          .eq('codigo_sup_aux', codigoSupAux)
          .maybeSingle();

      final nombreSupervisor = perfilSupervisorData?['nombre_completo']?.toString() ?? codigoSupAux;

      // Obtener la cédula del funcionario desde la tabla personal
      final personalFuncionarioData = await supabase
          .from('personal')
          .select('numero_cedula')
          .eq('id_codigo', _codigoSeleccionado!)
          .maybeSingle();

      final cedulaFuncionario = personalFuncionarioData?['numero_cedula']?.toString() ?? '';

      // Obtener la cédula del supervisor desde la tabla personal
      final personalSupervisorData = await supabase
          .from('personal')
          .select('numero_cedula')
          .eq('id_codigo', codigoSupAux)
          .maybeSingle();

      final cedulaSupervisor = personalSupervisorData?['numero_cedula']?.toString() ?? '';

      // Obtener la fecha actual
      final now = DateTime.now();
      
      // Formato para la base de datos (YYYY-MM-DD)
      final fechaDB = '${now.year}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}';
      
      // Formato para mostrar en el PDF (DD-MM-YYYY)
      final fechaPDF = '${now.day.toString().padLeft(2, '0')}-${now.month.toString().padLeft(2, '0')}-${now.year}';

      // Formatear la hora seleccionada con segundos (HH:MM:SS)
      final horaDB = '${_horaSeleccionada!.hour.toString().padLeft(2, '0')}:${_horaSeleccionada!.minute.toString().padLeft(2, '0')}:00';
      
      // Hora para el PDF (HH:MM)
      final horaPDFDisplay = '${_horaSeleccionada!.hour.toString().padLeft(2, '0')}:${_horaSeleccionada!.minute.toString().padLeft(2, '0')}';

      // Generar el PDF
      final pdfBytes = await _generarPDF(
        codigo: _codigoSeleccionado!,
        nombre: _nombreSeleccionado!,
        fecha: fechaPDF,
        hora: horaPDFDisplay,
        motivo: _motivoController.text,
        supervisor: nombreSupervisor,
        cedulaFuncionario: cedulaFuncionario,
        cedulaSupervisor: cedulaSupervisor,
        firmaFuncionario: _firmaFuncionario!,
        firmaSupervisor: _firmaSupervisor!,
      );

      // Crear nombre del archivo: CEDULA_CODIGO_DDMMYYYY_HHMM.pdf
      final fechaNombreArchivo = '${now.day.toString().padLeft(2, '0')}${now.month.toString().padLeft(2, '0')}${now.year}';
      final horaNombreArchivo = '${_horaSeleccionada!.hour.toString().padLeft(2, '0')}${_horaSeleccionada!.minute.toString().padLeft(2, '0')}';
      final nombreArchivo = '${cedulaFuncionario}_${_codigoSeleccionado}_${fechaNombreArchivo}_$horaNombreArchivo.pdf';

      // Ruta en el storage: llegadas_tarde/CODIGO_LECTOR/nombre_archivo.pdf
      final rutaStorage = 'llegadas_tarde/$_codigoSeleccionado/$nombreArchivo';

      // Subir PDF al bucket cold - si ya existe, lo sobrescribe con upsert
      try {
        await supabase.storage
            .from('cold')
            .uploadBinary(
              rutaStorage, 
              pdfBytes,
            );
      } catch (e) {
        // Si el archivo ya existe, intentar actualizarlo
        await supabase.storage
            .from('cold')
            .updateBinary(
              rutaStorage, 
              pdfBytes,
            );
      }

      // Obtener URL pública del PDF
      final urlPDF = supabase.storage
          .from('cold')
          .getPublicUrl(rutaStorage);

      // Guardar en la tabla llegadas_tarde
      await supabase.from('llegadas_tarde').insert({
        'codigo': _codigoSeleccionado,
        'nombre': _nombreSeleccionado,
        'fecha': fechaDB,
        'hora': horaDB,
        'motivo': _motivoController.text,
        'supervisor': codigoSupAux,
        'pdf': urlPDF,
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Registro y PDF guardados exitosamente'),
            backgroundColor: Colors.green,
            duration: Duration(seconds: 3),
          ),
        );

        // Limpiar el formulario
        _codigoController.clear();
        _motivoController.clear();
        
        setState(() {
          _codigoSeleccionado = null;
          _nombreSeleccionado = null;
          _horaSeleccionada = null;
          _firmaFuncionario = null;
          _firmaSupervisor = null;
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error al guardar: ${e.toString()}'),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 4),
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Llegadas Tarde'),
        backgroundColor: const Color(0xFF1A237E),
        foregroundColor: Colors.white,
      ),
      body: _isLoading
          ? const Center(
              child: CircularProgressIndicator(
                valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF1A237E)),
              ),
            )
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Código Funcionario (Autocompletado)
                  _buildSectionTitle('Código Funcionario'),
                  Autocomplete<Map<String, dynamic>>(
                    optionsBuilder: (TextEditingValue textEditingValue) {
                      if (textEditingValue.text.isEmpty) {
                        return const Iterable<Map<String, dynamic>>.empty();
                      }
                      return _personal.where((p) {
                        final codigo = p['id_codigo']?.toString().toLowerCase() ?? '';
                        final nombre = p['nombre_completo']?.toString().toLowerCase() ?? '';
                        final search = textEditingValue.text.toLowerCase();
                        return codigo.contains(search) || nombre.contains(search);
                      });
                    },
                    displayStringForOption: (Map<String, dynamic> option) {
                      return '${option['id_codigo']} - ${option['nombre_completo']}';
                    },
                    onSelected: (Map<String, dynamic> selection) {
                      setState(() {
                        _codigoSeleccionado = selection['id_codigo']?.toString();
                        _nombreSeleccionado = selection['nombre_completo']?.toString();
                      });
                    },
                    fieldViewBuilder: (context, controller, focusNode, onEditingComplete) {
                      // Mantener sincronización y mostrar el valor seleccionado
                      if (_codigoSeleccionado != null && _nombreSeleccionado != null) {
                        final textoCompleto = '$_codigoSeleccionado - $_nombreSeleccionado';
                        if (controller.text != textoCompleto) {
                          controller.text = textoCompleto;
                        }
                      } else if (_codigoController.text.isEmpty && controller.text.isNotEmpty) {
                        controller.clear();
                      }
                      return TextField(
                        controller: controller,
                        focusNode: focusNode,
                        decoration: InputDecoration(
                          hintText: 'Buscar por código o nombre...',
                          prefixIcon: const Icon(
                            Icons.person_search,
                            color: Color(0xFF1A237E),
                          ),
                          suffixIcon: _codigoSeleccionado != null
                              ? Icon(
                                  Icons.check_circle,
                                  color: Colors.green.shade600,
                                )
                              : null,
                          filled: true,
                          fillColor: Colors.grey.shade100,
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          enabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: BorderSide(
                              color: _codigoSeleccionado != null
                                  ? Colors.green
                                  : Colors.grey.shade300,
                              width: _codigoSeleccionado != null ? 2 : 1,
                            ),
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: const BorderSide(
                              color: Color(0xFF1A237E),
                              width: 2,
                            ),
                          ),
                        ),
                      );
                    },
                    optionsViewBuilder: (context, onSelected, options) {
                      return Align(
                        alignment: Alignment.topLeft,
                        child: Material(
                          elevation: 4,
                          borderRadius: BorderRadius.circular(12),
                          child: Container(
                            constraints: const BoxConstraints(maxHeight: 200),
                            width: MediaQuery.of(context).size.width - 32,
                            child: ListView.builder(
                              padding: EdgeInsets.zero,
                              shrinkWrap: true,
                              itemCount: options.length,
                              itemBuilder: (context, index) {
                                final option = options.elementAt(index);
                                return ListTile(
                                  title: Text(
                                    option['id_codigo']?.toString() ?? '',
                                    style: const TextStyle(
                                      fontWeight: FontWeight.bold,
                                      color: Color(0xFF1A237E),
                                    ),
                                  ),
                                  subtitle: Text(
                                    option['nombre_completo']?.toString() ?? '',
                                  ),
                                  onTap: () {
                                    onSelected(option);
                                  },
                                );
                              },
                            ),
                          ),
                        ),
                      );
                    },
                  ),
                  const SizedBox(height: 24),

                  // Hora
                  _buildSectionTitle('Hora de Llegada'),
                  InkWell(
                    onTap: _seleccionarHora,
                    child: Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Colors.grey.shade100,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: _horaSeleccionada != null
                              ? Colors.green
                              : Colors.grey.shade300,
                          width: _horaSeleccionada != null ? 2 : 1,
                        ),
                      ),
                      child: Row(
                        children: [
                          const Icon(
                            Icons.access_time,
                            color: Color(0xFF1A237E),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Text(
                              _horaSeleccionada != null
                                  ? _horaSeleccionada!.format(context)
                                  : 'Seleccionar hora...',
                              style: TextStyle(
                                fontSize: 16,
                                color: _horaSeleccionada != null
                                    ? Colors.black87
                                    : Colors.grey.shade600,
                              ),
                            ),
                          ),
                          if (_horaSeleccionada != null)
                            Icon(
                              Icons.check_circle,
                              color: Colors.green.shade600,
                            ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),

                  // Motivo Llegada Tarde
                  _buildSectionTitle('Motivo de Llegada Tarde'),
                  TextField(
                    controller: _motivoController,
                    maxLines: 4,
                    decoration: InputDecoration(
                      hintText: 'Describa el motivo de la llegada tarde...',
                      filled: true,
                      fillColor: Colors.grey.shade100,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide(
                          color: Colors.grey.shade300,
                        ),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: const BorderSide(
                          color: Color(0xFF1A237E),
                          width: 2,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),

                  // Firma Funcionario
                  _buildSectionTitle('Firma del Funcionario'),
                  _buildFirmaCard(
                    titulo: 'Firma del Funcionario',
                    firma: _firmaFuncionario,
                    onCapturar: () => _mostrarPanelFirma(true),
                    onLimpiar: () {
                      setState(() {
                        _firmaFuncionario = null;
                      });
                    },
                  ),
                  const SizedBox(height: 24),

                  // Firma Supervisor
                  _buildSectionTitle('Firma del Supervisor'),
                  _buildFirmaCard(
                    titulo: 'Firma del Supervisor',
                    firma: _firmaSupervisor,
                    onCapturar: () => _mostrarPanelFirma(false),
                    onLimpiar: () {
                      setState(() {
                        _firmaSupervisor = null;
                      });
                    },
                  ),
                  const SizedBox(height: 32),

                  // Botones Guardar y Limpiar
                  Row(
                    children: [
                      // Botón Limpiar
                      Expanded(
                        flex: 2,
                        child: OutlinedButton.icon(
                          onPressed: _isSaving ? null : _limpiarFormulario,
                          icon: const Icon(Icons.clear_all),
                          label: const Text(
                            'LIMPIAR',
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 16,
                            ),
                          ),
                          style: OutlinedButton.styleFrom(
                            foregroundColor: const Color(0xFF1A237E),
                            side: const BorderSide(
                              color: Color(0xFF1A237E),
                              width: 2,
                            ),
                            padding: const EdgeInsets.symmetric(vertical: 16),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 16),
                      // Botón Guardar
                      Expanded(
                        flex: 3,
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
                            _isSaving ? 'GUARDANDO...' : 'GUARDAR',
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
                ],
              ),
            ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Text(
        title,
        style: const TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.bold,
          color: Color(0xFF1A237E),
        ),
      ),
    );
  }

  Widget _buildFirmaCard({
    required String titulo,
    required Uint8List? firma,
    required VoidCallback onCapturar,
    required VoidCallback onLimpiar,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        border: Border.all(
          color: firma != null ? Colors.green : Colors.grey.shade300,
          width: firma != null ? 2 : 1,
        ),
        borderRadius: BorderRadius.circular(12),
        color: Colors.grey.shade50,
      ),
      child: Column(
        children: [
          if (firma != null) ...[
            Container(
              height: 150,
              width: double.infinity,
              decoration: BoxDecoration(
                border: Border.all(color: Colors.grey.shade300),
                borderRadius: BorderRadius.circular(8),
                color: Colors.white,
              ),
              child: Image.memory(
                firma,
                fit: BoxFit.contain,
              ),
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: onCapturar,
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
                    onPressed: onLimpiar,
                    icon: const Icon(Icons.delete),
                    label: const Text('Limpiar'),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: Colors.red,
                    ),
                  ),
                ),
              ],
            ),
          ] else
            ElevatedButton.icon(
              onPressed: onCapturar,
              icon: const Icon(Icons.draw),
              label: const Text('CAPTURAR FIRMA'),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF1A237E),
                foregroundColor: Colors.white,
                minimumSize: const Size(double.infinity, 48),
              ),
            ),
        ],
      ),
    );
  }
}
