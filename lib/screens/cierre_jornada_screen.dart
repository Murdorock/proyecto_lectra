import 'package:flutter/material.dart';
import '../main.dart';
import '../services/user_session.dart';
import 'editar_registro_salida_screen.dart';

class CierreJornadaScreen extends StatefulWidget {
  const CierreJornadaScreen({super.key});

  @override
  State<CierreJornadaScreen> createState() => _CierreJornadaScreenState();
}

class _CierreJornadaScreenState extends State<CierreJornadaScreen> {
  List<Map<String, dynamic>> _lectores = [];
  List<Map<String, dynamic>> _lectoresFiltrados = [];
  bool _isLoading = true;
  String? _errorMessage;
  int _totalCodigos = 0;
  int _codigosConRegistro = 0;
  int _codigosPendientes = 0;
  int _codigosConHoraLlegada = 0;
  int _codigosConHoraCierre = 0;
  final TextEditingController _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _loadLectores();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _filtrarLectores(String query) {
    setState(() {
      if (query.isEmpty) {
        _lectoresFiltrados = _lectores;
      } else {
        _lectoresFiltrados = _lectores.where((lector) {
          final idLector = lector['id_lector']?.toString().toLowerCase() ?? '';
          final searchLower = query.toLowerCase();
          return idLector.contains(searchLower);
        }).toList();
      }
    });
  }

