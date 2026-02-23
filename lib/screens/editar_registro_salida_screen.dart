import 'package:flutter/material.dart';
//import 'package:flutter/services.dart';
import '../main.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'llegadas_tarde_screen.dart';
import 'package:geolocator/geolocator.dart';

class EditarRegistroSalidaScreen extends StatefulWidget {
  final String idLector;

  const EditarRegistroSalidaScreen({
    super.key,
    required this.idLector,
  });

  @override
  State<EditarRegistroSalidaScreen> createState() => _EditarRegistroSalidaScreenState();
}

class _EditarRegistroSalidaScreenState extends State<EditarRegistroSalidaScreen> {
  bool _isLoading = true;
  String? _errorMessage;
  Map<String, dynamic>? _registro;
  bool _isSaving = false;
  bool _isValidatingBarcode = false;

  // Controllers y valores
  TimeOfDay? _registroSalida;
  String? _novedades;
  String? _cargoCiclo;
  final TextEditingController _observacionesController = TextEditingController();
  final TextEditingController _codigoBarrasController = TextEditingController();
  String? _tipoCierre;
  String? _transporte;

  // Opciones para dropdowns
  final List<String> _opcionesNovedades = ['Sin novedad', 'Lector nuevo', 'Apoyo en zona'];
  final List<String> _opcionesCargoCiclo = ['Si', 'No'];
  final List<String> _opcionesTipoCierre = ['Presencial', 'Remoto'];
  final List<String> _opcionesTransporte = ['A pie', 'Bus', 'Carro', 'Motorizado'];

  @override
  void initState() {
    super.initState();
    _loadRegistro();
  }

  @override
  void dispose() {
    _observacionesController.dispose();
    _codigoBarrasController.dispose();
    super.dispose();
  }

  Future<void> _loadRegistro() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      // Consultar el registro específico
      final data = await supabase
          .from('base')
          .select('id_lector, registro_salida, novedades, carga_ciclo, obs_general, tipo_cierre, trans_correria, inicio_jornada')
          .eq('id_lector', widget.idLector)
          .maybeSingle();

