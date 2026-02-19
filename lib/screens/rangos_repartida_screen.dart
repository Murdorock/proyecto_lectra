import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class RangosRepartidaScreen extends StatefulWidget {
  const RangosRepartidaScreen({super.key});

  @override
  State<RangosRepartidaScreen> createState() => _RangosRepartidaScreenState();
}

class _RangosRepartidaScreenState extends State<RangosRepartidaScreen> {
  final _correriaController = TextEditingController();
  final _rangoController = TextEditingController();
  String? _cicloSeleccionado;
  bool _isLoading = false;
  List<Map<String, dynamic>> _resultados = [];
  Map<String, List<Map<String, dynamic>>> _resultadosAgrupados = {};

  @override
  void dispose() {
    _correriaController.dispose();
    _rangoController.dispose();
    super.dispose();
  }

  void _limpiar() {
    setState(() {
      _cicloSeleccionado = null;
      _correriaController.clear();
      _rangoController.clear();
      _resultados = [];
      _resultadosAgrupados = {};
    });
  }

  Future<void> _buscar() async {
    // Validar que se ingresaron datos
    final ciclo = _cicloSeleccionado;
    final correria = _correriaController.text.trim();
    final rango = _rangoController.text.trim().toUpperCase();

    // Validación: CICLO+CORRERIA juntos o RANGO solo
    if ((ciclo != null || correria.isNotEmpty) && rango.isNotEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Use CICLO+CORRERIA juntos o RANGO solo, no ambos'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    if (ciclo != null && correria.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Si ingresa CICLO, debe ingresar CORRERIA también'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    if (correria.isNotEmpty && ciclo == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Si ingresa CORRERIA, debe seleccionar CICLO también'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    if (ciclo == null && correria.isEmpty && rango.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Ingrese CICLO+CORRERIA o RANGO para buscar'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    setState(() {
      _isLoading = true;
      _resultados = [];
      _resultadosAgrupados = {};
    });

    try {
      final supabase = Supabase.instance.client;
      List<Map<String, dynamic>> data;

      // Búsqueda por CICLO + CORRERIA
      if (ciclo != null && correria.isNotEmpty) {
        final response = await supabase
            .from('rangos_reparto')
            .select('ciclo, correria, rangos, num_paquete, cantidad_aprox')
            .eq('ciclo', ciclo)
            .eq('correria', correria)
            .order('num_paquete', ascending: true);

        data = List<Map<String, dynamic>>.from(response);
        
        if (data.isEmpty) {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('No se encontraron resultados'),
                backgroundColor: Colors.orange,
              ),
            );
          }
        }

        setState(() {
          _resultados = data;
          _isLoading = false;
        });
      }
      // Búsqueda por RANGO
      else if (rango.isNotEmpty) {
        final response = await supabase
            .from('rangos_reparto')
            .select('ciclo, correria, rangos, num_paquete, cantidad_aprox')
            .eq('rangos', rango)
            .order('correria', ascending: true)
            .order('num_paquete', ascending: true);

        data = List<Map<String, dynamic>>.from(response);
        
        if (data.isEmpty) {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('No se encontraron resultados para ese rango'),
                backgroundColor: Colors.orange,
              ),
            );
          }
        }

        // Agrupar por CORRERIA
        final Map<String, List<Map<String, dynamic>>> agrupados = {};
        for (var item in data) {
          final correria = item['correria']?.toString() ?? 'Sin correria';
          if (!agrupados.containsKey(correria)) {
            agrupados[correria] = [];
          }
          agrupados[correria]!.add(item);
        }

        setState(() {
          _resultadosAgrupados = agrupados;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error al buscar: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
      setState(() {
        _isLoading = false;
      });
    }
  }

  Widget _buildTabla(List<Map<String, dynamic>> datos, {String? titulo}) {
    if (datos.isEmpty) return const SizedBox.shrink();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (titulo != null) ...[
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: const Color(0xFF1A237E),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text(
              titulo,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          const SizedBox(height: 8),
        ],
        Container(
          decoration: BoxDecoration(
            border: Border.all(color: Colors.grey.shade300),
            borderRadius: BorderRadius.circular(8),
          ),
          child: SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: DataTable(
              headingRowColor: WidgetStateProperty.all(const Color(0xFF1A237E).withValues(alpha: 0.1)),
              border: TableBorder.all(
                color: Colors.grey.shade300,
                width: 1,
              ),
              columns: const [
                DataColumn(
                  label: Text(
                    'CICLO',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF1A237E),
                    ),
                  ),
                ),
                DataColumn(
                  label: Text(
                    'CORRERIA',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF1A237E),
                    ),
                  ),
                ),
                DataColumn(
                  label: Text(
                    'RANGO',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF1A237E),
                    ),
                  ),
                ),
                DataColumn(
                  label: Text(
                    'NUM_PAQUETE',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF1A237E),
                    ),
                  ),
                ),
                DataColumn(
                  label: Text(
                    'CANTIDAD_APROX',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF1A237E),
                    ),
                  ),
                ),
              ],
              rows: datos.map((item) {
                return DataRow(
                  cells: [
                    DataCell(Text(item['ciclo']?.toString() ?? '')),
                    DataCell(Text(item['correria']?.toString() ?? '')),
                    DataCell(Text(item['rangos']?.toString() ?? '')),
                    DataCell(Text(item['num_paquete']?.toString() ?? '')),
                    DataCell(Text(item['cantidad_aprox']?.toString() ?? '')),
                  ],
                );
              }).toList(),
            ),
          ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'RANGOS REPARTIDA',
          style: TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
          ),
        ),
        backgroundColor: const Color(0xFF1A237E),
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: Column(
        children: [
          // Área de búsqueda
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              boxShadow: [
                BoxShadow(
                  color: Colors.grey.shade300,
                  blurRadius: 4,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Column(
              children: [
                Row(
                  children: [
                    // Campo CICLO
                    Expanded(
                      child: DropdownButtonFormField<String>(
                        key: ValueKey(_cicloSeleccionado),
                        decoration: InputDecoration(
                          labelText: 'CICLO',
                          labelStyle: const TextStyle(
                            color: Color(0xFF1A237E),
                            fontWeight: FontWeight.bold,
                          ),
                          prefixIcon: const Icon(Icons.refresh, color: Color(0xFF1A237E)),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                          enabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8),
                            borderSide: BorderSide(color: Colors.grey.shade400),
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8),
                            borderSide: const BorderSide(color: Color(0xFF1A237E), width: 2),
                          ),
                        helperText: 'Seleccione',
                        helperStyle: const TextStyle(fontSize: 10),
                      ),
                      initialValue: _cicloSeleccionado,
                      items: List.generate(20, (index) => (index + 1).toString())
                          .map((ciclo) => DropdownMenuItem<String>(
                                value: ciclo,
                                child: Text(ciclo),
                              ))
                          .toList(),
                        onChanged: (value) {
                          setState(() {
                            _cicloSeleccionado = value;
                            if (value != null) {
                              _rangoController.clear();
                            }
                          });
                        },
                      ),
                    ),
                    const SizedBox(width: 12),
                    // Campo CORRERIA
                    Expanded(
                      child: TextField(
                        controller: _correriaController,
                        keyboardType: TextInputType.number,
                        inputFormatters: [
                          FilteringTextInputFormatter.digitsOnly,
                          LengthLimitingTextInputFormatter(4),
                        ],
                        decoration: InputDecoration(
                          labelText: 'CORRERIA',
                          labelStyle: const TextStyle(
                            color: Color(0xFF1A237E),
                            fontWeight: FontWeight.bold,
                          ),
                          prefixIcon: const Icon(Icons.directions_run, color: Color(0xFF1A237E)),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                          enabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8),
                            borderSide: BorderSide(color: Colors.grey.shade400),
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8),
                            borderSide: const BorderSide(color: Color(0xFF1A237E), width: 2),
                          ),
                          helperText: 'Máx 4 dígitos',
                          helperStyle: const TextStyle(fontSize: 10),
                        ),
                        onChanged: (value) {
                          if (value.isNotEmpty) {
                            setState(() {
                              _rangoController.clear();
                            });
                          }
                        },
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                // Campo RANGO
                TextField(
                  controller: _rangoController,
                  textCapitalization: TextCapitalization.characters,
                  decoration: InputDecoration(
                    labelText: 'RANGO',
                    labelStyle: const TextStyle(
                      color: Color(0xFF1A237E),
                      fontWeight: FontWeight.bold,
                    ),
                    prefixIcon: const Icon(Icons.label, color: Color(0xFF1A237E)),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                      borderSide: BorderSide(color: Colors.grey.shade400),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                      borderSide: const BorderSide(color: Color(0xFF1A237E), width: 2),
                    ),
                    helperText: 'Búsqueda exacta (mayúsculas)',
                    helperStyle: const TextStyle(fontSize: 10),
                  ),
                  onChanged: (value) {
                    if (value.isNotEmpty) {
                      setState(() {
                        _cicloSeleccionado = null;
                        _correriaController.clear();
                      });
                    }
                  },
                ),
                const SizedBox(height: 16),
                // Botones
                Row(
                  children: [
                    Expanded(
                      child: ElevatedButton.icon(
                        onPressed: _isLoading ? null : _buscar,
                        icon: _isLoading
                            ? const SizedBox(
                                width: 20,
                                height: 20,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                                ),
                              )
                            : const Icon(Icons.search, color: Colors.white),
                        label: Text(
                          _isLoading ? 'BUSCANDO...' : 'BUSCAR',
                          style: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF1A237E),
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: _isLoading ? null : _limpiar,
                        icon: const Icon(Icons.clear, color: Color(0xFF1A237E)),
                        label: const Text(
                          'LIMPIAR',
                          style: TextStyle(
                            color: Color(0xFF1A237E),
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        style: OutlinedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          side: const BorderSide(color: Color(0xFF1A237E), width: 2),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          // Área de resultados
          Expanded(
            child: _isLoading
                ? const Center(
                    child: CircularProgressIndicator(
                      color: Color(0xFF1A237E),
                    ),
                  )
                : _resultados.isNotEmpty
                    ? SingleChildScrollView(
                        padding: const EdgeInsets.all(16),
                        child: _buildTabla(_resultados),
                      )
                    : _resultadosAgrupados.isNotEmpty
                        ? ListView.builder(
                            padding: const EdgeInsets.all(16),
                            itemCount: _resultadosAgrupados.length,
                            itemBuilder: (context, index) {
                              final correria = _resultadosAgrupados.keys.elementAt(index);
                              final datos = _resultadosAgrupados[correria]!;
                              final ciclo = datos.first['ciclo']?.toString() ?? '';
                              
                              return Padding(
                                padding: const EdgeInsets.only(bottom: 24),
                                child: _buildTabla(
                                  datos,
                                  titulo: 'CICLO: $ciclo - CORRERIA: $correria (${datos.length} registros)',
                                ),
                              );
                            },
                          )
                        : Center(
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(
                                  Icons.table_chart,
                                  size: 80,
                                  color: Colors.grey.shade400,
                                ),
                                const SizedBox(height: 16),
                                Text(
                                  'Ingrese criterios de búsqueda',
                                  style: TextStyle(
                                    fontSize: 16,
                                    color: Colors.grey.shade600,
                                  ),
                                ),
                                const SizedBox(height: 8),
                                Text(
                                  'CICLO+CORRERIA o RANGO',
                                  style: TextStyle(
                                    fontSize: 14,
                                    color: Colors.grey.shade500,
                                  ),
                                ),
                              ],
                            ),
                          ),
          ),
        ],
      ),
    );
  }
}
