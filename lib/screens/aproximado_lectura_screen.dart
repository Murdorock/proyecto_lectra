import 'package:flutter/material.dart';
import '../main.dart';
import '../services/user_session.dart';

class AproximadoLecturaScreen extends StatefulWidget {
  const AproximadoLecturaScreen({super.key});

  @override
  State<AproximadoLecturaScreen> createState() => _AproximadoLecturaScreenState();
}

class _AproximadoLecturaScreenState extends State<AproximadoLecturaScreen> {
  List<Map<String, dynamic>> _codigos = [];
  List<Map<String, dynamic>> _codigosFiltrados = [];
  bool _isLoading = true;
  String? _errorMessage;
  bool _vistaTabla = false;
  final TextEditingController _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _loadCodigos();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _filtrarCodigos(String query) {
    setState(() {
      if (query.isEmpty) {
        _codigosFiltrados = _codigos;
      } else {
        _codigosFiltrados = _codigos.where((codigo) {
          final codigoStr = codigo['codigo']?.toString().toLowerCase() ?? '';
          final nombreLector = codigo['nombre_lector']?.toString().toLowerCase() ?? '';
          final idCorreria = codigo['id_correria']?.toString().toLowerCase() ?? '';
          final searchLower = query.toLowerCase();
          
          return codigoStr.contains(searchLower) ||
                 nombreLector.contains(searchLower) ||
                 idCorreria.contains(searchLower);
        }).toList();
      }
    });
  }