      if (mounted) {
        if (data != null) {
          setState(() {
            _registro = data;
            // Cargar datos existentes si los hay
            if (data['registro_salida'] != null) {
              // Parsear hora (formato esperado: "HH:mm" o cualquier string de hora)
              try {
                final partes = data['registro_salida'].toString().split(':');
                if (partes.length >= 2) {
                  _registroSalida = TimeOfDay(
                    hour: int.parse(partes[0]),
                    minute: int.parse(partes[1]),
                  );
                }
              } catch (e) {
                // Si no se puede parsear, dejar null
              }
            }
            if (data['novedades'] != null) {
              _novedades = data['novedades'].toString();
            } else {
              // Valor por defecto: Sin novedad
              _novedades = 'Sin novedad';
            }
            if (data['carga_ciclo'] != null) {
              _cargoCiclo = data['carga_ciclo'].toString();
            } else {
              // Valor por defecto: Si
              _cargoCiclo = 'Si';
            }
            if (data['obs_general'] != null) {
              _observacionesController.text = data['obs_general'].toString();
            }
            if (data['tipo_cierre'] != null) {
              _tipoCierre = data['tipo_cierre'].toString();
            } else {
              // Valor por defecto: Presencial
              _tipoCierre = 'Presencial';
            }
            if (data['trans_correria'] != null) {
              _transporte = data['trans_correria'].toString();
            } else {
              // Valor por defecto: A pie
              _transporte = 'A pie';
            }
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

  Future<void> _guardarCambios() async {
    // Validar que el registro de salida sea obligatorio
    if (_registroSalida == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Por favor seleccione la hora de salida'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    setState(() {
      _isSaving = true;
    });

    try {
      // Convertir TimeOfDay a timestamp completo (YYYY-MM-DD HH:MM:SS)
      String? registroSalidaStr;
      if (_registroSalida != null) {
        final now = DateTime.now();
        final registroDateTime = DateTime(
          now.year,
          now.month,
          now.day,
          _registroSalida!.hour,
          _registroSalida!.minute,
        );
        // Formato: 2025-11-08 16:36:00
        registroSalidaStr = '${registroDateTime.year}-${registroDateTime.month.toString().padLeft(2, '0')}-${registroDateTime.day.toString().padLeft(2, '0')} ${registroDateTime.hour.toString().padLeft(2, '0')}:${registroDateTime.minute.toString().padLeft(2, '0')}:00';
      }

      await supabase
          .from('base')
          .update({
            'registro_salida': registroSalidaStr,
            'novedades': _novedades,
            'carga_ciclo': _cargoCiclo,
            'obs_general': _observacionesController.text.isNotEmpty ? _observacionesController.text : null,
            'tipo_cierre': _tipoCierre,
            'trans_correria': _transporte,
          })
          .eq('id_lector', widget.idLector);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Registro guardado exitosamente'),
            backgroundColor: Colors.green,
          ),
        );
        Navigator.pop(context, true);
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isSaving = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error al guardar: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  /// Abre la cámara para escanear código de barras
  Future<void> _abrirScannerCodigoBarras() async {
    try {
      final result = await Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => const BarcodeScannerScreen(
            title: 'Escanear Código de Barras',
          ),
        ),
      );

      if (result != null && result.isNotEmpty) {
        setState(() {
          _codigoBarrasController.text = result;
        });
        // Buscar y validar el código escaneado
        await _validarCodigoBarras(result);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error al abrir escáner: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  /// Valida que el código escaneado corresponda al lector actual
  Future<void> _validarCodigoBarras(String codigoEscaneado) async {
    // Mostrar diálogo de validación
    if (mounted) {
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (BuildContext context) {
          return Dialog(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const CircularProgressIndicator(
                    valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF1A237E)),
                  ),
                  const SizedBox(height: 24),
                  const Text(
                    'Registrando información',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF1A237E),
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Por favor espere...',
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.grey.shade600,
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      );
    }

    try {
      // Buscar en la tabla personal por numero_cedula
      final data = await supabase
          .from('personal')
          .select('id_codigo, numero_cedula, nombre_completo')
          .eq('numero_cedula', codigoEscaneado)
          .maybeSingle();

      if (mounted) {
        if (data != null) {
          final idCodigo = data['id_codigo'].toString();
          
          // Comparar con el código del lector actual
          if (idCodigo == widget.idLector) {
            // Verificar si ya tiene hora de llegada registrada
            if (_registro != null && 
                _registro!['inicio_jornada'] != null && 
                _registro!['inicio_jornada'].toString().isNotEmpty) {
              // Ya tiene hora de llegada registrada
              if (mounted) {
                Navigator.pop(context);
                setState(() {
                  _codigoBarrasController.clear();
                });
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('La hora de llegada ya fue registrada para ${data['nombre_completo']}'),
                    backgroundColor: Colors.orange,
                    duration: const Duration(seconds: 3),
                  ),
                );
              }
              return;
            }
            
            // Código válido - coincide con el lector
            // Guardar fecha y hora del sistema
            final now = DateTime.now();
            final horaLlegada = '${now.year}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')} ${now.hour.toString().padLeft(2, '0')}:${now.minute.toString().padLeft(2, '0')}:${now.second.toString().padLeft(2, '0')}';
            
            // Definir la hora límite: 06:31:00 del día actual
            final horaLimite = DateTime(now.year, now.month, now.day, 6, 31, 0);
            
            try {
              // Preparar el objeto de actualización
              final updateData = <String, dynamic>{
                'inicio_jornada': horaLlegada,
              };
              
              // Si la hora actual es superior a las 06:31:00, también guardar en llegada_tarde
              if (now.isAfter(horaLimite)) {
                updateData['llegada_tarde'] = horaLlegada;
              }
              
              // Obtener coordenadas GPS
              String? coordenadas;
              try {
                // Verificar permisos de ubicación
                LocationPermission permission = await Geolocator.checkPermission();
                if (permission == LocationPermission.denied) {
                  permission = await Geolocator.requestPermission();
                }
                
                if (permission == LocationPermission.denied || 
                    permission == LocationPermission.deniedForever) {
                  // Si no hay permisos, continuar sin coordenadas
                  coordenadas = null;
                } else {
                  // Obtener posición actual
                  Position position = await Geolocator.getCurrentPosition(
                    desiredAccuracy: LocationAccuracy.high,
                    timeLimit: const Duration(seconds: 10),
                  );
                  coordenadas = '${position.latitude},${position.longitude}';
                  updateData['dir_llegada'] = coordenadas;
                }
              } catch (e) {
                // Si hay error obteniendo GPS, continuar sin coordenadas
                coordenadas = null;
              }
              
              // Actualizar la tabla base
              await supabase
                  .from('base')
                  .update(updateData)
                  .eq('id_lector', widget.idLector);
              
              // Cerrar el diálogo de validación
              if (mounted) {
                Navigator.pop(context);
              }
              
              // Actualizar el estado local para mostrar en HORA LLEGADA
              if (mounted) {
                setState(() {
                  if (_registro != null) {
                    _registro!['inicio_jornada'] = horaLlegada;
                  }
                });
                
                String mensaje = '✓ Código verificado: ${data['nombre_completo']}\nHora de llegada registrada: ${now.hour.toString().padLeft(2, '0')}:${now.minute.toString().padLeft(2, '0')}';
                
                if (now.isAfter(horaLimite)) {
                  mensaje += '\n⚠ Llegada tarde registrada';
                  
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(mensaje),
                      backgroundColor: Colors.orange,
                      duration: const Duration(seconds: 2),
                    ),
                  );
                  
                  // Navegar a la pantalla de llegadas tarde
                  Future.delayed(const Duration(seconds: 2), () async {
                    if (mounted) {
                      // Obtener el nombre del funcionario desde la tabla personal
                      String? nombreFuncionario;
                      try {
                        final personalData = await supabase
                            .from('personal')
                            .select('nombre_completo')
                            .eq('id_codigo', widget.idLector)
                            .maybeSingle();
                        nombreFuncionario = personalData?['nombre_completo']?.toString();
                      } catch (e) {
                        // Si hay error, usar solo el código
                      }
                      
                      // Convertir la hora de llegada a TimeOfDay
                      TimeOfDay? horaConvertida;
                      try {
                        final partes = horaLlegada.split(' ');
                        if (partes.length >= 2) {
                          final horaPartes = partes[1].split(':');
                          if (horaPartes.length >= 2) {
                            horaConvertida = TimeOfDay(
                              hour: int.parse(horaPartes[0]),
                              minute: int.parse(horaPartes[1]),
                            );
                          }
                        }
                      } catch (e) {
                        // Si hay error, usar la hora actual
                      }
                      
                      if (mounted) {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => LlegadasTardeScreen(
                              codigoInicial: widget.idLector,
                              nombreInicial: nombreFuncionario,
                              horaInicial: horaConvertida,
                            ),
                          ),
                        );
                      }
                    }
                  });
                } else {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(mensaje),
                      backgroundColor: Colors.green,
                      duration: const Duration(seconds: 3),
                    ),
                  );
                }
              }
            } catch (e) {
              if (mounted) {
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('Error al guardar hora de llegada: ${e.toString()}'),
                    backgroundColor: Colors.red,
                  ),
                );
              }
            }
          } else {
            // Código no coincide con el lector actual
            if (mounted) {
              Navigator.pop(context);
              setState(() {
                _codigoBarrasController.clear();
              });
            }
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text('Error: Este código pertenece a ${data['nombre_completo']} (${idCodigo}), no al lector actual (${widget.idLector})'),
                backgroundColor: Colors.red,
                duration: const Duration(seconds: 4),
              ),
            );
          }
        } else {
          // No se encontró el código escaneado
          if (mounted) {
            Navigator.pop(context);
            setState(() {
              _codigoBarrasController.clear();
            });
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('Error: Código no encontrado en el sistema'),
                backgroundColor: Colors.red,
                duration: Duration(seconds: 3),
              ),
            );
          }
        }
      }
    } catch (e) {
      if (mounted) {
        Navigator.pop(context);
        setState(() {
          _codigoBarrasController.clear();
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error al validar código: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Editar Registro'),
        backgroundColor: const Color(0xFF1A237E),
        foregroundColor: Colors.white,
        actions: [
          if (!_isLoading && _registro != null)
            IconButton(
              icon: _isSaving
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                      ),
                    )
                  : const Icon(Icons.save),
              onPressed: (_isSaving || _registroSalida == null) ? null : _guardarCambios,
              tooltip: 'Guardar',
            ),
        ],
      ),
      body: _isLoading
          ? const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  CircularProgressIndicator(
                    valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF1A237E)),
                  ),
                  SizedBox(height: 16),
                  Text('Cargando registro...'),
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
                          onPressed: _loadRegistro,
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
                      // Header con código
                      Card(
                        elevation: 2,
                        color: const Color(0xFF1A237E).withValues(alpha: 0.1),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                          side: const BorderSide(
                            color: Color(0xFF1A237E),
                            width: 2,
                          ),
                        ),
                        child: Padding(
                          padding: const EdgeInsets.all(16.0),
                          child: Row(
                            children: [
                              const Icon(
                                Icons.person,
                                color: Color(0xFF1A237E),
                                size: 32,
                              ),
                              const SizedBox(width: 12),
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const Text(
                                    'Código Lector',
                                    style: TextStyle(
                                      fontSize: 12,
                                      color: Colors.grey,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    widget.idLector,
                                    style: const TextStyle(
                                      fontSize: 20,
                                      fontWeight: FontWeight.bold,
                                      color: Color(0xFF1A237E),
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(height: 16),
                      
                      const SizedBox(height: 24),

                      // Formulario
                      // REGISTRO DE SALIDA - Time Picker
                      _buildTimePickerField(),
                      const SizedBox(height: 16),
                      
                      // NOVEDADES - Dropdown
                      _buildDropdownField(
                        label: 'NOVEDADES',
                        icon: Icons.announcement,
                        value: _novedades,
                        items: _opcionesNovedades,
                        onChanged: (value) {
                          setState(() {
                            _novedades = value;
                          });
                        },
                      ),
                      const SizedBox(height: 16),
                      
                      // CARGO CICLO - Dropdown
                      _buildDropdownField(
                        label: 'CARGO CICLO',
                        icon: Icons.loop,
                        value: _cargoCiclo,
                        items: _opcionesCargoCiclo,
                        onChanged: (value) {
                          setState(() {
                            _cargoCiclo = value;
                          });
                        },
                      ),
                      const SizedBox(height: 16),
                      
                      // OBSERVACIONES - Text Field
                      _buildTextField(
                        controller: _observacionesController,
                        label: 'OBSERVACIONES',
                        icon: Icons.note,
                        maxLines: 3,
                      ),
                      const SizedBox(height: 16),
                      
                      // TIPO CIERRE - Dropdown
                      _buildDropdownField(
                        label: 'TIPO CIERRE',
                        icon: Icons.category,
                        value: _tipoCierre,
                        items: _opcionesTipoCierre,
                        onChanged: (value) {
                          setState(() {
                            _tipoCierre = value;
                          });
                        },
                      ),
                      const SizedBox(height: 16),
                      
                      // TRANSPORTE - Dropdown
                      _buildDropdownField(
                        label: 'TRANSPORTE',
                        icon: Icons.directions_bus,
                        value: _transporte,
                        items: _opcionesTransporte,
                        onChanged: (value) {
                          setState(() {
                            _transporte = value;
                          });
                        },
                      ),
                      const SizedBox(height: 32),

                      // Botón de guardar
                      SizedBox(
                        width: double.infinity,
                        height: 50,
                        child: ElevatedButton.icon(
                          onPressed: (_isSaving || _registroSalida == null) ? null : _guardarCambios,
                          icon: _isSaving
                              ? const SizedBox(
                                  width: 20,
                                  height: 20,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                    valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                                  ),
                                )
                              : const Icon(Icons.save, size: 24),
                          label: Text(
                            _isSaving ? 'Guardando...' : 'Guardar Registro',
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF1A237E),
                            foregroundColor: Colors.white,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                            elevation: 2,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
    );
  }

  Widget _buildTimePickerField() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'REGISTRO DE SALIDA',
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.bold,
            color: Color(0xFF1A237E),
          ),
        ),
        const SizedBox(height: 8),
        InkWell(
          onTap: () async {
            final TimeOfDay? picked = await showTimePicker(
              context: context,
              initialTime: _registroSalida ?? TimeOfDay.now(),
            );
            if (picked != null) {
              setState(() {
                _registroSalida = picked;
              });
            }
          },
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
            decoration: BoxDecoration(
              color: Colors.grey.shade100,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: Colors.grey.shade300,
                width: 1,
              ),
            ),
            child: Row(
              children: [
                const Icon(
                  Icons.access_time,
                  color: Color(0xFF1A237E),
                ),
                const SizedBox(width: 12),
                Text(
                  _registroSalida != null
                      ? _registroSalida!.format(context)
                      : 'Seleccione hora de salida',
                  style: TextStyle(
                    fontSize: 16,
                    color: _registroSalida != null
                        ? Colors.black87
                        : Colors.grey.shade400,
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildDropdownField({
    required String label,
    required IconData icon,
    required String? value,
    required List<String> items,
    required Function(String?) onChanged,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.bold,
            color: Color(0xFF1A237E),
          ),
        ),
        const SizedBox(height: 8),
        DropdownButtonFormField<String>(
          initialValue: value,
          decoration: InputDecoration(
            hintText: 'Seleccione $label',
            hintStyle: TextStyle(color: Colors.grey.shade400),
            prefixIcon: Icon(
              icon,
              color: const Color(0xFF1A237E),
            ),
            filled: true,
            fillColor: Colors.grey.shade100,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(
                color: Colors.grey.shade300,
                width: 1,
              ),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(
                color: Colors.grey.shade300,
                width: 1,
              ),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(
                color: Color(0xFF1A237E),
                width: 2,
              ),
            ),
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 16,
              vertical: 14,
            ),
          ),
          items: items.map((String item) {
            return DropdownMenuItem<String>(
              value: item,
              child: Text(item),
            );
          }).toList(),
          onChanged: onChanged,
        ),
      ],
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    int maxLines = 1,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.bold,
            color: Color(0xFF1A237E),
          ),
        ),
        const SizedBox(height: 8),
        TextField(
          controller: controller,
          maxLines: maxLines,
          decoration: InputDecoration(
            hintText: 'Ingrese $label',
            hintStyle: TextStyle(color: Colors.grey.shade400),
            prefixIcon: Icon(
              icon,
              color: const Color(0xFF1A237E),
            ),
            filled: true,
            fillColor: Colors.grey.shade100,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(
                color: Colors.grey.shade300,
                width: 1,
              ),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(
                color: Colors.grey.shade300,
                width: 1,
              ),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(
                color: Color(0xFF1A237E),
                width: 2,
              ),
            ),
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 16,
              vertical: 14,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildHoraLlegadaField() {
    String horaLlegada = '';
    if (_registro != null && _registro!["inicio_jornada"] != null) {
      horaLlegada = _registro!["inicio_jornada"].toString();
    }
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'HORA LLEGADA',
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.bold,
            color: Color(0xFF1A237E),
          ),
        ),
        const SizedBox(height: 8),
        Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
          decoration: BoxDecoration(
            color: Colors.grey.shade100,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: Colors.grey.shade300,
              width: 1,
            ),
          ),
          child: Row(
            children: [
              const Icon(
                Icons.access_time,
                color: Color(0xFF1A237E),
              ),
              const SizedBox(width: 12),
              Text(
                horaLlegada.isNotEmpty ? horaLlegada : 'No disponible',
                style: TextStyle(
                  fontSize: 16,
                  color: horaLlegada.isNotEmpty ? Colors.black87 : Colors.grey.shade400,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildCodigoBarrasField() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'CÓDIGO DE BARRAS',
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.bold,
            color: Color(0xFF1A237E),
          ),
        ),
        const SizedBox(height: 8),
        Row(
          children: [
            Expanded(
              child: TextField(
                controller: _codigoBarrasController,
                decoration: InputDecoration(
                  hintText: 'Escanee o ingrese la cédula',
                  hintStyle: TextStyle(color: Colors.grey.shade400),
                  prefixIcon: const Icon(
                    Icons.qr_code_scanner,
                    color: Color(0xFF1A237E),
                  ),
                  suffixIcon: _codigoBarrasController.text.isNotEmpty
                      ? IconButton(
                          icon: const Icon(Icons.clear),
                          onPressed: () {
                            setState(() {
                              _codigoBarrasController.clear();
                            });
                          },
                        )
                      : null,
                  filled: true,
                  fillColor: Colors.grey.shade100,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(
                      color: Colors.grey.shade300,
                      width: 1,
                    ),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(
                      color: Colors.grey.shade300,
                      width: 1,
                    ),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: const BorderSide(
                      color: Color(0xFF1A237E),
                      width: 2,
                    ),
                  ),
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 14,
                  ),
                ),
                onChanged: (_) => setState(() {}),
                onSubmitted: (value) {
                  // Validar cuando se completa el ingreso manual (presiona Enter)
                  if (value.isNotEmpty) {
                    _validarCodigoBarras(value);
                  }
                },
              ),
            ),
            const SizedBox(width: 12),
            SizedBox(
              height: 56,
              child: ElevatedButton(
                onPressed: _abrirScannerCodigoBarras,
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF1A237E),
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                ),
                child: const Icon(Icons.qr_code_scanner, size: 28),
              ),
            ),
          ],
        ),
      ],
    );
  }
}

