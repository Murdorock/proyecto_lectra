import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';
import '../main.dart';

class EditarContingenciaScreen extends StatefulWidget {
  final List<Map<String, dynamic>> registros;
  final int indexInicial;

  const EditarContingenciaScreen({
    super.key,
    required this.registros,
    required this.indexInicial,
  });

  @override
  State<EditarContingenciaScreen> createState() => _EditarContingenciaScreenState();
}

class _EditarContingenciaScreenState extends State<EditarContingenciaScreen> {
  late int _currentIndex;
  late Map<String, dynamic> _currentData;
  bool _isLoading = false;
  String? _errorMessage;
  final TextEditingController _lecturaTomadaController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  final GlobalKey _lecturaFieldKey = GlobalKey();

  @override
  void initState() {
    super.initState();
    _currentIndex = widget.indexInicial;
    _currentData = Map<String, dynamic>.from(widget.registros[_currentIndex]);
    _lecturaTomadaController.text = _currentData['lectura_tomada']?.toString() ?? '';
  }

  @override
  void dispose() {
    _lecturaTomadaController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  Future<void> _irAlSiguiente() async {
    if (_currentIndex < widget.registros.length - 1) {
      // Guardar si hay datos en el campo antes de cambiar
      if (_lecturaTomadaController.text.trim().isNotEmpty) {
        await _guardarLecturaSinMensaje();
      }
      
      setState(() {
        _currentIndex++;
        _currentData = Map<String, dynamic>.from(widget.registros[_currentIndex]);
        _lecturaTomadaController.text = _currentData['lectura_tomada']?.toString() ?? '';
        _errorMessage = null;
      });
    }
  }

  void _irAlAnterior() {
    if (_currentIndex > 0) {
      setState(() {
        _currentIndex--;
        _currentData = Map<String, dynamic>.from(widget.registros[_currentIndex]);
        _lecturaTomadaController.text = _currentData['lectura_tomada']?.toString() ?? '';
        _errorMessage = null;
      });
    }
  }

  Future<void> _guardarLecturaSinMensaje() async {
    try {
      final ordenLectura = _currentData['orden_lectura'];
      final lecturaTomada = _lecturaTomadaController.text.trim();

      await supabase
          .from('secuencia_sin_lectura')
          .update({'lectura_tomada': lecturaTomada.isEmpty ? null : lecturaTomada})
          .eq('orden_lectura', ordenLectura);

      if (mounted) {
        _currentData['lectura_tomada'] = lecturaTomada.isEmpty ? null : lecturaTomada;
        widget.registros[_currentIndex]['lectura_tomada'] = lecturaTomada.isEmpty ? null : lecturaTomada;
      }
    } catch (e) {
      // Error silencioso, no mostrar mensaje
    }
  }

  Future<void> _guardarLectura() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final ordenLectura = _currentData['orden_lectura'];
      final lecturaTomada = _lecturaTomadaController.text.trim();

      await supabase
          .from('secuencia_sin_lectura')
          .update({'lectura_tomada': lecturaTomada.isEmpty ? null : lecturaTomada})
          .eq('orden_lectura', ordenLectura);

      if (mounted) {
        setState(() {
          _currentData['lectura_tomada'] = lecturaTomada.isEmpty ? null : lecturaTomada;
          widget.registros[_currentIndex]['lectura_tomada'] = lecturaTomada.isEmpty ? null : lecturaTomada;
          _isLoading = false;
        });

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Lectura guardada exitosamente'),
            backgroundColor: Colors.green,
            duration: Duration(seconds: 2),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _errorMessage = 'Error al guardar: ${e.toString()}';
          _isLoading = false;
        });
      }
    }
  }

  void _onNumericKeyTap(String value) {
    final currentText = _lecturaTomadaController.text;
    if (value == '⌫') {
      if (currentText.isNotEmpty) {
        _lecturaTomadaController.text = currentText.substring(0, currentText.length - 1);
      }
    } else if (value == '✓') {
      _guardarLectura();
    } else {
      _lecturaTomadaController.text = currentText + value;
    }
  }

  Widget _buildNumericKeyboard() {
    return Container(
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: Colors.grey.shade900,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          _buildKeyboardRow(['1', '2', '3']),
          const SizedBox(height: 8),
          _buildKeyboardRow(['4', '5', '6']),
          const SizedBox(height: 8),
          _buildKeyboardRow(['7', '8', '9']),
          const SizedBox(height: 8),
          _buildKeyboardRow(['⌫', '0', '✓']),
        ],
      ),
    );
  }

  Widget _buildKeyboardRow(List<String> keys) {
    return Row(
      children: keys.map((key) {
        final isDelete = key == '⌫';
        final isCheck = key == '✓';
        
        return Expanded(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 4),
            child: ElevatedButton(
              onPressed: () => _onNumericKeyTap(key),
              style: ElevatedButton.styleFrom(
                backgroundColor: isCheck 
                    ? const Color(0xFF1A5A8A) 
                    : (isDelete ? Colors.grey.shade700 : Colors.grey.shade600),
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              child: Text(
                key,
                style: const TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
        );
      }).toList(),
    );
  }

  void _mostrarDialogoCausa() {
    final opciones = [
      '01 NO EXISTE GEOGRAFICAMENTE',
      '02 IMPOSIBILIDAD DE ACCESO',
      '03 PROFUNDO MUY ALTO',
      '04 TAPADO INTERIORMENTE',
      '05 DESTRUÍDO/DAÑADO',
      '06 VOLTEADO',
      '07 MEDIDOR CON DISPLAY DESENERGIZADO',
      '08 DEMOLIDA',
      '09 SERVICIO DIRECTO',
      '11 SIN SERVICIO SIN MEDIDOR',
      '12 NO LEIDA',
      '13 NO  PERTENECE A LA CORRERIA',
      '14 AFECTACION POR FENOMENO NATURAL',
      '15 MEDIDOR PREPAGO',
    ];
    
    _mostrarDialogoSeleccion('Seleccione Causa', opciones);
  }

  void _mostrarDialogoObservacion() {
    final opciones = [
      '18 AGUA PROPIA COMUNAL',
      '19 REPARO DAÑO O FUGA',
      '21 POSIBLE IRREGULARIDAD',
      '22 CAMBIO DE ACTIVIDAD',
      '23 INSTALACION VACIA',
      '25 MEDIDOR PARADO O DAÑADO',
      '26 SURTE OTRAS INSTALACIONES',
      '27 SE SURTE DE OTRA INSTALACION',
      '28 SIN  SERVICIO CON MEDIDOR',
      '29 REGISTRO DEVOLVIENDO',
      '30 DESVIACIÓN SIGNIFICATIVA',
      '31 MEDIDOR CAMBIADO',
      '33 FUGA PERCEPTIBLE',
      '34 LECTURA MENOR',
      '36 MEDIDORES TROCADOS',
      '39 CORRECCIÓN LECTURA',
    ];
    
    _mostrarDialogoSeleccion('Seleccione Observación', opciones);
  }

  void _mostrarDialogoSeleccion(String titulo, List<String> opciones) {
    String? seleccion;
    
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return StatefulBuilder(
          builder: (context, setStateDialog) {
            return AlertDialog(
              title: Text(
                titulo,
                style: const TextStyle(
                  color: Color(0xFF1A237E),
                  fontWeight: FontWeight.bold,
                ),
              ),
              content: SizedBox(
                width: double.maxFinite,
                child: Column(
                  children: opciones.map((opcion) {
                    return RadioListTile<String>(
                      value: opcion,
                      groupValue: seleccion,
                      onChanged: (value) {
                        setStateDialog(() {
                          seleccion = value;
                        });
                      },
                      title: Text(
                        opcion,
                        style: const TextStyle(fontSize: 13),
                      ),
                    );
                  }).toList(),
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () {
                    Navigator.of(context).pop();
                  },
                  child: const Text(
                    'LIMPIAR',
                    style: TextStyle(color: Colors.grey),
                  ),
                ),
                ElevatedButton(
                  onPressed: seleccion != null
                      ? () {
                          Navigator.of(context).pop();
                          _guardarCausaObservacion(seleccion!);
                        }
                      : null,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF1A237E),
                    foregroundColor: Colors.white,
                  ),
                  child: const Text('GUARDAR'),
                ),
              ],
            );
          },
        );
      },
    );
  }

  Future<void> _guardarCausaObservacion(String valor) async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final ordenLectura = _currentData['orden_lectura'];

      await supabase
          .from('secuencia_sin_lectura')
          .update({'causanl_obs': valor})
          .eq('orden_lectura', ordenLectura);

      if (mounted) {
        setState(() {
          _currentData['causanl_obs'] = valor;
          widget.registros[_currentIndex]['causanl_obs'] = valor;
          _isLoading = false;
        });

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Guardado: $valor'),
            backgroundColor: Colors.green,
            duration: const Duration(seconds: 2),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _errorMessage = 'Error al guardar: ${e.toString()}';
          _isLoading = false;
        });
      }
    }
  }

  // Botón Adicional
  void _mostrarDialogoAdicional() {
    final opciones = [
      '54-SUSPENDIDO',
      '55-VACIA/ABANDONADA',
      '56-HABITADA USAN',
      '57-HABITADA NO USAN',
      '58-LECTURA NO RECUPERABLE',
      '60-ACOMETIDA PELADA ( E )',
      '63-CAMBIO DE USO O ACTIVIDAD(EGA)',
      '68-POSIBLE IRREGULARIDAD',
      '70-FUGA PERCEPTIBLE (A)',
      '71-VER ALFANUMÉRICA (EGA)',
      '72-LTM Y REVISIÓN TÉCN LECT (EGA)',
      '73-OBSERVACION ESPECIFICA (EGA)',
      '74-OLOR A GAS (G)',
      '75-NO PERTENECE A LA CORRERÍA EGA',
      '80-SURTE OTROS INMUEBLES(EGA)',
      '83-MEDIDOR PARADO O DAÑADO (EGA)',
      '84-DISPLAY REINICIADO (E)',
      '85-DISPLAY DESCONFIGURADO (E)',
      '90-SIN PUENTE/GARRUCHA MALA (E)',
      '91-CASA SOLA',
      '92-CLIENTE NO JUSTIFICA',
      '93-REVISIÓN TÉCNICA LECT (EGA)',
      '96-MEDIDOR MAL PARAMETRIZADO (E)',
      '98-SE DEJO CONSTANCIA LECTURA',
    ];
    
    String? seleccion;
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return StatefulBuilder(
          builder: (context, setStateDialog) {
            return AlertDialog(
              title: const Text('Seleccione Adicional'),
              content: SizedBox(
                width: double.maxFinite,
                child: ListView.builder(
                  shrinkWrap: true,
                  itemCount: opciones.length,
                  itemBuilder: (context, index) {
                    final opcion = opciones[index];
                    return RadioListTile<String>(
                      value: opcion,
                      groupValue: seleccion,
                      activeColor: const Color(0xFF1A237E),
                      contentPadding: EdgeInsets.zero,
                      visualDensity: VisualDensity.compact,
                      dense: true,
                      title: Text(
                        opcion,
                        style: const TextStyle(fontSize: 13),
                      ),
                      onChanged: (value) {
                        setStateDialog(() {
                          seleccion = value;
                        });
                      },
                    );
                  },
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () {
                    Navigator.of(context).pop();
                  },
                  child: const Text(
                    'LIMPIAR',
                    style: TextStyle(color: Colors.grey),
                  ),
                ),
                ElevatedButton(
                  onPressed: seleccion != null
                      ? () {
                          Navigator.of(context).pop();
                          _guardarObsAdic(seleccion!);
                        }
                      : null,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF1A237E),
                    foregroundColor: Colors.white,
                  ),
                  child: const Text('GUARDAR'),
                ),
              ],
            );
          },
        );
      },
    );
  }

  Future<void> _guardarObsAdic(String valor) async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final ordenLectura = _currentData['orden_lectura'];

      await supabase
          .from('secuencia_sin_lectura')
          .update({'obs_adic': valor})
          .eq('orden_lectura', ordenLectura);

      if (mounted) {
        setState(() {
          _currentData['obs_adic'] = valor;
          widget.registros[_currentIndex]['obs_adic'] = valor;
          _isLoading = false;
        });

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Guardado: $valor'),
            backgroundColor: Colors.green,
            duration: const Duration(seconds: 2),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _errorMessage = 'Error al guardar: ${e.toString()}';
          _isLoading = false;
        });
      }
    }
  }

  // Botón Alfa
  void _mostrarDialogoAlfa() {
    final TextEditingController textoController = TextEditingController();
    
    // Cargar valor existente si hay
    final valorActual = _currentData['observ_alfanum']?.toString() ?? '';
    textoController.text = valorActual;
    
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Observación Alfanumérica'),
          content: TextField(
            controller: textoController,
            decoration: const InputDecoration(
              hintText: 'Ingrese observación',
              border: OutlineInputBorder(),
            ),
            maxLines: 3,
            textCapitalization: TextCapitalization.characters,
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
              },
              child: const Text(
                'CANCELAR',
                style: TextStyle(color: Colors.grey),
              ),
            ),
            ElevatedButton(
              onPressed: () {
                Navigator.of(context).pop();
                _guardarObservAlfanum(textoController.text.trim());
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF1A237E),
                foregroundColor: Colors.white,
              ),
              child: const Text('GUARDAR'),
            ),
          ],
        );
      },
    );
  }

  Future<void> _guardarObservAlfanum(String valor) async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final ordenLectura = _currentData['orden_lectura'];

      await supabase
          .from('secuencia_sin_lectura')
          .update({'observ_alfanum': valor})
          .eq('orden_lectura', ordenLectura);

      if (mounted) {
        setState(() {
          _currentData['observ_alfanum'] = valor;
          widget.registros[_currentIndex]['observ_alfanum'] = valor;
          _isLoading = false;
        });

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Observación guardada: $valor'),
            backgroundColor: Colors.green,
            duration: const Duration(seconds: 2),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _errorMessage = 'Error al guardar: ${e.toString()}';
          _isLoading = false;
        });
      }
    }
  }

  // Botón Foto
  void _mostrarDialogoFoto() async {
    final urlActual = _currentData['orden_agrupadora']?.toString() ?? '';
    
    if (urlActual.isNotEmpty && urlActual.startsWith('http')) {
      // Mostrar foto existente
      showDialog(
        context: context,
        builder: (BuildContext context) {
          return AlertDialog(
            title: const Text('Foto de Contingencia'),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Image.network(
                  urlActual,
                  loadingBuilder: (context, child, loadingProgress) {
                    if (loadingProgress == null) return child;
                    return const CircularProgressIndicator();
                  },
                  errorBuilder: (context, error, stackTrace) {
                    return const Text('Error al cargar la imagen');
                  },
                ),
                const SizedBox(height: 16),
                const Text('¿Desea tomar una nueva foto?'),
              ],
            ),
            actions: [
              TextButton(
                onPressed: () {
                  Navigator.of(context).pop();
                },
                child: const Text('CANCELAR'),
              ),
              ElevatedButton(
                onPressed: () {
                  Navigator.of(context).pop();
                  _tomarFoto();
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF1A237E),
                  foregroundColor: Colors.white,
                ),
                child: const Text('TOMAR NUEVA FOTO'),
              ),
            ],
          );
        },
      );
    } else {
      // No hay foto, tomar nueva
      _tomarFoto();
    }
  }

  Future<void> _tomarFoto() async {
    try {
      final ImagePicker picker = ImagePicker();
      final XFile? photo = await picker.pickImage(
        source: ImageSource.camera,
        maxWidth: 1920,
        maxHeight: 1080,
        imageQuality: 85,
      );

      if (photo == null) return;

      setState(() {
        _isLoading = true;
        _errorMessage = null;
      });

      // Leer archivo
      final File imageFile = File(photo.path);
      final bytes = await imageFile.readAsBytes();
      
      // Generar nombre único
      final ordenLectura = _currentData['orden_lectura'];
      final timestamp = DateTime.now().millisecondsSinceEpoch;
      final fileName = 'contingencia/${ordenLectura}_$timestamp.jpg';

      // Subir a Supabase Storage
      await supabase.storage
          .from('cold')
          .uploadBinary(fileName, bytes);

      // Obtener URL pública
      final publicUrl = supabase.storage
          .from('cold')
          .getPublicUrl(fileName);

      // Guardar URL en la base de datos
      await supabase
          .from('secuencia_sin_lectura')
          .update({'orden_agrupadora': publicUrl})
          .eq('orden_lectura', ordenLectura);

      if (mounted) {
        setState(() {
          _currentData['orden_agrupadora'] = publicUrl;
          widget.registros[_currentIndex]['orden_agrupadora'] = publicUrl;
          _isLoading = false;
        });

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Foto guardada exitosamente'),
            backgroundColor: Colors.green,
            duration: Duration(seconds: 2),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _errorMessage = 'Error al guardar foto: ${e.toString()}';
          _isLoading = false;
        });
        
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: ${e.toString()}'),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 3),
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Registro ${_currentIndex + 1} de ${widget.registros.length}',
          style: const TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
          ),
        ),
        backgroundColor: const Color(0xFF1A237E),
        iconTheme: const IconThemeData(color: Colors.white),
        actions: [
          // Botón anterior
          IconButton(
            icon: const Icon(Icons.arrow_back_ios),
            onPressed: _currentIndex > 0 ? _irAlAnterior : null,
            tooltip: 'Anterior',
          ),
          // Indicador de posición
          Center(
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.2),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Text(
                '${_currentIndex + 1}/${widget.registros.length}',
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: 14,
                ),
              ),
            ),
          ),
          // Botón siguiente
          IconButton(
            icon: const Icon(Icons.arrow_forward_ios),
            onPressed: _currentIndex < widget.registros.length - 1 ? _irAlSiguiente : null,
            tooltip: 'Siguiente',
          ),
        ],
      ),
      body: _isLoading
          ? const Center(
              child: CircularProgressIndicator(
                color: Color(0xFF1A237E),
              ),
            )
          : Column(
              children: [
                // Contenido con scroll
                Expanded(
                  child: SingleChildScrollView(
                    controller: _scrollController,
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Mensaje de error si existe
                        if (_errorMessage != null) ...[
                          Container(
                            padding: const EdgeInsets.all(12),
                            margin: const EdgeInsets.only(bottom: 16),
                            decoration: BoxDecoration(
                              color: Colors.red.shade50,
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(color: Colors.red.shade300),
                            ),
                            child: Row(
                              children: [
                                Icon(Icons.error_outline, color: Colors.red.shade700),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: Text(
                                    _errorMessage!,
                                    style: TextStyle(color: Colors.red.shade700),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],

                  // Tarjeta de información principal
                  Card(
                    elevation: 2,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Dirección
                          Text(
                            _currentData['direccion']?.toString() ?? 'Sin dirección',
                            style: const TextStyle(
                              fontSize: 14,
                              color: Colors.black87,
                              height: 1.4,
                            ),
                          ),
                          const SizedBox(height: 12),

                          // Municipio
                          Text(
                            _currentData['municipio']?.toString() ?? 'Sin municipio',
                            style: const TextStyle(
                              fontSize: 14,
                              color: Colors.black87,
                            ),
                          ),
                          const SizedBox(height: 20),

                          // Ubicación del medidor
                          Text(
                            _currentData['ubicacion_med']?.toString().toUpperCase() ?? 'SIN UBICACIÓN',
                            style: const TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.w600,
                              color: Colors.black87,
                            ),
                          ),
                          const SizedBox(height: 16),

                          // Serie del medidor
                          Row(
                            children: [
                              const Text(
                                'Serie ',
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.black87,
                                ),
                              ),
                              Text(
                                _currentData['serie_medidor']?.toString() ?? 'Sin serie',
                                style: const TextStyle(
                                  fontSize: 16,
                                  color: Colors.black87,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 20),

                          // Advertencia (si existe)
                          if (_currentData['advertencia_lect'] != null && 
                              _currentData['advertencia_lect'].toString().isNotEmpty) ...[
                            Container(
                              padding: const EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                color: Colors.orange.shade50,
                                borderRadius: BorderRadius.circular(8),
                                border: Border.all(color: Colors.orange.shade300),
                              ),
                              child: Row(
                                children: [
                                  Icon(Icons.warning_amber, color: Colors.orange.shade700),
                                  const SizedBox(width: 8),
                                  Expanded(
                                    child: Text(
                                      _currentData['advertencia_lect'].toString(),
                                      style: TextStyle(
                                        fontSize: 13,
                                        color: Colors.orange.shade900,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(height: 20),
                          ],

                          // Tipo de consumo
                          Text(
                            _currentData['tipo_consumo']?.toString() ?? 'Sin tipo de consumo',
                            style: const TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: Colors.black87,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),

                  const SizedBox(height: 16),

                  // Tarjeta de Lectura Tomada
                  Card(
                    key: _lecturaFieldKey,
                    elevation: 2,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const SizedBox(height: 8),
                          // Campo de texto simple para lectura
                          TextField(
                            controller: _lecturaTomadaController,
                            readOnly: true,
                            textAlign: TextAlign.center,
                            decoration: InputDecoration(
                              hintText: 'Ingrese la lectura',
                              hintStyle: TextStyle(
                                color: Colors.grey.shade400,
                                fontSize: 18,
                              ),
                              filled: true,
                              fillColor: Colors.grey.shade50,
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(8),
                                borderSide: BorderSide(color: Colors.grey.shade300, width: 1.5),
                              ),
                              enabledBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(8),
                                borderSide: BorderSide(color: Colors.grey.shade300, width: 1.5),
                              ),
                              contentPadding: const EdgeInsets.symmetric(
                                horizontal: 16,
                                vertical: 20,
                              ),
                            ),
                            style: const TextStyle(
                              fontSize: 32,
                              fontWeight: FontWeight.bold,
                              color: Colors.black87,
                              letterSpacing: 4,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                      ],
                    ),
                  ),
                ),
                
                // Botones de acciones (Causa, Observación, etc.)
                Container(
                  padding: const EdgeInsets.fromLTRB(8, 8, 8, 0),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    boxShadow: [
                      BoxShadow(
                        color: Colors.grey.shade300,
                        blurRadius: 4,
                        offset: const Offset(0, -2),
                      ),
                    ],
                  ),
                  child: Row(
                    children: [
                      Expanded(
                        child: Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 2),
                          child: OutlinedButton(
                            onPressed: _mostrarDialogoCausa,
                            style: OutlinedButton.styleFrom(
                              padding: const EdgeInsets.symmetric(vertical: 10),
                              foregroundColor: const Color(0xFF1A237E),
                              side: const BorderSide(color: Color(0xFF1A237E), width: 1.5),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(8),
                              ),
                            ),
                            child: const Text(
                              'Causa',
                              style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold),
                            ),
                          ),
                        ),
                      ),
                      Expanded(
                        child: Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 2),
                          child: OutlinedButton(
                            onPressed: _mostrarDialogoObservacion,
                            style: OutlinedButton.styleFrom(
                              padding: const EdgeInsets.symmetric(vertical: 10),
                              foregroundColor: const Color(0xFF1A237E),
                              side: const BorderSide(color: Color(0xFF1A237E), width: 1.5),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(8),
                              ),
                            ),
                            child: const Text(
                              'Observación',
                              style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ),
                      ),
                      Expanded(
                        child: Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 2),
                          child: OutlinedButton(
                            onPressed: _mostrarDialogoAdicional,
                            style: OutlinedButton.styleFrom(
                              padding: const EdgeInsets.symmetric(vertical: 10),
                              foregroundColor: const Color(0xFF1A237E),
                              side: const BorderSide(color: Color(0xFF1A237E), width: 1.5),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(8),
                              ),
                            ),
                            child: const Text(
                              'Adicional',
                              style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold),
                            ),
                          ),
                        ),
                      ),
                      Expanded(
                        child: Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 2),
                          child: OutlinedButton(
                            onPressed: _mostrarDialogoAlfa,
                            style: OutlinedButton.styleFrom(
                              padding: const EdgeInsets.symmetric(vertical: 10),
                              foregroundColor: const Color(0xFF1A237E),
                              side: const BorderSide(color: Color(0xFF1A237E), width: 1.5),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(8),
                              ),
                            ),
                            child: const Text(
                              'Alfa',
                              style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold),
                            ),
                          ),
                        ),
                      ),
                      Expanded(
                        child: Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 2),
                          child: OutlinedButton(
                            onPressed: _mostrarDialogoFoto,
                            style: OutlinedButton.styleFrom(
                              padding: const EdgeInsets.symmetric(vertical: 10),
                              foregroundColor: const Color(0xFF1A237E),
                              side: const BorderSide(color: Color(0xFF1A237E), width: 1.5),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(8),
                              ),
                            ),
                            child: const Text(
                              'Foto',
                              style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                
                // Botones de navegación fijos
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.white,
                  ),
                  child: Row(
                    children: [
                      Expanded(
                        child: OutlinedButton.icon(
                          onPressed: _currentIndex > 0 ? _irAlAnterior : null,
                          icon: const Icon(Icons.arrow_back),
                          label: const Text('ANTERIOR'),
                          style: OutlinedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(vertical: 14),
                            side: BorderSide(
                              color: _currentIndex > 0 
                                  ? const Color(0xFF1A237E) 
                                  : Colors.grey.shade300,
                              width: 2,
                            ),
                            foregroundColor: _currentIndex > 0 
                                ? const Color(0xFF1A237E) 
                                : Colors.grey.shade400,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(10),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: ElevatedButton.icon(
                          onPressed: _currentIndex < widget.registros.length - 1 
                              ? _irAlSiguiente 
                              : null,
                          icon: const Icon(Icons.arrow_forward),
                          label: const Text('SIGUIENTE'),
                          style: ElevatedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(vertical: 14),
                            backgroundColor: _currentIndex < widget.registros.length - 1
                                ? const Color(0xFF1A237E)
                                : Colors.grey.shade400,
                            foregroundColor: Colors.white,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(10),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),

                // Teclado numérico
                _buildNumericKeyboard(),
              ],
            ),
    );
  }
}
