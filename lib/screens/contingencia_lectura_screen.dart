import 'package:flutter/material.dart';
import '../main.dart';
import 'editar_contingencia_screen.dart';

class ContingenciaLecturaScreen extends StatefulWidget {
  const ContingenciaLecturaScreen({super.key});

  @override
  State<ContingenciaLecturaScreen> createState() => _ContingenciaLecturaScreenState();
}

class _ContingenciaLecturaScreenState extends State<ContingenciaLecturaScreen> {
  List<Map<String, dynamic>> _registros = [];
  List<Map<String, dynamic>> _registrosFiltrados = [];
  bool _isLoading = true;
  String? _errorMessage;
  String _codigoSupAux = '';
  final TextEditingController _searchController = TextEditingController();
  String? _tipoConsumoSeleccionado;

  @override
  void initState() {
    super.initState();
    _tipoConsumoSeleccionado = 'Todos';
    _loadRegistros();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _filtrarSinLectura() {
    _aplicarFiltrosCombinados(filtroLectura: 'sin');
  }

  void _filtrarConLectura() {
    _aplicarFiltrosCombinados(filtroLectura: 'con');
  }

  void _aplicarFiltrosCombinados({String? filtroLectura}) {
    final query = _searchController.text.toLowerCase();

    setState(() {
      _registrosFiltrados = _registros.where((registro) {
        // Filtro por búsqueda de texto
        bool coincideBusqueda = true;
        if (query.isNotEmpty) {
          final instalacion = registro['nro_instalacion']?.toString().toLowerCase() ?? '';
          final direccion = registro['direccion']?.toString().toLowerCase() ?? '';
          coincideBusqueda = instalacion.contains(query) || direccion.contains(query);
        }
        
        // Filtro por tipo_consumo
        bool coincideTipoConsumo = true;
        if (_tipoConsumoSeleccionado != null && _tipoConsumoSeleccionado != 'Todos') {
          final tipoConsumo = registro['tipo_consumo']?.toString() ?? '';
          coincideTipoConsumo = tipoConsumo == _tipoConsumoSeleccionado;
        }
        
        // Filtro por lectura
        bool coincideLectura = true;
        if (filtroLectura != null) {
          final lecturaTomada = registro['lectura_tomada'];
          if (filtroLectura == 'sin') {
            coincideLectura = lecturaTomada == null || lecturaTomada.toString().isEmpty;
          } else if (filtroLectura == 'con') {
            coincideLectura = lecturaTomada != null && lecturaTomada.toString().isNotEmpty;
          }
        }
        
        return coincideBusqueda && coincideTipoConsumo && coincideLectura;
      }).toList();
      
      // Ordenar por nro_instalacion y luego por tipo_consumo
      _registrosFiltrados.sort((a, b) {
        final instalacionA = int.tryParse(a['nro_instalacion']?.toString() ?? '0') ?? 0;
        final instalacionB = int.tryParse(b['nro_instalacion']?.toString() ?? '0') ?? 0;
        final compareInstalacion = instalacionA.compareTo(instalacionB);
        
        if (compareInstalacion != 0) return compareInstalacion;
        
        final tipoConsumoA = a['tipo_consumo']?.toString() ?? '';
        final tipoConsumoB = b['tipo_consumo']?.toString() ?? '';
        return tipoConsumoA.compareTo(tipoConsumoB);
      });
    });
  }

  List<String> _obtenerTiposConsumoUnicos() {
    final tiposSet = <String>{};
    for (var registro in _registros) {
      final tipo = registro['tipo_consumo']?.toString();
      if (tipo != null && tipo.isNotEmpty) {
        tiposSet.add(tipo);
      }
    }
    final tiposOrdenados = tiposSet.toList()..sort();
    return ['Todos', ...tiposOrdenados];
  }

  void _limpiarFiltro() {
    setState(() {
      _searchController.clear();
      _tipoConsumoSeleccionado = 'Todos';
      _registrosFiltrados = List.from(_registros);
      
      // Ordenar por nro_instalacion y luego por tipo_consumo
      _registrosFiltrados.sort((a, b) {
        final instalacionA = int.tryParse(a['nro_instalacion']?.toString() ?? '0') ?? 0;
        final instalacionB = int.tryParse(b['nro_instalacion']?.toString() ?? '0') ?? 0;
        final compareInstalacion = instalacionA.compareTo(instalacionB);
        
        if (compareInstalacion != 0) return compareInstalacion;
        
        final tipoConsumoA = a['tipo_consumo']?.toString() ?? '';
        final tipoConsumoB = b['tipo_consumo']?.toString() ?? '';
        return tipoConsumoA.compareTo(tipoConsumoB);
      });
    });
  }

  Future<void> _loadRegistros() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final user = supabase.auth.currentUser;
      if (user == null) {
        setState(() {
          _errorMessage = 'Usuario no autenticado';
          _isLoading = false;
        });
        return;
      }

      // Obtener el codigo_sup_aux del usuario logueado
      final profileData = await supabase
          .from('perfiles')
          .select('codigo_sup_aux')
          .eq('email', user.email!)
          .maybeSingle();

      if (profileData == null || profileData['codigo_sup_aux'] == null) {
        setState(() {
          _errorMessage = 'No se encontró el código de supervisor/auxiliar';
          _isLoading = false;
        });
        return;
      }

      _codigoSupAux = profileData['codigo_sup_aux'].toString();

      // Buscar registros en secuencia_sin_lectura donde cod_lector coincida con codigo_sup_aux
      final data = await supabase
          .from('secuencia_sin_lectura')
          .select('*')
          .eq('cod_lector', _codigoSupAux)
          .order('consecutivo_reporte', ascending: true);

      if (mounted) {
        setState(() {
          _registros = List<Map<String, dynamic>>.from(data);
          _registrosFiltrados = List.from(_registros);
          
          // Ordenar por nro_instalacion y luego por tipo_consumo
          _registrosFiltrados.sort((a, b) {
            final instalacionA = int.tryParse(a['nro_instalacion']?.toString() ?? '0') ?? 0;
            final instalacionB = int.tryParse(b['nro_instalacion']?.toString() ?? '0') ?? 0;
            final compareInstalacion = instalacionA.compareTo(instalacionB);
            
            if (compareInstalacion != 0) return compareInstalacion;
            
            final tipoConsumoA = a['tipo_consumo']?.toString() ?? '';
            final tipoConsumoB = b['tipo_consumo']?.toString() ?? '';
            return tipoConsumoA.compareTo(tipoConsumoB);
          });
          
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _errorMessage = 'Error al cargar registros: ${e.toString()}';
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'CONTINGENCIA LECTURA',
          style: TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
          ),
        ),
        backgroundColor: const Color(0xFF1A237E),
        iconTheme: const IconThemeData(color: Colors.white),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadRegistros,
            tooltip: 'Actualizar',
          ),
        ],
      ),
      body: _isLoading
          ? const Center(
              child: CircularProgressIndicator(
                color: Color(0xFF1A237E),
              ),
            )
          : _errorMessage != null
              ? Center(
                  child: Padding(
                    padding: const EdgeInsets.all(24),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.error_outline,
                          size: 64,
                          color: Colors.red.shade300,
                        ),
                        const SizedBox(height: 16),
                        Text(
                          _errorMessage!,
                          textAlign: TextAlign.center,
                          style: const TextStyle(
                            fontSize: 16,
                            color: Colors.black87,
                          ),
                        ),
                        const SizedBox(height: 24),
                        ElevatedButton.icon(
                          onPressed: _loadRegistros,
                          icon: const Icon(Icons.refresh),
                          label: const Text('Reintentar'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF1A237E),
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(
                              horizontal: 24,
                              vertical: 12,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                )
              : _registros.isEmpty
                  ? Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.check_circle_outline,
                            size: 80,
                            color: Colors.green.shade300,
                          ),
                          const SizedBox(height: 16),
                          const Text(
                            'No hay registros de contingencia',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: Colors.black87,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'Lector: $_codigoSupAux',
                            style: TextStyle(
                              fontSize: 14,
                              color: Colors.grey.shade600,
                            ),
                          ),
                        ],
                      ),
                    )
                  : Column(
                      children: [
                        // Header con contador
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
                          child: Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 12,
                                  vertical: 6,
                                ),
                                decoration: BoxDecoration(
                                  color: const Color(0xFF1A237E),
                                  borderRadius: BorderRadius.circular(20),
                                ),
                                child: Text(
                                  '${_registros.length}',
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontWeight: FontWeight.bold,
                                    fontSize: 14,
                                  ),
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Text(
                                  'Lector: $_codigoSupAux',
                                  style: TextStyle(
                                    fontSize: 14,
                                    color: Colors.grey.shade700,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                        // Campo de búsqueda
                        Padding(
                          padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
                          child: TextField(
                            controller: _searchController,
                            decoration: InputDecoration(
                              hintText: 'Buscar por instalación o dirección...',
                              prefixIcon: const Icon(Icons.search, color: Color(0xFF1A237E)),
                              filled: true,
                              fillColor: Colors.grey.shade100,
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                                borderSide: BorderSide.none,
                              ),
                              contentPadding: const EdgeInsets.symmetric(
                                horizontal: 16,
                                vertical: 12,
                              ),
                            ),
                          ),
                        ),
                        // Filtro por tipo de consumo
                        Padding(
                          padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                            decoration: BoxDecoration(
                              color: Colors.grey.shade100,
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: DropdownButtonHideUnderline(
                              child: DropdownButton<String>(
                                value: _tipoConsumoSeleccionado ?? 'Todos',
                                isExpanded: true,
                                icon: const Icon(Icons.filter_list, color: Color(0xFF1A237E)),
                                style: const TextStyle(
                                  fontSize: 14,
                                  color: Colors.black87,
                                ),
                                items: _obtenerTiposConsumoUnicos().map((String tipo) {
                                  return DropdownMenuItem<String>(
                                    value: tipo,
                                    child: Text(
                                      tipo == 'Todos' ? 'Tipo de Consumo: Todos' : tipo,
                                      style: TextStyle(
                                        fontWeight: tipo == 'Todos' ? FontWeight.bold : FontWeight.normal,
                                      ),
                                    ),
                                  );
                                }).toList(),
                                onChanged: (String? nuevoValor) {
                                  setState(() {
                                    _tipoConsumoSeleccionado = nuevoValor;
                                  });
                                  _aplicarFiltrosCombinados();
                                },
                              ),
                            ),
                          ),
                        ),
                        // Botones de filtrado
                        Padding(
                          padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                          child: Row(
                            children: [
                              Expanded(
                                child: ElevatedButton.icon(
                                  onPressed: _filtrarSinLectura,
                                  icon: const Icon(Icons.remove_circle_outline, size: 20),
                                  label: const Text('SIN LECTURA'),
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: Colors.orange.shade700,
                                    foregroundColor: Colors.white,
                                    padding: const EdgeInsets.symmetric(vertical: 12),
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(10),
                                    ),
                                  ),
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: ElevatedButton.icon(
                                  onPressed: _filtrarConLectura,
                                  icon: const Icon(Icons.check_circle_outline, size: 20),
                                  label: const Text('CON LECTURA'),
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: Colors.green.shade700,
                                    foregroundColor: Colors.white,
                                    padding: const EdgeInsets.symmetric(vertical: 12),
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(10),
                                    ),
                                  ),
                                ),
                              ),
                              const SizedBox(width: 12),
                              ElevatedButton(
                                onPressed: _limpiarFiltro,
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: Colors.grey.shade600,
                                  foregroundColor: Colors.white,
                                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(10),
                                  ),
                                ),
                                child: const Icon(Icons.clear_all, size: 20),
                              ),
                            ],
                          ),
                        ),
                        // Lista de registros
                        Expanded(
                          child: _registrosFiltrados.isEmpty
                              ? Center(
                                  child: Text(
                                    _searchController.text.isEmpty
                                        ? 'No hay registros'
                                        : 'No se encontraron coincidencias',
                                    style: TextStyle(
                                      fontSize: 16,
                                      color: Colors.grey.shade600,
                                    ),
                                  ),
                                )
                              : ListView.builder(
                            padding: const EdgeInsets.all(16),
                            itemCount: _registrosFiltrados.length,
                            itemBuilder: (context, index) {
                              final item = _registrosFiltrados[index];
                              final instalacion = item['nro_instalacion']?.toString() ?? 'Sin instalación';
                              final direccion = item['direccion']?.toString() ?? 'Sin dirección';

                              return Card(
                                margin: const EdgeInsets.only(bottom: 12),
                                elevation: 2,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: InkWell(
                                  borderRadius: BorderRadius.circular(12),
                                  onTap: () {
                                    Navigator.push(
                                      context,
                                      MaterialPageRoute(
                                        builder: (context) => EditarContingenciaScreen(
                                          registros: _registrosFiltrados,
                                          indexInicial: index,
                                        ),
                                      ),
                                    );
                                  },
                                  child: Padding(
                                    padding: const EdgeInsets.all(16),
                                    child: Row(
                                      children: [
                                        // Número de registro
                                        Container(
                                          width: 50,
                                          height: 50,
                                          decoration: BoxDecoration(
                                            color: const Color(0xFF1A237E),
                                            borderRadius: BorderRadius.circular(25),
                                          ),
                                          child: Center(
                                            child: Text(
                                              '${index + 1}',
                                              style: const TextStyle(
                                                color: Colors.white,
                                                fontWeight: FontWeight.bold,
                                                fontSize: 18,
                                              ),
                                            ),
                                          ),
                                        ),
                                        const SizedBox(width: 16),
                                        // Información
                                        Expanded(
                                          child: Column(
                                            crossAxisAlignment: CrossAxisAlignment.start,
                                            children: [
                                              Row(
                                                children: [
                                                  const Icon(
                                                    Icons.home,
                                                    size: 16,
                                                    color: Color(0xFF1A237E),
                                                  ),
                                                  const SizedBox(width: 4),
                                                  Expanded(
                                                    child: Text(
                                                      'Instalación: $instalacion',
                                                      style: const TextStyle(
                                                        fontWeight: FontWeight.bold,
                                                        fontSize: 15,
                                                        color: Colors.black87,
                                                      ),
                                                      maxLines: 1,
                                                      overflow: TextOverflow.ellipsis,
                                                    ),
                                                  ),
                                                ],
                                              ),
                                              const SizedBox(height: 8),
                                              Row(
                                                children: [
                                                  const Icon(
                                                    Icons.location_on,
                                                    size: 16,
                                                    color: Colors.grey,
                                                  ),
                                                  const SizedBox(width: 4),
                                                  Expanded(
                                                    child: Text(
                                                      direccion,
                                                      style: TextStyle(
                                                        fontSize: 14,
                                                        color: Colors.grey.shade700,
                                                      ),
                                                      maxLines: 2,
                                                      overflow: TextOverflow.ellipsis,
                                                    ),
                                                  ),
                                                ],
                                              ),
                                            ],
                                          ),
                                        ),
                                        // Icono de flecha
                                        const Icon(
                                          Icons.chevron_right,
                                          color: Color(0xFF1A237E),
                                          size: 28,
                                        ),
                                      ],
                                    ),
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
}
