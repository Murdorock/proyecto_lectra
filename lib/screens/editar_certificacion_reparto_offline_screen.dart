import 'package:flutter/material.dart';
import '../services/certificaciones_reparto_offline_sync_service.dart';
import 'entrega_correrias_screen.dart';

class EditarCertificacionRepartoOfflineScreen extends StatefulWidget {
  final String certificacionId;

  const EditarCertificacionRepartoOfflineScreen({
    super.key,
    required this.certificacionId,
  });

  @override
  State<EditarCertificacionRepartoOfflineScreen> createState() =>
      _EditarCertificacionRepartoOfflineScreenState();
}

class _EditarCertificacionRepartoOfflineScreenState
    extends State<EditarCertificacionRepartoOfflineScreen> {
  bool _isLoading = true;
  bool _isSaving = false;
  String? _errorMessage;
  Map<String, dynamic>? _data;

  final TextEditingController _tipoController = TextEditingController();
  final TextEditingController _instalacionController = TextEditingController();
  final TextEditingController _contratoController = TextEditingController();
  final TextEditingController _direccionController = TextEditingController();

  String _direccionKey = 'direccion';

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  @override
  void dispose() {
    _tipoController.dispose();
    _instalacionController.dispose();
    _contratoController.dispose();
    _direccionController.dispose();
    super.dispose();
  }

  Future<void> _loadData() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final all = await CertificacionesRepartoOfflineSyncService.getAll();
      final idx = all.indexWhere((item) => _rowId(item) == widget.certificacionId);

      if (idx == -1) {
        setState(() {
          _errorMessage = 'No se encontró la certificación.';
          _isLoading = false;
        });
        return;
      }

      final row = Map<String, dynamic>.from(all[idx]);
      _data = row;

      _direccionKey = row.containsKey('direccion') ? 'direccion' : 'direccion_entrega';

      _tipoController.text = row['tipo_certificacion']?.toString() ?? '';
      _instalacionController.text = row['instalacion']?.toString() ?? '';
      _contratoController.text = row['contrato']?.toString() ?? '';
      _direccionController.text = row[_direccionKey]?.toString() ?? '';

      setState(() {
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _errorMessage = 'Error cargando certificación: $e';
        _isLoading = false;
      });
    }
  }

  Future<void> _guardarCambios() async {
    if (_data == null) return;

    setState(() {
      _isSaving = true;
      _errorMessage = null;
    });

    try {
      final all = await CertificacionesRepartoOfflineSyncService.getAll();
      final idx = all.indexWhere((item) => _rowId(item) == widget.certificacionId);

      if (idx == -1) {
        throw Exception('No se encontró el registro para guardar');
      }

      final updated = Map<String, dynamic>.from(all[idx]);
      updated['tipo_certificacion'] = _tipoController.text.trim();
      updated['instalacion'] = _instalacionController.text.trim();
      updated['contrato'] = _contratoController.text.trim();
      updated[_direccionKey] = _direccionController.text.trim();
      updated['sincronizado'] = false;

      all[idx] = updated;
      await CertificacionesRepartoOfflineSyncService.saveAll(all);

      if (!mounted) return;
      Navigator.pop(context, true);
    } catch (e) {
      setState(() {
        _errorMessage = 'Error guardando cambios: $e';
        _isSaving = false;
      });
    }
  }

  Future<void> _abrirScannerContrato() async {
    try {
      final result = await Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => const BarcodeScannerScreen(
            title: 'Escanear Contrato',
          ),
        ),
      );

      if (result != null && result.toString().isNotEmpty) {
        setState(() {
          _contratoController.text = result.toString();
        });
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error al abrir escáner: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  String? _rowId(Map<String, dynamic> item) {
    final raw = item['id_certificacion'] ?? item['id'];
    if (raw == null) return null;
    final value = raw.toString().trim();
    return value.isEmpty ? null : value;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Editar Certificación',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
        backgroundColor: const Color(0xFF1A237E),
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(color: Color(0xFF1A237E)))
          : _errorMessage != null
              ? Center(
                  child: Padding(
                    padding: const EdgeInsets.all(24),
                    child: Text(
                      _errorMessage!,
                      style: const TextStyle(fontSize: 16, color: Colors.black87),
                    ),
                  ),
                )
              : SingleChildScrollView(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    children: [
                      _buildField(
                        controller: _tipoController,
                        label: 'Tipo certificación',
                        icon: Icons.assignment_turned_in,
                      ),
                      const SizedBox(height: 12),
                      _buildField(
                        controller: _instalacionController,
                        label: 'Instalación',
                        icon: Icons.home,
                      ),
                      const SizedBox(height: 12),
                      _buildField(
                        controller: _contratoController,
                        label: 'Contrato',
                        icon: Icons.badge,
                        suffixIcon: IconButton(
                          onPressed: _abrirScannerContrato,
                          icon: const Icon(Icons.qr_code_scanner),
                          color: const Color(0xFF1A237E),
                          tooltip: 'Escanear contrato',
                        ),
                      ),
                      const SizedBox(height: 12),
                      _buildField(
                        controller: _direccionController,
                        label: 'Dirección',
                        icon: Icons.location_on,
                        maxLines: 2,
                      ),
                      const SizedBox(height: 20),
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton.icon(
                          onPressed: _isSaving ? null : _guardarCambios,
                          icon: _isSaving
                              ? const SizedBox(
                                  width: 18,
                                  height: 18,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                    valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                                  ),
                                )
                              : const Icon(Icons.save),
                          label: Text(
                            _isSaving ? 'GUARDANDO...' : 'GUARDAR CAMBIOS',
                            style: const TextStyle(fontWeight: FontWeight.bold),
                          ),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF1A237E),
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(vertical: 14),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
    );
  }

  Widget _buildField({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    int maxLines = 1,
    Widget? suffixIcon,
  }) {
    return TextField(
      controller: controller,
      maxLines: maxLines,
      decoration: InputDecoration(
        labelText: label,
        prefixIcon: Icon(icon, color: const Color(0xFF1A237E)),
        suffixIcon: suffixIcon,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: const BorderSide(color: Color(0xFF1A237E), width: 2),
        ),
      ),
    );
  }
}
