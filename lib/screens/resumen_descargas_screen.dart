import 'package:intl/intl.dart';
import 'package:flutter/material.dart';
import 'package:share_plus/share_plus.dart';
import 'dart:ui' as ui;
import 'dart:math';
import 'package:flutter/rendering.dart';
import '../main.dart';

class ResumenDescargasScreen extends StatefulWidget {
  const ResumenDescargasScreen({super.key});

  @override
  State<ResumenDescargasScreen> createState() => _ResumenDescargasScreenState();
}

class _ResumenDescargasScreenState extends State<ResumenDescargasScreen> {
    final NumberFormat _numberFormat = NumberFormat.decimalPattern();
  int totalCorreria = 0;
  int ejecutadasCorreria = 0;
  int pendientesCorreria = 0;
  num totalOrdenes = 0;
  num descargadasOrdenes = 0;
  num pendientesOrdenes = 0;
  double porcentajeEjecutado = 0;
  double porcentajePendiente = 0;
  String ciclo = '';
  bool _isLoading = true;
  String? _errorMessage;
  final GlobalKey _previewKey = GlobalKey();

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  String _truncarDecimales(double valor, int decimales) {
    final multiplicador = pow(10, decimales);
    final truncado = (valor * multiplicador).truncate() / multiplicador;
    return truncado.toStringAsFixed(decimales);
  }

  String _calcularPorcentajePendiente(int decimales) {
    // Calcular el porcentaje pendiente basado en el valor truncado del ejecutado
    final multiplicador = pow(10, decimales);
    final ejecutadoTruncado = (porcentajeEjecutado * multiplicador).truncate() / multiplicador;
    final pendiente = 100 - ejecutadoTruncado;
    return pendiente.toStringAsFixed(decimales);
  }

