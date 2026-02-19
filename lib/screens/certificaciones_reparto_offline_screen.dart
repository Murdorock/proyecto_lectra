import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../main.dart';
import 'editar_certificacion_reparto_offline_screen.dart';
import '../services/certificaciones_reparto_offline_sync_service.dart';

class CertificacionesRepartoOfflineScreen extends StatefulWidget {
  const CertificacionesRepartoOfflineScreen({super.key});

  @override
  State<CertificacionesRepartoOfflineScreen> createState() => _CertificacionesRepartoOfflineScreenState();
}

class _CertificacionesRepartoOfflineScreenState extends State<CertificacionesRepartoOfflineScreen> {
  List<Map<String, dynamic>> _certificaciones = [];
  List<Map<String, dynamic>> _filtradas = [];
  bool _isLoading = true;
  bool _isSyncing = false;
  String? _errorMessage;
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';
  List<String> _syncResults = [];

  @override
  void initState() {
    super.initState();
    _loadCertificacionesOffline();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadCertificacionesOffline() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final all = await CertificacionesRepartoOfflineSyncService.getAll();
      setState(() {
        _certificaciones = all;
        _applySearch();
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _errorMessage = 'Error cargando datos offline: $e';
        _isLoading = false;
      });
    }
  }

  Future<void> _descargarDesdeNube() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final user = supabase.auth.currentUser;
      if (user == null) {
        setState(() {
          _errorMessage = 'No hay usuario autenticado.';
          _isLoading = false;
        });
        return;
      }

      if (user.email == null || user.email!.trim().isEmpty) {
        setState(() {
          _errorMessage = 'El usuario autenticado no tiene email válido.';
          _isLoading = false;
        });
        return;
      }

      final profileData = await supabase
          .from('perfiles')
          .select('codigo_sup_aux')
          .eq('email', user.email!.trim())
          .maybeSingle();

      if (profileData == null || profileData['codigo_sup_aux'] == null) {
        setState(() {
          _errorMessage = 'No se encontró el código de supervisor/auxiliar';
          _isLoading = false;
        });
        return;
      }

      final codigoSupAux = profileData['codigo_sup_aux'].toString().trim();

      if (codigoSupAux.isEmpty) {
        setState(() {
          _errorMessage = 'El código de supervisor/auxiliar está vacío en perfiles.';
          _isLoading = false;
        });
        return;
      }

      final data = List<Map<String, dynamic>>.from(
        await supabase
            .from('certificaciones_reparto')
            .select('*')
            .eq('nombre_funcionario', codigoSupAux),
      );

      final prefs = await SharedPreferences.getInstance();
      final prev = await CertificacionesRepartoOfflineSyncService.getAll();

      final prevById = <String, Map<String, dynamic>>{};
      for (final item in prev) {
        final id = _rowId(item);
        if (id != null) prevById[id] = item;
      }

      final merged = <Map<String, dynamic>>[];
      final serverIds = <String>{};

      for (final raw in data) {
        final serverItem = Map<String, dynamic>.from(raw);
        final id = _rowId(serverItem);
        if (id != null) serverIds.add(id);

        if (id == null || !prevById.containsKey(id)) {
          serverItem['sincronizado'] = true;
          merged.add(serverItem);
          continue;
        }

        final local = prevById[id]!;
        final mergedItem = Map<String, dynamic>.from(serverItem);

        for (final entry in local.entries) {
          final key = entry.key;
          final localValue = entry.value;

          if (_keysNoFusionables.contains(key)) {
            continue;
          }

          final isEmpty = localValue == null || (localValue is String && localValue.isEmpty);
          if (!isEmpty) {
            mergedItem[key] = localValue;
          }
        }

        mergedItem['sincronizado'] = local['sincronizado'] == true;
        merged.add(mergedItem);
      }

      for (final local in prev) {
        final id = _rowId(local);
        if (id != null && !serverIds.contains(id)) {
          merged.add(local);
        }
      }

      await CertificacionesRepartoOfflineSyncService.saveAll(merged);
      await prefs.setString('codigo_sup_aux', codigoSupAux);
      await prefs.setString('codigo_sup_aux_email', user.email!);

      setState(() {
        _certificaciones = merged;
        _applySearch();
        _isLoading = false;
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Certificaciones descargadas y fusionadas con cambios offline'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      setState(() {
        _errorMessage = 'Error al descargar certificaciones: $e';
        _isLoading = false;
      });
    }
  }

  Future<void> _subirTodoANube() async {
    setState(() {
      _isSyncing = true;
      _syncResults = ['Iniciando sincronización...'];
    });

    try {
      final pendientesAntes = _pendientesSync();
      final results = await CertificacionesRepartoOfflineSyncService.syncAllToCloud();

      setState(() {
        _syncResults = results;
      });

      await _loadCertificacionesOffline();

      if (!mounted) return;

      final exitosos = results.where((r) => r.startsWith('✅')).length;
      final errores = results.where((r) => r.startsWith('❌')).length;
      final pendientesRestantes = (pendientesAntes - exitosos).clamp(0, pendientesAntes);

      final mensaje = exitosos > 0 && errores == 0
          ? '✅ Sincronización completada: $exitosos/$pendientesAntes subidas. Pendientes: $pendientesRestantes'
          : exitosos > 0 && errores > 0
              ? '⚠️ Sincronización parcial: $exitosos/$pendientesAntes subidas, $errores errores. Pendientes: $pendientesRestantes'
              : errores > 0
                  ? '❌ Sincronización con errores: $errores fallos. Pendientes: $pendientesRestantes'
                  : results.first;

      final color = exitosos > 0 && errores == 0
          ? Colors.green
          : exitosos > 0 && errores > 0
              ? Colors.orange
              : errores > 0
                  ? Colors.red
                  : Colors.blue;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(mensaje),
          backgroundColor: color,
          duration: const Duration(seconds: 5),
        ),
      );
    } catch (e) {
      setState(() {
        _syncResults = ['❌ Error general: $e'];
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error en la sincronización: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isSyncing = false;
        });
      }
    }
  }

  Future<void> _marcarSincronizacion(String id, bool synced) async {
    final all = await CertificacionesRepartoOfflineSyncService.getAll();
    final idx = all.indexWhere((e) => _rowId(e) == id);
    if (idx == -1) return;

    all[idx]['sincronizado'] = synced;
    await CertificacionesRepartoOfflineSyncService.saveAll(all);
    await _loadCertificacionesOffline();
  }

  Future<void> _borrarDatosLocalesConConfirmacion() async {
    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('¿Borrar datos locales?'),
        content: const Text('Se eliminarán todas las certificaciones guardadas localmente.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(),
            child: const Text('Cancelar'),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.of(dialogContext).pop();
              await _ejecutarBorradoDatos();
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
            ),
            child: const Text('Sí, borrar todo'),
          ),
        ],
      ),
    );
  }

  Future<void> _ejecutarBorradoDatos() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove('certificaciones_reparto_offline');

      if (!mounted) return;

      setState(() {
        _certificaciones = [];
        _filtradas = [];
        _errorMessage = null;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('✅ Datos locales eliminados correctamente'),
          backgroundColor: Colors.green,
        ),
      );
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('❌ Error al borrar datos: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  void _applySearch() {
    final query = _searchQuery.toLowerCase();
    _filtradas = _certificaciones.where((item) {
      if (query.isEmpty) return true;
      final instalacion = item['instalacion']?.toString().toLowerCase() ?? '';
      final direccion = item['direccion']?.toString().toLowerCase() ??
          item['direccion_entrega']?.toString().toLowerCase() ?? '';
      final contrato = item['contrato']?.toString().toLowerCase() ?? '';
      return instalacion.contains(query) || direccion.contains(query) || contrato.contains(query);
    }).toList();
  }

  int _pendientesSync() {
    return _certificaciones.where((e) => e['sincronizado'] != true).length;
  }

  int _sincronizados() {
    return _certificaciones.where((e) => e['sincronizado'] == true).length;
  }

  String? _rowId(Map<String, dynamic> item) {
    final raw = item['id_certificacion'] ?? item['id'];
    if (raw == null) return null;
    final value = raw.toString().trim();
    return value.isEmpty ? null : value;
  }

  String? _extractReviewerValue(Map<String, dynamic> item) {
    final raw = item['nombre_funcionario'] ?? item['nombre_revisor'] ?? item['correria'] ?? item['codigo_sup_aux'];
    if (raw == null) return null;
    final value = raw.toString().trim();
    return value.isEmpty ? null : value;
  }

  static const Set<String> _keysNoFusionables = {
    'id_certificacion',
    'id',
    'created_at',
    'updated_at',
  };

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'CERTIFICACIONES REPARTO',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
        backgroundColor: const Color(0xFF1A237E),
        iconTheme: const IconThemeData(color: Colors.white),
        actions: [
          IconButton(
            icon: const Icon(Icons.download),
            onPressed: _descargarDesdeNube,
            tooltip: 'Descargar datos',
          ),
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadCertificacionesOffline,
            tooltip: 'Actualizar',
          ),
          IconButton(
            icon: const Icon(Icons.cloud_upload),
            onPressed: _isSyncing ? null : _subirTodoANube,
            tooltip: 'Subir pendientes',
          ),
          IconButton(
            icon: const Icon(Icons.delete_sweep, color: Colors.redAccent),
            onPressed: _borrarDatosLocalesConConfirmacion,
            tooltip: 'Borrar datos locales',
          ),
        ],
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
              : Column(
                  children: [
                    if (_isSyncing) ...[
                      const LinearProgressIndicator(
                        backgroundColor: Colors.grey,
                        valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF1A237E)),
                      ),
                      const SizedBox(height: 8),
                    ],
                    if (_syncResults.isNotEmpty)
                      Container(
                        margin: const EdgeInsets.all(8),
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: Colors.grey.shade100,
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: Colors.grey.shade300),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                const Icon(Icons.cloud_done, color: Color(0xFF1A237E), size: 18),
                                const SizedBox(width: 8),
                                const Expanded(
                                  child: Text(
                                    'Resultados de sincronización',
                                    style: TextStyle(fontWeight: FontWeight.bold),
                                  ),
                                ),
                                IconButton(
                                  icon: const Icon(Icons.close, size: 18),
                                  onPressed: () {
                                    setState(() {
                                      _syncResults.clear();
                                    });
                                  },
                                ),
                              ],
                            ),
                            ..._syncResults.map((r) => Text(
                                  r,
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: r.startsWith('✅')
                                        ? Colors.green.shade700
                                        : r.startsWith('❌')
                                            ? Colors.red.shade700
                                            : Colors.grey.shade700,
                                  ),
                                )),
                          ],
                        ),
                      ),
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        boxShadow: [
                          BoxShadow(
                            color: Colors.grey.shade300,
                            blurRadius: 4,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      child: Column(
                        children: [
                          Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                                decoration: BoxDecoration(
                                  color: const Color(0xFF1A237E),
                                  borderRadius: BorderRadius.circular(20),
                                ),
                                child: Text(
                                  'Total: ${_certificaciones.length}',
                                  style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                                ),
                              ),
                              const SizedBox(width: 10),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                                decoration: BoxDecoration(
                                  color: Colors.green.shade700,
                                  borderRadius: BorderRadius.circular(20),
                                ),
                                child: Text(
                                  'Sincronizadas: ${_sincronizados()}',
                                  style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                                ),
                              ),
                              const SizedBox(width: 10),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                                decoration: BoxDecoration(
                                  color: Colors.orange.shade700,
                                  borderRadius: BorderRadius.circular(20),
                                ),
                                child: Text(
                                  'Pendientes: ${_pendientesSync()}',
                                  style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 12),
                          TextField(
                            controller: _searchController,
                            decoration: InputDecoration(
                              hintText: 'Buscar por instalación, contrato o dirección',
                              prefixIcon: const Icon(Icons.search, color: Color(0xFF1A237E)),
                              suffixIcon: _searchQuery.isNotEmpty
                                  ? IconButton(
                                      icon: const Icon(Icons.clear),
                                      onPressed: () {
                                        _searchController.clear();
                                        setState(() {
                                          _searchQuery = '';
                                          _applySearch();
                                        });
                                      },
                                    )
                                  : null,
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                            ),
                            onChanged: (value) {
                              setState(() {
                                _searchQuery = value;
                                _applySearch();
                              });
                            },
                          ),
                        ],
                      ),
                    ),
                    Expanded(
                      child: _filtradas.isEmpty
                          ? const Center(
                              child: Text(
                                'No hay certificaciones offline guardadas',
                                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                              ),
                            )
                          : ListView.builder(
                              padding: const EdgeInsets.all(16),
                              itemCount: _filtradas.length,
                              itemBuilder: (context, index) {
                                final item = _filtradas[index];
                                final id = _rowId(item);
                                final instalacion = item['instalacion']?.toString() ?? 'Sin instalación';
                                final contrato = item['contrato']?.toString() ?? 'Sin contrato';
                                final tipoCertificacion = item['tipo_certificacion']?.toString() ?? 'Sin tipo';
                                final direccion = item['direccion']?.toString() ??
                                    item['direccion_entrega']?.toString() ??
                                    'Sin dirección';
                                final synced = item['sincronizado'] == true;

                                return Card(
                                  margin: const EdgeInsets.only(bottom: 12),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(12),
                                    side: BorderSide(
                                      color: synced ? Colors.green : Colors.orange,
                                      width: 1.8,
                                    ),
                                  ),
                                  child: InkWell(
                                    borderRadius: BorderRadius.circular(12),
                                    onTap: id == null
                                        ? null
                                        : () async {
                                            final result = await Navigator.push(
                                              context,
                                              MaterialPageRoute(
                                                builder: (_) => EditarCertificacionRepartoOfflineScreen(
                                                  certificacionId: id,
                                                ),
                                              ),
                                            );

                                            if (result == true) {
                                              await _loadCertificacionesOffline();
                                            }
                                          },
                                    child: Padding(
                                      padding: const EdgeInsets.all(14),
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          Row(
                                            children: [
                                              Expanded(
                                                child: Text(
                                                  'Tipo certificación: $tipoCertificacion',
                                                  style: const TextStyle(
                                                    fontWeight: FontWeight.bold,
                                                    color: Color(0xFF1A237E),
                                                  ),
                                                ),
                                              ),
                                              Chip(
                                                label: Text(
                                                  synced ? 'Sincronizado' : 'Pendiente',
                                                  style: const TextStyle(color: Colors.white, fontSize: 12),
                                                ),
                                                backgroundColor: synced ? Colors.green : Colors.orange,
                                              ),
                                            ],
                                          ),
                                          const SizedBox(height: 6),
                                          Text('Instalación: $instalacion'),
                                          const SizedBox(height: 4),
                                          Text('Contrato: $contrato'),
                                          const SizedBox(height: 4),
                                          Text(
                                            direccion,
                                            style: TextStyle(color: Colors.grey.shade700),
                                          ),
                                          const SizedBox(height: 8),
                                          if (id != null)
                                            Row(
                                              mainAxisAlignment: MainAxisAlignment.end,
                                              children: [
                                                TextButton.icon(
                                                  onPressed: () => _marcarSincronizacion(id, false),
                                                  icon: const Icon(Icons.schedule_send, size: 18),
                                                  label: const Text('Marcar pendiente'),
                                                ),
                                                TextButton.icon(
                                                  onPressed: () => _marcarSincronizacion(id, true),
                                                  icon: const Icon(Icons.cloud_done, size: 18),
                                                  label: const Text('Marcar sincronizado'),
                                                ),
                                              ],
                                            ),
                                        ],
                                      ),
                                    ),
                                  ),
                                );
                              },
                            ),
                    ),
                  ],
                ),
    );
  }
}
