import '../main.dart';
import 'package:flutter/material.dart';
import 'package:share_plus/share_plus.dart';
import 'dart:ui' as ui;
import 'package:flutter/rendering.dart';

class ResumenJornadaScreen extends StatefulWidget {
  const ResumenJornadaScreen({super.key});

  @override
  State<ResumenJornadaScreen> createState() => _ResumenJornadaScreenState();
}

class _ResumenJornadaScreenState extends State<ResumenJornadaScreen> {
  final GlobalKey _previewKey = GlobalKey();
  List<Map<String, dynamic>> _tabla = [];
  bool _isLoading = true;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
      // Obtener datos de control_descargas para Desc. Confirmadas
      final descargas = await supabase.from('control_descargas').select('supervisor, pendientes');
    setState(() { _isLoading = true; });
    try {
      // Simulación de consulta a la tabla base (reemplaza 'tabla_base' por el nombre real si es necesario)
      final base = await supabase.from('base').select('supervisor, registro_salida');
        // Obtener supervisores únicos, ignorando vacíos
        final supervisores = base.map((row) => row['supervisor'])
          .where((sup) => sup != null && sup.toString().trim().isNotEmpty)
          .toSet()
          .toList();
      List<Map<String, dynamic>> tabla = [];
      for (var sup in supervisores) {
          // Buscar filas en control_descargas para el supervisor actual
          final filasDescargas = descargas.where((row) => row['supervisor'] == sup).toList();
          String descConfirmadas;
          String descPendientes;
          String porcentajeDescargado;
        if (sup == 'ADM_004') {
          descConfirmadas = 'Otra Actividad';
          descPendientes = 'Otra Actividad';
          porcentajeDescargado = 'Otra Actividad';
        } else {
          int confirmadas = 0;
          int pendientes = 0;
          if (filasDescargas.isEmpty) {
            descConfirmadas = '';
            descPendientes = '';
            porcentajeDescargado = '';
          } else {
            confirmadas = filasDescargas.where((row) => row['pendientes'] == 0).length;
            pendientes = filasDescargas.where((row) => (row['pendientes'] ?? 0) > 0).length;
            descConfirmadas = confirmadas.toString();
            descPendientes = pendientes.toString();
            porcentajeDescargado = (confirmadas + pendientes) == 0
                ? '0%'
                : pendientes == 0
                    ? '100%'
                    : '${((confirmadas / (confirmadas + pendientes)) * 100).toStringAsFixed(0)}%';
          }
          // Si ambas columnas están vacías o son cero, poner 'Repartida'
          final isRepartida = ((descConfirmadas == '' || descConfirmadas == '0') && (descPendientes == '' || descPendientes == '0'));
          if (isRepartida) {
            descConfirmadas = 'Repartida';
            descPendientes = 'Repartida';
            porcentajeDescargado = 'Repartida';
          } else if (filasDescargas.isEmpty) {
            descConfirmadas = 'Otra Act.';
            descPendientes = 'Otra Act.';
            porcentajeDescargado = 'Otra Act.';
          }
        }
        final filasSupervisor = base.where((row) => row['supervisor'] == sup).toList();
        final cantidad = filasSupervisor.length;
        final registrados = filasSupervisor.where((row) => row['registro_salida'] != null && row['registro_salida'].toString().isNotEmpty).length;
        final pendientes = filasSupervisor.where((row) => row['registro_salida'] == null || row['registro_salida'].toString().isEmpty).length;
        final porcentajeRegistrado = cantidad == 0
          ? 0
          : (pendientes == 0 ? 100 : (registrados / cantidad) * 100);
        tabla.add({
          'supervisor': sup,
          'cantidad': cantidad,
          'registrados': registrados,
          'pendientes': pendientes,
          'porcentaje_registrado': porcentajeRegistrado,
          'desc_confirmadas': descConfirmadas,
          'desc_pendientes': descPendientes,
          'porcentaje_descargado': porcentajeDescargado,
        });
      }
        tabla.sort((a, b) => a['supervisor'].toString().compareTo(b['supervisor'].toString()));
        setState(() {
          _tabla = tabla;
          _isLoading = false;
        });
    } catch (e) {
      setState(() {
        _errorMessage = 'Error al cargar datos: ' + e.toString();
        _isLoading = false;
      });
    }
  }
  Future<void> _exportarImagen() async {
    try {
      RenderRepaintBoundary boundary = _previewKey.currentContext!.findRenderObject() as RenderRepaintBoundary;
      final image = await boundary.toImage(pixelRatio: 3.0);
      final byteData = await image.toByteData(format: ui.ImageByteFormat.png);
      if (byteData != null) {
        final pngBytes = byteData.buffer.asUint8List();
        await Share.shareXFiles([
          XFile.fromData(pngBytes, mimeType: 'image/png', name: 'resumen_jornada.png')
        ],
        text: 'Resumen Jornada');
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error al exportar: ' + e.toString())),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Resumen Jornada'),
        backgroundColor: const Color(0xFF1A237E),
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: const Icon(Icons.image),
            tooltip: 'Exportar imagen',
            onPressed: _exportarImagen,
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _errorMessage != null
              ? Center(child: Text(_errorMessage!, style: TextStyle(color: Colors.red)))
              : Scrollbar(
                  thumbVisibility: true,
                  child: SingleChildScrollView(
                    scrollDirection: Axis.vertical,
                    child: SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      child: RepaintBoundary(
                        key: _previewKey,
                        child: Container(
                          color: Colors.white,
                          padding: const EdgeInsets.all(24.0),
                          child: Table(
                            border: TableBorder.all(color: Colors.grey.shade400, width: 1),
                            columnWidths: const {
                              0: IntrinsicColumnWidth(),
                              1: IntrinsicColumnWidth(),
                              2: IntrinsicColumnWidth(),
                              3: IntrinsicColumnWidth(),
                              4: IntrinsicColumnWidth(),
                              5: IntrinsicColumnWidth(),
                              6: IntrinsicColumnWidth(),
                              7: IntrinsicColumnWidth(),
                            },
                            children: [
                              TableRow(
                                decoration: BoxDecoration(color: Colors.grey.shade300),
                                children: [
                                  Padding(
                                    padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 4),
                                    child: Text('Supervisor', style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold)),
                                  ),
                                  Padding(
                                    padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 4),
                                    child: Text('Cantidad', style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold)),
                                  ),
                                  Padding(
                                    padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 4),
                                    child: Text('Registrados', style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold)),
                                  ),
                                  Padding(
                                    padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 4),
                                    child: Text('Pend. Registrar', style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold)),
                                  ),
                                  Padding(
                                    padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 4),
                                    child: Text('% Registrado', style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold)),
                                  ),
                                  Padding(
                                    padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 4),
                                    child: Text('Desc. Confirmadas', style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold)),
                                  ),
                                  Padding(
                                    padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 4),
                                    child: Text('Desc. Pendientes', style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold)),
                                  ),
                                  Padding(
                                    padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 4),
                                    child: Text('% Descargado', style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold)),
                                  ),
                                ],
                              ),
                              ..._tabla.map((row) {
                                final pendientesRegistrar = int.tryParse(row['pendientes']?.toString() ?? '0') ?? 0;
                                final descPendientes = int.tryParse(row['desc_pendientes']?.toString() ?? '0') ?? 0;
                                final highlight = pendientesRegistrar != 0 || descPendientes != 0;
                                return TableRow(
                                  decoration: BoxDecoration(color: highlight ? Colors.red.shade100 : Colors.white),
                                  children: [
                                    Padding(
                                      padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 4),
                                      child: Text(row['supervisor']?.toString() ?? '', style: const TextStyle(color: Colors.black)),
                                    ),
                                    Padding(
                                      padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 4),
                                      child: Text(row['cantidad']?.toString() ?? '', style: const TextStyle(color: Colors.black)),
                                    ),
                                    Padding(
                                      padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 4),
                                      child: Text(row['registrados']?.toString() ?? '', style: const TextStyle(color: Colors.black)),
                                    ),
                                    Padding(
                                      padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 4),
                                      child: Text(row['pendientes']?.toString() ?? '', style: const TextStyle(color: Colors.black)),
                                    ),
                                    Padding(
                                      padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 4),
                                      child: Text('${row['porcentaje_registrado']?.toStringAsFixed(0) ?? '0'}%', style: const TextStyle(color: Colors.black)),
                                    ),
                                    Padding(
                                      padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 4),
                                      child: Text(row['desc_confirmadas']?.toString() ?? '', style: const TextStyle(color: Colors.black)),
                                    ),
                                    Padding(
                                      padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 4),
                                      child: Text(row['desc_pendientes']?.toString() ?? '', style: const TextStyle(color: Colors.black)),
                                    ),
                                    Padding(
                                      padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 4),
                                      child: Text(row['porcentaje_descargado']?.toString() ?? '', style: const TextStyle(color: Colors.black)),
                                    ),
                                  ],
                                );
                              }),
                              // Fila de totales
                              TableRow(
                                decoration: BoxDecoration(color: Colors.grey.shade200),
                                children: [
                                  Padding(
                                    padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 4),
                                    child: Text('TOTALES', style: const TextStyle(color: Colors.black, fontWeight: FontWeight.bold)),
                                  ),
                                  Padding(
                                    padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 4),
                                    child: Text(_tabla.fold<int>(0, (sum, row) => sum + (int.tryParse(row['cantidad']?.toString() ?? '0') ?? 0)).toString(), style: const TextStyle(color: Colors.black, fontWeight: FontWeight.bold)),
                                  ),
                                  Padding(
                                    padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 4),
                                    child: Text(_tabla.fold<int>(0, (sum, row) => sum + (int.tryParse(row['registrados']?.toString() ?? '0') ?? 0)).toString(), style: const TextStyle(color: Colors.black, fontWeight: FontWeight.bold)),
                                  ),
                                  Padding(
                                    padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 4),
                                    child: Text(_tabla.fold<int>(0, (sum, row) => sum + (int.tryParse(row['pendientes']?.toString() ?? '0') ?? 0)).toString(), style: const TextStyle(color: Colors.black, fontWeight: FontWeight.bold)),
                                  ),
                                  Padding(
                                    padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 4),
                                    child: Builder(
                                      builder: (context) {
                                        final totalCantidad = _tabla.fold<int>(0, (sum, row) => sum + (int.tryParse(row['cantidad']?.toString() ?? '0') ?? 0));
                                        final totalRegistrados = _tabla.fold<int>(0, (sum, row) => sum + (int.tryParse(row['registrados']?.toString() ?? '0') ?? 0));
                                        final porcentajeRegistrado = totalCantidad == 0 ? 0 : (totalRegistrados / totalCantidad) * 100;
                                        return Text('${porcentajeRegistrado.toStringAsFixed(0)}%', style: const TextStyle(color: Colors.black, fontWeight: FontWeight.bold));
                                      },
                                    ),
                                  ),
                                  Padding(
                                    padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 4),
                                    child: Text(_tabla.fold<int>(0, (sum, row) => sum + (int.tryParse(row['desc_confirmadas']?.toString() ?? '0') ?? 0)).toString(), style: const TextStyle(color: Colors.black, fontWeight: FontWeight.bold)),
                                  ),
                                  Padding(
                                    padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 4),
                                    child: Text(_tabla.fold<int>(0, (sum, row) => sum + (int.tryParse(row['desc_pendientes']?.toString() ?? '0') ?? 0)).toString(), style: const TextStyle(color: Colors.black, fontWeight: FontWeight.bold)),
                                  ),
                                  Padding(
                                    padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 4),
                                    child: Builder(
                                      builder: (context) {
                                        final totalDescConfirmadas = _tabla.fold<int>(0, (sum, row) => sum + (int.tryParse(row['desc_confirmadas']?.toString() ?? '0') ?? 0));
                                        final totalDescPendientes = _tabla.fold<int>(0, (sum, row) => sum + (int.tryParse(row['desc_pendientes']?.toString() ?? '0') ?? 0));
                                        final totalDesc = totalDescConfirmadas + totalDescPendientes;
                                        final porcentajeDescargado = totalDesc == 0 ? 0 : (totalDescConfirmadas / totalDesc) * 100;
                                        return Text('${porcentajeDescargado.toStringAsFixed(0)}%', style: const TextStyle(color: Colors.black, fontWeight: FontWeight.bold));
                                      },
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
    );
  }
}