  Future<void> _loadData() async {
    setState(() { _isLoading = true; });
    try {
      // Obtener ciclo de cmlec
      final cmlec = await supabase.from('cmlec').select('correria_mp').limit(1);
      if (cmlec.isNotEmpty && cmlec[0]['correria_mp'] != null) {
        final correriaMp = cmlec[0]['correria_mp'].toString();
        if (correriaMp.length >= 6) {
          ciclo = correriaMp.substring(4, 6); // dígitos 5 y 6 (índice 4 y 5)
        }
      }
      // Obtener datos de control_descargas
      final descargas = await supabase.from('control_descargas').select('id_correria, pendientes, totales, descargadas');
      totalCorreria = descargas.length;
      ejecutadasCorreria = descargas.where((row) => row['pendientes'] == 0).length;
      pendientesCorreria = descargas.where((row) => row['pendientes'] != 0).length;
      
      // Calcular totales como double para preservar decimales
      double totalOrdenesTemp = 0;
      double descargadasOrdenesTemp = 0;
      
      for (var row in descargas) {
        totalOrdenesTemp += (row['totales'] ?? 0).toDouble();
        descargadasOrdenesTemp += (row['descargadas'] ?? 0).toDouble();
      }
      
      totalOrdenes = totalOrdenesTemp;
      descargadasOrdenes = descargadasOrdenesTemp;
      pendientesOrdenes = totalOrdenes - descargadasOrdenes;
      porcentajeEjecutado = totalOrdenes == 0 ? 100 : (descargadasOrdenes / totalOrdenes) * 100;
      porcentajePendiente = 100 - porcentajeEjecutado;
      
      // Debug: imprimir valores
      print('Total Ordenes: $totalOrdenes');
      print('Descargadas Ordenes: $descargadasOrdenes');
      print('Porcentaje: $porcentajeEjecutado');
      setState(() { _isLoading = false; });
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
          XFile.fromData(pngBytes, mimeType: 'image/png', name: 'resumen_descargas.png')
        ],
        text: 'Resumen Descargas');
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
        title: Text('Resumen Descargas'),
        backgroundColor: const Color(0xFF1A237E),
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: const Icon(Icons.image),
            tooltip: 'Exportar imagen',
            onPressed: _isLoading ? null : _exportarImagen,
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _errorMessage != null
              ? Center(child: Text(_errorMessage!, style: const TextStyle(color: Colors.red)))
              : SingleChildScrollView(
                  child: RepaintBoundary(
                    key: _previewKey,
                    child: Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              const Icon(Icons.insert_chart, color: Color(0xFF1A237E)),
                              const SizedBox(width: 8),
                              Text('Estadísticas de Avance - Ciclo $ciclo', style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
                            ],
                          ),
                          const SizedBox(height: 16),
                          Card(
                            color: const Color(0xFF263248),
                            elevation: 4,
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                            child: Padding(
                              padding: const EdgeInsets.all(16.0),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    children: [
                                      const Icon(Icons.inventory_2, color: Colors.brown),
                                      const SizedBox(width: 8),
                                      Text('Correrias', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 18)),
                                    ],
                                  ),
                                  const SizedBox(height: 16),
                                  Row(
                                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                                    children: [
                                      _buildStatBox(totalCorreria.toString(), 'Total', Colors.white),
                                      _buildStatBox(ejecutadasCorreria.toString(), 'Ejecutadas', Colors.green),
                                      _buildStatBox(pendientesCorreria.toString(), 'Pendientes', Colors.red),
                                    ],
                                  ),
                                  const SizedBox(height: 16),
                                  LinearProgressIndicator(
                                    value: totalCorreria == 0 ? 1 : ejecutadasCorreria / totalCorreria,
                                    minHeight: 12,
                                    backgroundColor: Colors.white24,
                                    valueColor: AlwaysStoppedAnimation<Color>(Colors.green),
                                  ),
                                  const SizedBox(height: 4),
                                  Align(
                                    alignment: Alignment.centerRight,
                                    child: Text(
                                      totalCorreria == 0 ? '100.00%' : '${((ejecutadasCorreria / totalCorreria) * 100).toStringAsFixed(2)}%',
                                      style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                          const SizedBox(height: 16),
                          Card(
                            color: const Color(0xFF263248),
                            elevation: 4,
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                            child: Padding(
                              padding: const EdgeInsets.all(16.0),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    children: [
                                      const Icon(Icons.assignment, color: Colors.purple),
                                      const SizedBox(width: 8),
                                      Text('Órdenes', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 18)),
                                    ],
                                  ),
                                  const SizedBox(height: 16),
                                  Row(
                                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                                    children: [
                                      _buildStatBox(_numberFormat.format(totalOrdenes), 'Total', Colors.white),
                                      _buildStatBox(_numberFormat.format(descargadasOrdenes), 'Descargadas', Colors.green),
                                      _buildStatBox(_numberFormat.format(pendientesOrdenes), 'Pendientes', Colors.red),
                                    ],
                                  ),
                                  const SizedBox(height: 16),
                                  LinearProgressIndicator(
                                    value: totalOrdenes == 0 ? 1 : descargadasOrdenes / totalOrdenes,
                                    minHeight: 12,
                                    backgroundColor: Colors.white24,
                                    valueColor: AlwaysStoppedAnimation<Color>(Colors.green),
                                  ),
                                  const SizedBox(height: 4),
                                  Align(
                                    alignment: Alignment.centerRight,
                                    child: Text(
                                      '${_truncarDecimales(porcentajeEjecutado, 2)}%',
                                      style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                          const SizedBox(height: 16),
                          Card(
                            color: Colors.white,
                            elevation: 2,
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                            child: Padding(
                              padding: const EdgeInsets.all(16.0),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    children: [
                                      const Icon(Icons.insert_chart, color: Color(0xFF1A237E)),
                                      const SizedBox(width: 8),
                                      Text('Resumen General', style: TextStyle(color: Color(0xFF1A237E), fontWeight: FontWeight.bold, fontSize: 18)),
                                    ],
                                  ),
                                  const SizedBox(height: 16),
                                  Row(
                                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                                    children: [
                                      Expanded(
                                        child: Container(
                                          decoration: BoxDecoration(
                                            color: Colors.white,
                                            borderRadius: BorderRadius.circular(12),
                                            border: Border.all(color: Colors.green, width: 2),
                                          ),
                                          padding: const EdgeInsets.all(12),
                                          margin: const EdgeInsets.only(right: 8),
                                          child: Column(
                                            children: [
                                              Text('Porcentaje Ejecutado', style: TextStyle(color: Colors.green, fontWeight: FontWeight.bold)),
                                              const SizedBox(height: 8),
                                              Text('${_truncarDecimales(porcentajeEjecutado, 2)}%', style: TextStyle(color: Colors.green, fontWeight: FontWeight.bold, fontSize: 28)),
                                            ],
                                          ),
                                        ),
                                      ),
                                      Expanded(
                                        child: Container(
                                          decoration: BoxDecoration(
                                            color: Colors.white,
                                            borderRadius: BorderRadius.circular(12),
                                            border: Border.all(color: Colors.red, width: 2),
                                          ),
                                          padding: const EdgeInsets.all(12),
                                          margin: const EdgeInsets.only(left: 8),
                                          child: Column(
                                            children: [
                                              Text('Porcentaje Pendiente', style: TextStyle(color: Colors.red, fontWeight: FontWeight.bold)),
                                              const SizedBox(height: 8),
                                              Text('${_calcularPorcentajePendiente(2)}%', style: TextStyle(color: Colors.red, fontWeight: FontWeight.bold, fontSize: 28)),
                                            ],
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
    );
  }

  Widget _buildStatBox(String value, String label, Color color) {
    return Column(
      children: [
        Text(
          value,
          style: TextStyle(
            fontSize: 28,
            fontWeight: FontWeight.bold,
            color: color,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          label,
          style: TextStyle(
            fontSize: 16,
            color: color,
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }
}
