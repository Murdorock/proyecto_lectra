import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:geolocator/geolocator.dart';
import 'dart:math' show cos, sqrt, asin;
import '../main.dart';
import '../services/historicos_metricas_service.dart';import '../services/user_session.dart';import 'detalle_historico_screen.dart';

class HistoricosScreen extends StatefulWidget {
  const HistoricosScreen({super.key});

  @override
  State<HistoricosScreen> createState() => _HistoricosScreenState();
}

class _HistoricosScreenState extends State<HistoricosScreen> {
  final TextEditingController _instalacionController = TextEditingController();
  final TextEditingController _direccionController = TextEditingController();
  final TextEditingController _serieMedidorController = TextEditingController();

  List<Map<String, dynamic>> _resultados = [];
  bool _isSearching = false;
  String? _errorMessage;
  String? _mensajeBusqueda;
  late DateTime _horaApertura;
  Position? _currentPosition;

  @override
  void initState() {
    super.initState();
    _horaApertura = DateTime.now();
    _validarAcceso();
  }

  Future<void> _validarAcceso() async {
    try {
      // Validar que la sesión sea válida
      final sessionValid = await UserSession().ensureSessionValid();
      
      if (!sessionValid) {
        _mostrarErrorYRedireccionar('Sesión inválida');
        return;
      }
      
      // Validar rol de usuario
      final userRole = UserSession().rol?.toUpperCase();
      if (userRole != 'SUPERVISOR' && userRole != 'ADMINISTRADOR') {
        await HistoricosMetricasService.registrarIntentofallido(
          tipo: 'acceso_no_autorizado',
          mensaje: 'Usuario con rol $userRole intentó acceder a históricos',
        );
        _mostrarErrorYRedireccionar(
          'No tiene permisos para acceder a Históricos.\nSolo supervisores y administradores pueden consultar este módulo.',
        );
        return;
      }
      
      HistoricosMetricasService.registrarVistaAbierta();
    } catch (e) {
      _mostrarErrorYRedireccionar('Error al validar acceso: ${e.toString()}');
    }
  }

