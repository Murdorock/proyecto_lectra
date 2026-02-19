import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:syncfusion_flutter_signaturepad/signaturepad.dart';
import 'dart:ui' as ui;
import 'dart:math';
import '../main.dart';
import '../services/user_session.dart';
import 'detalle_registro_formacion_screen.dart';

class RegistroFormacionScreen extends StatefulWidget {
  const RegistroFormacionScreen({super.key});

  @override
  State<RegistroFormacionScreen> createState() => _RegistroFormacionScreenState();
}

class _RegistroFormacionScreenState extends State<RegistroFormacionScreen> {
  bool _isLoading = true;
  List<Map<String, dynamic>> _formularios = [];

  @override
  void initState() {
    super.initState();
    _cargarFormularios();
  }

  Future<void> _cargarFormularios() async {
    setState(() {
      _isLoading = true;
    });

    try {
      // Verificar sesión válida
      final sessionValid = await UserSession().ensureSessionValid();
      if (!sessionValid) {
        if (mounted) {
          Navigator.of(context).pushReplacementNamed('/login');
        }
        return;
      }

      // Obtener el código del supervisor logueado
      final codigoSup = UserSession().codigoSupAux;
      if (codigoSup == null) {
        setState(() {
          _formularios = [];
          _isLoading = false;
        });
        return;
      }

      // Cargar formularios únicos (agrupados por numero_formulario) solo del supervisor logueado
      final response = await supabase
          .from('registro_formacion')
          .select('numero_formulario, tema, origen, objetivo, aspectos, fecha, firma_sup, codigo')
          .eq('codigo', codigoSup)
          .order('id', ascending: false);

      // Filtrar para obtener solo un registro por numero_formulario
      final Map<String, Map<String, dynamic>> formulariosUnicos = {};
      for (var item in response) {
        final numeroFormulario = item['numero_formulario'];
        if (numeroFormulario != null && !formulariosUnicos.containsKey(numeroFormulario)) {
          formulariosUnicos[numeroFormulario] = item;
        }
      }

      if (mounted) {
        setState(() {
          _formularios = formulariosUnicos.values.toList();
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error al cargar formularios: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<String> _generarCodigoUnico() async {
    final random = Random();
    String codigo;
    bool esUnico = false;
    int intentos = 0;
    const maxIntentos = 100;

    while (!esUnico && intentos < maxIntentos) {
      // Generar código de 4 dígitos (1000-9999)
      codigo = (1000 + random.nextInt(9000)).toString();

      // Verificar si ya existe en la base de datos
      final existe = await supabase
          .from('registro_formacion')
          .select('numero_formulario')
          .eq('numero_formulario', codigo)
          .maybeSingle();

      if (existe == null) {
        esUnico = true;
        return codigo;
      }

      intentos++;
    }

    throw Exception('No se pudo generar un código único después de $maxIntentos intentos');
  }

  Future<void> _mostrarDialogoCrearFormulario() async {
    final formKey = GlobalKey<FormState>();
    final temaController = TextEditingController();
    final origenController = TextEditingController();
    final objetivoController = TextEditingController();
    final aspectosController = TextEditingController();
    ui.Image? firmaSupervisor;
    bool guardando = false;
    bool camposEditables = true;

    // Nueva lógica: Si ya se generó un código, verificar si existen registros de asistencia
    Future<void> verificarAsistencia(String numeroFormulario) async {
      final response = await supabase
          .from('registro_formacion')
          .select('id')
          .eq('numero_formulario', numeroFormulario)
          .not('codigo_lec', 'is', null)
          .limit(1)
          .maybeSingle();
      camposEditables = response == null;
    }

    await showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext dialogContext) {
        return StatefulBuilder(
          builder: (context, setStateDialog) {
            return AlertDialog(
              title: Row(
                children: [
                  Icon(Icons.add_circle, color: const Color(0xFF1A237E)),
                  const SizedBox(width: 8),
                  const Expanded(
                    child: Text(
                      'Nuevo Formulario de Formación',
                      style: TextStyle(
                        color: Color(0xFF1A237E),
                        fontWeight: FontWeight.bold,
                        fontSize: 18,
                      ),
                    ),
                  ),
                ],
              ),
              content: SingleChildScrollView(
                child: Form(
                  key: formKey,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Se generará automáticamente un código único de 4 dígitos',
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.grey,
                          fontStyle: FontStyle.italic,
                        ),
                      ),
                      const SizedBox(height: 16),
                      TextFormField(
                        controller: temaController,
                        textCapitalization: TextCapitalization.sentences,
                        maxLines: 3,
                        enabled: camposEditables,
                        decoration: InputDecoration(
                          labelText: 'Tema del Formulario *',
                          labelStyle: const TextStyle(
                            color: Color(0xFF1A237E),
                            fontWeight: FontWeight.bold,
                          ),
                          hintText: 'Ingrese el tema de la formación',
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                          enabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8),
                            borderSide: const BorderSide(color: Color(0xFF1A237E), width: 2),
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8),
                            borderSide: const BorderSide(color: Color(0xFF1A237E), width: 2),
                          ),
                          filled: true,
                          fillColor: Colors.blue.shade50,
                        ),
                        validator: (value) {
                          if (value == null || value.trim().isEmpty) {
                            return 'El tema es obligatorio';
                          }
                          if (value.trim().length < 3) {
                            return 'El tema debe tener al menos 3 caracteres';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 12),
                      TextFormField(
                        controller: origenController,
                        textCapitalization: TextCapitalization.sentences,
                        maxLines: 2,
                        enabled: camposEditables,
                        decoration: InputDecoration(
                          labelText: 'Origen',
                          labelStyle: const TextStyle(
                            color: Color(0xFF1A237E),
                            fontWeight: FontWeight.bold,
                          ),
                          hintText: 'Ingrese el origen',
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                          enabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8),
                            borderSide: const BorderSide(color: Color(0xFF1A237E), width: 2),
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8),
                            borderSide: const BorderSide(color: Color(0xFF1A237E), width: 2),
                          ),
                          filled: true,
                          fillColor: Colors.blue.shade50,
                        ),
                      ),
                      const SizedBox(height: 12),
                      TextFormField(
                        controller: objetivoController,
                        textCapitalization: TextCapitalization.sentences,
                        maxLines: 3,
                        enabled: camposEditables,
                        decoration: InputDecoration(
                          labelText: 'Objetivo',
                          labelStyle: const TextStyle(
                            color: Color(0xFF1A237E),
                            fontWeight: FontWeight.bold,
                          ),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                          enabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8),
                            borderSide: const BorderSide(color: Color(0xFF1A237E), width: 2),
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8),
                            borderSide: const BorderSide(color: Color(0xFF1A237E), width: 2),
                          ),
                          filled: true,
                          fillColor: Colors.blue.shade50,
                        ),
                      ),
                      const SizedBox(height: 12),
                      TextFormField(
                        controller: aspectosController,
                        textCapitalization: TextCapitalization.sentences,
                        maxLines: 3,
                        enabled: camposEditables,
                        decoration: InputDecoration(
                          labelText: 'Aspectos',
                          labelStyle: const TextStyle(
                            color: Color(0xFF1A237E),
                            fontWeight: FontWeight.bold,
                          ),
                          hintText: 'Ingrese los aspectos',
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                          enabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8),
                            borderSide: const BorderSide(color: Color(0xFF1A237E), width: 2),
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8),
                            borderSide: const BorderSide(color: Color(0xFF1A237E), width: 2),
                          ),
                          filled: true,
                          fillColor: Colors.blue.shade50,
                        ),
                      ),
                      const SizedBox(height: 16),
                      // Firma del supervisor
                      Container(
                        decoration: BoxDecoration(
                          border: Border.all(color: const Color(0xFF1A237E), width: 2),
                          borderRadius: BorderRadius.circular(8),
                          color: Colors.blue.shade50,
                        ),
                        child: Column(
                          children: [
                            Padding(
                              padding: const EdgeInsets.all(12),
                              child: Row(
                                children: [
                                  Expanded(
                                    child: Text(
                                      firmaSupervisor == null 
                                          ? 'Firma del Supervisor *' 
                                          : 'Firma capturada',
                                      style: const TextStyle(
                                        color: Color(0xFF1A237E),
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ),
                                  ElevatedButton.icon(
                                    onPressed: camposEditables ? () async {
                                      final firma = await _mostrarDialogoCapturarFirma(dialogContext);
                                      if (firma != null) {
                                        setStateDialog(() {
                                          firmaSupervisor = firma;
                                        });
                                      }
                                    } : null,
                                    icon: Icon(
                                      firmaSupervisor == null ? Icons.draw : Icons.edit,
                                      size: 16,
                                    ),
                                    label: Text(firmaSupervisor == null ? 'Capturar' : 'Cambiar'),
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: const Color(0xFF1A237E),
                                      foregroundColor: Colors.white,
                                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            if (firmaSupervisor != null)
                              Padding(
                                padding: const EdgeInsets.fromLTRB(12, 0, 12, 12),
                                child: Container(
                                  height: 100,
                                  width: double.infinity,
                                  decoration: BoxDecoration(
                                    color: Colors.white,
                                    borderRadius: BorderRadius.circular(8),
                                    border: Border.all(color: Colors.grey.shade300),
                                  ),
                                  child: CustomPaint(
                                    painter: _FirmaPainter(firmaSupervisor!),
                                  ),
                                ),
                              ),
                          ],
                        ),
                      ),
                      if (!camposEditables)
                        Padding(
                          padding: const EdgeInsets.only(top: 16),
                          child: Text(
                            'No se pueden editar los campos porque ya existe al menos un registro de asistencia para este formulario.',
                            style: TextStyle(color: Colors.red.shade700, fontWeight: FontWeight.bold),
                          ),
                        ),
                    ],
                  ),
                ),
              ),
              actions: [
                TextButton(
                  onPressed: guardando ? null : () {
                    Navigator.of(dialogContext).pop();
                  },
                  child: const Text('CANCELAR'),
                ),
                ElevatedButton(
                  onPressed: guardando || !camposEditables ? null : () async {
                    if (formKey.currentState!.validate()) {
                      if (firmaSupervisor == null) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('Debe capturar la firma del supervisor'),
                            backgroundColor: Colors.red,
                          ),
                        );
                        return;
                      }

                      setStateDialog(() {
                        guardando = true;
                      });

                      try {
                        // Generar código único
                        final codigoUnico = await _generarCodigoUnico();

                        // Verificar si ya hay registros de asistencia
                        await verificarAsistencia(codigoUnico);
                        setStateDialog(() {});
                        if (!camposEditables) {
                          guardando = false;
                          return;
                        }

                        // Subir firma del supervisor al bucket
                        final firmaPngBytes = await _convertirFirmaAPng(firmaSupervisor!);
                        final timestamp = DateTime.now().millisecondsSinceEpoch;
                        final firmaSupPath = 'registro_formacion/firma_sup_${codigoUnico}_$timestamp.png';

                        await supabase.storage.from('cold').uploadBinary(
                          firmaSupPath,
                          firmaPngBytes,
                        );

                        final firmaSupUrl = supabase.storage.from('cold').getPublicUrl(firmaSupPath);

                        // Crear el formulario en la base de datos
                        await supabase.from('registro_formacion').insert({
                          'numero_formulario': codigoUnico,
                          'tema': temaController.text.trim(),
                          'origen': origenController.text.trim(),
                          'objetivo': objetivoController.text.trim(),
                          'aspectos': aspectosController.text.trim(),
                          'fecha': DateTime.now().toIso8601String().split('T')[0],
                          'firma_sup': firmaSupUrl,
                          'codigo': UserSession().codigoSupAux,
                        });

                        if (mounted) {
                          Navigator.of(dialogContext).pop();

                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text('Formulario creado exitosamente con código: $codigoUnico'),
                              backgroundColor: Colors.green,
                              duration: const Duration(seconds: 3),
                            ),
                          );

                          // Recargar la lista
                          _cargarFormularios();
                        }
                      } catch (e) {
                        setStateDialog(() {
                          guardando = false;
                        });

                        if (mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text('Error al crear formulario: ${e.toString()}'),
                              backgroundColor: Colors.red,
                              duration: const Duration(seconds: 4),
                            ),
                          );
                        }
                      }
                    }
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF1A237E),
                    foregroundColor: Colors.white,
                  ),
                  child: guardando
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                          ),
                        )
                      : const Text('CREAR'),
                ),
              ],
            );
          },
        );
      },
    );
  }

  Future<ui.Image?> _mostrarDialogoCapturarFirma(BuildContext parentContext) async {
    final GlobalKey<SfSignaturePadState> signatureKey = GlobalKey();
    
    return await showDialog<ui.Image>(
      context: parentContext,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text(
            'Capturar Firma del Supervisor',
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
    );
  }

  Future<Uint8List> _convertirFirmaAPng(ui.Image imagen) async {
    final byteData = await imagen.toByteData(format: ui.ImageByteFormat.png);
    return byteData!.buffer.asUint8List();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Registro de Formación',
          style: TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
          ),
        ),
        backgroundColor: const Color(0xFF1A237E),
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: _isLoading
          ? const Center(
              child: CircularProgressIndicator(
                color: Color(0xFF1A237E),
              ),
            )
          : _formularios.isEmpty
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.school_outlined,
                        size: 80,
                        color: Colors.grey.shade400,
                      ),
                      const SizedBox(height: 16),
                      Text(
                        'No hay formularios de formación',
                        style: TextStyle(
                          fontSize: 18,
                          color: Colors.grey.shade600,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Presiona el botón + para crear uno',
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.grey.shade500,
                        ),
                      ),
                    ],
                  ),
                )
              : RefreshIndicator(
                  onRefresh: _cargarFormularios,
                  color: const Color(0xFF1A237E),
                  child: ListView.builder(
                    padding: const EdgeInsets.all(16),
                    itemCount: _formularios.length,
                    itemBuilder: (context, index) {
                      final formulario = _formularios[index];
                      return Card(
                        elevation: 2,
                        margin: const EdgeInsets.only(bottom: 12),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                          side: BorderSide(color: Colors.blue.shade200, width: 1),
                        ),
                        child: ListTile(
                          contentPadding: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 12,
                          ),
                          leading: Container(
                            width: 56,
                            height: 56,
                            decoration: BoxDecoration(
                              color: const Color(0xFF1A237E),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                const Icon(
                                  Icons.school,
                                  color: Colors.white,
                                  size: 20,
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  formulario['numero_formulario'] ?? '',
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontWeight: FontWeight.bold,
                                    fontSize: 12,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          title: Text(
                            formulario['tema'] ?? 'Sin tema',
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 16,
                            ),
                          ),
                          subtitle: Text(
                            'Código: ${formulario['numero_formulario'] ?? 'N/A'}',
                            style: TextStyle(
                              color: Colors.grey.shade600,
                              fontSize: 12,
                            ),
                          ),
                          trailing: const Icon(
                            Icons.arrow_forward_ios,
                            color: Color(0xFF1A237E),
                            size: 16,
                          ),
                          onTap: () async {
                            // Verificar si el formulario tiene firma_sup
                            if (formulario['firma_sup'] == null || (formulario['firma_sup'] as String).isEmpty) {
                              // Pedir firma del supervisor antes de continuar
                              final nuevaFirma = await _mostrarDialogoCapturarFirma(context);
                              if (nuevaFirma != null) {
                                // Subir la firma y actualizar el formulario
                                final firmaPngBytes = await _convertirFirmaAPng(nuevaFirma);
                                final timestamp = DateTime.now().millisecondsSinceEpoch;
                                final firmaSupPath = 'registro_formacion/firma_sup_${formulario['numero_formulario']}_$timestamp.png';
                                await supabase.storage.from('cold').uploadBinary(
                                  firmaSupPath,
                                  firmaPngBytes,
                                );
                                final firmaSupUrl = supabase.storage.from('cold').getPublicUrl(firmaSupPath);
                                await supabase.from('registro_formacion')
                                  .update({'firma_sup': firmaSupUrl})
                                  .eq('numero_formulario', formulario['numero_formulario']);
                                // Actualizar el valor local para que la siguiente pantalla lo reciba actualizado
                                formulario['firma_sup'] = firmaSupUrl;
                              } else {
                                // Si no se capturó firma, no continuar
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(
                                    content: Text('Debe capturar la firma del supervisor para continuar'),
                                    backgroundColor: Colors.red,
                                  ),
                                );
                                return;
                              }
                            }
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) => DetalleRegistroFormacionScreen(
                                  formulario: formulario,
                                ),
                              ),
                            ).then((result) {
                              if (result == true) {
                                _cargarFormularios();
                              }
                            });
                          },
                        ),
                      );
                    },
                  ),
                ),
      floatingActionButton: FloatingActionButton(
        onPressed: _mostrarDialogoCrearFormulario,
        backgroundColor: const Color(0xFF1A237E),
        child: const Icon(Icons.add, color: Colors.white),
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
