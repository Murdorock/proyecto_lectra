import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:syncfusion_flutter_signaturepad/signaturepad.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:path_provider/path_provider.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';
import '../main.dart';

class QuejasScreen extends StatefulWidget {
  const QuejasScreen({super.key});

  @override
  State<QuejasScreen> createState() => _QuejasScreenState();
}

class _QuejasScreenState extends State<QuejasScreen> {
  final _fechaOcurrenciaController = TextEditingController();
  final _fechaAtencionController = TextEditingController();
  final _correriaController = TextEditingController();
  final _nombreController = TextEditingController();
  final _cedulaController = TextEditingController();
  final _direccionHechosController = TextEditingController();
  final _ciudadMunicipioController = TextEditingController();
  final _descripcionHechosController = TextEditingController();

  DateTime? _fechaOcurrencia;
  DateTime? _fechaAtencion;
  int? _ciclo;
  Uint8List? _firmaBytes;
  Uint8List? _evidenciaBytes;
  bool _generandoPdf = false;
  final ImagePicker _imagePicker = ImagePicker();

  @override
  void dispose() {
    _fechaOcurrenciaController.dispose();
    _fechaAtencionController.dispose();
    _correriaController.dispose();
    _nombreController.dispose();
    _cedulaController.dispose();
    _direccionHechosController.dispose();
    _ciudadMunicipioController.dispose();
    _descripcionHechosController.dispose();
    super.dispose();
  }

  String _formatDate(DateTime date) {
    final day = date.day.toString().padLeft(2, '0');
    final month = date.month.toString().padLeft(2, '0');
    final year = date.year.toString();
    return '$day/$month/$year';
  }

  Future<void> _pickDate({
    required TextEditingController controller,
    required DateTime? initialDate,
    required ValueChanged<DateTime> onSelected,
  }) async {
    final now = DateTime.now();
    final selected = await showDatePicker(
      context: context,
      initialDate: initialDate ?? now,
      firstDate: DateTime(2000),
      lastDate: DateTime(now.year + 5),
    );

    if (selected != null) {
      onSelected(selected);
      controller.text = _formatDate(selected);
    }
  }

  Widget _buildDateField({
    required String label,
    required IconData icon,
    required TextEditingController controller,
    required DateTime? selectedDate,
    required ValueChanged<DateTime> onSelected,
  }) {
    return InkWell(
      borderRadius: BorderRadius.circular(8),
      onTap: () => _pickDate(
        controller: controller,
        initialDate: selectedDate,
        onSelected: onSelected,
      ),
      child: AbsorbPointer(
        child: TextFormField(
          controller: controller,
          readOnly: true,
          style: const TextStyle(fontSize: 12),
          decoration: InputDecoration(
            labelText: label,
            labelStyle: const TextStyle(fontSize: 12, height: 1.2),
            floatingLabelBehavior: FloatingLabelBehavior.always,
            prefixIcon: Icon(icon, size: 20),
            suffixIcon: IconButton(
              icon: const Icon(Icons.calendar_month, size: 20),
              onPressed: () => _pickDate(
                controller: controller,
                initialDate: selectedDate,
                onSelected: onSelected,
              ),
            ),
            border: const OutlineInputBorder(),
            contentPadding: const EdgeInsets.symmetric(vertical: 12, horizontal: 12),
          ),
        ),
      ),
    );
  }

  Future<Uint8List> _imageToBytes(ui.Image image) async {
    final byteData = await image.toByteData(format: ui.ImageByteFormat.png);
    return byteData!.buffer.asUint8List();
  }

  Future<void> _openFirmaDialog() async {
    final signatureKey = GlobalKey<SfSignaturePadState>();

    await showDialog<void>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Firma'),
        content: SizedBox(
          width: double.maxFinite,
          child: Container(
            padding: const EdgeInsets.all(8),
            color: Colors.grey.shade200,
            child: SizedBox(
              height: 200,
              child: SfSignaturePad(
                key: signatureKey,
                backgroundColor: Colors.white,
                minimumStrokeWidth: 2,
                maximumStrokeWidth: 4,
              ),
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => signatureKey.currentState?.clear(),
            child: const Text('Limpiar'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancelar'),
          ),
          TextButton(
            onPressed: () async {
              final image = await signatureKey.currentState?.toImage(pixelRatio: 3.0);
              if (image == null) {
                return;
              }
              final bytes = await _imageToBytes(image);
              if (!mounted) return;
              setState(() {
                _firmaBytes = bytes;
              });
              if (mounted) {
                Navigator.pop(context);
              }
            },
            child: const Text('Guardar'),
          ),
        ],
      ),
    );
  }