  void _mostrarErrorYRedireccionar(String mensaje) {
    if (mounted) {
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => AlertDialog(
          title: const Text('Acceso Denegado'),
          content: Text(mensaje),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
                Navigator.of(context).pop(); // Volver a home
              },
              child: const Text('Cerrar'),
            ),
          ],
        ),
      );
    }
  }

  @override
  void dispose() {
    final tiempoVista = DateTime.now().difference(_horaApertura).inSeconds;
    HistoricosMetricasService.registrarTiempoVista(tiempoVista);
    _instalacionController.dispose();
    _direccionController.dispose();
    _serieMedidorController.dispose();
    super.dispose();
  }

  // Calcular distancia entre dos coordenadas usando fórmula de Haversine
  double _calcularDistancia(double lat1, double lon1, double lat2, double lon2) {
    const double radioTierraKm = 6371.0;
    final double dLat = _toRadians(lat2 - lat1);
    final double dLon = _toRadians(lon2 - lon1);
    
    final double a = 
        (1 - cos(dLat)) / 2 + 
        cos(_toRadians(lat1)) * cos(_toRadians(lat2)) * (1 - cos(dLon)) / 2;
    
    final double c = 2 * asin(sqrt(a));
    final double distanciaKm = radioTierraKm * c;
    return distanciaKm * 1000; // Convertir a metros
  }

  double _toRadians(double grados) {
    return grados * 3.141592653589793 / 180;
  }

  // Obtener ubicación actual del usuario
  Future<Position?> _obtenerUbicacionActual() async {
    try {
      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        setState(() {
          _errorMessage = 'El servicio de ubicación está desactivado';
        });
        return null;
      }

      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) {
          setState(() {
            _errorMessage = 'Permiso de ubicación denegado';
          });
          return null;
        }
      }

      if (permission == LocationPermission.deniedForever) {
        setState(() {
          _errorMessage = 'Permiso de ubicación denegado permanentemente';
        });
        return null;
      }

      Position position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
        timeLimit: const Duration(seconds: 30),
      );

      return position;
    } catch (e) {
      setState(() {
        _errorMessage = 'Error al obtener ubicación: ${e.toString()}';
      });
      return null;
    }
  }

  Future<void> _buscar() async {
    // Validar que solo un campo tenga valor
    int camposLlenos = 0;
    String? campoBusqueda;
    String? valorBusqueda;
    String? columnaBusqueda;

    if (_instalacionController.text.isNotEmpty) {
      // Validar que tenga exactamente 18 dígitos
      if (_instalacionController.text.length != 18) {
        await HistoricosMetricasService.registrarIntentofallido(
          tipo: 'longitud_instalacion',
          mensaje: 'Ingreso ${_instalacionController.text.length} digitos, requiere 18',
        );
        setState(() {
          _errorMessage = 'El campo INSTALACIÓN debe tener exactamente 18 dígitos';
          _resultados = [];
          _mensajeBusqueda = null;
        });
        return;
      }
      camposLlenos++;
      campoBusqueda = 'INSTALACIÓN';
      valorBusqueda = _instalacionController.text;
      columnaBusqueda = 'nro_instalacion';
    }
    if (_direccionController.text.isNotEmpty) {
      camposLlenos++;
      campoBusqueda = 'DIRECCIÓN';
      valorBusqueda = _direccionController.text.toUpperCase();
      columnaBusqueda = 'direccion';
    }
    if (_serieMedidorController.text.isNotEmpty) {
      camposLlenos++;
      campoBusqueda = 'SERIE MEDIDOR';
      valorBusqueda = _serieMedidorController.text.toUpperCase();
      columnaBusqueda = 'serie_medidor';
    }

    if (camposLlenos == 0) {
      await HistoricosMetricasService.registrarIntentofallido(
        tipo: 'validacion_vacia',
        mensaje: 'No se ingreso criterio de busqueda',
      );
      setState(() {
        _errorMessage = 'Por favor ingrese un criterio de búsqueda';
        _resultados = [];
        _mensajeBusqueda = null;
      });
      return;
    }

    if (camposLlenos > 1) {
      await HistoricosMetricasService.registrarIntentofallido(
        tipo: 'multiples_campos',
        mensaje: '$camposLlenos campos completados',
      );
      setState(() {
        _errorMessage = 'Solo puede buscar por un campo a la vez';
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
      // Obtener ubicación actual del usuario
      final ubicacionActual = await _obtenerUbicacionActual();
      if (ubicacionActual == null) {
        setState(() {
          _isSearching = false;
        });
        return;
      }

      // DEBUG: Mostrar ubicación actual
      print('=== TU UBICACIÓN ACTUAL ===');
      print('Latitud:  ${ubicacionActual.latitude}');
      print('Longitud: ${ubicacionActual.longitude}');
      print('Formato:  ${ubicacionActual.latitude} ${ubicacionActual.longitude}');
      print('===========================');

      // Realizar la búsqueda en la tabla hystoricos incluyendo coordenada
      final data = await supabase
          .from('hystoricos')
          .select('nro_instalacion, direccion, tipo_consumo, coordenada')
          .eq(columnaBusqueda!, valorBusqueda!)
          .limit(10);

      if (mounted) {
        // Filtrar resultados según distancia GPS
        List<Map<String, dynamic>> resultadosFiltrados = [];
        List<String> registrosRechazados = [];

        for (var registro in data) {
          final coordenadaStr = registro['coordenada']?.toString();
          if (coordenadaStr != null && coordenadaStr.isNotEmpty) {
            try {
              // Parsear coordenadas - soporta formatos: "lat, lon" o "lat lon"
              List<String> partes = coordenadaStr.contains(',') 
                ? coordenadaStr.split(',') 
                : coordenadaStr.trim().split(RegExp(r'\s+'));
              
              if (partes.length >= 2) {
                final latRegistro = double.parse(partes[0].trim());
                final lonRegistro = double.parse(partes[1].trim());
                
                // Calcular distancia
                final distancia = _calcularDistancia(
                  ubicacionActual.latitude,
                  ubicacionActual.longitude,
                  latRegistro,
                  lonRegistro,
                );

                // DEBUG: Mostrar distancia calculada
                print('Registro: ${registro['nro_instalacion']}');
                print('  Coordenada DB: $latRegistro $lonRegistro');
                print('  Distancia: ${distancia.toStringAsFixed(2)} metros');

                // Si está dentro del rango de 200 metros, incluir
                if (distancia <= 200.0) {
                  resultadosFiltrados.add(registro);
                  print('  ✓ ACEPTADO (dentro de 200 metros)');
                } else {
                  registrosRechazados.add(registro['nro_instalacion']?.toString() ?? 'N/A');
                  print('  ✗ RECHAZADO (fuera del rango)');
                }
              } else {
                // No se pudo parsear correctamente - rechazar
                registrosRechazados.add(registro['nro_instalacion']?.toString() ?? 'N/A');
              }
            } catch (e) {
              // Error parseando coordenadas - rechazar
              registrosRechazados.add(registro['nro_instalacion']?.toString() ?? 'N/A');
            }
          } else {
            // Si no tiene coordenadas - rechazar
            registrosRechazados.add(registro['nro_instalacion']?.toString() ?? 'N/A');
          }
        }

        setState(() {
          if (resultadosFiltrados.isEmpty && registrosRechazados.isNotEmpty) {
            _errorMessage = 'Debe estar en la ubicación para consultar este registro. Se encontraron ${data.length} registro(s) pero no está en la ubicación correcta.';
            _resultados = [];
            _mensajeBusqueda = null;
          } else {
            _resultados = resultadosFiltrados;
            if (_resultados.isNotEmpty) {
              _mensajeBusqueda = 'Resultados para: $campoBusqueda: $valorBusqueda\n${_resultados.length} registro(s) encontrado(s)';
              if (registrosRechazados.isNotEmpty) {
                _mensajeBusqueda = '$_mensajeBusqueda\n(${registrosRechazados.length} registro(s) omitido(s) por ubicación)';
              }
            } else {
              _mensajeBusqueda = 'No se encontraron resultados';
            }
          }
          _isSearching = false;
        });
        
        if (resultadosFiltrados.isEmpty) {
          await HistoricosMetricasService.registrarBusquedaSinResultados(
            criterio: campoBusqueda ?? 'DESCONOCIDO',
            valor: valorBusqueda ?? '',
          );
        }

        await HistoricosMetricasService.registrarConsulta(
          criterio: campoBusqueda ?? 'DESCONOCIDO',
          valor: valorBusqueda ?? '',
          consultaEfectiva: resultadosFiltrados.isNotEmpty,
          tipoConsumo: '',
          totalResultados: resultadosFiltrados.length,
        );
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
      _instalacionController.clear();
      _direccionController.clear();
      _serieMedidorController.clear();
      _resultados = [];
      _errorMessage = null;
      _mensajeBusqueda = null;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Históricos'),
        backgroundColor: const Color(0xFF1A237E),
        foregroundColor: Colors.white,
      ),
      body: Container(
        color: Colors.white,
        child: Column(
          children: [
            // Mensaje de búsqueda única
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              color: Colors.white,
              child: const Text(
                'Solo puede buscar por un campo a la vez',
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.grey,
                  fontStyle: FontStyle.italic,
                ),
                textAlign: TextAlign.center,
              ),
            ),

            // Campos de búsqueda
            Container(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
              color: Colors.white,
              child: Column(
                children: [
                  // Campo INSTALACIÓN
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
                          fontSize: 13,
                        ),
                        prefixIcon: Icon(Icons.home, color: Color(0xFF1A237E), size: 20),
                        border: InputBorder.none,
                        contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                        counterText: '',
                        helperText: '18 dígitos',
                        helperStyle: TextStyle(fontSize: 10, color: Colors.grey),
                      ),
                      style: const TextStyle(fontSize: 14),
                      onChanged: (value) {
                        if (value.isNotEmpty) {
                          _direccionController.clear();
                          _serieMedidorController.clear();
                        }
                      },
                    ),
                  ),
                  const SizedBox(height: 8),

                  // Campo DIRECCIÓN
                  Container(
                    decoration: BoxDecoration(
                      border: Border.all(color: Colors.grey, width: 1),
                      borderRadius: BorderRadius.circular(8),
                      color: Colors.white,
                    ),
                    child: TextField(
                      controller: _direccionController,
                      textCapitalization: TextCapitalization.characters,
                      decoration: const InputDecoration(
                        labelText: 'DIRECCIÓN',
                        labelStyle: TextStyle(fontSize: 13),
                        prefixIcon: Icon(Icons.location_on, color: Colors.grey, size: 20),
                        border: InputBorder.none,
                        contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                      ),
                      style: const TextStyle(fontSize: 14),
                      onChanged: (value) {
                        if (value.isNotEmpty) {
                          _instalacionController.clear();
                          _serieMedidorController.clear();
                        }
                      },
                    ),
                  ),
                  const SizedBox(height: 8),

                  // Campo SERIE MEDIDOR
                  Container(
                    decoration: BoxDecoration(
                      border: Border.all(color: Colors.grey, width: 1),
                      borderRadius: BorderRadius.circular(8),
                      color: Colors.white,
                    ),
                    child: TextField(
                      controller: _serieMedidorController,
                      textCapitalization: TextCapitalization.characters,
                      decoration: const InputDecoration(
                        labelText: 'SERIE MEDIDOR',
                        labelStyle: TextStyle(fontSize: 13),
                        prefixIcon: Icon(Icons.speed, color: Colors.grey, size: 20),
                        border: InputBorder.none,
                        contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                      ),
                      style: const TextStyle(fontSize: 14),
                      onChanged: (value) {
                        if (value.isNotEmpty) {
                          _instalacionController.clear();
                          _direccionController.clear();
                        }
                      },
                    ),
                  ),
                ],
              ),
            ),

            // Botones
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              color: Colors.white,
              child: Row(
                children: [
                  Expanded(
                    child: ElevatedButton(
                      onPressed: _isSearching ? null : _buscar,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF1A237E),
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                      child: _isSearching
                          ? const SizedBox(
                              height: 18,
                              width: 18,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                              ),
                            )
                          : const Text(
                              'BUSCAR',
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 14,
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
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                      child: const Text(
                        'LIMPIAR',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 14,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),

            // Mensaje de búsqueda o error
            if (_mensajeBusqueda != null || _errorMessage != null)
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                color: _errorMessage != null ? Colors.red.shade50 : Colors.green.shade50,
                child: Text(
                  _errorMessage ?? _mensajeBusqueda!,
                  style: TextStyle(
                    color: _errorMessage != null ? Colors.red : Colors.green.shade800,
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                  ),
                  textAlign: TextAlign.center,
                ),
              ),

            // Lista de resultados
            Expanded(
              child: _resultados.isEmpty && _mensajeBusqueda == null && _errorMessage == null
                  ? const Center(
                      child: Text(
                        'Ingrese un criterio de búsqueda',
                        style: TextStyle(
                          fontSize: 16,
                          color: Colors.grey,
                        ),
                      ),
                    )
                  : ListView.builder(
                      padding: const EdgeInsets.all(12),
                      itemCount: _resultados.length,
                      itemBuilder: (context, index) {
                        final registro = _resultados[index];
                        final direccion = registro['direccion']?.toString() ?? 'N/A';
                        final tipoConsumo = registro['tipo_consumo']?.toString() ?? 'N/A';
                        final nroInstalacion = registro['nro_instalacion']?.toString() ?? '';

                        return Card(
                          margin: const EdgeInsets.only(bottom: 10),
                          elevation: 2,
                          color: Colors.white,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: ListTile(
                            contentPadding: const EdgeInsets.all(12),
                            leading: Container(
                              width: 40,
                              height: 40,
                              decoration: BoxDecoration(
                                color: const Color(0xFF1A237E),
                                borderRadius: BorderRadius.circular(20),
                              ),
                              child: Center(
                                child: Text(
                                  '${index + 1}',
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontWeight: FontWeight.bold,
                                    fontSize: 14,
                                  ),
                                  textAlign: TextAlign.center,
                                ),
                              ),
                            ),
                            title: Row(
                              children: [
                                const Icon(Icons.location_on, size: 14, color: Colors.grey),
                                const SizedBox(width: 4),
                                Expanded(
                                  child: Text(
                                    direccion,
                                    style: const TextStyle(
                                      fontWeight: FontWeight.bold,
                                      fontSize: 13,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            subtitle: Padding(
                              padding: const EdgeInsets.only(top: 4),
                              child: Row(
                                children: [
                                  const Icon(Icons.water_drop, size: 14, color: Colors.grey),
                                  const SizedBox(width: 4),
                                  Text(
                                    'Tipo: $tipoConsumo',
                                    style: const TextStyle(fontSize: 12),
                                  ),
                                ],
                              ),
                            ),
                            trailing: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                IconButton(
                                  icon: const Icon(Icons.visibility, color: Color(0xFF1A237E), size: 20),
                                  onPressed: () async {
                                    await HistoricosMetricasService.registrarIngresoDetalle(
                                      nroInstalacion: nroInstalacion,
                                      tipoConsumo: tipoConsumo == 'N/A' ? '' : tipoConsumo,
                                    );
                                    if (!context.mounted) return;
                                    Navigator.push(
                                      context,
                                      MaterialPageRoute(
                                        builder: (context) => DetalleHistoricoScreen(
                                          nroInstalacion: nroInstalacion,
                                          tipoConsumo: tipoConsumo,
                                        ),
                                      ),
                                    );
                                  },
                                  tooltip: 'Ver detalles',
                                  padding: EdgeInsets.zero,
                                  constraints: const BoxConstraints(),
                                ),
                                const SizedBox(width: 4),
                                const Icon(Icons.chevron_right, color: Colors.grey, size: 20),
                              ],
                            ),
                          ),
                        );
                      },
                    ),
            ),
          ],
        ),
      ),
    );
  }
}