  Future<void> _loadLectores() async {
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

      // Consultar la tabla base filtrando por supervisor
      final data = await supabase
          .from('base')
          .select('id_lector, registro_salida, inicio_jornada')
          .eq('supervisor', codigoSupAux)
          .order('id_lector', ascending: true);

      if (mounted) {
        // Contar códigos con y sin registro
        int conRegistro = 0;
        int pendientes = 0;
        int conHoraLlegada = 0;
        int conHoraCierre = 0;

        for (var item in data) {
          if (item['registro_salida'] != null && item['registro_salida'].toString().isNotEmpty) {
            conRegistro++;
            conHoraCierre++;
          } else {
            pendientes++;
          }
          
          if (item['inicio_jornada'] != null && item['inicio_jornada'].toString().isNotEmpty) {
            conHoraLlegada++;
          }
        }

        setState(() {
          _lectores = List<Map<String, dynamic>>.from(data);
          _lectoresFiltrados = _lectores;
          _totalCodigos = data.length;
          _codigosConRegistro = conRegistro;
          _codigosPendientes = pendientes;
          _codigosConHoraLlegada = conHoraLlegada;
          _codigosConHoraCierre = conHoraCierre;
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
        title: const Text('INICIO - CIERRE JORNADA'),
        backgroundColor: const Color(0xFF1A237E),
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadLectores,
            tooltip: 'Actualizar',
          ),
        ],
      ),
      body: Column(
        children: [
          // Header con estadísticas
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              border: Border(
                bottom: BorderSide(
                  color: Colors.grey.shade300,
                  width: 1,
                ),
              ),
            ),
            child: Row(
              children: [
                // Total Códigos
                Expanded(
                  child: _buildStatCard(
                    icon: Icons.code,
                    value: '$_totalCodigos',
                    label: 'Total Códigos',
                    color: const Color(0xFF1A237E),
                  ),
                ),
                const SizedBox(width: 8),
                // Con Hora Llegada
                Expanded(
                  child: _buildStatCard(
                    icon: Icons.login,
                    value: '$_codigosConHoraLlegada/$_totalCodigos',
                    label: 'Hora Llegada',
                    color: Colors.green.shade700,
                  ),
                ),
                const SizedBox(width: 8),
                // Con Hora Cierre
                Expanded(
                  child: _buildStatCard(
                    icon: Icons.logout,
                    value: '$_codigosConHoraCierre/$_totalCodigos',
                    label: 'Hora Cierre',
                    color: Colors.orange.shade700,
                  ),
                ),
              ],
            ),
          ),

          // Campo de búsqueda (opcional, como en la imagen)
          Container(
            padding: const EdgeInsets.all(16),
            color: Colors.white,
            child: TextField(
              controller: _searchController,
              onChanged: _filtrarLectores,
              decoration: InputDecoration(
                hintText: 'Buscar código...',
                hintStyle: TextStyle(color: Colors.grey.shade600),
                prefixIcon: const Icon(
                  Icons.search,
                  color: Color(0xFF1A237E),
                ),
                suffixIcon: _searchController.text.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.clear),
                        onPressed: () {
                          _searchController.clear();
                          _filtrarLectores('');
                        },
                      )
                    : null,
                filled: true,
                fillColor: Colors.grey.shade50,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: const BorderSide(
                    color: Color(0xFF1A237E),
                    width: 2,
                  ),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: const BorderSide(
                    color: Color(0xFF1A237E),
                    width: 2,
                  ),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: const BorderSide(
                    color: Color(0xFF1A237E),
                    width: 2.5,
                  ),
                ),
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 12,
                ),
              ),
            ),
          ),

          // Lista de códigos
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
                        Text('Cargando códigos...'),
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
                                onPressed: _loadLectores,
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
                    : _lectoresFiltrados.isEmpty
                        ? Center(
                            child: Padding(
                              padding: const EdgeInsets.all(24.0),
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(
                                    Icons.inbox,
                                    size: 64,
                                    color: Colors.grey.shade400,
                                  ),
                                  const SizedBox(height: 16),
                                  Text(
                                    _searchController.text.isNotEmpty
                                        ? 'No se encontraron resultados'
                                        : 'No se encontraron códigos',
                                    style: TextStyle(
                                      fontSize: 16,
                                      color: Colors.grey.shade600,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          )
                        : ListView.builder(
                            padding: const EdgeInsets.all(16),
                            itemCount: _lectoresFiltrados.length,
                            itemBuilder: (context, index) {
                              final lector = _lectoresFiltrados[index];
                              final idLector = lector['id_lector']?.toString() ?? 'N/A';
                              final registroSalida = lector['registro_salida'];
                              final inicioJornada = lector['inicio_jornada'];
                              final tieneRegistro = registroSalida != null && registroSalida.toString().isNotEmpty;
                              final tieneHoraLlegada = inicioJornada != null && inicioJornada.toString().isNotEmpty;

                              return Card(
                                margin: const EdgeInsets.only(bottom: 12),
                                elevation: 2,
                                color: tieneRegistro
                                    ? const Color(0xFFC8E6C9) // Verde claro
                                    : Colors.white, // Blanco
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                  side: BorderSide(
                                    color: tieneRegistro
                                        ? Colors.green.shade400
                                        : const Color(0xFF1A237E),
                                    width: 2,
                                  ),
                                ),
                                child: ListTile(
                                  contentPadding: const EdgeInsets.symmetric(
                                    horizontal: 20,
                                    vertical: 12,
                                  ),
                                  leading: Container(
                                    width: 50,
                                    height: 50,
                                    decoration: BoxDecoration(
                                      color: tieneRegistro
                                          ? Colors.green.shade700
                                          : const Color(0xFF1A237E),
                                      shape: BoxShape.circle,
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
                                  title: Text(
                                    'Código: $idLector',
                                    style: const TextStyle(
                                      fontWeight: FontWeight.bold,
                                      fontSize: 16,
                                    ),
                                  ),
                                  subtitle: Padding(
                                    padding: const EdgeInsets.only(top: 4),
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          tieneRegistro
                                              ? 'Registro de salida completado'
                                              : 'Pendiente registro de salida',
                                          style: TextStyle(
                                            fontSize: 13,
                                            color: tieneRegistro
                                                ? Colors.green.shade900
                                                : const Color(0xFF1A237E),
                                            fontWeight: FontWeight.w600,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                  trailing: Icon(
                                    tieneRegistro ? Icons.check_circle : Icons.edit,
                                    color: tieneRegistro
                                        ? Colors.green.shade700
                                        : const Color(0xFF1A237E),
                                    size: 28,
                                  ),
                                  onTap: tieneRegistro 
                                    ? null // Deshabilitar edición para códigos con registro
                                    : () async {
                                    // Navegar a la pantalla de edición de registro
                                    final result = await Navigator.push(
                                      context,
                                      MaterialPageRoute(
                                        builder: (context) => EditarRegistroSalidaScreen(
                                          idLector: idLector,
                                        ),
                                      ),
                                    );
                                    // Si se guardaron cambios, recargar los datos
                                    if (result == true) {
                                      _loadLectores();
                                    }
                                  },
                                ),
                              );
                            },
                          ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatCard({
    required IconData icon,
    required String value,
    required String label,
    required Color color,
  }) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: color,
          width: 2,
        ),
      ),
      child: Column(
        children: [
          Icon(
            icon,
            color: color,
            size: 28,
          ),
          const SizedBox(height: 8),
          Text(
            value,
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            label,
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 11,
              color: Colors.grey.shade700,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}
