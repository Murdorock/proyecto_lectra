import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../main.dart';

class EditarReporteTotalesScreen extends StatefulWidget {
  final String codigo;
  final String correria;

  const EditarReporteTotalesScreen({
    super.key,
    required this.codigo,
    required this.correria,
  });

  @override
  State<EditarReporteTotalesScreen> createState() => _EditarReporteTotalesScreenState();
}

class _EditarReporteTotalesScreenState extends State<EditarReporteTotalesScreen> {
  bool _isLoading = true;
  String? _errorMessage;
  Map<String, dynamic>? _registro;
  final TextEditingController _totalesReportadosController = TextEditingController();
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    _loadRegistro();
  }

  @override
  void dispose() {
    _totalesReportadosController.dispose();
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
          .from('programacion_lectura')
          .select('codigo, correria, nombre_correria, totales, totales_supervisor')
          .eq('codigo', widget.codigo)
          .eq('correria', widget.correria)
          .maybeSingle();

      if (mounted) {
        if (data != null) {
          setState(() {
            _registro = data;
            // Cargar totales_supervisor si existe
            if (data['totales_supervisor'] != null) {
              _totalesReportadosController.text = data['totales_supervisor'].toString();
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
    if (_totalesReportadosController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Por favor ingrese los totales reportados'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    setState(() {
      _isSaving = true;
    });

    try {
      final totalesReportados = int.parse(_totalesReportadosController.text);
      // Obtener fecha y hora local en formato ISO 8601
      final horaReporte = DateTime.now().toIso8601String();

      await supabase
          .from('programacion_lectura')
          .update({
            'totales_supervisor': totalesReportados,
            'hora_reporte': horaReporte,
          })
          .eq('codigo', widget.codigo)
          .eq('correria', widget.correria);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Cambios guardados exitosamente'),
            backgroundColor: Colors.green,
          ),
        );
        Navigator.pop(context, true); // Retornar true para indicar que se guardaron cambios
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

  Future<void> _borrarDato() async {
    // Mostrar diálogo de confirmación
    final confirmar = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Confirmar eliminación'),
        content: const Text('¿Está seguro que desea borrar los totales reportados?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancelar'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            style: TextButton.styleFrom(
              foregroundColor: Colors.red,
            ),
            child: const Text('Borrar'),
          ),
        ],
      ),
    );

    if (confirmar != true) return;

    setState(() {
      _isSaving = true;
    });

    try {
      await supabase
          .from('programacion_lectura')
          .update({
            'totales_supervisor': null,
            'hora_reporte': null,
          })
          .eq('codigo', widget.codigo)
          .eq('correria', widget.correria);

      if (mounted) {
        setState(() {
          _totalesReportadosController.clear();
          _isSaving = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Dato eliminado exitosamente'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isSaving = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error al borrar: ${e.toString()}'),
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
        title: const Text('Editar Reporte Totales'),
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
              onPressed: _isSaving ? null : _guardarCambios,
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
                      // Card con información del registro
                      Card(
                        elevation: 2,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                          side: BorderSide(
                            color: const Color(0xFF1A237E).withValues(alpha: 0.2),
                            width: 1,
                          ),
                        ),
                        child: Padding(
                          padding: const EdgeInsets.all(20.0),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              // Header
                              Row(
                                children: [
                                  Container(
                                    padding: const EdgeInsets.all(12),
                                    decoration: BoxDecoration(
                                      color: const Color(0xFF1A237E).withValues(alpha: 0.1),
                                      borderRadius: BorderRadius.circular(10),
                                    ),
                                    child: const Icon(
                                      Icons.edit_document,
                                      color: Color(0xFF1A237E),
                                      size: 32,
                                    ),
                                  ),
                                  const SizedBox(width: 16),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          'Información del Registro',
                                          style: TextStyle(
                                            fontSize: 18,
                                            fontWeight: FontWeight.bold,
                                            color: Colors.grey.shade800,
                                          ),
                                        ),
                                        const SizedBox(height: 4),
                                        Text(
                                          'Datos de lectura programada',
                                          style: TextStyle(
                                            fontSize: 13,
                                            color: Colors.grey.shade600,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 24),
                              const Divider(height: 1),
                              const SizedBox(height: 24),

                              // Campos de solo lectura
                              _buildReadOnlyField(
                                'Código',
                                _registro!['codigo']?.toString() ?? 'N/A',
                                Icons.numbers,
                              ),
                              const SizedBox(height: 16),
                              _buildReadOnlyField(
                                'Correría',
                                _registro!['correria']?.toString() ?? 'N/A',
                                Icons.route,
                              ),
                              const SizedBox(height: 16),
                              _buildReadOnlyField(
                                'Nombre Correría',
                                _registro!['nombre_correria']?.toString() ?? 'N/A',
                                Icons.label,
                              ),
                              const SizedBox(height: 16),
                              _buildReadOnlyField(
                                'Totales',
                                _registro!['totales']?.toString() ?? 'N/A',
                                Icons.functions,
                              ),
                              const SizedBox(height: 24),
                              const Divider(height: 1),
                              const SizedBox(height: 24),

                              // Campo editable
                              Text(
                                'Totales Reportados',
                                style: TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.grey.shade800,
                                ),
                              ),
                              const SizedBox(height: 8),
                              TextField(
                                controller: _totalesReportadosController,
                                keyboardType: TextInputType.number,
                                inputFormatters: [
                                  FilteringTextInputFormatter.digitsOnly,
                                ],
                                decoration: InputDecoration(
                                  hintText: 'Ingrese los totales reportados',
                                  hintStyle: TextStyle(color: Colors.grey.shade400),
                                  prefixIcon: Icon(
                                    Icons.edit,
                                    color: const Color(0xFF1A237E),
                                  ),
                                  filled: true,
                                  fillColor: const Color(0xFF1A237E).withValues(alpha: 0.05),
                                  border: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(12),
                                    borderSide: BorderSide(
                                      color: const Color(0xFF1A237E).withValues(alpha: 0.3),
                                      width: 1.5,
                                    ),
                                  ),
                                  enabledBorder: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(12),
                                    borderSide: BorderSide(
                                      color: const Color(0xFF1A237E).withValues(alpha: 0.3),
                                      width: 1.5,
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
                                    vertical: 16,
                                  ),
                                ),
                                style: const TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                              const SizedBox(height: 8),
                              Row(
                                children: [
                                  Icon(
                                    Icons.info_outline,
                                    size: 16,
                                    color: Colors.grey.shade600,
                                  ),
                                  const SizedBox(width: 6),
                                  Expanded(
                                    child: Text(
                                      'Solo se permiten números enteros',
                                      style: TextStyle(
                                        fontSize: 12,
                                        color: Colors.grey.shade600,
                                        fontStyle: FontStyle.italic,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(height: 24),

                      // Botones de acción
                      Row(
                        children: [
                          // Botón de borrar
                          Expanded(
                            flex: 2,
                            child: SizedBox(
                              height: 50,
                              child: OutlinedButton.icon(
                                onPressed: _isSaving ? null : _borrarDato,
                                icon: const Icon(Icons.delete_outline, size: 24),
                                label: const Text(
                                  'Borrar',
                                  style: TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                style: OutlinedButton.styleFrom(
                                  foregroundColor: Colors.red,
                                  side: const BorderSide(
                                    color: Colors.red,
                                    width: 2,
                                  ),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(width: 12),
                          // Botón de guardar
                          Expanded(
                            flex: 3,
                            child: SizedBox(
                              height: 50,
                              child: ElevatedButton.icon(
                                onPressed: _isSaving ? null : _guardarCambios,
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
                                  _isSaving ? 'Guardando...' : 'Guardar',
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
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
    );
  }

  Widget _buildReadOnlyField(String label, String value, IconData icon) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.bold,
            color: Colors.grey.shade800,
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
              Icon(
                icon,
                size: 20,
                color: Colors.grey.shade600,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  value,
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w500,
                    color: Colors.grey.shade800,
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
