import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../main.dart';
import 'package:url_launcher/url_launcher.dart';
import '../services/coordenadas_metricas_service.dart';

class CoordenadasScreen extends StatefulWidget {
  const CoordenadasScreen({super.key});

  @override
  State<CoordenadasScreen> createState() => _CoordenadasScreenState();
}

class _CoordenadasScreenState extends State<CoordenadasScreen> {
  final TextEditingController _instalacionController = TextEditingController();
  
  Map<String, dynamic>? _resultado;
  bool _isSearching = false;
  String? _errorMessage;
  late DateTime _horaApertura;

  @override
  void initState() {
    super.initState();
    _horaApertura = DateTime.now();
    CoordenadasMetricasService.registrarVistaAbierta();
  }

  @override
  void dispose() {
    final tiempoVista = DateTime.now().difference(_horaApertura).inSeconds;
    CoordenadasMetricasService.registrarTiempoVista(tiempoVista);
    _instalacionController.dispose();
    super.dispose();
  }

  Future<void> _buscar() async {
    final instalacion = _instalacionController.text.trim();

    if (instalacion.isEmpty) {
      await CoordenadasMetricasService.registrarIntentofallido(
        tipo: 'instalacion_vacia',
        mensaje: 'Se intento buscar sin ingresar instalacion',
      );
      setState(() {
        _errorMessage = 'Por favor ingrese un número de instalación';
        _resultado = null;
      });
      return;
    }

    if (instalacion.length != 18) {
      await CoordenadasMetricasService.registrarIntentofallido(
        tipo: 'longitud_instalacion',
        mensaje: 'Ingreso ${instalacion.length} digitos, requiere 18',
      );
      setState(() {
        _errorMessage = 'El número de instalación debe tener exactamente 18 dígitos';
        _resultado = null;
      });
      return;
    }

    setState(() {
      _isSearching = true;
      _errorMessage = null;
      _resultado = null;
    });

    try {
      await CoordenadasMetricasService.registrarConsulta(
        criterio: 'instalacion',
        valor: instalacion,
      );
      final data = await supabase
          .from('coordenadas')
          .select('ciclo, direccion, coordenada, instalacion')
          .eq('instalacion', instalacion)
          .limit(1);

      if (mounted) {
        if (data.isNotEmpty) {
          setState(() {
            _resultado = data[0];
            _isSearching = false;
          });
        } else {
          await CoordenadasMetricasService.registrarBusquedaSinResultados(
            criterio: 'instalacion',
            valor: instalacion,
          );
          setState(() {
            _errorMessage = 'No se encontraron resultados para esta instalación';
            _isSearching = false;
          });
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _errorMessage = 'Error al buscar: ${e.toString()}';
          _isSearching = false;
        });
      }
    }
  }

  Future<void> _abrirGoogleMaps(String coordenada) async {
    try {
      await CoordenadasMetricasService.registrarAbrirMaps(coordenada);
      // Formato esperado: "latitud,longitud" o "latitud longitud"
      final coordenadaLimpia = coordenada.trim().replaceAll(' ', ',');
      
      // Intentar abrir en la app de Google Maps primero (esquema geo)
      final geoUri = Uri.parse('geo:0,0?q=$coordenadaLimpia');
      
      if (await canLaunchUrl(geoUri)) {
        await launchUrl(geoUri, mode: LaunchMode.externalApplication);
      } else {
        // Si no funciona, usar el navegador web
        final webUri = Uri.parse('https://www.google.com/maps/search/?api=1&query=$coordenadaLimpia');
        
        if (await canLaunchUrl(webUri)) {
          await launchUrl(webUri, mode: LaunchMode.externalApplication);
        } else {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('No se pudo abrir Google Maps'),
                backgroundColor: Colors.red,
              ),
            );
          }
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error al abrir Google Maps: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  void _limpiar() {
    setState(() {
      _instalacionController.clear();
      _resultado = null;
      _errorMessage = null;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Coordenadas'),
        backgroundColor: const Color(0xFF1A237E),
        foregroundColor: Colors.white,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Campo de búsqueda
            Container(
              decoration: BoxDecoration(
                border: Border.all(color: const Color(0xFF1A237E), width: 2),
                borderRadius: BorderRadius.circular(8),
                color: Colors.white,
              ),
              child: TextField(
                controller: _instalacionController,
                keyboardType: TextInputType.number,
                maxLength: 18,
                inputFormatters: [
                  FilteringTextInputFormatter.digitsOnly,
                  LengthLimitingTextInputFormatter(18),
                ],
                decoration: const InputDecoration(
                  labelText: 'INSTALACIÓN',
                  labelStyle: TextStyle(
                    color: Color(0xFF1A237E),
                    fontWeight: FontWeight.bold,
                  ),
                  prefixIcon: Icon(Icons.home, color: Color(0xFF1A237E)),
                  border: InputBorder.none,
                  contentPadding: EdgeInsets.all(16),
                  counterText: '',
                  helperText: '18 dígitos numéricos',
                  helperStyle: TextStyle(fontSize: 11, color: Colors.grey),
                ),
              ),
            ),
            const SizedBox(height: 16),

            // Botones
            Row(
              children: [
                Expanded(
                  child: ElevatedButton(
                    onPressed: _isSearching ? null : _buscar,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF1A237E),
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                    child: _isSearching
                        ? const SizedBox(
                            height: 20,
                            width: 20,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                            ),
                          )
                        : const Text(
                            'BUSCAR',
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 16,
                            ),
                          ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: OutlinedButton(
                    onPressed: _limpiar,
                    style: OutlinedButton.styleFrom(
                      foregroundColor: const Color(0xFF1A237E),
                      side: const BorderSide(color: Color(0xFF1A237E), width: 2),
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                    child: const Text(
                      'LIMPIAR',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),

            // Mensaje de error
            if (_errorMessage != null)
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.red.shade50,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.red, width: 2),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.error_outline, color: Colors.red),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        _errorMessage!,
                        style: const TextStyle(
                          color: Colors.red,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                ),
              ),

            // Resultado
            if (_resultado != null) ...[
              Card(
                elevation: 4,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Título
                      const Row(
                        children: [
                          Icon(
                            Icons.location_on,
                            color: Color(0xFF1A237E),
                            size: 28,
                          ),
                          SizedBox(width: 12),
                          Text(
                            'Información de la Instalación',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: Color(0xFF1A237E),
                            ),
                          ),
                        ],
                      ),
                      const Divider(height: 24, thickness: 2),

                      // Instalación
                      _buildInfoRow(
                        icon: Icons.home,
                        label: 'Instalación',
                        value: _resultado!['instalacion']?.toString() ?? 'N/A',
                      ),
                      const SizedBox(height: 16),

                      // Ciclo
                      _buildInfoRow(
                        icon: Icons.loop,
                        label: 'Ciclo',
                        value: _resultado!['ciclo']?.toString() ?? 'N/A',
                      ),
                      const SizedBox(height: 16),

                      // Dirección
                      _buildInfoRow(
                        icon: Icons.location_city,
                        label: 'Dirección',
                        value: _resultado!['direccion']?.toString() ?? 'N/A',
                      ),
                      const SizedBox(height: 16),

                      // Coordenada
                      _buildInfoRow(
                        icon: Icons.my_location,
                        label: 'Coordenada GPS',
                        value: _resultado!['coordenada']?.toString() ?? 'N/A',
                      ),
                      const SizedBox(height: 24),

                      // Botón de Google Maps
                      if (_resultado!['coordenada'] != null &&
                          _resultado!['coordenada'].toString().isNotEmpty)
                        SizedBox(
                          width: double.infinity,
                          child: ElevatedButton.icon(
                            onPressed: () => _abrirGoogleMaps(_resultado!['coordenada'].toString()),
                            icon: const Icon(Icons.map),
                            label: const Text(
                              'ABRIR EN GOOGLE MAPS',
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 16,
                              ),
                            ),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.green,
                              foregroundColor: Colors.white,
                              padding: const EdgeInsets.symmetric(vertical: 16),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(8),
                              ),
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildInfoRow({
    required IconData icon,
    required String label,
    required String value,
  }) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, color: const Color(0xFF1A237E), size: 20),
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
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: Colors.black87,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