/// Pantalla personalizada de escaneo de código de barras
class BarcodeScannerScreen extends StatefulWidget {
  final String title;

  const BarcodeScannerScreen({super.key, required this.title});

  @override
  State<BarcodeScannerScreen> createState() => _BarcodeScannerScreenState();
}

class _BarcodeScannerScreenState extends State<BarcodeScannerScreen> {
  MobileScannerController cameraController = MobileScannerController();
  bool _isProcessing = false;

  @override
  void dispose() {
    cameraController.dispose();
    super.dispose();
  }

  void _onDetect(BarcodeCapture capture) {
    if (_isProcessing) return;
    
    final List<Barcode> barcodes = capture.barcodes;
    if (barcodes.isEmpty) return;

    final barcode = barcodes.first;
    if (barcode.rawValue != null && barcode.rawValue!.isNotEmpty) {
      _isProcessing = true;
      final String valorCompleto = barcode.rawValue!;
      String valorProcesado = valorCompleto;

      // Extrae desde el dígito 13 hasta el penúltimo si hay longitud suficiente.
      if (valorCompleto.length >= 14) {
        valorProcesado = valorCompleto.substring(12, valorCompleto.length - 1);
      }

      Navigator.pop(context, valorProcesado);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.title),
        backgroundColor: const Color(0xFF1A237E),
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: const Icon(Icons.flash_on, color: Colors.white),
            onPressed: () => cameraController.toggleTorch(),
          ),
        ],
      ),
      body: Stack(
        children: [
          MobileScanner(
            controller: cameraController,
            onDetect: _onDetect,
          ),
          // Overlay con línea de escaneo
          CustomPaint(
            painter: ScannerOverlay(),
            child: Container(),
          ),
          // Instrucciones
          Positioned(
            bottom: 100,
            left: 0,
            right: 0,
            child: Container(
              padding: const EdgeInsets.all(16),
              color: Colors.black54,
              child: const Text(
                'Apunte la cámara hacia el código de barras',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
                textAlign: TextAlign.center,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Dibuja el overlay del escáner con línea central
class ScannerOverlay extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final double scanAreaWidth = size.width * 0.8;
    final double scanAreaHeight = size.height * 0.4;
    final double left = (size.width - scanAreaWidth) / 2;
    final double top = (size.height - scanAreaHeight) / 2;
    final Rect scanArea = Rect.fromLTWH(left, top, scanAreaWidth, scanAreaHeight);

    // Fondo semi-transparente
    final Paint backgroundPaint = Paint()
      ..color = Colors.black.withValues(alpha: 0.5);
    canvas.drawPath(
      Path.combine(
        PathOperation.difference,
        Path()..addRect(Rect.fromLTWH(0, 0, size.width, size.height)),
        Path()..addRect(scanArea),
      ),
      backgroundPaint,
    );

    // Bordes del área de escaneo
    final Paint borderPaint = Paint()
      ..color = const Color(0xFF1A237E)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3;

    canvas.drawRect(scanArea, borderPaint);

    // Línea de escaneo central
    final Paint linePaint = Paint()
      ..color = const Color(0xFF1A237E)
      ..strokeWidth = 2;

    canvas.drawLine(
      Offset(left, scanArea.center.dy),
      Offset(left + scanAreaWidth, scanArea.center.dy),
      linePaint,
    );

    // Esquinas decorativas
    final Paint cornerPaint = Paint()
      ..color = const Color(0xFF1A237E)
      ..strokeWidth = 5
      ..strokeCap = StrokeCap.round;

    const double cornerLength = 30;

    // Esquina superior izquierda
    canvas.drawLine(Offset(left, top), Offset(left + cornerLength, top), cornerPaint);
    canvas.drawLine(Offset(left, top), Offset(left, top + cornerLength), cornerPaint);

    // Esquina superior derecha
    canvas.drawLine(Offset(left + scanAreaWidth, top), Offset(left + scanAreaWidth - cornerLength, top), cornerPaint);
    canvas.drawLine(Offset(left + scanAreaWidth, top), Offset(left + scanAreaWidth, top + cornerLength), cornerPaint);

    // Esquina inferior izquierda
    canvas.drawLine(Offset(left, top + scanAreaHeight), Offset(left + cornerLength, top + scanAreaHeight), cornerPaint);
    canvas.drawLine(Offset(left, top + scanAreaHeight), Offset(left, top + scanAreaHeight - cornerLength), cornerPaint);

    // Esquina inferior derecha
    canvas.drawLine(Offset(left + scanAreaWidth, top + scanAreaHeight), Offset(left + scanAreaWidth - cornerLength, top + scanAreaHeight), cornerPaint);
    canvas.drawLine(Offset(left + scanAreaWidth, top + scanAreaHeight), Offset(left + scanAreaWidth, top + scanAreaHeight - cornerLength), cornerPaint);
  }

  @override
  bool shouldRepaint(CustomPainter oldDelegate) => false;
}
