import 'package:flutter/material.dart';
import '../main.dart';
import '../services/user_session.dart';
import 'editar_error_screen.dart';

class RefutarErroresScreen extends StatefulWidget {
  const RefutarErroresScreen({super.key});

  @override
  State<RefutarErroresScreen> createState() => _RefutarErroresScreenState();
}

class _RefutarErroresScreenState extends State<RefutarErroresScreen> {
  List<Map<String, dynamic>> _errores = [];
  bool _isLoading = true;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _loadErrores();
  }

  Future<void> _loadErrores() async {
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

      // Consultar la tabla refutar_errores filtrando por lector
      final data = await supabase
          .from('refutar_errores')
          .select('id, direccion, instalacion, consumo, lector, evidencia1')
          .eq('lector', codigoSupAux)
          .order('instalacion', ascending: true);

      if (mounted) {
        setState(() {
          _errores = List<Map<String, dynamic>>.from(data);
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
        title: const Text('Refutar Errores'),
        backgroundColor: const Color(0xFF1A237E),
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadErrores,
            tooltip: 'Actualizar',
          ),
        ],
      ),
      body: Column(
        children: [
          // Contador de errores
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(16),
            color: const Color(0xFF1A237E),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Errores a Refutar',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 8,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    '${_errores.length}',
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF1A237E),
                    ),
                  ),
                ),
              ],
            ),
          ),

          // Lista de errores
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
                                onPressed: _loadErrores,
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
                    : _errores.isEmpty
                        ? Center(
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(
                                  Icons.check_circle_outline,
                                  size: 64,
                                  color: Colors.green.shade300,
                                ),
                                const SizedBox(height: 16),
                                Text(
                                  'No hay errores pendientes de refutar',
                                  style: TextStyle(
                                    fontSize: 16,
                                    color: Colors.grey.shade600,
                                  ),
                                ),
                              ],
                            ),
                          )
                        : ListView.builder(
                            padding: const EdgeInsets.all(16),
                            itemCount: _errores.length,
                            itemBuilder: (context, index) {
                              final error = _errores[index];
                              final direccion = error['direccion']?.toString() ?? 'N/A';
                              final instalacion = error['instalacion']?.toString() ?? 'N/A';
                              final consumo = error['consumo']?.toString() ?? 'N/A';
                              final tieneEvidencia = error['evidencia1'] != null && 
                                  error['evidencia1'].toString().isNotEmpty;

                              return Card(
                                margin: const EdgeInsets.only(bottom: 12),
                                elevation: 3,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                  side: BorderSide(
                                    color: tieneEvidencia 
                                        ? const Color(0xFF4CAF50) 
                                        : const Color(0xFF1A237E),
                                    width: 2,
                                  ),
                                ),
                                child: InkWell(
                                  onTap: () async {
                                    final result = await Navigator.push(
                                      context,
                                      MaterialPageRoute(
                                        builder: (context) => EditarErrorScreen(
                                          error: error,
                                        ),
                                      ),
                                    );
                                    
                                    if (result == true) {
                                      _loadErrores();
                                    }
                                  },
                                  borderRadius: BorderRadius.circular(12),
                                  child: Padding(
                                    padding: const EdgeInsets.all(16),
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        // Encabezado
                                        Row(
                                          children: [
                                            Container(
                                              padding: const EdgeInsets.all(8),
                                              decoration: BoxDecoration(
                                                color: tieneEvidencia 
                                                    ? Colors.green.shade100
                                                    : Colors.red.shade100,
                                                borderRadius: BorderRadius.circular(8),
                                              ),
                                              child: Icon(
                                                tieneEvidencia 
                                                    ? Icons.check_circle_outline
                                                    : Icons.error_outline,
                                                color: tieneEvidencia 
                                                    ? Colors.green.shade700
                                                    : Colors.red.shade700,
                                                size: 24,
                                              ),
                                            ),
                                            const SizedBox(width: 12),
                                            Expanded(
                                              child: Column(
                                                crossAxisAlignment: CrossAxisAlignment.start,
                                                children: [
                                                  Text(
                                                    'Error #${index + 1}',
                                                    style: const TextStyle(
                                                      fontSize: 18,
                                                      fontWeight: FontWeight.bold,
                                                      color: Color(0xFF1A237E),
                                                    ),
                                                  ),
                                                  Text(
                                                    tieneEvidencia 
                                                        ? 'Error refutado'
                                                        : 'Error no refutado',
                                                    style: TextStyle(
                                                      fontSize: 14,
                                                      fontWeight: FontWeight.w600,
                                                      color: tieneEvidencia 
                                                          ? Colors.green.shade700
                                                          : Colors.red.shade700,
                                                    ),
                                                  ),
                                                ],
                                              ),
                                            ),
                                            const Icon(
                                              Icons.chevron_right,
                                              color: Color(0xFF1A237E),
                                            ),
                                          ],
                                        ),
                                        const Divider(height: 24, thickness: 1),

                                        // Dirección
                                        _buildInfoRow(
                                          icon: Icons.location_on,
                                          label: 'Dirección',
                                          value: direccion,
                                        ),
                                        const SizedBox(height: 12),

                                        // Instalación
                                        _buildInfoRow(
                                          icon: Icons.home,
                                          label: 'Instalación',
                                          value: instalacion,
                                        ),
                                        const SizedBox(height: 12),

                                        // Consumo
                                        _buildInfoRow(
                                          icon: Icons.water_drop,
                                          label: 'Consumo',
                                          value: consumo,
                                          valueColor: Colors.red.shade700,
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

  Widget _buildInfoRow({
    required IconData icon,
    required String label,
    required String value,
    Color? valueColor,
  }) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(
          icon,
          color: const Color(0xFF1A237E),
          size: 20,
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: const TextStyle(
                  fontSize: 12,
                  color: Colors.grey,
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                value,
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: valueColor ?? Colors.black87,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
