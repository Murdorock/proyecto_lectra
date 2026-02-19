import 'package:flutter/material.dart';
import 'dart:async';
import 'dart:convert';
//import 'dart:io';
import 'package:shared_preferences/shared_preferences.dart';
import 'editar_inconsistencia_offline_screen.dart';
import '../services/offline_sync_service.dart';
import '../main.dart';

class InconsistenciasOfflineScreen extends StatefulWidget {
  const InconsistenciasOfflineScreen({super.key});

  @override
  State<InconsistenciasOfflineScreen> createState() => _InconsistenciasOfflineScreenState();
}

class _InconsistenciasOfflineScreenState extends State<InconsistenciasOfflineScreen> {
      bool _isSyncing = false;
      List<String> _syncResults = [];

  Future<void> _subirTodoANube() async {
    setState(() { 
      _isSyncing = true; 
      _syncResults = ['Iniciando sincronización...']; 
    });
    
    try {
      // Calcular cuántas inconsistencias son elegibles para sincronizar (PDF generado y no sincronizadas)
      final totalPendientes = await _contarPendientesSync();
      final results = await OfflineSyncService.syncAllToCloud();
      setState(() { _syncResults = results; });
      
      if (mounted) {
        // Contar exitosos y errores
        final exitosos = results.where((r) => r.startsWith('✅')).length;
        final errores = results.where((r) => r.startsWith('❌')).length;
        final pendientesRestantes = (totalPendientes - exitosos).clamp(0, totalPendientes);
        
        String mensaje;
        Color color;
        
        if (exitosos > 0 && errores == 0) {
          mensaje = '✅ Sincronización completada: $exitosos/$totalPendientes subidas. Pendientes: $pendientesRestantes';
          color = Colors.green;
        } else if (exitosos > 0 && errores > 0) {
          mensaje = '⚠️ Sincronización parcial: $exitosos/$totalPendientes subidas, $errores errores. Pendientes: $pendientesRestantes';
          color = Colors.orange;
        } else if (errores > 0) {
          mensaje = totalPendientes == 0
              ? 'ℹ️ No hay inconsistencias listas para subir'
              : '❌ Sincronización con errores: $errores fallos. Pendientes: $pendientesRestantes';
          color = Colors.red;
        } else {
          mensaje = results.first;
          color = Colors.blue;
        }
        
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(mensaje),
            backgroundColor: color,
            duration: const Duration(seconds: 5),
          ),
        );
        
        // Recargar la lista para reflejar cambios
        await _loadInconsistenciasOffline();
      }
    } catch (e) {
      setState(() { _syncResults = ['❌ Error general: $e']; });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error en la sincronización: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      setState(() { _isSyncing = false; });
    }
  }

  Future<int> _contarPendientesSync() async {
    final all = await OfflineSyncService.getAll();
    return all.where((e) {
      final sincronizado = e['sincronizado'] == true;
      final tienePdf = e['pdf'] != null && e['pdf'].toString().isNotEmpty;
      return !sincronizado && tienePdf;
    }).length;
  }

  Future<void> _borrarDatosLocalesConConfirmacion() async {
    showDialog(
      context: context,
      builder: (BuildContext dialogContext) => AlertDialog(
        elevation: 8,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Row(
          children: [
            Icon(Icons.warning, color: Colors.red, size: 28),
            SizedBox(width: 12),
            Expanded(
              child: Text('¿Borrar datos locales?', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.red)),
            ),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Se eliminarán todos los datos descargados localmente, incluyendo:',
              style: TextStyle(fontSize: 14),
            ),
            const SizedBox(height: 12),
            const Padding(
              padding: EdgeInsets.only(left: 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('• Inconsistencias offline', style: TextStyle(fontSize: 13)),
                  Text('• PDFs generados', style: TextStyle(fontSize: 13)),
                  Text('• Firmas capturadas', style: TextStyle(fontSize: 13)),
                  Text('• Fotos tomadas', style: TextStyle(fontSize: 13)),
                ],
              ),
            ),
            const SizedBox(height: 16),
            const Text(
              'Las fotos se conservarán en el dispositivo.',
              style: TextStyle(fontSize: 12, fontStyle: FontStyle.italic, color: Colors.grey),
            ),
            const SizedBox(height: 12),
            const Text(
              '⚠️ Esta acción no se puede deshacer.',
              style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: Colors.red),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(),
            child: const Text('Cancelar', style: TextStyle(color: Colors.blue)),
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
      await prefs.remove('inconsistencias_offline');
      await prefs.remove('codigo_sup_aux');
      await prefs.remove('codigo_sup_aux_email');

      if (mounted) {
        setState(() {
          _inconsistencias = [];
          _inconsistenciasFiltradas = [];
          _codigoSupAux = '';
          _errorMessage = null;
        });

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('✅ Datos locales eliminados correctamente'),
            backgroundColor: Colors.green,
            duration: Duration(seconds: 3),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('❌ Error al borrar datos: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
      print('❌ Error borrando datos: $e');
    }
  }
    Future<void> _descargarInconsistenciasDesdeNube() async {
      setState(() { _isLoading = true; _errorMessage = null; });
      try {
        // Obtener usuario logueado desde supabase
        final user = supabase.auth.currentUser;
        if (user == null) {
          setState(() {
            _errorMessage = 'No hay usuario autenticado.';
            _isLoading = false;
          });
          return;
        }
        // Obtener codigo_sup_aux
        final profileData = await supabase
            .from('perfiles')
            .select('codigo_sup_aux')
            .eq('email', user.email!)
            .maybeSingle();
        if (profileData == null || profileData['codigo_sup_aux'] == null) {
          setState(() {
            _errorMessage = 'No se encontró el código de supervisor/auxiliar';
            _isLoading = false;
          });
          return;
        }
        final codigoSupAux = profileData['codigo_sup_aux'].toString();
        // Descargar inconsistencias asignadas
        final data = await supabase
          .from('inconsistencias')
          .select('*')
          .eq('nombre_revisor', codigoSupAux)
          .order('instalacion', ascending: true);
        
        // Fusionar con datos locales existentes para preservar cambios offline
        final prefs = await SharedPreferences.getInstance();
        final prevStr = prefs.getString('inconsistencias_offline') ?? '[]';
        final prevList = List<Map<String, dynamic>>.from(json.decode(prevStr));

        Map<int, Map<String, dynamic>> prevById = {};
        for (final e in prevList) {
          final rawId = e['id'];
          int? idInt;
          if (rawId is int) idInt = rawId; else if (rawId is String) idInt = int.tryParse(rawId);
          if (idInt != null) prevById[idInt] = e;
        }

        List<Map<String, dynamic>> merged = [];
        final Set<int> serverIds = {};
        for (final s in List<Map<String, dynamic>>.from(data)) {
          final rawId = s['id'];
          int? idInt;
          if (rawId is int) idInt = rawId; else if (rawId is String) idInt = int.tryParse(rawId);
          if (idInt != null) serverIds.add(idInt);
          final local = idInt != null ? prevById[idInt] : null;
          if (local == null) {
            merged.add(s);
          } else {
            final mergedItem = Map<String, dynamic>.from(s);
            // Preservar campos locales si existen (no vacíos)
            for (final k in [
              'pdf',
              'causa_observacion',
              'observacion_adicional_real',
              'alfanumerica_revisor',
              'lectura_real',
              'correcciones_en_sistema',
              'advertencia_revisor',
              'firma_revisor',
              'foto',
              'foto1',
              'foto2',
              'sincronizado',
              'geolocalizacion',
              'coordenada_instalacion',
              'fecha_revision',
            ]) {
              final lv = local[k];
              final isEmpty = lv == null || (lv is String && lv.isEmpty);
              if (!isEmpty) mergedItem[k] = lv;
            }
            merged.add(mergedItem);
          }
        }

        // Incluir registros locales que no vinieron del servidor (preservar trabajo offline)
        for (final e in prevList) {
          final rawId = e['id'];
          int? idInt;
          if (rawId is int) idInt = rawId; else if (rawId is String) idInt = int.tryParse(rawId);
          if (idInt != null && !serverIds.contains(idInt)) {
            merged.add(e);
          }
        }

        // Guardar fusionado localmente
        await prefs.setString('inconsistencias_offline', json.encode(merged));
        await prefs.setString('codigo_sup_aux', codigoSupAux);
        await prefs.setString('codigo_sup_aux_email', user.email!);
        setState(() {
          _codigoSupAux = codigoSupAux;
          _inconsistencias = merged;
          _aplicarFiltro();
          _isLoading = false;
        });
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Datos descargados y fusionados con cambios offline'), backgroundColor: Colors.green),
          );
        }
      } catch (e) {
        setState(() {
          _errorMessage = 'Error al descargar inconsistencias: \n${e.toString()}';
          _isLoading = false;
        });
      }
    }
  List<Map<String, dynamic>> _inconsistencias = [];
  List<Map<String, dynamic>> _inconsistenciasFiltradas = [];
  bool _isLoading = true;
  String? _errorMessage;
  String _filtroSeleccionado = 'Todas';
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';
  // ignore: unused_field
  String _codigoSupAux = '';

  @override
  void initState() {
    super.initState();
    _loadInconsistenciasOffline();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  int _totalConPdfLocal() {
    return _inconsistencias.where((item) => item['pdf'] != null && item['pdf'].toString().isNotEmpty).length;
  }

  int _totalSincronizadosNube() {
    return _inconsistencias.where((item) {
      final tienePdf = item['pdf'] != null && item['pdf'].toString().isNotEmpty;
      final sincronizado = item['sincronizado'] == true;
      return tienePdf && sincronizado;
    }).length;
  }

  int _pendientesSubirNube() {
    return _inconsistencias.where((item) {
      final tienePdf = item['pdf'] != null && item['pdf'].toString().isNotEmpty;
      final sincronizado = item['sincronizado'] == true;
      return tienePdf && !sincronizado;
    }).length;
  }

  Future<void> _loadInconsistenciasOffline() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });
    try {
      // Cargar datos locales primero
      final prefs = await SharedPreferences.getInstance();
      final codigoGuardado = prefs.getString('codigo_sup_aux') ?? '';
      final inconsistenciasStr = prefs.getString('inconsistencias_offline') ?? '[]';
      final inconsistenciasLocales = List<Map<String, dynamic>>.from(json.decode(inconsistenciasStr));

      // Si hay datos locales descargados, cargarlos siempre sin requerir internet
      // Internet solo es necesaria para descargar, generar PDF o consultar ubicación
      if (codigoGuardado.isNotEmpty && inconsistenciasLocales.isNotEmpty) {
        _codigoSupAux = codigoGuardado;
        setState(() {
          _inconsistencias = inconsistenciasLocales;
          _aplicarFiltro();
          _isLoading = false;
        });
        return;
      }

      // Si no hay datos locales, verificar sesión
      final user = supabase.auth.currentUser;
      if (user == null) {
        setState(() {
          _errorMessage = 'Sin datos locales. Descarga primero con conexión.';
          _isLoading = false;
        });
        return;
      }

      setState(() {
        _inconsistencias = [];
        _aplicarFiltro();
        _isLoading = false;
      });
      
      print('✅ Datos offline cargados');
    } catch (e) {
      setState(() {
        _errorMessage = 'Error al cargar inconsistencias offline: \n${e.toString()}';
        _isLoading = false;
      });
      print('❌ Error cargando inconsistencias offline: $e');
    }
  }

  void _aplicarFiltro() {
    setState(() {
      List<Map<String, dynamic>> filtradas;
      switch (_filtroSeleccionado) {
        case 'Completadas':
          filtradas = _inconsistencias.where((item) {
            final pdf = item['pdf'];
            return pdf != null && pdf.toString().isNotEmpty;
          }).toList();
          break;
        case 'En Progreso':
          filtradas = _inconsistencias.where((item) {
            final pdf = item['pdf'];
            if (pdf != null && pdf.toString().isNotEmpty) return false;
            final causaObservacion = item['causa_observacion'];
            final lecturaReal = item['lectura_real'];
            final foto = item['foto'];
            final firma = item['firma_revisor'];
            return (causaObservacion != null && causaObservacion.toString().isNotEmpty) ||
                   (lecturaReal != null && lecturaReal.toString().isNotEmpty) ||
                   (foto != null && foto.toString().isNotEmpty) ||
                   (firma != null && firma.toString().isNotEmpty);
          }).toList();
          break;
        case 'Sin Iniciar':
          filtradas = _inconsistencias.where((item) {
            final pdf = item['pdf'];
            if (pdf != null && pdf.toString().isNotEmpty) return false;
            final causaObservacion = item['causa_observacion'];
            final lecturaReal = item['lectura_real'];
            final foto = item['foto'];
            final firma = item['firma_revisor'];
            bool hasChanges = (causaObservacion != null && causaObservacion.toString().isNotEmpty) ||
                             (lecturaReal != null && lecturaReal.toString().isNotEmpty) ||
                             (foto != null && foto.toString().isNotEmpty) ||
                             (firma != null && firma.toString().isNotEmpty);
            return !hasChanges;
          }).toList();
          break;
        default:
          filtradas = List.from(_inconsistencias);
      }
      if (_searchQuery.isNotEmpty) {
        filtradas = filtradas.where((item) {
          final direccion = item['direccion']?.toString().toLowerCase() ?? '';
          final instalacion = item['instalacion']?.toString().toLowerCase() ?? '';
          final query = _searchQuery.toLowerCase();
          return direccion.contains(query) || instalacion.contains(query);
        }).toList();
      }
      _inconsistenciasFiltradas = filtradas;
    });
  }

  Color _getBorderColor(Map<String, dynamic> item) {
    final pdf = item['pdf'];
    if (pdf != null && pdf.toString().isNotEmpty) return Colors.green;
    final causaObservacion = item['causa_observacion'];
    final lecturaReal = item['lectura_real'];
    final foto = item['foto'];
    final firma = item['firma_revisor'];
    bool hasChanges = (causaObservacion != null && causaObservacion.toString().isNotEmpty) ||
                      (lecturaReal != null && lecturaReal.toString().isNotEmpty) ||
                      (foto != null && foto.toString().isNotEmpty) ||
                      (firma != null && firma.toString().isNotEmpty);
    if (hasChanges) return Colors.orange;
    return Colors.transparent;
  }

  Widget _buildFiltroChip(String filtro) {
    final isSelected = _filtroSeleccionado == filtro;
    Color chipColor;
    switch (filtro) {
      case 'Completadas': chipColor = Colors.green; break;
      case 'En Progreso': chipColor = Colors.orange; break;
      case 'Sin Iniciar': chipColor = Colors.grey; break;
      default: chipColor = const Color(0xFF1A237E);
    }
    return FilterChip(
      label: Text(
        filtro,
        style: TextStyle(
          color: isSelected ? Colors.white : chipColor,
          fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
          fontSize: 12,
        ),
      ),
      selected: isSelected,
      onSelected: (selected) {
        setState(() {
          _filtroSeleccionado = filtro;
          _aplicarFiltro();
        });
      },
      backgroundColor: Colors.white,
      selectedColor: chipColor,
      checkmarkColor: Colors.white,
      side: BorderSide(color: chipColor, width: 2),
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('INCONSISTENCIAS OFFLINE', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
        backgroundColor: const Color(0xFF1A237E),
        iconTheme: const IconThemeData(color: Colors.white),
        actions: [
          IconButton(
            icon: const Icon(Icons.download),
            onPressed: _descargarInconsistenciasDesdeNube,
            tooltip: 'Descargar datos',
          ),
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadInconsistenciasOffline,
            tooltip: 'Actualizar',
          ),
          IconButton(
            icon: const Icon(Icons.cloud_upload),
            onPressed: _isSyncing ? null : _subirTodoANube,
            tooltip: 'Subir todo a la nube',
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
              ? Center(child: Padding(padding: const EdgeInsets.all(24), child: Text(_errorMessage!, style: const TextStyle(fontSize: 16, color: Colors.black87))))
              : _inconsistencias.isEmpty
                  ? Center(child: Text('No hay inconsistencias offline guardadas', style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.black87)))
                  : Column(
                      children: [
                        if (_isSyncing) ...[
                          const LinearProgressIndicator(
                            backgroundColor: Colors.grey,
                            valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF1A237E)),
                          ),
                          const SizedBox(height: 8),
                        ],
                        if (_syncResults.isNotEmpty) ...[
                          Container(
                            margin: const EdgeInsets.all(8.0),
                            padding: const EdgeInsets.all(12.0),
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
                                    const Icon(Icons.cloud_done, color: Color(0xFF1A237E), size: 20),
                                    const SizedBox(width: 8),
                                    const Text(
                                      'Resultados de sincronización:',
                                      style: TextStyle(
                                        fontWeight: FontWeight.bold,
                                        fontSize: 14,
                                        color: Color(0xFF1A237E),
                                      ),
                                    ),
                                    const Spacer(),
                                    IconButton(
                                      icon: const Icon(Icons.close, size: 18),
                                      onPressed: () {
                                        setState(() {
                                          _syncResults.clear();
                                        });
                                      },
                                      tooltip: 'Cerrar',
                                    ),
                                  ],
                                ),
                                const Divider(),
                                const SizedBox(height: 4),
                                ..._syncResults.map((r) => Padding(
                                  padding: const EdgeInsets.symmetric(vertical: 2),
                                  child: Text(
                                    r,
                                    style: TextStyle(
                                      fontSize: 12,
                                      color: r.startsWith('✅') 
                                          ? Colors.green.shade700
                                          : r.startsWith('❌')
                                              ? Colors.red.shade700
                                              : Colors.grey.shade700,
                                    ),
                                  ),
                                )),
                              ],
                            ),
                          ),
                        ],
                        Container(
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(color: Colors.white, boxShadow: [BoxShadow(color: Colors.grey.shade300, blurRadius: 4, offset: const Offset(0, 2))]),
                          child: Column(
                            children: [
                              Row(
                                children: [
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                                    decoration: BoxDecoration(color: const Color(0xFF1A237E), borderRadius: BorderRadius.circular(20)),
                                    child: Text('${_totalConPdfLocal()}/${_inconsistencias.length}', style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 14)),
                                  ),
                                  const SizedBox(width: 12),
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                                    decoration: BoxDecoration(color: Colors.green.shade700, borderRadius: BorderRadius.circular(20)),
                                    child: Text('Subidos nube: ${_totalSincronizadosNube()}', style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 14)),
                                  ),
                                  const SizedBox(width: 12),
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                                    decoration: BoxDecoration(color: Colors.orange.shade700, borderRadius: BorderRadius.circular(20)),
                                    child: Text('Pendientes nube: ${_pendientesSubirNube()}', style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 14)),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 12),
                              SingleChildScrollView(
                                scrollDirection: Axis.horizontal,
                                child: Row(
                                  children: [
                                    _buildFiltroChip('Todas'),
                                    const SizedBox(width: 8),
                                    _buildFiltroChip('Completadas'),
                                    const SizedBox(width: 8),
                                    _buildFiltroChip('En Progreso'),
                                    const SizedBox(width: 8),
                                    _buildFiltroChip('Sin Iniciar'),
                                  ],
                                ),
                              ),
                              const SizedBox(height: 12),
                              TextField(
                                controller: _searchController,
                                decoration: InputDecoration(
                                  hintText: 'Buscar por instalación o dirección',
                                  prefixIcon: const Icon(Icons.search, color: Color(0xFF1A237E)),
                                  suffixIcon: _searchQuery.isNotEmpty
                                      ? IconButton(
                                          icon: const Icon(Icons.clear),
                                          onPressed: () {
                                            _searchController.clear();
                                            setState(() {
                                              _searchQuery = '';
                                              _aplicarFiltro();
                                            });
                                          },
                                        )
                                      : null,
                                  border: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(12),
                                    borderSide: const BorderSide(color: Color(0xFF1A237E)),
                                  ),
                                  focusedBorder: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(12),
                                    borderSide: const BorderSide(color: Color(0xFF1A237E), width: 2),
                                  ),
                                  contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                                ),
                                onChanged: (value) {
                                  setState(() {
                                    _searchQuery = value;
                                    _aplicarFiltro();
                                  });
                                },
                              ),
                            ],
                          ),
                        ),
                        Expanded(
                          child: _inconsistenciasFiltradas.isEmpty
                              ? Center(child: Text('No hay inconsistencias con el filtro "$_filtroSeleccionado"', style: TextStyle(fontSize: 16, color: Colors.grey.shade600)))
                              : ListView.builder(
                                  padding: const EdgeInsets.all(16),
                                  itemCount: _inconsistenciasFiltradas.length,
                                  itemBuilder: (context, index) {
                                    final item = _inconsistenciasFiltradas[index];
                                    final direccion = item['direccion']?.toString() ?? 'Sin dirección';
                                    final instalacion = item['instalacion']?.toString() ?? 'Sin instalación';
                                    final tipoConsumo = item['tipo_consumo']?.toString() ?? 'Sin tipo';
                                    final borderColor = _getBorderColor(item);
                                    // Determinar color de fondo según estado
                                  Color backgroundColor = Colors.white;
                                  String estadoLabel = '';
                                  
                                  if (borderColor == Colors.green) {
                                    backgroundColor = Colors.green.shade50;
                                    estadoLabel = ' ✅ COMPLETADO';
                                  } else if (borderColor == Colors.orange) {
                                    backgroundColor = Colors.orange.shade50;
                                    estadoLabel = ' ⏳ EN PROGRESO';
                                  }

                                  return Container(
                                      margin: const EdgeInsets.only(bottom: 12),
                                      decoration: BoxDecoration(
                                        borderRadius: BorderRadius.circular(12),
                                        border: borderColor != Colors.transparent ? Border.all(color: borderColor, width: 3) : Border.all(color: Colors.grey.shade300, width: 1),
                                      ),
                                      child: Card(
                                        margin: EdgeInsets.zero,
                                        elevation: 2,
                                        color: backgroundColor,
                                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                                        child: InkWell(
                                          borderRadius: BorderRadius.circular(12),
                                          onTap: () async {
                                            final result = await Navigator.push(
                                              context,
                                              MaterialPageRoute(
                                                builder: (_) => EditarInconsistenciaOfflineScreen(
                                                  inconsistenciaId: item['id'],
                                                ),
                                              ),
                                            );
                                            // Si se retorna true, significa que hubo cambios
                                            if (result == true) {
                                              _loadInconsistenciasOffline();
                                            }
                                          },
                                          child: Padding(
                                            padding: const EdgeInsets.all(16),
                                            child: Column(
                                              crossAxisAlignment: CrossAxisAlignment.start,
                                              children: [
                                                if (estadoLabel.isNotEmpty)
                                                  Padding(
                                                    padding: const EdgeInsets.only(bottom: 8),
                                                    child: Text(
                                                      estadoLabel,
                                                      style: TextStyle(
                                                        fontSize: 12,
                                                        fontWeight: FontWeight.bold,
                                                        color: borderColor == Colors.green ? Colors.green.shade700 : Colors.orange.shade700,
                                                      ),
                                                    ),
                                                  ),
                                                Row(
                                                  children: [
                                                    Container(
                                                      width: 50,
                                                      height: 50,
                                                      decoration: BoxDecoration(color: const Color(0xFF1A237E), borderRadius: BorderRadius.circular(25)),
                                                      child: Center(child: Text('${index + 1}', style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 18))),
                                                    ),
                                                    const SizedBox(width: 16),
                                                    Expanded(
                                                      child: Column(
                                                        crossAxisAlignment: CrossAxisAlignment.start,
                                                        children: [
                                                          Row(
                                                            children: [
                                                              const Icon(Icons.location_on, size: 16, color: Color(0xFF1A237E)),
                                                              const SizedBox(width: 4),
                                                              Expanded(
                                                                child: Text(
                                                                  direccion,
                                                                  style: const TextStyle(color: Colors.black87),
                                                                  maxLines: 2,
                                                                  overflow: TextOverflow.ellipsis,
                                                                ),
                                                              ),
                                                            ],
                                                          ),
                                                          const SizedBox(height: 8),
                                                          Row(
                                                            children: [
                                                              const Icon(Icons.home, size: 16, color: Colors.grey),
                                                              const SizedBox(width: 4),
                                                              Text('Instalación: $instalacion', style: TextStyle(fontSize: 14, color: Colors.grey.shade700)),
                                                            ],
                                                          ),
                                                          const SizedBox(height: 8),
                                                          Row(
                                                            children: [
                                                              const Icon(Icons.bar_chart, size: 16, color: Colors.grey),
                                                              const SizedBox(width: 4),
                                                              Text('Tipo: $tipoConsumo', style: TextStyle(fontSize: 14, color: Colors.grey.shade700)),
                                                            ],
                                                          ),
                                                        ],
                                                      ),
                                                    ),
                                                    const Icon(Icons.chevron_right, color: Color(0xFF1A237E), size: 28),
                                                  ],
                                                ),
                                              ],
                                            ),
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