  Future<void> _loadCodigos() async {
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

      // Consultar la tabla aproximados filtrando por realiza_zona
      final data = await supabase
          .from('aproximados')
          .select('''
            id_correria, nombre_correria, codigo, origen, transporte, grupo_vehicular, 
            terreno, dias, totales, nombre_lector, historico1, historico2, observacion, calificativo
          ''')
          .eq('realiza_zona', codigoSupAux)
          .order('codigo', ascending: true);

      if (mounted) {
        setState(() {
          _codigos = List<Map<String, dynamic>>.from(data);
          _codigosFiltrados = _codigos;
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

  Future<void> _guardarObservacion(Map<String, dynamic> codigo, String nuevaObservacion) async {
    try {
      await supabase
          .from('aproximados')
          .update({'observacion': nuevaObservacion.isEmpty ? null : nuevaObservacion})
          .eq('id_correria', codigo['id_correria']);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Observación guardada exitosamente'),
            backgroundColor: Colors.green,
          ),
        );
        _loadCodigos();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error al guardar: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _guardarCodigo(Map<String, dynamic> registro, String? nuevoCodigo) async {
    if (nuevoCodigo == null || nuevoCodigo.isEmpty) {
      return;
    }

    try {
      // Validar en hist_lectura si el código ya está asignado a esta correría
      final validacion = await supabase
          .from('hist_lectura')
          .select('lector, correria, fecha')
          .eq('lector', nuevoCodigo)
          .eq('correria', registro['id_correria']);

      // Si hay coincidencias, no permitir el guardado
      if (validacion.isNotEmpty) {
        final fecha = validacion[0]['fecha']?.toString() ?? 'fecha desconocida';
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                'Este código ya realizó la correría ${registro['id_correria']} el día $fecha',
              ),
              backgroundColor: Colors.orange,
              duration: const Duration(seconds: 5),
            ),
          );
        }
        return;
      }

      // Obtener información del nuevo lector desde la tabla personal
      final datosLector = await supabase
          .from('personal')
          .select('id_codigo, nombre_completo')
          .eq('id_codigo', nuevoCodigo)
          .maybeSingle();

      String? nombreLector;
      if (datosLector != null) {
        nombreLector = datosLector['nombre_completo']?.toString();
      }

      // Buscar días y observación del lector desde el registro donde este código está como 'origen'
      final registroOrigen = await supabase
          .from('aproximados')
          .select('dias, observacion')
          .eq('origen', nuevoCodigo)
          .limit(1)
          .maybeSingle();

      int? diasLector;
      String? observacionLector;
      
      if (registroOrigen != null) {
        if (registroOrigen['dias'] != null) {
          diasLector = int.tryParse(registroOrigen['dias'].toString());
        }
        if (registroOrigen['observacion'] != null) {
          observacionLector = registroOrigen['observacion'].toString();
        }
      } else {
        // Si no se encuentra como origen, buscar en registros donde ya está asignado como código
        final registrosLector = await supabase
            .from('aproximados')
            .select('dias, observacion')
            .eq('codigo', nuevoCodigo)
            .limit(1)
            .maybeSingle();

        if (registrosLector != null) {
          if (registrosLector['dias'] != null) {
            diasLector = int.tryParse(registrosLector['dias'].toString());
          }
          if (registrosLector['observacion'] != null) {
            observacionLector = registrosLector['observacion'].toString();
          }
        }
      }

      // Preparar datos para actualizar
      final Map<String, dynamic> datosActualizar = {
        'codigo': nuevoCodigo,
      };

      // Agregar nombre_lector si se encontró
      if (nombreLector != null) {
        datosActualizar['nombre_lector'] = nombreLector;
      }

      // Agregar dias si se encontró
      if (diasLector != null) {
        datosActualizar['dias'] = diasLector;
      }

      // Agregar observación si se encontró
      if (observacionLector != null) {
        datosActualizar['observacion'] = observacionLector;
      } else {
        // Limpiar observación si no se encontró
        datosActualizar['observacion'] = null;
      }

      // Si no hay conflictos, proceder con el guardado
      await supabase
          .from('aproximados')
          .update(datosActualizar)
          .eq('id_correria', registro['id_correria']);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Código actualizado exitosamente'),
            backgroundColor: Colors.green,
          ),
        );
        _loadCodigos();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error al actualizar código: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  void _mostrarDialogObservacion(Map<String, dynamic> codigo) {
    final TextEditingController controller = TextEditingController(
      text: codigo['observacion']?.toString() ?? '',
    );

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Observación - Código ${codigo['codigo']}'),
        content: TextField(
          controller: controller,
          maxLines: 4,
          decoration: const InputDecoration(
            hintText: 'Escriba la observación',
            border: OutlineInputBorder(),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('CANCELAR'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              _guardarObservacion(codigo, controller.text);
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF1A237E),
              foregroundColor: Colors.white,
            ),
            child: const Text('GUARDAR'),
          ),
        ],
      ),
    );
  }

  List<DropdownMenuItem<String>> _buildCodigoDropdownItems(Map<String, dynamic> registro) {
    // Obtener todos los códigos de origen disponibles
    final Set<String> codigosOrigen = {};
    
    // Agregar el código actual
    if (registro['codigo'] != null && registro['codigo'].toString().isNotEmpty) {
      codigosOrigen.add(registro['codigo'].toString());
    }
    
    // Agregar los códigos de la columna origen de todos los registros
    for (var item in _codigos) {
      if (item['origen'] != null && item['origen'].toString().isNotEmpty) {
        codigosOrigen.add(item['origen'].toString());
      }
    }
    
    // Convertir a lista ordenada
    final List<String> codigosOrdenados = codigosOrigen.toList()..sort();
    
    return codigosOrdenados.map((codigo) {
      return DropdownMenuItem<String>(
        value: codigo,
        child: Text(codigo),
      );
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Aproximado Lectura'),
        backgroundColor: const Color(0xFF1A237E),
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadCodigos,
            tooltip: 'Actualizar',
          ),
        ],
      ),
      body: Column(
        children: [
          // Header con contador
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: const Color(0xFF1A237E).withValues(alpha: 0.1),
              border: const Border(
                bottom: BorderSide(
                  color: Color(0xFF1A237E),
                  width: 2,
                ),
              ),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Códigos Asignados',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF1A237E),
                  ),
                ),
                if (!_isLoading)
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
                      '${_codigosFiltrados.length}',
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
              ],
            ),
          ),

          // Barra de búsqueda y botón VISTA
          if (!_isLoading && _errorMessage == null)
            Container(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _searchController,
                      onChanged: _filtrarCodigos,
                      decoration: InputDecoration(
                        hintText: 'Buscar por código, lector o correria...',
                        prefixIcon: const Icon(
                          Icons.search,
                          color: Color(0xFF1A237E),
                        ),
                        suffixIcon: _searchController.text.isNotEmpty
                            ? IconButton(
                                icon: const Icon(Icons.clear),
                                onPressed: () {
                                  _searchController.clear();
                                  _filtrarCodigos('');
                                },
                              )
                            : null,
                        filled: true,
                        fillColor: Colors.grey.shade100,
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: const BorderSide(
                            color: Color(0xFF1A237E),
                          ),
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide(
                            color: Colors.grey.shade300,
                          ),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: const BorderSide(
                            color: Color(0xFF1A237E),
                            width: 2,
                          ),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  ElevatedButton.icon(
                    onPressed: () {
                      setState(() {
                        _vistaTabla = !_vistaTabla;
                      });
                    },
                    icon: Icon(_vistaTabla ? Icons.grid_view : Icons.table_chart),
                    label: const Text('VISTA'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF1A237E),
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(
                        horizontal: 20,
                        vertical: 16,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                  ),
                ],
              ),
            ),

          // Contenido
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
                                onPressed: _loadCodigos,
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
                    : _codigosFiltrados.isEmpty
                        ? Center(
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(
                                  Icons.inbox_outlined,
                                  size: 64,
                                  color: Colors.grey.shade400,
                                ),
                                const SizedBox(height: 16),
                                Text(
                                  _searchController.text.isNotEmpty
                                      ? 'No se encontraron resultados'
                                      : 'No hay códigos asignados',
                                  style: TextStyle(
                                    fontSize: 16,
                                    color: Colors.grey.shade600,
                                  ),
                                ),
                              ],
                            ),
                          )
                        : _vistaTabla
                            ? _buildVistaTabla()
                            : _buildVistaTarjetas(),
          ),
        ],
      ),
    );
  }

  Widget _buildVistaTabla() {
    // Identificar códigos repetidos en la columna LECT (codigo)
    final Map<String, int> contadorCodigos = {};
    for (var item in _codigosFiltrados) {
      final codigo = item['codigo']?.toString() ?? '';
      if (codigo.isNotEmpty) {
        contadorCodigos[codigo] = (contadorCodigos[codigo] ?? 0) + 1;
      }
    }
    
    // Identificar valores repetidos en HIST1
    final Map<String, int> contadorHist1 = {};
    for (var item in _codigosFiltrados) {
      final hist1 = item['historico1']?.toString() ?? '';
      if (hist1.isNotEmpty) {
        contadorHist1[hist1] = (contadorHist1[hist1] ?? 0) + 1;
      }
    }
    
    // Identificar valores repetidos en HIST2
    final Map<String, int> contadorHist2 = {};
    for (var item in _codigosFiltrados) {
      final hist2 = item['historico2']?.toString() ?? '';
      if (hist2.isNotEmpty) {
        contadorHist2[hist2] = (contadorHist2[hist2] ?? 0) + 1;
      }
    }
    
    return SingleChildScrollView(
      scrollDirection: Axis.vertical,
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Container(
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.08),
                  blurRadius: 10,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(16),
              child: DataTable(
                headingRowColor: WidgetStateProperty.all(
                  const Color(0xFF1A237E),
                ),
                headingRowHeight: 56,
                dataRowMinHeight: 48,
                dataRowMaxHeight: 56,
                headingTextStyle: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: 13,
                  letterSpacing: 0.5,
                ),
                dataTextStyle: const TextStyle(
                  fontSize: 12,
                  color: Colors.black87,
                ),
                columnSpacing: 24,
                horizontalMargin: 20,
                dividerThickness: 0.5,
                border: TableBorder(
                  horizontalInside: BorderSide(
                    color: Colors.grey.shade200,
                    width: 1,
                  ),
                  verticalInside: BorderSide(
                    color: Colors.grey.shade200,
                    width: 1,
                  ),
                ),
                columns: const [
              DataColumn(label: Text('CORRERIA')),
              DataColumn(label: Text('NOMBRE')),
              DataColumn(label: Text('GV')),
              DataColumn(label: Text('CALIFICATIVO')),
              DataColumn(label: Text('TERRE')),
              DataColumn(label: Text('TOTALES')),
              DataColumn(label: Text('LECT')),
              DataColumn(label: Text('DIAS')),
              DataColumn(label: Text('NOMBRE')),
              DataColumn(label: Text('HIST1')),
              DataColumn(label: Text('HIST2')),
              DataColumn(label: Text('OBSERVACION')),
            ],
            rows: _codigosFiltrados.map((codigo) {
              final codigoLect = codigo['codigo']?.toString() ?? '';
              final esRepetido = codigoLect.isNotEmpty && (contadorCodigos[codigoLect] ?? 0) > 1;
              
              // Verificar si los días son menores de 90
              final diasStr = codigo['dias']?.toString() ?? '';
              final dias = int.tryParse(diasStr) ?? 0;
              final diasMenorDe90 = dias < 90 && dias > 0;
              
              // Verificar si hist1 está repetido
              final hist1Str = codigo['historico1']?.toString() ?? '';
              final hist1Repetido = hist1Str.isNotEmpty && (contadorHist1[hist1Str] ?? 0) > 1;
              
              // Verificar si hist2 está repetido
              final hist2Str = codigo['historico2']?.toString() ?? '';
              final hist2Repetido = hist2Str.isNotEmpty && (contadorHist2[hist2Str] ?? 0) > 1;
              
              return DataRow(
                cells: [
                  DataCell(Text(codigo['id_correria']?.toString() ?? '')),
                  DataCell(Text(codigo['nombre_correria']?.toString() ?? '')),
                  // Columna GV con color rojo si contiene 'moto'
                  DataCell(
                    Builder(
                      builder: (context) {
                        final gv = codigo['grupo_vehicular']?.toString() ?? '';
                        final contienenMoto = gv.toLowerCase().contains('moto');
                        
                        return Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                          decoration: contienenMoto
                              ? BoxDecoration(
                                  color: Colors.red.shade100,
                                  borderRadius: BorderRadius.circular(4),
                                  border: Border.all(
                                    color: Colors.red.shade400,
                                    width: 1.5,
                                  ),
                                )
                              : null,
                          child: Text(
                            gv,
                            style: TextStyle(
                              fontWeight: contienenMoto ? FontWeight.bold : FontWeight.normal,
                              color: contienenMoto ? Colors.red.shade900 : Colors.black87,
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                  // Columna CALIFICATIVO con colores según el valor
                  DataCell(
                    Builder(
                      builder: (context) {
                        final calificativo = codigo['calificativo']?.toString().toUpperCase() ?? '';
                        Color? backgroundColor;
                        Color? borderColor;
                        Color? textColor;
                        
                        switch (calificativo) {
                          case 'B':
                            backgroundColor = Colors.blue.shade100;
                            borderColor = Colors.blue.shade400;
                            textColor = Colors.blue.shade900;
                            break;
                          case 'N':
                            backgroundColor = Colors.green.shade100;
                            borderColor = Colors.green.shade400;
                            textColor = Colors.green.shade900;
                            break;
                          case 'R':
                            backgroundColor = Colors.brown.shade100;
                            borderColor = Colors.brown.shade400;
                            textColor = Colors.brown.shade900;
                            break;
                          case 'M':
                            backgroundColor = Colors.red.shade100;
                            borderColor = Colors.red.shade400;
                            textColor = Colors.red.shade900;
                            break;
                          default:
                            backgroundColor = null;
                            borderColor = null;
                            textColor = Colors.black87;
                        }
                        
                        return Container(
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                          decoration: backgroundColor != null
                              ? BoxDecoration(
                                  color: backgroundColor,
                                  borderRadius: BorderRadius.circular(4),
                                  border: Border.all(
                                    color: borderColor!,
                                    width: 1.5,
                                  ),
                                )
                              : null,
                          child: Text(
                            calificativo,
                            style: TextStyle(
                              fontWeight: backgroundColor != null ? FontWeight.bold : FontWeight.normal,
                              color: textColor,
                              fontSize: 13,
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                  DataCell(Text(codigo['terreno']?.toString() ?? '')),
                  DataCell(Text(codigo['totales']?.toString() ?? '')),
                  // Columna LECT con color morado si está repetido
                  DataCell(
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: esRepetido
                          ? BoxDecoration(
                              color: Colors.purple.shade100,
                              borderRadius: BorderRadius.circular(4),
                              border: Border.all(
                                color: Colors.purple.shade700,
                                width: 1.5,
                              ),
                            )
                          : null,
                      child: Text(
                        codigoLect,
                        style: TextStyle(
                          fontWeight: esRepetido ? FontWeight.bold : FontWeight.normal,
                          color: esRepetido ? Colors.purple.shade900 : Colors.black87,
                        ),
                      ),
                    ),
                  ),
                  // Columna DIAS con color naranja si es menor de 90
                  DataCell(
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: diasMenorDe90
                          ? BoxDecoration(
                              color: Colors.orange.shade100,
                              borderRadius: BorderRadius.circular(4),
                              border: Border.all(
                                color: Colors.orange.shade700,
                                width: 1.5,
                              ),
                            )
                          : null,
                      child: Text(
                        diasStr,
                        style: TextStyle(
                          fontWeight: diasMenorDe90 ? FontWeight.bold : FontWeight.normal,
                          color: diasMenorDe90 ? Colors.orange.shade900 : Colors.black87,
                        ),
                      ),
                    ),
                  ),
                  DataCell(Text(codigo['nombre_lector']?.toString() ?? '')),
                  // Columna HIST1 con color rojo claro si está repetido
                  DataCell(
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: hist1Repetido
                          ? BoxDecoration(
                              color: Colors.red.shade100,
                              borderRadius: BorderRadius.circular(4),
                              border: Border.all(
                                color: Colors.red.shade400,
                                width: 1.5,
                              ),
                            )
                          : null,
                      child: Text(
                        hist1Str,
                        style: TextStyle(
                          fontWeight: hist1Repetido ? FontWeight.bold : FontWeight.normal,
                          color: hist1Repetido ? Colors.red.shade800 : Colors.black87,
                        ),
                      ),
                    ),
                  ),
                  // Columna HIST2 con color rojo claro si está repetido
                  DataCell(
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: hist2Repetido
                          ? BoxDecoration(
                              color: Colors.red.shade100,
                              borderRadius: BorderRadius.circular(4),
                              border: Border.all(
                                color: Colors.red.shade400,
                                width: 1.5,
                              ),
                            )
                          : null,
                      child: Text(
                        hist2Str,
                        style: TextStyle(
                          fontWeight: hist2Repetido ? FontWeight.bold : FontWeight.normal,
                          color: hist2Repetido ? Colors.red.shade800 : Colors.black87,
                        ),
                      ),
                    ),
                  ),
                  DataCell(
                    SizedBox(
                      width: 150,
                      child: Text(
                        codigo['observacion']?.toString() ?? '',
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ),
                ],
              );
            }).toList(),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildVistaTarjetas() {
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: _codigosFiltrados.length,
      itemBuilder: (context, index) {
        final codigo = _codigosFiltrados[index];
                              
                              return Card(
                                margin: const EdgeInsets.only(bottom: 16),
                                elevation: 3,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                  side: const BorderSide(
                                    color: Color(0xFF1A237E),
                                    width: 2,
                                  ),
                                ),
                                child: Padding(
                                  padding: const EdgeInsets.all(16),
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      // Encabezado con código editable
                                      Container(
                                        padding: const EdgeInsets.all(12),
                                        decoration: BoxDecoration(
                                          color: const Color(0xFF1A237E),
                                          borderRadius: BorderRadius.circular(8),
                                        ),
                                        child: Row(
                                          children: [
                                            const Icon(
                                              Icons.numbers,
                                              color: Colors.white,
                                              size: 24,
                                            ),
                                            const SizedBox(width: 8),
                                            const Text(
                                              'Código:',
                                              style: TextStyle(
                                                fontSize: 18,
                                                fontWeight: FontWeight.bold,
                                                color: Colors.white,
                                              ),
                                            ),
                                            const SizedBox(width: 12),
                                            Expanded(
                                              child: DropdownButtonFormField<String>(
                                                initialValue: codigo['codigo']?.toString(),
                                                dropdownColor: Colors.white,
                                                decoration: InputDecoration(
                                                  filled: true,
                                                  fillColor: Colors.white,
                                                  contentPadding: const EdgeInsets.symmetric(
                                                    horizontal: 12,
                                                    vertical: 8,
                                                  ),
                                                  border: OutlineInputBorder(
                                                    borderRadius: BorderRadius.circular(8),
                                                    borderSide: BorderSide.none,
                                                  ),
                                                ),
                                                style: const TextStyle(
                                                  fontSize: 16,
                                                  fontWeight: FontWeight.bold,
                                                  color: Colors.black87,
                                                ),
                                                items: _buildCodigoDropdownItems(codigo),
                                                onChanged: (nuevoValor) {
                                                  if (nuevoValor != null && nuevoValor != codigo['codigo']) {
                                                    _guardarCodigo(codigo, nuevoValor);
                                                  }
                                                },
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                      const SizedBox(height: 16),

                                      // Información principal
                                      _buildInfoRow(
                                        Icons.route,
                                        'ID Correria',
                                        codigo['id_correria'],
                                      ),
                                      _buildInfoRow(
                                        Icons.badge,
                                        'Nombre Correría',
                                        codigo['nombre_correria'],
                                      ),
                                      _buildInfoRow(
                                        Icons.directions_bus,
                                        'Transporte',
                                        codigo['transporte'],
                                      ),
                                      _buildInfoRow(
                                        Icons.local_shipping,
                                        'Grupo Vehicular',
                                        codigo['grupo_vehicular'],
                                      ),
                                      _buildInfoRow(
                                        Icons.terrain,
                                        'Terreno',
                                        codigo['terreno'],
                                      ),
                                      _buildInfoRow(
                                        Icons.calendar_today,
                                        'Días',
                                        codigo['dias'],
                                      ),
                                      _buildInfoRow(
                                        Icons.format_list_numbered,
                                        'Totales',
                                        codigo['totales'],
                                      ),
                                      _buildInfoRow(
                                        Icons.person,
                                        'Nombre Lector',
                                        codigo['nombre_lector'],
                                      ),
                                      
                                      const Divider(height: 24, thickness: 1),

                                      // Observación editable
                                      Row(
                                        children: [
                                          Expanded(
                                            child: Column(
                                              crossAxisAlignment: CrossAxisAlignment.start,
                                              children: [
                                                const Row(
                                                  children: [
                                                    Icon(
                                                      Icons.comment,
                                                      size: 18,
                                                      color: Color(0xFF1A237E),
                                                    ),
                                                    SizedBox(width: 8),
                                                    Text(
                                                      'Observación:',
                                                      style: TextStyle(
                                                        fontSize: 14,
                                                        fontWeight: FontWeight.bold,
                                                        color: Color(0xFF1A237E),
                                                      ),
                                                    ),
                                                  ],
                                                ),
                                                const SizedBox(height: 4),
                                                Text(
                                                  codigo['observacion']?.toString() ?? 'Sin observación',
                                                  style: TextStyle(
                                                    fontSize: 14,
                                                    color: codigo['observacion'] == null
                                                        ? Colors.grey
                                                        : Colors.black87,
                                                    fontStyle: codigo['observacion'] == null
                                                        ? FontStyle.italic
                                                        : FontStyle.normal,
                                                  ),
                                                ),
                                              ],
                                            ),
                                          ),
                                          const SizedBox(width: 8),
                                          IconButton(
                                            onPressed: () => _mostrarDialogObservacion(codigo),
                                            icon: const Icon(Icons.edit),
                                            color: const Color(0xFF1A237E),
                                            tooltip: 'Editar observación',
                                          ),
                                        ],
                                      ),
                                    ],
                                  ),
                                ),
                              );
                            },
                          );
  }

  Widget _buildInfoRow(IconData icon, String label, dynamic value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        children: [
          Icon(
            icon,
            size: 18,
            color: const Color(0xFF1A237E).withValues(alpha: 0.7),
          ),
          const SizedBox(width: 8),
          Expanded(
            flex: 2,
            child: Text(
              '$label:',
              style: const TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: Colors.black87,
              ),
            ),
          ),
          Expanded(
            flex: 3,
            child: Text(
              value?.toString() ?? 'N/A',
              style: const TextStyle(
                fontSize: 13,
                color: Colors.black87,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
