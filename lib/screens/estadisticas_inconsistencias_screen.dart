import 'package:flutter/material.dart';
import '../main.dart';

class EstadisticasInconsistenciasScreen extends StatefulWidget {
  const EstadisticasInconsistenciasScreen({super.key});

  @override
  State<EstadisticasInconsistenciasScreen> createState() => _EstadisticasInconsistenciasScreenState();
}

class _EstadisticasInconsistenciasScreenState extends State<EstadisticasInconsistenciasScreen> {
  bool _loading = false;
  List<Map<String, dynamic>> _stats = [];
  String? _error;

  Future<void> _fetchStats() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final List<dynamic> data = await supabase
          .from('inconsistencias')
          .select('nombre_revisor, pdf');
      final Map<String, Map<String, int>> stats = {};
      for (final row in data) {
        final nombre = row['nombre_revisor'] ?? 'Sin nombre';
        final tienePdf = row['pdf'] != null && row['pdf'].toString().isNotEmpty;
        stats.putIfAbsent(nombre, () => {'total': 0, 'conPdf': 0});
        stats[nombre]!['total'] = stats[nombre]!['total']! + 1;
        if (tienePdf) {
          stats[nombre]!['conPdf'] = stats[nombre]!['conPdf']! + 1;
        }
      }
      final List<Map<String, dynamic>> resumen = stats.entries.map((e) => {
        'nombre': e.key,
        'total': e.value['total'],
        'conPdf': e.value['conPdf'],
        'pendientes': e.value['total']! - e.value['conPdf']!
      }).toList();
      setState(() {
        _stats = resumen;
        _loading = false;
      });
    } catch (e) {
      setState(() {
        _error = e.toString();
        _loading = false;
      });
    }
  }

  @override
  void initState() {
    super.initState();
    _fetchStats();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Estadísticas de Revisores'),
        backgroundColor: const Color(0xFF1A237E),
        foregroundColor: Colors.white,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (_loading) const Center(child: CircularProgressIndicator()),
              if (_error != null) ...[
                Text('Error: $_error', style: const TextStyle(color: Colors.red)),
              ],
              if (_stats.isNotEmpty)
                Card(
                  elevation: 4,
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text('Resumen General', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
                        const SizedBox(height: 12),
                        SingleChildScrollView(
                          scrollDirection: Axis.horizontal,
                          child: ConstrainedBox(
                            constraints: const BoxConstraints(minWidth: 400),
                            child: SingleChildScrollView(
                              scrollDirection: Axis.vertical,
                              child: DataTable(
                                columns: const [
                                  DataColumn(label: Text('Revisor')),
                                  DataColumn(label: Text('Total')),
                                  DataColumn(label: Text('Con PDF')),
                                  DataColumn(label: Text('Pendientes')),
                                ],
                                rows: [
                                  ..._stats.map((row) => DataRow(cells: [
                                    DataCell(Text(row['nombre'].toString())),
                                    DataCell(Text(row['total'].toString())),
                                    DataCell(Text(row['conPdf'].toString(), style: const TextStyle(color: Colors.green))),
                                    DataCell(Text(row['pendientes'].toString(), style: TextStyle(color: row['pendientes'] == 0 ? Colors.green : Colors.red))),
                                  ])).toList(),
                                  // Fila de totales
                                  if (_stats.isNotEmpty)
                                    DataRow(
                                      color: WidgetStateProperty.resolveWith<Color?>((Set<WidgetState> states) {
                                        return Colors.grey[200];
                                      }),
                                      cells: [
                                        const DataCell(Text('Totales', style: TextStyle(fontWeight: FontWeight.bold))),
                                        DataCell(Text(_stats.fold<int>(0, (sum, row) => sum + (row['total'] as int)).toString(), style: const TextStyle(fontWeight: FontWeight.bold))),
                                        DataCell(Text(_stats.fold<int>(0, (sum, row) => sum + (row['conPdf'] as int)).toString(), style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.green))),
                                        DataCell(Text(_stats.fold<int>(0, (sum, row) => sum + (row['pendientes'] as int)).toString(), style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.red))),
                                      ],
                                    ),
                                ],
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}
