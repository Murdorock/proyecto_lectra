import 'package:flutter/material.dart';
import 'package:syncfusion_flutter_signaturepad/signaturepad.dart';
import 'dart:ui' as ui;
import 'dart:typed_data';
import '../main.dart';
import '../services/user_session.dart';

class DetalleRegistroFormacionScreen extends StatefulWidget {
  final Map<String, dynamic> formulario;

  const DetalleRegistroFormacionScreen({
    super.key,
    required this.formulario,
  });

  @override
  State<DetalleRegistroFormacionScreen> createState() => _DetalleRegistroFormacionScreenState();
}

class _DetalleRegistroFormacionScreenState extends State<DetalleRegistroFormacionScreen> {
  final _formKey = GlobalKey<FormState>();
  final _searchController = TextEditingController();
  
  List<Map<String, dynamic>> _funcionarios = [];
  List<Map<String, dynamic>> _funcionariosRegistrados = [];
  Map<String, dynamic>? _funcionarioSeleccionado;
  
  ui.Image? _firmaImagen;
  bool _isSaving = false;
  bool _isLoadingFuncionarios = true;
  bool _isLoadingRegistrados = true;

  @override
  void initState() {
    super.initState();
    _cargarFuncionarios();
    _cargarFuncionariosRegistrados();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _cargarFuncionarios() async {
    try {
      final sessionValid = await UserSession().ensureSessionValid();
      if (!sessionValid) {
        if (mounted) {
          Navigator.of(context).pushReplacementNamed('/login');
        }
        return;
      }

      final response = await supabase
          .from('personal')
          .select('id_codigo, nombre_completo, numero_cedula, supervisor')
          .order('nombre_completo', ascending: true);

      if (mounted) {
        setState(() {
          _funcionarios = List<Map<String, dynamic>>.from(response);
          _isLoadingFuncionarios = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoadingFuncionarios = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error al cargar funcionarios: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _cargarFuncionariosRegistrados() async {
    try {
      final sessionValid = await UserSession().ensureSessionValid();
      if (!sessionValid) {
        if (mounted) {
          Navigator.of(context).pushReplacementNamed('/login');
        }
        return;
      }

      final numeroFormulario = widget.formulario['numero_formulario'];
      
      final response = await supabase
          .from('registro_formacion')
          .select('nombre_completo, codigo_lec, cedula')
          .eq('numero_formulario', numeroFormulario)
          .not('codigo_lec', 'is', null)
          .order('nombre_completo', ascending: true);

      if (mounted) {
        setState(() {
          _funcionariosRegistrados = List<Map<String, dynamic>>.from(response);
          _isLoadingRegistrados = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoadingRegistrados = false;
        });
        print('Error al cargar funcionarios registrados: $e');
      }
    }
  }

  Future<void> _mostrarDialogoSeleccionFuncionario() async {
    final TextEditingController dialogSearchController = TextEditingController();
    List<Map<String, dynamic>> resultadosBusqueda = _funcionarios;

    await showDialog(
      context: context,
      builder: (BuildContext dialogContext) {
        return StatefulBuilder(
          builder: (context, setStateDialog) {
            return AlertDialog(
              title: const Text(
                'Seleccionar Funcionario',
                style: TextStyle(
                  color: Color(0xFF1A237E),
                  fontWeight: FontWeight.bold,
                ),
              ),
              content: SizedBox(
                width: double.maxFinite,
                height: 400,
                child: Column(
                  children: [
                    TextField(
                      controller: dialogSearchController,
                      decoration: InputDecoration(
                        labelText: 'Buscar por nombre o código',
                        prefixIcon: const Icon(Icons.search),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                      onChanged: (value) {
                        setStateDialog(() {
                          if (value.isEmpty) {
                            resultadosBusqueda = _funcionarios;
                          } else {
                            final queryLower = value.toLowerCase();
                            resultadosBusqueda = _funcionarios.where((f) {
                              final nombre = (f['nombre_completo'] ?? '').toString().toLowerCase();
                              final codigo = (f['id_codigo'] ?? '').toString().toLowerCase();
                              return nombre.contains(queryLower) || codigo.contains(queryLower);
                            }).toList();
                          }
                        });
                      },
                    ),
                    const SizedBox(height: 16),
                    Expanded(
                      child: resultadosBusqueda.isEmpty
                          ? const Center(
                              child: Text('No se encontraron funcionarios'),
                            )
                          : ListView.builder(
                              itemCount: resultadosBusqueda.length,
                              itemBuilder: (context, index) {
                                final funcionario = resultadosBusqueda[index];
                                return ListTile(
                                  leading: CircleAvatar(
                                    backgroundColor: const Color(0xFF1A237E),
                                    child: Text(
                                      (funcionario['nombre_completo'] ?? 'N')
                                          .toString()
                                          .substring(0, 1)
                                          .toUpperCase(),
                                      style: const TextStyle(color: Colors.white),
                                    ),
                                  ),
                                  title: Text(
                                    funcionario['nombre_completo'] ?? 'Sin nombre',
                                    style: const TextStyle(fontWeight: FontWeight.bold),
                                  ),
                                  subtitle: Text('Código: ${funcionario['id_codigo'] ?? 'N/A'}'),
                                  onTap: () {
                                    setState(() {
                                      _funcionarioSeleccionado = funcionario;
                                      _searchController.text = funcionario['nombre_completo'] ?? '';
                                    });
                                    Navigator.of(dialogContext).pop();
                                  },
                                );
                              },
                            ),
                    ),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.of(dialogContext).pop(),
                  child: const Text('CANCELAR'),
                ),
              ],
            );
          },
        );
      },
    );
  }

  Future<void> _mostrarDialogoFirma() async {
    final GlobalKey<SfSignaturePadState> signatureKey = GlobalKey();
    
    await showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text(
            'Capturar Firma del Funcionario',
            style: TextStyle(
              color: Color(0xFF1A237E),
              fontWeight: FontWeight.bold,
            ),
          ),
          content: SizedBox(
            width: double.maxFinite,
            height: 300,
            child: Column(
              children: [
                Expanded(
                  child: Container(
                    decoration: BoxDecoration(
                      border: Border.all(color: Colors.grey),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: SfSignaturePad(
                      key: signatureKey,
                      backgroundColor: Colors.white,
                      strokeColor: Colors.black,
                      minimumStrokeWidth: 1.0,
                      maximumStrokeWidth: 3.0,
                    ),
                  ),
                ),
                const SizedBox(height: 8),
                const Text(
                  'Dibuje la firma en el área superior',
                  style: TextStyle(fontSize: 12, color: Colors.grey),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () {
                signatureKey.currentState?.clear();
              },
              child: const Text('LIMPIAR'),
            ),
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('CANCELAR'),
            ),
            ElevatedButton(
              onPressed: () async {
                final signatureData = await signatureKey.currentState?.toImage();
                if (signatureData != null) {
                  Navigator.pop(context, signatureData);
                } else {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Por favor, dibuje una firma antes de guardar'),
                      backgroundColor: Colors.orange,
                    ),
                  );
                }
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
    ).then((firma) {
      if (firma != null && firma is ui.Image) {
        setState(() {
          _firmaImagen = firma;
        });
        
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Firma capturada correctamente'),
            backgroundColor: Colors.green,
            duration: Duration(seconds: 2),
          ),
        );
      }
    });
  }

  Future<Uint8List> _convertirFirmaAPng(ui.Image imagen) async {
    final byteData = await imagen.toByteData(format: ui.ImageByteFormat.png);
    return byteData!.buffer.asUint8List();
  }

  Future<void> _guardarDatos() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    if (_funcionarioSeleccionado == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Debe seleccionar un funcionario'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    if (_firmaImagen == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Debe capturar la firma del funcionario'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    setState(() {
      _isSaving = true;
    });

    try {
      final sessionValid = await UserSession().ensureSessionValid();
      if (!sessionValid) {
        if (mounted) {
          Navigator.of(context).pushReplacementNamed('/login');
        }
        return;
      }

      final numeroFormulario = widget.formulario['numero_formulario'];
      final cedulaFuncionario = _funcionarioSeleccionado!['numero_cedula'];

      // Validar que la cédula no esté repetida en este número de formulario
      final existeRegistro = await supabase
          .from('registro_formacion')
          .select('id')
          .eq('numero_formulario', numeroFormulario)
          .eq('cedula', cedulaFuncionario)
          .maybeSingle();

      if (existeRegistro != null) {
        if (mounted) {
          setState(() {
            _isSaving = false;
          });
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                'El funcionario con cédula $cedulaFuncionario ya está registrado en este formulario',
              ),
              backgroundColor: Colors.orange,
              duration: const Duration(seconds: 4),
            ),
          );
        }
        return;
      }

      // Obtener datos del supervisor logueado
      final codigoSupervisor = UserSession().codigoSupAux ?? '';
      final nombreSupervisor = UserSession().nombreCompleto ?? '';

      // Subir firma al bucket
      final firmaPngBytes = await _convertirFirmaAPng(_firmaImagen!);
      final timestamp = DateTime.now().millisecondsSinceEpoch;
      final codigoFuncionario = _funcionarioSeleccionado!['id_codigo'];
      
      final firmaPath = 'registro_formacion/firma_${numeroFormulario}_${codigoFuncionario}_$timestamp.png';
      
      await supabase.storage.from('cold').uploadBinary(
        firmaPath,
        firmaPngBytes,
      );

      // Obtener URL pública de la firma
      final firmaUrl = supabase.storage.from('cold').getPublicUrl(firmaPath);

      // Insertar registro en la tabla
      await supabase.from('registro_formacion').insert({
        'numero_formulario': numeroFormulario,
        'tema': widget.formulario['tema'],
        'origen': widget.formulario['origen'],
        'objetivo': widget.formulario['objetivo'],
        'aspectos': widget.formulario['aspectos'],
        'fecha': widget.formulario['fecha'],
        'codigo': codigoSupervisor,
        'instructor': nombreSupervisor,
        'nombre_completo': _funcionarioSeleccionado!['nombre_completo'],
        'cedula': cedulaFuncionario,
        'cargo': _funcionarioSeleccionado!['supervisor'],
        'codigo_lec': codigoFuncionario,
        'firma': firmaUrl,
        'firma_sup': widget.formulario['firma_sup'],
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Datos guardados exitosamente'),
            backgroundColor: Colors.green,
            duration: Duration(seconds: 3),
          ),
        );
        
        // Limpiar formulario después de guardar
        setState(() {
          _funcionarioSeleccionado = null;
          _searchController.clear();
          _firmaImagen = null;
        });
        
        // Recargar lista de funcionarios registrados
        _cargarFuncionariosRegistrados();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error al guardar: ${e.toString()}'),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 4),
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isSaving = false;
        });
      }
    }
  }

  void _limpiarFormulario() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text(
            'Limpiar Formulario',
            style: TextStyle(
              color: Color(0xFF1A237E),
              fontWeight: FontWeight.bold,
            ),
          ),
          content: const Text('¿Está seguro que desea limpiar todos los campos del formulario?'),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('CANCELAR'),
            ),
            ElevatedButton(
              onPressed: () {
                setState(() {
                  _funcionarioSeleccionado = null;
                  _searchController.clear();
                  _firmaImagen = null;
                });
                Navigator.of(context).pop();
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Formulario limpiado'),
                    backgroundColor: Colors.orange,
                    duration: Duration(seconds: 2),
                  ),
                );
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.orange,
                foregroundColor: Colors.white,
              ),
              child: const Text('LIMPIAR'),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Formulario ${widget.formulario['numero_formulario']}',
          style: const TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
          ),
        ),
        backgroundColor: const Color(0xFF1A237E),
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: _isLoadingFuncionarios || _isLoadingRegistrados
          ? const Center(
              child: CircularProgressIndicator(
                color: Color(0xFF1A237E),
              ),
            )
          : Form(
              key: _formKey,
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Información del formulario
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
                            Row(
                              children: [
                                const Icon(Icons.info_outline, color: Color(0xFF1A237E)),
                                const SizedBox(width: 8),
                                Text(
                                  'INFORMACIÓN DEL FORMULARIO',
                                  style: TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.grey.shade700,
                                  ),
                                ),
                              ],
                            ),
                            const Divider(),
                            _buildInfoRow('Código', widget.formulario['numero_formulario']?.toString() ?? 'N/A'),
                            _buildInfoRow('Tema', widget.formulario['tema']?.toString() ?? 'N/A'),
                            _buildInfoRow('Origen', widget.formulario['origen']?.toString() ?? 'N/A'),
                            _buildInfoRow('Objetivo', widget.formulario['objetivo']?.toString() ?? 'N/A'),
                            _buildInfoRow('Aspectos', widget.formulario['aspectos']?.toString() ?? 'N/A'),
                            _buildInfoRow('Fecha', widget.formulario['fecha']?.toString() ?? 'N/A'),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 24),

                    // Sección de funcionarios ya registrados
                    if (_funcionariosRegistrados.isNotEmpty) ...[
                      Row(
                        children: [
                          Icon(Icons.people, color: Colors.green.shade700, size: 20),
                          const SizedBox(width: 8),
                          Text(
                            'FUNCIONARIOS REGISTRADOS',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: Colors.green.shade700,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      Container(
                        decoration: BoxDecoration(
                          color: Colors.green.shade50,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: Colors.green.shade200, width: 2),
                        ),
                        child: ListView.separated(
                          shrinkWrap: true,
                          physics: const NeverScrollableScrollPhysics(),
                          itemCount: _funcionariosRegistrados.length,
                          separatorBuilder: (context, index) => Divider(
                            height: 1,
                            color: Colors.green.shade200,
                          ),
                          itemBuilder: (context, index) {
                            final func = _funcionariosRegistrados[index];
                            return ListTile(
                              dense: true,
                              leading: CircleAvatar(
                                backgroundColor: Colors.green.shade700,
                                radius: 18,
                                child: Text(
                                  '${index + 1}',
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontWeight: FontWeight.bold,
                                    fontSize: 12,
                                  ),
                                ),
                              ),
                              title: Text(
                                func['nombre_completo'] ?? 'Sin nombre',
                                style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 14,
                                ),
                              ),
                              subtitle: Text(
                                'Código: ${func['codigo_lec'] ?? 'N/A'}',
                                style: TextStyle(
                                  fontSize: 12,
                                  color: Colors.grey.shade600,
                                ),
                              ),
                              trailing: Icon(
                                Icons.check_circle,
                                color: Colors.green.shade700,
                                size: 20,
                              ),
                            );
                          },
                        ),
                      ),
                      const SizedBox(height: 24),
                    ],

                    // Sección de datos editables
                    Row(
                      children: [
                        Icon(Icons.edit_outlined, color: Colors.orange.shade700, size: 20),
                        const SizedBox(width: 8),
                        Text(
                          'AGREGAR NUEVO FUNCIONARIO',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: Colors.orange.shade700,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),

                    // Campo Funcionario
                    TextFormField(
                      controller: _searchController,
                      readOnly: true,
                      decoration: InputDecoration(
                        labelText: 'Funcionario *',
                        labelStyle: const TextStyle(
                          color: Color(0xFF1A237E),
                          fontWeight: FontWeight.bold,
                        ),
                        hintText: 'Seleccione un funcionario',
                        prefixIcon: const Icon(Icons.person, color: Color(0xFF1A237E)),
                        suffixIcon: IconButton(
                          icon: const Icon(Icons.search),
                          onPressed: _mostrarDialogoSeleccionFuncionario,
                        ),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                          borderSide: const BorderSide(color: Colors.orange, width: 2),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                          borderSide: const BorderSide(color: Color(0xFF1A237E), width: 2),
                        ),
                        filled: true,
                        fillColor: Colors.orange.shade50,
                      ),
                      validator: (value) {
                        if (_funcionarioSeleccionado == null) {
                          return 'Debe seleccionar un funcionario';
                        }
                        return null;
                      },
                      onTap: _mostrarDialogoSeleccionFuncionario,
                    ),

                    // Mostrar datos del funcionario seleccionado
                    if (_funcionarioSeleccionado != null) ...[
                      const SizedBox(height: 16),
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: Colors.blue.shade50,
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: Colors.blue.shade200),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Datos del Funcionario:',
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                color: Colors.grey.shade700,
                                fontSize: 12,
                              ),
                            ),
                            const SizedBox(height: 8),
                            _buildInfoRow('Código', _funcionarioSeleccionado!['id_codigo']?.toString() ?? 'N/A'),
                            _buildInfoRow('Cédula', _funcionarioSeleccionado!['numero_cedula']?.toString() ?? 'N/A'),
                            _buildInfoRow('Cargo', _funcionarioSeleccionado!['supervisor']?.toString() ?? 'N/A'),
                          ],
                        ),
                      ),
                    ],

                    const SizedBox(height: 24),

                    // Campo Firma
                    Row(
                      children: [
                        Icon(Icons.draw, color: Colors.orange.shade700, size: 20),
                        const SizedBox(width: 8),
                        Text(
                          'FIRMA DEL FUNCIONARIO',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: Colors.orange.shade700,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),

                    Container(
                      decoration: BoxDecoration(
                        border: Border.all(color: Colors.orange, width: 2),
                        borderRadius: BorderRadius.circular(8),
                        color: Colors.orange.shade50,
                      ),
                      child: Column(
                        children: [
                          Padding(
                            padding: const EdgeInsets.all(12),
                            child: Row(
                              children: [
                                Expanded(
                                  child: Text(
                                    _firmaImagen == null ? 'Sin firma capturada' : 'Firma capturada',
                                    style: const TextStyle(
                                      color: Color(0xFF1A237E),
                                      fontWeight: FontWeight.bold,
                                      fontSize: 16,
                                    ),
                                  ),
                                ),
                                ElevatedButton.icon(
                                  onPressed: _mostrarDialogoFirma,
                                  icon: Icon(_firmaImagen == null ? Icons.draw : Icons.edit, size: 18),
                                  label: Text(_firmaImagen == null ? 'Capturar' : 'Cambiar'),
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: const Color(0xFF1A237E),
                                    foregroundColor: Colors.white,
                                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                                  ),
                                ),
                              ],
                            ),
                          ),
                          if (_firmaImagen != null)
                            Padding(
                              padding: const EdgeInsets.fromLTRB(12, 0, 12, 12),
                              child: Container(
                                height: 150,
                                width: double.infinity,
                                decoration: BoxDecoration(
                                  color: Colors.white,
                                  borderRadius: BorderRadius.circular(8),
                                  border: Border.all(color: Colors.grey.shade300),
                                ),
                                child: CustomPaint(
                                  painter: _FirmaPainter(_firmaImagen!),
                                ),
                              ),
                            ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 32),

                    // Botones de acción
                    Row(
                      children: [
                        Expanded(
                          child: OutlinedButton.icon(
                            onPressed: _limpiarFormulario,
                            icon: const Icon(Icons.clear_all),
                            label: const Text(
                              'LIMPIAR',
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 16,
                              ),
                            ),
                            style: OutlinedButton.styleFrom(
                              foregroundColor: Colors.orange,
                              side: const BorderSide(color: Colors.orange, width: 2),
                              padding: const EdgeInsets.symmetric(vertical: 16),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(8),
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          flex: 2,
                          child: ElevatedButton.icon(
                            onPressed: _isSaving ? null : _guardarDatos,
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
                            label: Text(
                              _isSaving ? 'GUARDANDO...' : 'GUARDAR',
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 16,
                              ),
                            ),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFF1A237E),
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
                    const SizedBox(height: 24),
                  ],
                ),
              ),
            ),
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            flex: 2,
            child: Text(
              '$label:',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 13,
                color: Colors.grey.shade700,
              ),
            ),
          ),
          Expanded(
            flex: 3,
            child: Text(
              value,
              style: const TextStyle(fontSize: 13),
            ),
          ),
        ],
      ),
    );
  }
}

class _FirmaPainter extends CustomPainter {
  final ui.Image image;

  _FirmaPainter(this.image);

  @override
  void paint(Canvas canvas, Size size) {
    canvas.drawImageRect(
      image,
      Rect.fromLTWH(0, 0, image.width.toDouble(), image.height.toDouble()),
      Rect.fromLTWH(0, 0, size.width, size.height),
      Paint(),
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
