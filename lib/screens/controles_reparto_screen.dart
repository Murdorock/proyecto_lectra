import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../main.dart';

class ControlesRepartoScreen extends StatefulWidget {
  const ControlesRepartoScreen({super.key});

  @override
  State<ControlesRepartoScreen> createState() => _ControlesRepartoScreenState();
}

class _ControlesRepartoScreenState extends State<ControlesRepartoScreen> {
  final TextEditingController _correriaController = TextEditingController();

  String? _cicloSeleccionado;
  List<Map<String, dynamic>> _resultados = [];
  bool _isSearching = false;
  String? _errorMessage;
  String? _mensajeBusqueda;

  @override
  void dispose() {
    _correriaController.dispose();
    super.dispose();
  }

  Future<void> _buscar() async {
    // Validaciones
    final ciclo = _cicloSeleccionado;
    final correria = _correriaController.text.trim();

    // Validar que ciclo y correría se usen juntos
    if ((ciclo != null && correria.isEmpty) || (ciclo == null && correria.isNotEmpty)) {
      setState(() {
        _errorMessage = 'CICLO y CORRERÍA deben usarse juntos';
        _resultados = [];
        _mensajeBusqueda = null;
      });
      return;
    }

    // Validar que al menos un criterio esté lleno
    if (ciclo == null && correria.isEmpty) {
      setState(() {
        _errorMessage = 'Debe ingresar CICLO y CORRERÍA para buscar';
        _resultados = [];
        _mensajeBusqueda = null;
      });
      return;
    }

    setState(() {
      _isSearching = true;
      _errorMessage = null;
      _mensajeBusqueda = null;
    });

    try {
      var query = supabase
          .from('controles_reparto')
          .select('ciclo, correria, contrato, instalacion, direccion_entrega');

      // Aplicar filtros
      if (ciclo != null && correria.isNotEmpty) {
        query = query.eq('ciclo', ciclo).eq('correria', correria);
      }

      final data = await query.limit(100);

      if (mounted) {
        String criterio = 'Ciclo: $ciclo, Correría: $correria';

        setState(() {
          _resultados = List<Map<String, dynamic>>.from(data);
          _isSearching = false;
          if (_resultados.isNotEmpty) {
            _mensajeBusqueda = 'Resultados para: $criterio\n${_resultados.length} registro(s) encontrado(s)';
          } else {
            _mensajeBusqueda = 'No se encontraron resultados para: $criterio';
          }
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _errorMessage = 'Error al buscar: ${e.toString()}';
          _isSearching = false;
          _resultados = [];
          _mensajeBusqueda = null;
        });
      }
    }
  }

