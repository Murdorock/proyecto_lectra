import 'package:flutter/material.dart';
import 'dart:async';
import '../main.dart';
import '../services/user_session.dart';

class ControlDescargasScreen extends StatefulWidget {
  const ControlDescargasScreen({super.key});

  @override
  State<ControlDescargasScreen> createState() => _ControlDescargasScreenState();
}

class _ControlDescargasScreenState extends State<ControlDescargasScreen> {
  List<Map<String, dynamic>> _descargas = [];
  List<Map<String, dynamic>> _descargasFiltradas = [];
  bool _isLoading = true;
  String? _errorMessage;
  final TextEditingController _searchController = TextEditingController();
  
  int _registrosEncontrados = 0;
  int _totalGeneral = 0;
  int _conPendientes = 0;
  
  DateTime? _ultimaActualizacion;
  Duration _tiempoTranscurrido = Duration.zero;
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _loadDescargas();
    _iniciarTimer();
  }

  void _iniciarTimer() {
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (_ultimaActualizacion != null) {
        setState(() {
          _tiempoTranscurrido = DateTime.now().difference(_ultimaActualizacion!);
        });
      }
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    _timer?.cancel();
    super.dispose();
  }

  Future<void> _loadDescargas() async {
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

      // Consultar la tabla control_descargas filtrando por supervisor
      final data = await supabase
          .from('control_descargas')
          .select('id_correria, codigo, totales, pendientes, descargadas')
          .eq('supervisor', codigoSupAux)
          .order('id_correria', ascending: true);
      
      // Obtener la última actualización de la tabla cmlec
      DateTime? ultimaActualizacion;
      try {
        // Ordenar por updated_at que es más reciente que created_at
        final ultimaActualizacionData = await supabase
            .from('cmlec')
            .select('created_at, updated_at')
            .order('updated_at', ascending: false)
            .limit(1);
        
        print('Datos recibidos de cmlec: $ultimaActualizacionData'); // Debug
        
        if (ultimaActualizacionData.isNotEmpty) {
          final registro = ultimaActualizacionData[0];
          // Usar updated_at si existe, sino created_at
          String? timestamp = registro['updated_at'] ?? registro['created_at'];
          
          if (timestamp != null) {
            // Convertir de UTC a hora local
            ultimaActualizacion = DateTime.parse(timestamp).toLocal();
            print('Última actualización obtenida: $ultimaActualizacion'); // Debug
          } else {
            print('Timestamp es null en el registro'); // Debug
          }
        } else {
          print('No se encontraron registros en cmlec'); // Debug
        }
      } catch (e) {
        print('Error al obtener última actualización de cmlec: $e'); // Debug
      }
      
      // Si no se pudo obtener de cmlec, mostrar un mensaje claro
      if (ultimaActualizacion == null) {
        print('ADVERTENCIA: No se pudo obtener la última actualización de cmlec'); // Debug
      }

      if (mounted) {
        // Calcular totales
        int totalSum = 0;
        int pendientesCount = 0;

        for (var item in data) {
          totalSum += (item['totales'] as int? ?? 0);
          if ((item['pendientes'] as int? ?? 0) > 0) {
            pendientesCount++;
          }
        }

        setState(() {
          _descargas = List<Map<String, dynamic>>.from(data);
          _descargasFiltradas = List<Map<String, dynamic>>.from(data);
          _registrosEncontrados = data.length;
          _totalGeneral = totalSum;
          _conPendientes = pendientesCount;
          _ultimaActualizacion = ultimaActualizacion;
          _tiempoTranscurrido = ultimaActualizacion != null 
              ? DateTime.now().difference(ultimaActualizacion) 
              : Duration.zero;
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

  void _filtrarDescargas(String query) {
    setState(() {
      if (query.isEmpty) {
        _descargasFiltradas = List<Map<String, dynamic>>.from(_descargas);
        _registrosEncontrados = _descargas.length;
      } else {
        _descargasFiltradas = _descargas.where((descarga) {
          final correria = descarga['id_correria']?.toString().toLowerCase() ?? '';
          final codigo = descarga['codigo']?.toString().toLowerCase() ?? '';
          final searchLower = query.toLowerCase();
          return correria.contains(searchLower) || codigo.contains(searchLower);
        }).toList();
        _registrosEncontrados = _descargasFiltradas.length;
      }
    });
  }

  String _calcularProgreso(int descargadas, int totales) {
    if (totales == 0) return '0.00';
    double progreso = (descargadas / totales) * 100;
    // Truncar a 2 decimales sin redondear
    String progresoStr = progreso.toStringAsFixed(4);
    int dotIndex = progresoStr.indexOf('.');
    return progresoStr.substring(0, dotIndex + 3);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('CONTROL DESCARGAS'),
        backgroundColor: const Color(0xFF1A237E),
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadDescargas,
            tooltip: 'Actualizar',
          ),
        ],
      ),
      body: Column(
        children: [
          // Barra de búsqueda
          Container(
            color: Colors.grey.shade100,
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _searchController,
                    decoration: InputDecoration(
                      hintText: 'Buscar por código...',
                      prefixIcon: const Icon(Icons.search),
                      filled: true,
                      fillColor: Colors.white,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                        borderSide: BorderSide.none,
                      ),
                    ),
                    onChanged: _filtrarDescargas,
                  ),
                ),
                const SizedBox(width: 12),
                ElevatedButton(
                  onPressed: () {
                    _searchController.clear();
                    _filtrarDescargas('');
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF1A237E),
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
                  ),
                  child: const Text('Limpiar'),
                ),
              ],
            ),
          ),

          // Contadores
          Container(
            padding: const EdgeInsets.all(16),
            color: Colors.white,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Registros encontrados: $_registrosEncontrados',
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 14,
                    color: Color(0xFF1A237E),
                  ),
                ),
                Text(
                  'Total general: $_totalGeneral',
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 14,
                    color: Color(0xFF1A237E),
                  ),
                ),
              ],
            ),
          ),

          // Contador de pendientes
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            color: Colors.white,
            alignment: Alignment.centerLeft,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              decoration: BoxDecoration(
                color: const Color(0xFF1A237E),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Text(
                'Con pendientes: $_conPendientes',
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 14,
                  color: Colors.white,
                ),
              ),
            ),
          ),

          // Última actualización y tiempo transcurrido
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
            color: Colors.white,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Última actualización: ${_ultimaActualizacion != null ? "${_ultimaActualizacion!.hour.toString().padLeft(2, '0')}:${_ultimaActualizacion!.minute.toString().padLeft(2, '0')}:${_ultimaActualizacion!.second.toString().padLeft(2, '0')}" : "N/A"}',
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey.shade700,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  'Tiempo transcurrido: ${_tiempoTranscurrido.inMinutes}m ${_tiempoTranscurrido.inSeconds % 60}s',
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey.shade700,
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 8),

          // Lista de descargas
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
                                onPressed: _loadDescargas,
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
                    : _descargasFiltradas.isEmpty
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
                                    'No se encontraron registros',
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
                            itemCount: _descargasFiltradas.length,
                            itemBuilder: (context, index) {
                              final descarga = _descargasFiltradas[index];
                              final correria = descarga['id_correria']?.toString() ?? 'N/A';
                              final codigo = descarga['codigo']?.toString() ?? 'N/A';
                              final totales = descarga['totales'] as int? ?? 0;
                              final pendientes = descarga['pendientes'] as int? ?? 0;
                              final descargadas = descarga['descargadas'] as int? ?? 0;
                              final progreso = _calcularProgreso(descargadas, totales);

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
                                      // Título con correria y código
                                      Row(
                                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                        children: [
                                          Expanded(
                                            child: Text(
                                              'Correría $correria',
                                              style: const TextStyle(
                                                fontSize: 18,
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
                                              color: Colors.grey.shade100,
                                              borderRadius: BorderRadius.circular(12),
                                              border: Border.all(
                                                color: Colors.grey.shade300,
                                                width: 1,
                                              ),
                                            ),
                                            child: Text(
                                              'Código: $codigo',
                                              style: const TextStyle(
                                                fontSize: 12,
                                                fontWeight: FontWeight.bold,
                                                color: Color(0xFF1A237E),
                                              ),
                                            ),
                                          ),
                                        ],
                                      ),
                                      const SizedBox(height: 16),

                                      // Tres tarjetas con totales, pendientes y descargadas
                                      Row(
                                        children: [
                                          Expanded(
                                            child: _buildInfoCard(
                                              icon: Icons.inventory_2,
                                              value: totales.toString(),
                                              label: 'TOTALES',
                                              color: const Color(0xFF1A237E),
                                            ),
                                          ),
                                          const SizedBox(width: 8),
                                          Expanded(
                                            child: _buildInfoCard(
                                              icon: Icons.pending_actions,
                                              value: pendientes.toString(),
                                              label: 'PENDIENTES',
                                              color: Colors.red,
                                            ),
                                          ),
                                          const SizedBox(width: 8),
                                          Expanded(
                                            child: _buildInfoCard(
                                              icon: Icons.check_circle,
                                              value: descargadas.toString(),
                                              label: 'DESCARGADAS',
                                              color: Colors.green,
                                              fontSize: 9,
                                            ),
                                          ),
                                        ],
                                      ),
                                      const SizedBox(height: 16),

                                      // Barra de progreso
                                      Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            'Progreso: $progreso%',
                                            style: const TextStyle(
                                              fontWeight: FontWeight.bold,
                                              fontSize: 14,
                                              color: Color(0xFF1A237E),
                                            ),
                                          ),
                                          const SizedBox(height: 8),
                                          ClipRRect(
                                            borderRadius: BorderRadius.circular(8),
                                            child: LinearProgressIndicator(
                                              value: double.parse(progreso) / 100,
                                              backgroundColor: Colors.grey.shade300,
                                              valueColor: AlwaysStoppedAnimation<Color>(
                                                double.parse(progreso) >= 100 ? Colors.green : Colors.red,
                                              ),
                                              minHeight: 10,
                                            ),
                                          ),
                                        ],
                                      ),
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

  Widget _buildInfoCard({
    required IconData icon,
    required String value,
    required String label,
    required Color color,
    double fontSize = 10,
  }) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: color.withValues(alpha: 0.3),
          width: 1,
        ),
      ),
      child: Column(
        children: [
          Icon(
            icon,
            color: color,
            size: 24,
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
            style: TextStyle(
              fontSize: fontSize,
              fontWeight: FontWeight.bold,
              color: color.withValues(alpha: 0.8),
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}
