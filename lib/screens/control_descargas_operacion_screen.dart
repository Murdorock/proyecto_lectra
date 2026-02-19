import 'package:flutter/material.dart';
import 'dart:ui' as ui;
import 'package:share_plus/share_plus.dart';
import 'package:flutter/rendering.dart';
import '../main.dart';

class ControlDescargasOperacionScreen extends StatefulWidget {
  const ControlDescargasOperacionScreen({super.key});

  @override
  State<ControlDescargasOperacionScreen> createState() => _ControlDescargasOperacionScreenState();
}

class _ControlDescargasOperacionScreenState extends State<ControlDescargasOperacionScreen> {
  final TextEditingController _correriaController = TextEditingController();
  final TextEditingController _codigoController = TextEditingController();
  final TextEditingController _supervisorController = TextEditingController();
  bool _pendientesFiltro = false;
  final GlobalKey _tableKey = GlobalKey();
  bool _isLoading = false;
  String? _errorMessage;
  List<Map<String, dynamic>> _resultados = [];

  Future<void> _buscar() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
      _resultados = [];
    });
    try {
      var query = supabase.from('control_descargas').select('id_correria, codigo, supervisor, totales, pendientes, descargadas');
      if (_correriaController.text.isNotEmpty) {
        query = query.eq('id_correria', _correriaController.text);
      }
      if (_codigoController.text.isNotEmpty) {
        query = query.eq('codigo', _codigoController.text);
      }
      if (_supervisorController.text.isNotEmpty) {
        query = query.eq('supervisor', _supervisorController.text);
      }
      if (_pendientesFiltro) {
        query = query.gt('pendientes', 0);
      }
      final data = await query.order('supervisor', ascending: true);
      setState(() {
        _resultados = List<Map<String, dynamic>>.from(data);
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _errorMessage = 'Error al buscar: ' + e.toString();
        _isLoading = false;
      });
    }
  }

  Future<void> _mostrarModalExportar() async {
    showDialog(
      context: context,
      barrierDismissible: true,
      builder: (context) {
        final GlobalKey previewKey = GlobalKey();
        return Scaffold(
          backgroundColor: Colors.black.withValues(alpha: 0.7),
          body: SafeArea(
            child: Column(
              children: [
                Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      IconButton(
                        icon: const Icon(Icons.close, color: Colors.white),
                        onPressed: () => Navigator.of(context).pop(),
                      ),
                      ElevatedButton.icon(
                        icon: const Icon(Icons.image),
                        label: const Text('Exportar imagen'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Color(0xFF25D366),
                          foregroundColor: Colors.white,
                        ),
                        onPressed: () async {
                          try {
                            RenderRepaintBoundary boundary = previewKey.currentContext!.findRenderObject() as RenderRepaintBoundary;
                            final image = await boundary.toImage(pixelRatio: 3.0);
                            final byteData = await image.toByteData(format: ui.ImageByteFormat.png);
                            if (byteData != null) {
                              final pngBytes = byteData.buffer.asUint8List();
                              await Share.shareXFiles([
                                XFile.fromData(pngBytes, mimeType: 'image/png', name: 'control_descargas.png')
                              ],
                              text: 'Control Descargas');
                            }
                          } catch (e) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(content: Text('Error al exportar: ' + e.toString())),
                            );
                          }
                        },
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 8),
                Expanded(
                  child: Center(
                    child: Scrollbar(
                      thumbVisibility: true,
                      child: SingleChildScrollView(
                        scrollDirection: Axis.vertical,
                        child: SingleChildScrollView(
                          scrollDirection: Axis.horizontal,
                          child: RepaintBoundary(
                            key: previewKey,
                            child: Container(
                              color: Colors.white,
                              padding: const EdgeInsets.all(24),
                              child: _TablaExportable(resultados: _resultados),
                            ),
                          ),
                        ),
                      ),
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

  @override
  void dispose() {
    _correriaController.dispose();
    _codigoController.dispose();
    _supervisorController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Control Descargas'),
        backgroundColor: const Color(0xFF1A237E),
        foregroundColor: Colors.white,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _correriaController,
                    decoration: const InputDecoration(labelText: 'Correria'),
                    onChanged: (value) {
                      final upper = value.toUpperCase();
                      if (value != upper) {
                        _correriaController.value = _correriaController.value.copyWith(
                          text: upper,
                          selection: TextSelection.collapsed(offset: upper.length),
                        );
                      }
                    },
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: TextField(
                    controller: _codigoController,
                    decoration: const InputDecoration(labelText: 'Código'),
                    onChanged: (value) {
                      final upper = value.toUpperCase();
                      if (value != upper) {
                        _codigoController.value = _codigoController.value.copyWith(
                          text: upper,
                          selection: TextSelection.collapsed(offset: upper.length),
                        );
                      }
                    },
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: TextField(
                    controller: _supervisorController,
                    decoration: const InputDecoration(labelText: 'Supervisor'),
                    onChanged: (value) {
                      final upper = value.toUpperCase();
                      if (value != upper) {
                        _supervisorController.value = _supervisorController.value.copyWith(
                          text: upper,
                          selection: TextSelection.collapsed(offset: upper.length),
                        );
                      }
                    },
                  ),
                ),
                const SizedBox(width: 8),
                Column(
                  children: [
                    Row(
                      children: [
                        Checkbox(
                          value: _pendientesFiltro,
                          onChanged: (val) {
                            setState(() {
                              _pendientesFiltro = val ?? false;
                            });
                          },
                        ),
                        const Text('Pendientes > 0'),
                      ],
                    ),
                    ElevatedButton(
                      onPressed: _isLoading ? null : _buscar,
                      child: const Text('Buscar'),
                    ),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 16),
            if (_isLoading) const CircularProgressIndicator(),
            if (_errorMessage != null) ...[
              Text(_errorMessage!, style: const TextStyle(color: Colors.red)),
            ],
            if (_resultados.isNotEmpty)
              Expanded(
                child: Column(
                  children: [
                    Expanded(
                      child: SingleChildScrollView(
                        scrollDirection: Axis.horizontal,
                        child: RepaintBoundary(
                          key: _tableKey,
                          child: Container(
                            color: Colors.white,
                            padding: const EdgeInsets.all(24),
                            child: _TablaExportable(resultados: _resultados),
                          ),
                        ),
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.symmetric(vertical: 12.0),
                      child: ElevatedButton.icon(
                        icon: const Icon(Icons.image),
                        label: const Text('Exportar imagen para WhatsApp'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Color(0xFF25D366),
                          foregroundColor: Colors.white,
                        ),
                        onPressed: _mostrarModalExportar,
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

class _TablaExportable extends StatelessWidget {
  final List<Map<String, dynamic>> resultados;
  const _TablaExportable({required this.resultados});

  @override
  Widget build(BuildContext context) {
    final headerStyle = TextStyle(
      color: Colors.white,
      fontWeight: FontWeight.bold,
      fontSize: 16,
      letterSpacing: 1.2,
      backgroundColor: Color(0xFF1A237E),
    );
    final cellStyle = TextStyle(color: Colors.black, fontSize: 15);

    return Table(
      border: TableBorder.symmetric(
        inside: BorderSide(color: Colors.grey.shade400, width: 1),
        outside: BorderSide(color: Colors.grey.shade600, width: 1.5),
      ),
      columnWidths: const {
        0: IntrinsicColumnWidth(),
        1: IntrinsicColumnWidth(),
        2: IntrinsicColumnWidth(),
        3: IntrinsicColumnWidth(),
        4: IntrinsicColumnWidth(),
        5: IntrinsicColumnWidth(),
      },
      children: [
        TableRow(
          decoration: BoxDecoration(color: Color(0xFF1A237E)),
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
              child: Text('Correria', style: headerStyle, textAlign: TextAlign.center),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
              child: Text('Código', style: headerStyle, textAlign: TextAlign.center),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
              child: Text('Supervisor', style: headerStyle, textAlign: TextAlign.center),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
              child: Text('Totales', style: headerStyle, textAlign: TextAlign.center),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
              child: Text('Pendientes', style: headerStyle, textAlign: TextAlign.center),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
              child: Text('Descargadas', style: headerStyle, textAlign: TextAlign.center),
            ),
          ],
        ),
        ...resultados.map((row) => TableRow(
          decoration: BoxDecoration(color: Colors.white),
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 8),
              child: Text(row['id_correria']?.toString() ?? '', style: cellStyle, textAlign: TextAlign.center),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 8),
              child: Text(row['codigo']?.toString() ?? '', style: cellStyle, textAlign: TextAlign.center),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 8),
              child: Text(row['supervisor']?.toString() ?? '', style: cellStyle, textAlign: TextAlign.center),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 8),
              child: Text(row['totales']?.toString() ?? '', style: cellStyle, textAlign: TextAlign.center),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 8),
              child: Text(row['pendientes']?.toString() ?? '', style: cellStyle, textAlign: TextAlign.center),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 8),
              child: Text(row['descargadas']?.toString() ?? '', style: cellStyle, textAlign: TextAlign.center),
            ),
          ],
        ))
      ],
    );
  }
}