  Future<void> _capturarEvidencia() async {
    final XFile? foto = await _imagePicker.pickImage(
      source: ImageSource.camera,
      imageQuality: 100,
    );

    if (foto != null) {
      final bytes = await foto.readAsBytes();
      if (mounted) {
        setState(() {
          _evidenciaBytes = bytes;
        });
        // Mostrar la foto capturada automáticamente
        if (mounted) {
          _mostrarEvidenciaCompleta();
        }
      }
    }
  }

  Future<void> _mostrarEvidenciaCompleta() async {
    if (_evidenciaBytes == null) return;

    await showDialog<void>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Evidencia Capturada'),
        content: SizedBox(
          width: double.maxFinite,
          child: SingleChildScrollView(
            child: Image.memory(
              _evidenciaBytes!,
              fit: BoxFit.contain,
            ),
          ),
        ),
        actions: [
          ElevatedButton(
            onPressed: () {
              setState(() {
                _evidenciaBytes = null;
              });
              Navigator.pop(context);
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
            ),
            child: const Text('Eliminar'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF1A237E),
              foregroundColor: Colors.white,
            ),
            child: const Text('Cerrar'),
          ),
        ],
      ),
    );
  }

  Future<pw.Document> _construirPdf() async {
    final pdf = pw.Document();
      
      // Cargar firma si existe
      pw.ImageProvider? firmaImage;
      if (_firmaBytes != null) {
        firmaImage = pw.MemoryImage(_firmaBytes!);
      }

      // Cargar evidencia si existe
      pw.ImageProvider? evidenciaImage;
      if (_evidenciaBytes != null) {
        evidenciaImage = pw.MemoryImage(_evidenciaBytes!);
      }

      pdf.addPage(
        pw.Page(
          pageFormat: PdfPageFormat.a4,
          margin: const pw.EdgeInsets.all(20),
          build: (context) {
            return pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                // Título
                pw.Container(
                  width: double.infinity,
                  padding: const pw.EdgeInsets.all(10),
                  decoration: pw.BoxDecoration(
                    border: pw.Border.all(color: PdfColors.black, width: 2),
                  ),
                  child: pw.Center(
                    child: pw.Text(
                      'PETICIONES, QUEJAS, RECLAMOS Y SOLICITUDES',
                      style: pw.TextStyle(
                        fontSize: 14,
                        fontWeight: pw.FontWeight.bold,
                      ),
                    ),
                  ),
                ),
                pw.SizedBox(height: 5),
                
                // Sección Datos
                pw.Container(
                  width: double.infinity,
                  padding: const pw.EdgeInsets.symmetric(vertical: 4, horizontal: 8),
                  decoration: pw.BoxDecoration(
                    border: pw.Border.all(color: PdfColors.black),
                    color: PdfColors.grey300,
                  ),
                  child: pw.Center(
                    child: pw.Text(
                      'Datos',
                      style: pw.TextStyle(fontSize: 11, fontWeight: pw.FontWeight.bold),
                    ),
                  ),
                ),
                
                // Tabla de datos
                pw.Table(
                  border: pw.TableBorder.all(color: PdfColors.black),
                  children: [
                    pw.TableRow(
                      children: [
                        pw.Padding(
                          padding: const pw.EdgeInsets.all(4),
                          child: pw.Text('FECHA OCURRENCIA', style: const pw.TextStyle(fontSize: 10)),
                        ),
                        pw.Padding(
                          padding: const pw.EdgeInsets.all(4),
                          child: pw.Text(_fechaOcurrenciaController.text, style: const pw.TextStyle(fontSize: 10)),
                        ),
                        pw.Padding(
                          padding: const pw.EdgeInsets.all(4),
                          child: pw.Text('FECHA ATENCIÓN', style: const pw.TextStyle(fontSize: 10)),
                        ),
                        pw.Padding(
                          padding: const pw.EdgeInsets.all(4),
                          child: pw.Text(_fechaAtencionController.text, style: const pw.TextStyle(fontSize: 10)),
                        ),
                      ],
                    ),
                    pw.TableRow(
                      children: [
                        pw.Padding(
                          padding: const pw.EdgeInsets.all(4),
                          child: pw.Text('CORRERIA', style: const pw.TextStyle(fontSize: 10)),
                        ),
                        pw.Padding(
                          padding: const pw.EdgeInsets.all(4),
                          child: pw.Text(_correriaController.text, style: const pw.TextStyle(fontSize: 10)),
                        ),
                        pw.Padding(
                          padding: const pw.EdgeInsets.all(4),
                          child: pw.Text('CICLO', style: const pw.TextStyle(fontSize: 10)),
                        ),
                        pw.Padding(
                          padding: const pw.EdgeInsets.all(4),
                          child: pw.Text(_ciclo?.toString() ?? '', style: const pw.TextStyle(fontSize: 10)),
                        ),
                      ],
                    ),
                    pw.TableRow(
                      children: [
                        pw.Padding(
                          padding: const pw.EdgeInsets.all(4),
                          child: pw.Text('DIRECCION HECHOS', style: const pw.TextStyle(fontSize: 10)),
                        ),
                        pw.Padding(
                          padding: const pw.EdgeInsets.all(4),
                          child: pw.Text(_direccionHechosController.text, style: const pw.TextStyle(fontSize: 10)),
                        ),
                        pw.Padding(
                          padding: const pw.EdgeInsets.all(4),
                          child: pw.Text('CIUDAD / MUNICIPIO', style: const pw.TextStyle(fontSize: 10)),
                        ),
                        pw.Padding(
                          padding: const pw.EdgeInsets.all(4),
                          child: pw.Text(_ciudadMunicipioController.text, style: const pw.TextStyle(fontSize: 10)),
                        ),
                      ],
                    ),
                  ],
                ),
                pw.SizedBox(height: 5),
                
                // Novedad Presentada
                pw.Container(
                  width: double.infinity,
                  padding: const pw.EdgeInsets.symmetric(vertical: 4, horizontal: 8),
                  decoration: pw.BoxDecoration(
                    border: pw.Border.all(color: PdfColors.black),
                    color: PdfColors.grey300,
                  ),
                  child: pw.Center(
                    child: pw.Text(
                      'Novedad Presentada',
                      style: pw.TextStyle(fontSize: 11, fontWeight: pw.FontWeight.bold),
                    ),
                  ),
                ),
                pw.Container(
                  width: double.infinity,
                  height: 20,
                  decoration: pw.BoxDecoration(
                    border: pw.Border.all(color: PdfColors.black),
                  ),
                  child: pw.Padding(
                    padding: const pw.EdgeInsets.all(4),
                    child: pw.Text('DAÑO OCASIONADO        |_X_| Otro ¿Cuál?', style: const pw.TextStyle(fontSize: 10)),
                  ),
                ),
                
                // Descripción de los hechos
                pw.Container(
                  width: double.infinity,
                  padding: const pw.EdgeInsets.symmetric(vertical: 4, horizontal: 8),
                  decoration: pw.BoxDecoration(
                    border: pw.Border.all(color: PdfColors.black),
                    color: PdfColors.grey300,
                  ),
                  child: pw.Center(
                    child: pw.Text(
                      'Descripción de los hechos',
                      style: pw.TextStyle(fontSize: 11, fontWeight: pw.FontWeight.bold),
                    ),
                  ),
                ),
                pw.Container(
                  width: double.infinity,
                  height: 150,
                  decoration: pw.BoxDecoration(
                    border: pw.Border.all(color: PdfColors.black),
                  ),
                  child: pw.Padding(
                    padding: const pw.EdgeInsets.all(4),
                    child: pw.Text(_descripcionHechosController.text, style: const pw.TextStyle(fontSize: 10)),
                  ),
                ),
                pw.SizedBox(height: 5),
                
                // Sección Evidencia (Foto)
                if (evidenciaImage != null) ...[
                    pw.Container(
                      width: double.infinity,
                      padding: const pw.EdgeInsets.symmetric(vertical: 4, horizontal: 8),
                      decoration: pw.BoxDecoration(
                        border: pw.Border.all(color: PdfColors.black),
                        color: PdfColors.grey300,
                      ),
                      child: pw.Center(
                        child: pw.Text(
                          'Evidencia',
                          style: pw.TextStyle(fontSize: 11, fontWeight: pw.FontWeight.bold),
                        ),
                      ),
                    ),
                    pw.Container(
                      width: double.infinity,
                      height: 200,
                      decoration: pw.BoxDecoration(
                        border: pw.Border.all(color: PdfColors.black),
                      ),
                      child: pw.Padding(
                        padding: const pw.EdgeInsets.all(8),
                        child: pw.Image(evidenciaImage, fit: pw.BoxFit.contain),
                      ),
                    ),
                    pw.SizedBox(height: 5),
                  ],

                
                // Conformidad (Firma, Nombre, Cedula)
                pw.Container(
                  width: double.infinity,
                  padding: const pw.EdgeInsets.symmetric(vertical: 4, horizontal: 8),
                  decoration: pw.BoxDecoration(
                    border: pw.Border.all(color: PdfColors.black),
                    color: PdfColors.grey300,
                  ),
                  child: pw.Center(
                    child: pw.Text(
                      'Conformidad',
                      style: pw.TextStyle(fontSize: 11, fontWeight: pw.FontWeight.bold),
                    ),
                  ),
                ),
                pw.Container(
                  width: double.infinity,
                  decoration: pw.BoxDecoration(
                    border: pw.Border.all(color: PdfColors.black),
                  ),
                  child: pw.Row(
                    crossAxisAlignment: pw.CrossAxisAlignment.start,
                    children: [
                      pw.Expanded(
                        flex: 2,
                        child: pw.Container(
                          height: 100,
                          decoration: const pw.BoxDecoration(
                            border: pw.Border(right: pw.BorderSide(color: PdfColors.black)),
                          ),
                          child: firmaImage != null
                              ? pw.Padding(
                                  padding: const pw.EdgeInsets.all(8),
                                  child: pw.Image(firmaImage, fit: pw.BoxFit.contain),
                                )
                              : pw.Center(child: pw.Text('')),
                        ),
                      ),
                      pw.Expanded(
                        flex: 1,
                        child: pw.Padding(
                          padding: const pw.EdgeInsets.all(4),
                          child: pw.Column(
                            crossAxisAlignment: pw.CrossAxisAlignment.start,
                            mainAxisAlignment: pw.MainAxisAlignment.spaceEvenly,
                            children: [
                              pw.Text('Firma', style: const pw.TextStyle(fontSize: 10)),
                              pw.Text('Nombre: ${_nombreController.text}', style: const pw.TextStyle(fontSize: 9)),
                              pw.Text('Cedula: ${_cedulaController.text}', style: const pw.TextStyle(fontSize: 9)),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            );
          },
        ),
      );

      return pdf;
  }

  Future<void> _generarPdf() async {
    // Validar campos requeridos
    if (_fechaOcurrencia == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('La fecha de ocurrencia es requerida'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    try {
      // Construir PDF
      final pdf = await _construirPdf();
      final pdfBytes = await pdf.save();

      // Mostrar previsualización
      if (!mounted) return;
      
      // Cerrar teclado
      FocusScope.of(context).unfocus();
      
      final shouldSave = await showDialog<bool>(
        context: context,
        barrierDismissible: false,
        builder: (context) => AlertDialog(
          title: const Text('Previsualización del PDF'),
          content: SizedBox(
            width: double.maxFinite,
            height: 400,
            child: SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Información del PDF:', style: TextStyle(fontWeight: FontWeight.bold)),
                  const SizedBox(height: 12),
                  Text('Fecha Ocurrencia: ${_fechaOcurrenciaController.text}'),
                  Text('Fecha Atención: ${_fechaAtencionController.text}'),
                  Text('Ciclo: ${_ciclo ?? 'N/A'}'),
                  Text('Correría: ${_correriaController.text}'),
                  Text('Dirección: ${_direccionHechosController.text}'),
                  Text('Ciudad: ${_ciudadMunicipioController.text}'),
                  const SizedBox(height: 12),
                  const Text('Descripción de los hechos:', style: TextStyle(fontWeight: FontWeight.bold)),
                  Text(_descripcionHechosController.text),
                  const SizedBox(height: 12),
                  Text('Nombre: ${_nombreController.text}'),
                  Text('Cédula: ${_cedulaController.text}'),
                  if (_firmaBytes != null) ...
                    [
                      const SizedBox(height: 12),
                      const Text('Firma: Sí', style: TextStyle(fontWeight: FontWeight.bold)),
                    ],
                  if (_evidenciaBytes != null) ...
                    [
                      const SizedBox(height: 12),
                      const Text('Evidencia:'),
                      const SizedBox(height: 8),
                      Image.memory(
                        _evidenciaBytes!,
                        height: 150,
                        fit: BoxFit.contain,
                      ),
                    ],
                ],
              ),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('Cancelar'),
            ),
            ElevatedButton(
              onPressed: () => Navigator.pop(context, true),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF1A237E),
                foregroundColor: Colors.white,
              ),
              child: const Text('Guardar PDF'),
            ),
          ],
        ),
      ) ?? false;

      if (!shouldSave) return;

      // Cerrar teclado
      FocusScope.of(context).unfocus();

      setState(() {
        _generandoPdf = true;
      });

      // Subir PDF a Supabase Storage
      final timestamp = DateTime.now().millisecondsSinceEpoch;
      final fileName = 'queja_${timestamp}.pdf';
      final filePath = 'quejas/$fileName';

      await supabase.storage.from('cold').uploadBinary(
        filePath,
        pdfBytes,
        fileOptions: FileOptions(
          contentType: 'application/pdf',
          upsert: true,
        ),
      );

      final pdfUrl = supabase.storage.from('cold').getPublicUrl(filePath);

      // Subir firma si existe
      String? firmaUrl;
      if (_firmaBytes != null) {
        final firmaFileName = 'firma_${timestamp}.png';
        final firmaPath = 'quejas/$firmaFileName';
        
        await supabase.storage.from('cold').uploadBinary(
          firmaPath,
          _firmaBytes!,
          fileOptions: FileOptions(
            contentType: 'image/png',
            upsert: true,
          ),
        );
        
        firmaUrl = supabase.storage.from('cold').getPublicUrl(firmaPath);
      }

      // Subir evidencia si existe
      String? evidenciaUrl;
      if (_evidenciaBytes != null) {
        final evidenciaFileName = 'evidencia_${timestamp}.png';
        final evidenciaPath = 'quejas/$evidenciaFileName';
        
        await supabase.storage.from('cold').uploadBinary(
          evidenciaPath,
          _evidenciaBytes!,
          fileOptions: FileOptions(
            contentType: 'image/png',
            upsert: true,
          ),
        );
        
        evidenciaUrl = supabase.storage.from('cold').getPublicUrl(evidenciaPath);
      }

      // Guardar en la base de datos
      await supabase.from('quejas').insert({
        'fecha_ocurrencia': _fechaOcurrencia!.toIso8601String(),
        'fecha_atencion': _fechaAtencion?.toIso8601String(),
        'ciclo': _ciclo,
        'correria': _correriaController.text.isNotEmpty ? int.tryParse(_correriaController.text) : null,
        'direccion_hechos': _direccionHechosController.text,
        'ciudad_municipio': _ciudadMunicipioController.text,
        'descripcion_hechos': _descripcionHechosController.text,
        'nombre': _nombreController.text,
        'cedula': _cedulaController.text,
        'firma_url': firmaUrl,
        'evidencia': evidenciaUrl,
        'pdf': pdfUrl,
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('PDF generado y guardado exitosamente'),
            backgroundColor: Colors.green,
          ),
        );
        
        // Limpiar formulario
        setState(() {
          _fechaOcurrenciaController.clear();
          _fechaAtencionController.clear();
          _correriaController.clear();
          _direccionHechosController.clear();
          _ciudadMunicipioController.clear();
          _descripcionHechosController.clear();
          _nombreController.clear();
          _cedulaController.clear();
          _fechaOcurrencia = null;
          _fechaAtencion = null;
          _ciclo = null;
          _firmaBytes = null;
          _evidenciaBytes = null;
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error al generar PDF: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _generandoPdf = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('QUEJAS'),
        backgroundColor: const Color(0xFF1A237E),
        foregroundColor: Colors.white,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                Expanded(
                  child: _buildDateField(
                    label: 'FECHA\nOCURRENCIA',
                    icon: Icons.event,
                    controller: _fechaOcurrenciaController,
                    selectedDate: _fechaOcurrencia,
                    onSelected: (date) {
                      setState(() {
                        _fechaOcurrencia = date;
                      });
                    },
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _buildDateField(
                    label: 'FECHA\nATENCION',
                    icon: Icons.event_available,
                    controller: _fechaAtencionController,
                    selectedDate: _fechaAtencion,
                    onSelected: (date) {
                      setState(() {
                        _fechaAtencion = date;
                      });
                    },
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: DropdownButtonFormField<int>(
                    value: _ciclo,
                    items: List.generate(
                      20,
                      (index) => DropdownMenuItem(
                        value: index + 1,
                        child: Text('${index + 1}'),
                      ),
                    ),
                    onChanged: (value) {
                      setState(() {
                        _ciclo = value;
                      });
                    },
                    decoration: const InputDecoration(
                      labelText: 'CICLO',
                      prefixIcon: Icon(Icons.format_list_numbered),
                      border: OutlineInputBorder(),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: TextFormField(
                    controller: _correriaController,
                    keyboardType: TextInputType.number,
                    inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                    decoration: const InputDecoration(
                      labelText: 'CORRERIA',
                      prefixIcon: Icon(Icons.route),
                      border: OutlineInputBorder(),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _direccionHechosController,
              decoration: const InputDecoration(
                labelText: 'DIRECCION HECHOS',
                prefixIcon: Icon(Icons.location_on),
                border: OutlineInputBorder(),
              ),
              textCapitalization: TextCapitalization.characters,
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _ciudadMunicipioController,
              decoration: const InputDecoration(
                labelText: 'CIUDAD/MUNICIPIO',
                prefixIcon: Icon(Icons.location_city),
                border: OutlineInputBorder(),
              ),
              textCapitalization: TextCapitalization.characters,
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _descripcionHechosController,
              decoration: const InputDecoration(
                labelText: 'DESCRIPCION DE LOS HECHOS',
                prefixIcon: Icon(Icons.description),
                border: OutlineInputBorder(),
              ),
              textCapitalization: TextCapitalization.sentences,
              maxLines: 3,
            ),
            const SizedBox(height: 16),
            Card(
              elevation: 2,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              child: Padding(
                padding: const EdgeInsets.all(12.0),
                child: Column(
                  children: [
                    TextFormField(
                      controller: _nombreController,
                      decoration: const InputDecoration(
                        labelText: 'NOMBRE',
                        prefixIcon: Icon(Icons.person),
                        border: OutlineInputBorder(),
                      ),
                      textCapitalization: TextCapitalization.words,
                    ),
                    const SizedBox(height: 12),
                    TextFormField(
                      controller: _cedulaController,
                      keyboardType: TextInputType.number,
                      inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                      decoration: const InputDecoration(
                        labelText: 'CEDULA',
                        prefixIcon: Icon(Icons.badge),
                        border: OutlineInputBorder(),
                      ),
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        Expanded(
                          child: ElevatedButton.icon(
                            onPressed: _openFirmaDialog,
                            icon: const Icon(Icons.draw),
                            label: const Text('FIRMA'),
                          ),
                        ),
                        const SizedBox(width: 12),
                        if (_firmaBytes != null)
                          Container(
                            width: 100,
                            height: 50,
                            decoration: BoxDecoration(
                              border: Border.all(color: Colors.grey.shade400),
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: Image.memory(
                              _firmaBytes!,
                              fit: BoxFit.contain,
                            ),
                          )
                        else
                          Text(
                            'Sin firma',
                            style: TextStyle(color: Colors.grey.shade600),
                          ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        Expanded(
                          child: ElevatedButton.icon(
                            onPressed: _capturarEvidencia,
                            icon: const Icon(Icons.camera_alt),
                            label: const Text('EVIDENCIA'),
                          ),
                        ),
                        const SizedBox(width: 12),
                        if (_evidenciaBytes != null)
                          InkWell(
                            onTap: _mostrarEvidenciaCompleta,
                            borderRadius: BorderRadius.circular(6),
                            child: Container(
                              width: 100,
                              height: 50,
                              decoration: BoxDecoration(
                                border: Border.all(color: Colors.grey.shade400),
                                borderRadius: BorderRadius.circular(6),
                              ),
                              child: Image.memory(
                                _evidenciaBytes!,
                                fit: BoxFit.cover,
                              ),
                            ),
                          )
                        else
                          Text(
                            'Sin evidencia',
                            style: TextStyle(color: Colors.grey.shade600),
                          ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 24),
            SizedBox(
              height: 50,
              child: ElevatedButton.icon(
                onPressed: _generandoPdf ? null : _generarPdf,
                icon: _generandoPdf
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
                  _generandoPdf ? 'Generando...' : 'Generar PDF',
                  style: const TextStyle(fontSize: 16),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF1A237E),
                  foregroundColor: Colors.white,
                ),
              ),
            ),
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }
}
