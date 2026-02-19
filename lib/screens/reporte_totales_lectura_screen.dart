import 'package:flutter/material.dart';
import '../main.dart';
import '../services/user_session.dart';
import 'editar_reporte_totales_screen.dart';

class ReporteTotalesLecturaScreen extends StatefulWidget {
  const ReporteTotalesLecturaScreen({super.key});

  @override
  State<ReporteTotalesLecturaScreen> createState() => _ReporteTotalesLecturaScreenState();
}

class _ReporteTotalesLecturaScreenState extends State<ReporteTotalesLecturaScreen> {
  Map<String, List<Map<String, dynamic>>> _programacionesAgrupadas = {};
  Map<String, List<Map<String, dynamic>>> _programacionesFiltradas = {};
  final TextEditingController _searchController = TextEditingController();
  bool _isLoading = true;
  String? _errorMessage;
  int _totalCorreriasUnicas = 0;
  int _correriasReportadas = 0;

  @override
  void initState() {
    super.initState();
    _loadProgramaciones();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _filterProgramaciones(String query) {
    setState(() {
      if (query.isEmpty) {
        _programacionesFiltradas = Map.from(_programacionesAgrupadas);
      } else {
        _programacionesFiltradas = {};
        _programacionesAgrupadas.forEach((codigo, correrias) {
          // Buscar por código o por correría
          if (codigo.toLowerCase().contains(query.toLowerCase()) ||
              correrias.any((c) => c['correria'].toString().toLowerCase().contains(query.toLowerCase()))) {
            _programacionesFiltradas[codigo] = correrias;
          }
        });
      }
    });
  }

  Future<void> _loadProgramaciones() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
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
      
      // Obtener el código del supervisor auxiliar logueado
      final codigoSupAux = UserSession().codigoSupAux;

      if (codigoSupAux == null || codigoSupAux.isEmpty) {
        setState(() {
          _errorMessage = 'No se pudo obtener el código del usuario';
          _isLoading = false;
        });
        return;
      }

      // Consultar programación_lectura filtrando por realiza_zona
      final data = await supabase
          .from('programacion_lectura')
          .select('codigo, correria, totales_supervisor')
          .eq('realiza_zona', codigoSupAux)
          .order('codigo', ascending: true);

      if (mounted) {
        // Agrupar correrias por código
        final Map<String, List<Map<String, dynamic>>> agrupadas = {};
        final Set<String> correriasUnicas = {};
        int reportadas = 0;
        
        for (var item in data) {
          final codigo = item['codigo']?.toString() ?? 'N/A';
          final correria = item['correria']?.toString() ?? 'N/A';
          final totalesSupervisor = item['totales_supervisor'];
          
          correriasUnicas.add(correria);
          
          // Contar las correrias con reporte
          if (totalesSupervisor != null) {
            reportadas++;
          }
          
          final correriaData = {
            'correria': correria,
            'tiene_reporte': totalesSupervisor != null,
          };
          
          if (agrupadas.containsKey(codigo)) {
            // Verificar si la correría ya existe
            final existe = agrupadas[codigo]!.any((c) => c['correria'] == correria);
            if (!existe) {
              agrupadas[codigo]!.add(correriaData);
            }
          } else {
            agrupadas[codigo] = [correriaData];
          }
        }

        setState(() {
          _programacionesAgrupadas = agrupadas;
          _programacionesFiltradas = Map.from(agrupadas);
          _totalCorreriasUnicas = correriasUnicas.length;
          _correriasReportadas = reportadas;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _errorMessage = 'Error al cargar los datos: ${e.toString()}';
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Reporte Totales Lectura'),
        backgroundColor: const Color(0xFF1A237E),
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadProgramaciones,
            tooltip: 'Actualizar',
          ),
        ],
      ),
      body: Column(
        children: [
          // Header con información
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: const Color(0xFF1A237E).withValues(alpha: 0.05),
              border: Border(
                bottom: BorderSide(
                  color: Colors.grey.shade300,
                  width: 1,
                ),
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(
                      Icons.person,
                      size: 20,
                      color: Colors.grey.shade700,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      'Supervisor: ${UserSession().nombreCompleto ?? "N/A"}',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                        color: Colors.grey.shade700,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Row(
                  children: [
                    Icon(
                      Icons.badge,
                      size: 20,
                      color: Colors.grey.shade700,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      'Código: ${UserSession().codigoSupAux ?? "N/A"}',
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.grey.shade600,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),

          // Filtro de búsqueda y estadísticas
          if (!_isLoading && _errorMessage == null)
            Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.05),
                  blurRadius: 4,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Column(
              children: [
                // Campo de búsqueda
                TextField(
                  controller: _searchController,
                  onChanged: _filterProgramaciones,
                  decoration: InputDecoration(
                    hintText: 'Buscar por código o correría...',
                    hintStyle: TextStyle(color: Colors.grey.shade400),
                    prefixIcon: Icon(
                      Icons.search,
                      color: Colors.grey.shade600,
                    ),
                    suffixIcon: _searchController.text.isNotEmpty
                        ? IconButton(
                            icon: const Icon(Icons.clear),
                            onPressed: () {
                              _searchController.clear();
                              _filterProgramaciones('');
                            },
                          )
                        : null,
                    filled: true,
                    fillColor: Colors.grey.shade100,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide.none,
                    ),
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 14,
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                // Contadores de estadísticas
                Row(
                  children: [
                    Expanded(
                      child: Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: const Color(0xFF1A237E).withValues(alpha: 0.08),
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(
                            color: const Color(0xFF1A237E).withValues(alpha: 0.2),
                            width: 1,
                          ),
                        ),
                        child: Column(
                          children: [
                            Icon(
                              Icons.numbers,
                              color: const Color(0xFF1A237E),
                              size: 24,
                            ),
                            const SizedBox(height: 4),
                            Text(
                              '${_programacionesFiltradas.length}',
                              style: const TextStyle(
                                fontSize: 20,
                                fontWeight: FontWeight.bold,
                                color: Color(0xFF1A237E),
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              'Códigos',
                              style: TextStyle(
                                fontSize: 12,
                                color: Colors.grey.shade700,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: const Color(0xFF1A237E).withValues(alpha: 0.08),
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(
                            color: const Color(0xFF1A237E).withValues(alpha: 0.2),
                            width: 1,
                          ),
                        ),
                        child: Column(
                          children: [
                            Icon(
                              Icons.route,
                              color: const Color(0xFF1A237E),
                              size: 24,
                            ),
                            const SizedBox(height: 4),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              crossAxisAlignment: CrossAxisAlignment.baseline,
                              textBaseline: TextBaseline.alphabetic,
                              children: [
                                Text(
                                  '$_correriasReportadas',
                                  style: const TextStyle(
                                    fontSize: 20,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.green,
                                  ),
                                ),
                                Text(
                                  '/',
                                  style: TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.grey.shade600,
                                  ),
                                ),
                                Text(
                                  '$_totalCorreriasUnicas',
                                  style: const TextStyle(
                                    fontSize: 20,
                                    fontWeight: FontWeight.bold,
                                    color: Color(0xFF1A237E),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 2),
                            Text(
                              'Correrias',
                              style: TextStyle(
                                fontSize: 12,
                                color: Colors.grey.shade700,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          
          // Contenido principal
          Expanded(
            child: _isLoading
                ? const Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        CircularProgressIndicator(
                          valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF1A237E)),
                        ),
                        SizedBox(height: 16),
                        Text('Cargando programaciones...'),
                      ],
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
                                color: Colors.red.shade300,
                              ),
                              const SizedBox(height: 16),
                              Text(
                                _errorMessage!,
                                textAlign: TextAlign.center,
                                style: const TextStyle(fontSize: 16),
                              ),
                              const SizedBox(height: 24),
                              ElevatedButton.icon(
                                onPressed: _loadProgramaciones,
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
                    : _programacionesFiltradas.isEmpty
                        ? Center(
                            child: Padding(
                              padding: const EdgeInsets.all(24.0),
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(
                                    Icons.search_off,
                                    size: 64,
                                    color: Colors.grey.shade400,
                                  ),
                                  const SizedBox(height: 16),
                                  Text(
                                    'No se encontraron resultados',
                                    style: TextStyle(
                                      fontSize: 16,
                                      color: Colors.grey.shade600,
                                    ),
                                  ),
                                  const SizedBox(height: 8),
                                  Text(
                                    'Intenta con otro término de búsqueda',
                                    style: TextStyle(
                                      fontSize: 14,
                                      color: Colors.grey.shade500,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          )
                        : ListView.builder(
                            padding: const EdgeInsets.all(16),
                            itemCount: _programacionesFiltradas.length,
                            itemBuilder: (context, index) {
                              final codigo = _programacionesFiltradas.keys.elementAt(index);
                              final correrias = _programacionesFiltradas[codigo]!;
                              
                              return Card(
                                margin: const EdgeInsets.only(bottom: 12),
                                elevation: 2,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                  side: BorderSide(
                                    color: const Color(0xFF1A237E).withValues(alpha: 0.2),
                                    width: 1,
                                  ),
                                ),
                                child: Padding(
                                  padding: const EdgeInsets.all(16.0),
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      // Header con código e icono
                                      Row(
                                        children: [
                                          Container(
                                            width: 50,
                                            height: 50,
                                            decoration: BoxDecoration(
                                              color: const Color(0xFF1A237E).withValues(alpha: 0.1),
                                              borderRadius: BorderRadius.circular(8),
                                            ),
                                            child: const Icon(
                                              Icons.description,
                                              color: Color(0xFF1A237E),
                                              size: 28,
                                            ),
                                          ),
                                          const SizedBox(width: 12),
                                          Expanded(
                                            child: Column(
                                              crossAxisAlignment: CrossAxisAlignment.start,
                                              children: [
                                                Text(
                                                  'Código: $codigo',
                                                  style: const TextStyle(
                                                    fontWeight: FontWeight.bold,
                                                    fontSize: 16,
                                                    color: Color(0xFF1A237E),
                                                  ),
                                                ),
                                                const SizedBox(height: 4),
                                                Text(
                                                  '${correrias.length} ${correrias.length == 1 ? 'correría' : 'correrias'}',
                                                  style: TextStyle(
                                                    fontSize: 13,
                                                    color: Colors.grey.shade600,
                                                    fontWeight: FontWeight.w500,
                                                  ),
                                                ),
                                              ],
                                            ),
                                          ),
                                          Container(
                                            padding: const EdgeInsets.symmetric(
                                              horizontal: 12,
                                              vertical: 6,
                                            ),
                                            decoration: BoxDecoration(
                                              color: const Color(0xFF1A237E),
                                              borderRadius: BorderRadius.circular(12),
                                            ),
                                            child: Text(
                                              '${correrias.length}',
                                              style: const TextStyle(
                                                color: Colors.white,
                                                fontWeight: FontWeight.bold,
                                                fontSize: 14,
                                              ),
                                            ),
                                          ),
                                        ],
                                      ),
                                      const SizedBox(height: 16),
                                      const Divider(height: 1),
                                      const SizedBox(height: 16),
                                      // Lista de correrias
                                      Row(
                                        children: [
                                          Icon(
                                            Icons.route,
                                            size: 18,
                                            color: Colors.grey.shade700,
                                          ),
                                          const SizedBox(width: 8),
                                          Text(
                                            'Correrias asignadas:',
                                            style: TextStyle(
                                              fontSize: 14,
                                              fontWeight: FontWeight.bold,
                                              color: Colors.grey.shade800,
                                            ),
                                          ),
                                        ],
                                      ),
                                      const SizedBox(height: 12),
                                      Wrap(
                                        spacing: 8,
                                        runSpacing: 8,
                                        children: correrias.map((correriaData) {
                                          final correria = correriaData['correria'] as String;
                                          final tieneReporte = correriaData['tiene_reporte'] as bool;
                                          final color = tieneReporte ? Colors.green : Colors.red;
                                          
                                          return InkWell(
                                            onTap: () async {
                                              // Navegar a la pantalla de edición
                                              final result = await Navigator.push(
                                                context,
                                                MaterialPageRoute(
                                                  builder: (context) => EditarReporteTotalesScreen(
                                                    codigo: codigo,
                                                    correria: correria,
                                                  ),
                                                ),
                                              );
                                              // Si se guardaron cambios, recargar los datos
                                              if (result == true) {
                                                _loadProgramaciones();
                                              }
                                            },
                                            borderRadius: BorderRadius.circular(8),
                                            child: Container(
                                              padding: const EdgeInsets.symmetric(
                                                horizontal: 12,
                                                vertical: 8,
                                              ),
                                              decoration: BoxDecoration(
                                                color: color.withValues(alpha: 0.1),
                                                borderRadius: BorderRadius.circular(8),
                                                border: Border.all(
                                                  color: color.withValues(alpha: 0.5),
                                                  width: 1.5,
                                                ),
                                              ),
                                              child: Row(
                                                mainAxisSize: MainAxisSize.min,
                                                children: [
                                                  Icon(
                                                    tieneReporte ? Icons.check_circle : Icons.cancel,
                                                    size: 16,
                                                    color: color,
                                                  ),
                                                  const SizedBox(width: 6),
                                                  Text(
                                                    correria,
                                                    style: TextStyle(
                                                      fontSize: 13,
                                                      fontWeight: FontWeight.w600,
                                                      color: color,
                                                    ),
                                                  ),
                                                  const SizedBox(width: 6),
                                                  Icon(
                                                    Icons.edit,
                                                    size: 14,
                                                    color: color,
                                                  ),
                                                ],
                                              ),
                                            ),
                                          );
                                        }).toList(),
                                      ),
                                    ],
                                  ),
                                ),
                              );
                            },
                          ),
          ),

          // Footer con contador
          if (!_isLoading && _errorMessage == null && _programacionesFiltradas.isNotEmpty)
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.grey.shade100,
                border: Border(
                  top: BorderSide(
                    color: Colors.grey.shade300,
                    width: 1,
                  ),
                ),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.list_alt,
                    size: 20,
                    color: Colors.grey.shade700,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    'Mostrando ${_programacionesFiltradas.length} de ${_programacionesAgrupadas.length} códigos',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                      color: Colors.grey.shade700,
                    ),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }
}
