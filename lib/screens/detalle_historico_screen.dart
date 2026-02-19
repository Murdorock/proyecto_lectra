import 'package:flutter/material.dart';
import '../main.dart';

class DetalleHistoricoScreen extends StatefulWidget {
  final String nroInstalacion;
  final String tipoConsumo;

  const DetalleHistoricoScreen({
    super.key,
    required this.nroInstalacion,
    required this.tipoConsumo,
  });

  @override
  State<DetalleHistoricoScreen> createState() => _DetalleHistoricoScreenState();
}

class _DetalleHistoricoScreenState extends State<DetalleHistoricoScreen> {
  Map<String, dynamic>? _registro;
  bool _isLoading = true;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _loadDetalle();
  }

  Future<void> _loadDetalle() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final data = await supabase
          .from('hystoricos')
          .select('''
            direccion, nro_instalacion, categoria_servicio, serie_medidor,
            ruta_lectura, supervisor, lector,
            tipo_consumo, actual, anterior, mes3_ant, mes4_ant, mes5_ant, mes6_ant, mes7_ant,
            causal_obs_act, causal_obs_ant, causal_obs_mes3, causal_obs_mes4, causal_obs_mes5, causal_obs_mes6, obs_adic
          ''')
          .eq('nro_instalacion', widget.nroInstalacion)
          .eq('tipo_consumo', widget.tipoConsumo)
          .limit(1);

      if (mounted) {
        if (data.isNotEmpty) {
          setState(() {
            _registro = data[0];
            _isLoading = false;
          });
        } else {
          setState(() {
            _errorMessage = 'No se encontró el registro';
            _isLoading = false;
          });
        }
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
        title: const Text('Detalle del Registro'),
        backgroundColor: const Color(0xFF1A237E),
        foregroundColor: Colors.white,
      ),
      body: _isLoading
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
                          onPressed: _loadDetalle,
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
              : SingleChildScrollView(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Tarjeta 1: INFORMACIÓN BÁSICA
                      _buildSectionCard(
                        title: 'INFORMACIÓN BÁSICA',
                        icon: Icons.info_outline,
                        color: Colors.blue,
                        fields: [
                          _buildField('Dirección', _registro!['direccion']),
                          _buildField('Nro. Instalación', _registro!['nro_instalacion']),
                          _buildField('Categoría Servicio', _registro!['categoria_servicio']),
                          _buildField('Serie Medidor', _registro!['serie_medidor']),
                        ],
                      ),
                      const SizedBox(height: 16),

                      // Tarjeta 2: RUTA Y PERSONAL
                      _buildSectionCard(
                        title: 'RUTA Y PERSONAL',
                        icon: Icons.people_outline,
                        color: Colors.orange,
                        fields: [
                          _buildField('Ruta Lectura', _registro!['ruta_lectura']),
                          _buildField('Supervisor', _registro!['supervisor']),
                          _buildField('Lector', _registro!['lector']),
                        ],
                      ),
                      const SizedBox(height: 16),

                      // Tarjeta 3: LECTURAS Y CONSUMO
                      _buildSectionCard(
                        title: 'LECTURAS Y CONSUMO',
                        icon: Icons.analytics_outlined,
                        color: Colors.green,
                        fields: [
                          _buildField('Tipo Consumo', _registro!['tipo_consumo']),
                          _buildField('Actual', _registro!['actual']),
                          _buildField('Anterior', _registro!['anterior']),
                          _buildField('Mes 3 Anterior', _registro!['mes3_ant']),
                          _buildField('Mes 4 Anterior', _registro!['mes4_ant']),
                          _buildField('Mes 5 Anterior', _registro!['mes5_ant']),
                          _buildField('Mes 6 Anterior', _registro!['mes6_ant']),
                          _buildField('Mes 7 Anterior', _registro!['mes7_ant']),
                        ],
                      ),
                      const SizedBox(height: 16),

                      // Tarjeta 4: OBSERVACIONES Y CAUSALES
                      _buildSectionCard(
                        title: 'OBSERVACIONES Y CAUSALES',
                        icon: Icons.note_outlined,
                        color: Colors.purple,
                        fields: [
                          _buildField('Causal Obs. Actual', _registro!['causal_obs_act']),
                          _buildField('Causal Obs. Anterior', _registro!['causal_obs_ant']),
                          _buildField('Causal Obs. Mes 3', _registro!['causal_obs_mes3']),
                          _buildField('Causal Obs. Mes 4', _registro!['causal_obs_mes4']),
                          _buildField('Causal Obs. Mes 5', _registro!['causal_obs_mes5']),
                          _buildField('Causal Obs. Mes 6', _registro!['causal_obs_mes6']),
                          _buildField('Obs. Adicional', _registro!['obs_adic']),
                        ],
                      ),
                    ],
                  ),
                ),
    );
  }

  Widget _buildSectionCard({
    required String title,
    required IconData icon,
    required Color color,
    required List<Widget> fields,
  }) {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Encabezado de la tarjeta
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.1),
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(12),
                topRight: Radius.circular(12),
              ),
              border: Border(
                bottom: BorderSide(
                  color: color,
                  width: 2,
                ),
              ),
            ),
            child: Row(
              children: [
                Icon(icon, color: color, size: 28),
                const SizedBox(width: 12),
                Text(
                  title,
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: color,
                  ),
                ),
              ],
            ),
          ),
          // Contenido de la tarjeta
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: fields,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildField(String label, dynamic value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            flex: 2,
            child: Text(
              '$label:',
              style: const TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 14,
                color: Color(0xFF1A237E),
              ),
            ),
          ),
          Expanded(
            flex: 3,
            child: Text(
              value?.toString() ?? 'N/A',
              style: const TextStyle(
                fontSize: 14,
                color: Colors.black87,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
