import 'package:flutter/material.dart';
import '../main.dart';

class ResultadosRangosScreen extends StatefulWidget {
  final String? ciclo;
  final String? correria;
  final String? direccion;

  const ResultadosRangosScreen({
    super.key,
    this.ciclo,
    this.correria,
    this.direccion,
  });

  @override
  State<ResultadosRangosScreen> createState() => _ResultadosRangosScreenState();
}

class _ResultadosRangosScreenState extends State<ResultadosRangosScreen> {
  List<Map<String, dynamic>> _resultados = [];
  bool _isLoading = true;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _buscarRangos();
  }

  Future<void> _buscarRangos() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      List<Map<String, dynamic>> data = [];

      // Si solo se busca por dirección, primero encontrar todos los ciclos y correrias
      if (widget.direccion != null && widget.ciclo == null && widget.correria == null) {
        // Buscar TODAS las ocurrencias de la dirección para obtener sus ciclos y correrias
        final direccionData = await supabase
            .from('rangos')
            .select('ciclo, correria')
            .ilike('direccion', '%${widget.direccion}%');

        if (direccionData.isNotEmpty) {
          // Obtener todos los pares únicos de ciclo-correría
          Set<String> ciclosCorrerias = {};
          for (var item in direccionData) {
            ciclosCorrerias.add('${item['ciclo']}_${item['correria']}');
          }

          // Buscar todas las filas para cada par ciclo-correría encontrado
          for (var pair in ciclosCorrerias) {
            var parts = pair.split('_');
            var ciclo = parts[0];
            var correria = parts[1];

            final allData = await supabase
                .from('rangos')
                .select('ciclo, correria, direccion, lecturas, instalaciones')
                .eq('ciclo', ciclo)
                .eq('correria', correria)
                .order('direccion', ascending: true);

            data.addAll(List<Map<String, dynamic>>.from(allData));
          }
        }
      } else {
        // Búsqueda normal con ciclo y/o correría
        var query = supabase
            .from('rangos')
            .select('ciclo, correria, direccion, lecturas, instalaciones');

        if (widget.ciclo != null) {
          query = query.eq('ciclo', widget.ciclo!);
        }
        if (widget.correria != null) {
          query = query.eq('correria', widget.correria!);
        }
        if (widget.direccion != null) {
          query = query.ilike('direccion', '%${widget.direccion}%');
        }

        final queryData = await query.order('direccion', ascending: true);
        data = List<Map<String, dynamic>>.from(queryData);
      }

      if (mounted) {
        setState(() {
          _resultados = data;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _errorMessage = 'Error al buscar: ${e.toString()}';
          _isLoading = false;
        });
      }
    }
  }

  String _getFiltrosTexto() {
    List<String> filtros = [];
    if (widget.ciclo != null) filtros.add('Ciclo: ${widget.ciclo}');
    if (widget.correria != null) filtros.add('Correria: ${widget.correria}');
    if (widget.direccion != null) filtros.add('Dirección: ${widget.direccion}');
    return filtros.join(', ');
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Resultados de Rangos'),
        backgroundColor: const Color(0xFF1A237E),
        foregroundColor: Colors.white,
      ),
      body: Column(
        children: [
          // Tarjeta de resultados de búsqueda
          Container(
            margin: const EdgeInsets.all(16),
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: const Color(0xFF1A237E),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Row(
                  children: [
                    Icon(Icons.search, color: Colors.white, size: 28),
                    SizedBox(width: 12),
                    Text(
                      'Resultados de Búsqueda',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Text(
                  'Filtros: ${_getFiltrosTexto()}',
                  style: const TextStyle(
                    fontSize: 14,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  '${_resultados.length} registro(s) encontrado(s)',
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
              ],
            ),
          ),

          // Lista de resultados agrupados
          Expanded(
            child: _isLoading
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
                                color: Colors.grey.shade400,
                              ),
                              const SizedBox(height: 16),
                              Text(
                                _errorMessage!,
                                textAlign: TextAlign.center,
                                style: const TextStyle(fontSize: 16),
                              ),
                              const SizedBox(height: 24),
                              ElevatedButton.icon(
                                onPressed: _buscarRangos,
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
                    : _resultados.isEmpty
                        ? const Center(
                            child: Text(
                              'No se encontraron registros',
                              style: TextStyle(
                                fontSize: 16,
                                color: Colors.grey,
                              ),
                            ),
                          )
                        : _buildResultadosAgrupados(),
          ),

          // Botón volver a filtros
          Container(
            padding: const EdgeInsets.all(16),
            child: SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: () => Navigator.pop(context),
                icon: const Icon(Icons.arrow_back),
                label: const Text(
                  'VOLVER A FILTROS',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF1A237E),
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildResultadosAgrupados() {
    // Agrupar por ciclo y correria
    Map<String, List<Map<String, dynamic>>> agrupados = {};
    
    for (var resultado in _resultados) {
      String key = 'Ciclo ${resultado['ciclo']} - Correría ${resultado['correria']}';
      if (!agrupados.containsKey(key)) {
        agrupados[key] = [];
      }
      agrupados[key]!.add(resultado);
    }

    return ListView.builder(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      itemCount: agrupados.length,
      itemBuilder: (context, index) {
        String key = agrupados.keys.elementAt(index);
        List<Map<String, dynamic>> items = agrupados[key]!;
        
        return Card(
          margin: const EdgeInsets.only(bottom: 16),
          elevation: 2,
          color: Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
            side: BorderSide(
              color: Colors.grey.shade300,
              width: 1,
            ),
          ),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Encabezado del grupo
                Row(
                  children: [
                    const Icon(Icons.folder, color: Color(0xFF1A237E)),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        key,
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF1A237E),
                        ),
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: const Color(0xFF1A237E),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        '${items.length}',
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),

                // Tabla de resultados
                Table(
                  border: TableBorder.all(
                    color: Colors.grey.shade300,
                    width: 1,
                  ),
                  columnWidths: const {
                    0: FlexColumnWidth(3),
                    1: FlexColumnWidth(1.5),
                    2: FlexColumnWidth(1.5),
                  },
                  children: [
                    // Encabezado de la tabla
                    TableRow(
                      decoration: BoxDecoration(
                        color: Colors.grey.shade200,
                      ),
                      children: const [
                        Padding(
                          padding: EdgeInsets.all(8.0),
                          child: Text(
                            'DIRECCIÓN',
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 12,
                            ),
                            textAlign: TextAlign.center,
                          ),
                        ),
                        Padding(
                          padding: EdgeInsets.all(8.0),
                          child: Text(
                            'LECTURAS',
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 12,
                            ),
                            textAlign: TextAlign.center,
                          ),
                        ),
                        Padding(
                          padding: EdgeInsets.all(8.0),
                          child: Text(
                            'INSTALACIONES',
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 12,
                            ),
                            textAlign: TextAlign.center,
                          ),
                        ),
                      ],
                    ),
                    // Filas de datos
                    ...items.map((item) {
                      return TableRow(
                        children: [
                          Padding(
                            padding: const EdgeInsets.all(8.0),
                            child: Text(
                              item['direccion']?.toString() ?? 'N/A',
                              style: const TextStyle(fontSize: 11),
                            ),
                          ),
                          Padding(
                            padding: const EdgeInsets.all(8.0),
                            child: Text(
                              item['lecturas']?.toString() ?? '0',
                              style: const TextStyle(fontSize: 11),
                              textAlign: TextAlign.center,
                            ),
                          ),
                          Padding(
                            padding: const EdgeInsets.all(8.0),
                            child: Text(
                              item['instalaciones']?.toString() ?? '0',
                              style: const TextStyle(fontSize: 11),
                              textAlign: TextAlign.center,
                            ),
                          ),
                        ],
                      );
                    }).toList(),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