  void _limpiar() {
    setState(() {
      _cicloSeleccionado = null;
      _correriaController.clear();
      _resultados = [];
      _errorMessage = null;
      _mensajeBusqueda = null;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Controles Reparto'),
        backgroundColor: const Color(0xFF1A237E),
        foregroundColor: Colors.white,
      ),
      body: Column(
        children: [
          // Campos de búsqueda
          Container(
            padding: const EdgeInsets.all(16),
            color: Colors.white,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Instrucción
                Text(
                  'Ingrese CICLO y CORRERÍA para buscar.',
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey.shade700,
                    fontStyle: FontStyle.italic,
                  ),
                ),
                const SizedBox(height: 16),

                // Fila: Ciclo y Correría
                Row(
                  children: [
                    // Campo CICLO (Dropdown)
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
                          });
                        },
                      ),
                    ),
                    const SizedBox(width: 12),
                    // Campo CORRERÍA
                    Expanded(
                      child: TextField(
                        controller: _correriaController,
                        keyboardType: TextInputType.number,
                        maxLength: 4,
                        inputFormatters: [
                          FilteringTextInputFormatter.digitsOnly,
                        ],
                        decoration: InputDecoration(
                          labelText: 'CORRERÍA',
                          labelStyle: const TextStyle(
                            color: Color(0xFF1A237E),
                            fontWeight: FontWeight.bold,
                          ),
                          prefixIcon: const Icon(Icons.route, color: Color(0xFF1A237E)),
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
                          counterText: '',
                          helperText: 'Máx 4',
                          helperStyle: const TextStyle(fontSize: 10),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),

                // Botones
                Row(
                  children: [
                    Expanded(
                      child: ElevatedButton.icon(
                        onPressed: _isSearching ? null : _buscar,
                        icon: _isSearching
                            ? const SizedBox(
                                width: 18,
                                height: 18,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                                ),
                              )
                            : const Icon(Icons.search),
                        label: Text(
                          _isSearching ? 'BUSCANDO...' : 'BUSCAR',
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 14,
                          ),
                        ),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF1A237E),
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: _limpiar,
                        icon: const Icon(Icons.clear_all),
                        label: const Text(
                          'LIMPIAR',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 14,
                          ),
                        ),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: const Color(0xFF1A237E),
                          side: const BorderSide(color: Color(0xFF1A237E), width: 2),
                          padding: const EdgeInsets.symmetric(vertical: 14),
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

          // Mensaje de búsqueda o error
          if (_mensajeBusqueda != null || _errorMessage != null)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              color: _errorMessage != null ? Colors.red.shade50 : Colors.green.shade50,
              child: Row(
                children: [
                  Icon(
                    _errorMessage != null ? Icons.error_outline : Icons.info_outline,
                    color: _errorMessage != null ? Colors.red : Colors.green.shade800,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      _errorMessage ?? _mensajeBusqueda!,
                      style: TextStyle(
                        color: _errorMessage != null ? Colors.red : Colors.green.shade800,
                        fontSize: 13,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              ),
            ),

          // Lista de resultados
          Expanded(
            child: _resultados.isEmpty && _mensajeBusqueda == null && _errorMessage == null
                ? const Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.search,
                          size: 64,
                          color: Colors.grey,
                        ),
                        SizedBox(height: 16),
                        Text(
                          'Ingrese un criterio de búsqueda',
                          style: TextStyle(
                            fontSize: 16,
                            color: Colors.grey,
                          ),
                        ),
                      ],
                    ),
                  )
                : ListView.builder(
                    padding: const EdgeInsets.all(16),
                    itemCount: _resultados.length,
                    itemBuilder: (context, index) {
                      final registro = _resultados[index];
                      final ciclo = registro['ciclo']?.toString() ?? 'N/A';
                      final correria = registro['correria']?.toString() ?? 'N/A';
                      final contrato = registro['contrato']?.toString() ?? 'N/A';
                      final instalacion = registro['instalacion']?.toString() ?? 'N/A';
                      final direccion = registro['direccion_entrega']?.toString() ?? 'N/A';

                      return Card(
                        margin: const EdgeInsets.only(bottom: 12),
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
                              // Encabezado
                              Row(
                                children: [
                                  Container(
                                    width: 40,
                                    height: 40,
                                    decoration: const BoxDecoration(
                                      color: Color(0xFF1A237E),
                                      shape: BoxShape.circle,
                                    ),
                                    child: Center(
                                      child: Text(
                                        '${index + 1}',
                                        style: const TextStyle(
                                          color: Colors.white,
                                          fontWeight: FontWeight.bold,
                                          fontSize: 16,
                                        ),
                                      ),
                                    ),
                                  ),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          'Ciclo: $ciclo - Correría: $correria',
                                          style: const TextStyle(
                                            fontSize: 14,
                                            fontWeight: FontWeight.bold,
                                            color: Color(0xFF1A237E),
                                          ),
                                        ),
                                        const SizedBox(height: 2),
                                        Text(
                                          'Contrato: $contrato',
                                          style: TextStyle(
                                            fontSize: 12,
                                            color: Colors.grey.shade700,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 12),
                              const Divider(),
                              const SizedBox(height: 8),

                              // Información detallada
                              _buildInfoRow(Icons.home, 'Instalación', instalacion),
                              const SizedBox(height: 8),
                              _buildInfoRow(Icons.location_on, 'Dirección', direccion),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoRow(IconData icon, String label, String value) {
    return Row(
      children: [
        Icon(icon, size: 18, color: Colors.grey.shade600),
        const SizedBox(width: 8),
        Text(
          '$label: ',
          style: const TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.bold,
            color: Color(0xFF1A237E),
          ),
        ),
        Expanded(
          child: Text(
            value,
            style: TextStyle(
              fontSize: 13,
              color: Colors.grey.shade800,
            ),
          ),
        ),
      ],
    );
  }
}
