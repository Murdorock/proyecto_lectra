import 'package:flutter/material.dart';
import '../main.dart';
import 'editar_inconsistencia_screen.dart';

class InconsistenciasScreen extends StatefulWidget {
  const InconsistenciasScreen({super.key});

  @override
  State<InconsistenciasScreen> createState() => _InconsistenciasScreenState();
}

class _InconsistenciasScreenState extends State<InconsistenciasScreen> {
  List<Map<String, dynamic>> _inconsistencias = [];
  List<Map<String, dynamic>> _inconsistenciasFiltradas = [];
  bool _isLoading = true;
  String? _errorMessage;
  String _codigoSupAux = '';
  String _filtroSeleccionado = 'Todas'; // Filtro por defecto
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';

  @override
  void initState() {
    super.initState();
    _loadInconsistencias();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadInconsistencias() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final user = supabase.auth.currentUser;
      if (user == null) {
        setState(() {
          _errorMessage = 'Usuario no autenticado';
          _isLoading = false;
        });
        return;
      }

      // Obtener el codigo_sup_aux del usuario logueado
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

      _codigoSupAux = profileData['codigo_sup_aux'].toString();

      // Buscar inconsistencias donde nombre_revisor coincida con codigo_sup_aux
      final data = await supabase
          .from('inconsistencias')
          .select('id, direccion, instalacion, nombre_revisor, foto, fecha_revision, causa_observacion, lectura_real, firma_revisor, pdf')
          .eq('nombre_revisor', _codigoSupAux)
          .order('instalacion', ascending: true);

      if (mounted) {
        setState(() {
          _inconsistencias = List<Map<String, dynamic>>.from(data);
          _aplicarFiltro();
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _errorMessage = 'Error al cargar inconsistencias: ${e.toString()}';
          _isLoading = false;
        });
      }
    }
  }

  void _aplicarFiltro() {
    setState(() {
      // Primero filtrar por estado
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
            if (pdf != null && pdf.toString().isNotEmpty) {
              return false; // Ya tiene PDF
            }
            
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
            if (pdf != null && pdf.toString().isNotEmpty) {
              return false;
            }
            
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
        default: // 'Todas'
          filtradas = List.from(_inconsistencias);
      }
      
      // Luego aplicar filtro de búsqueda si existe
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

  // Determinar el color del borde según el estado de la revisión
  Color _getBorderColor(Map<String, dynamic> item) {
    final pdf = item['pdf'];
    
    // Verde: Si se generó el PDF (columna pdf existe)
    if (pdf != null && pdf.toString().isNotEmpty) {
      return Colors.green;
    }
    
    // Naranja: Si hay cambios guardados pero no se generó PDF
    final causaObservacion = item['causa_observacion'];
    final lecturaReal = item['lectura_real'];
    final foto = item['foto'];
    final firma = item['firma_revisor'];
    
    bool hasChanges = (causaObservacion != null && causaObservacion.toString().isNotEmpty) ||
                      (lecturaReal != null && lecturaReal.toString().isNotEmpty) ||
                      (foto != null && foto.toString().isNotEmpty) ||
                      (firma != null && firma.toString().isNotEmpty);
    
    if (hasChanges) {
      return Colors.orange;
    }
    
    // Sin color: No hay cambios
    return Colors.transparent;
  }

  Widget _buildFiltroChip(String filtro) {
    final isSelected = _filtroSeleccionado == filtro;
    Color chipColor;
    
    switch (filtro) {
      case 'Completadas':
        chipColor = Colors.green;
        break;
      case 'En Progreso':
        chipColor = Colors.orange;
        break;
      case 'Sin Iniciar':
        chipColor = Colors.grey;
        break;
      default: // 'Todas'
        chipColor = const Color(0xFF1A237E);
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
      side: BorderSide(
        color: chipColor,
        width: 2,
      ),
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'INCONSISTENCIAS',
          style: TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
          ),
        ),
        backgroundColor: const Color(0xFF1A237E),
        iconTheme: const IconThemeData(color: Colors.white),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadInconsistencias,
            tooltip: 'Actualizar',
          ),
        ],
      ),
      body: _isLoading
          ? const Center(
              child: CircularProgressIndicator(
                color: Color(0xFF1A237E),
              ),
            )
          : _errorMessage != null
              ? Center(
                  child: Padding(
                    padding: const EdgeInsets.all(24),
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
                          style: const TextStyle(
                            fontSize: 16,
                            color: Colors.black87,
                          ),
                        ),
                        const SizedBox(height: 24),
                        ElevatedButton.icon(
                          onPressed: _loadInconsistencias,
                          icon: const Icon(Icons.refresh),
                          label: const Text('Reintentar'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF1A237E),
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(
                              horizontal: 24,
                              vertical: 12,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                )
              : _inconsistencias.isEmpty
                  ? Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.check_circle_outline,
                            size: 80,
                            color: Colors.green.shade300,
                          ),
                          const SizedBox(height: 16),
                          const Text(
                            'No hay inconsistencias asignadas',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: Colors.black87,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'Código revisor: $_codigoSupAux',
                            style: TextStyle(
                              fontSize: 14,
                              color: Colors.grey.shade600,
                            ),
                          ),
                        ],
                      ),
                    )
                  : Column(
                      children: [
                        // Header con contador y filtro
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
                              // Fila con contador y revisor
                              Builder(
                                builder: (context) {
                                  // Calcular cuántas inconsistencias tienen PDF generado (columna pdf)
                                  final completedCount = _inconsistencias.where((item) {
                                    final pdf = item['pdf'];
                                    return pdf != null && pdf.toString().isNotEmpty;
                                  }).length;
                              
                                  return Row(
                                    children: [
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
                                          '$completedCount/${_inconsistencias.length}',
                                          style: const TextStyle(
                                            color: Colors.white,
                                            fontWeight: FontWeight.bold,
                                            fontSize: 14,
                                          ),
                                        ),
                                      ),
                                      const SizedBox(width: 12),
                                      Expanded(
                                        child: Text(
                                          'Revisor: $_codigoSupAux',
                                          style: TextStyle(
                                            fontSize: 14,
                                            color: Colors.grey.shade700,
                                          ),
                                        ),
                                      ),
                                    ],
                                  );
                                },
                              ),
                              const SizedBox(height: 12),
                              // Filtro por estado
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
                              // Campo de búsqueda
                              TextField(
                                controller: _searchController,
                                decoration: InputDecoration(
                                  hintText: 'Buscar por instalación o dirección',
                                  prefixIcon: const Icon(
                                    Icons.search,
                                    color: Color(0xFF1A237E),
                                  ),
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
                                    borderSide: const BorderSide(
                                      color: Color(0xFF1A237E),
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
                                    vertical: 12,
                                  ),
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
                        // Lista de inconsistencias
                        Expanded(
                          child: _inconsistenciasFiltradas.isEmpty
                              ? Center(
                                  child: Column(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      Icon(
                                        Icons.filter_list_off,
                                        size: 64,
                                        color: Colors.grey.shade400,
                                      ),
                                      const SizedBox(height: 16),
                                      Text(
                                        'No hay inconsistencias con el filtro "$_filtroSeleccionado"',
                                        textAlign: TextAlign.center,
                                        style: TextStyle(
                                          fontSize: 16,
                                          color: Colors.grey.shade600,
                                        ),
                                      ),
                                    ],
                                  ),
                                )
                              : ListView.builder(
                            padding: const EdgeInsets.all(16),
                            itemCount: _inconsistenciasFiltradas.length,
                            itemBuilder: (context, index) {
                              final item = _inconsistenciasFiltradas[index];
                              final direccion = item['direccion']?.toString() ?? 'Sin dirección';
                              final instalacion = item['instalacion']?.toString() ?? 'Sin instalación';
                              
                              // Obtener el color del borde según el estado
                              final borderColor = _getBorderColor(item);

                              return Container(
                                margin: const EdgeInsets.only(bottom: 12),
                                decoration: BoxDecoration(
                                  borderRadius: BorderRadius.circular(12),
                                  border: borderColor != Colors.transparent ? Border.all(
                                    color: borderColor,
                                    width: 3,
                                  ) : null,
                                ),
                                child: Card(
                                  margin: EdgeInsets.zero,
                                  elevation: 2,
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  child: InkWell(
                                    borderRadius: BorderRadius.circular(12),
                                    onTap: () async {
                                      final result = await Navigator.push(
                                        context,
                                        MaterialPageRoute(
                                          builder: (_) => EditarInconsistenciaScreen(
                                            inconsistenciaId: item['id'],
                                          ),
                                        ),
                                      );
                                    // Si se guardaron cambios, recargar la lista
                                    if (result == true) {
                                      _loadInconsistencias();
                                    }
                                  },
                                  child: Padding(
                                    padding: const EdgeInsets.all(16),
                                    child: Row(
                                      children: [
                                        // Número de registro
                                        Container(
                                          width: 50,
                                          height: 50,
                                          decoration: BoxDecoration(
                                            color: const Color(0xFF1A237E),
                                            borderRadius: BorderRadius.circular(25),
                                          ),
                                          child: Center(
                                            child: Text(
                                              '${index + 1}',
                                              style: const TextStyle(
                                                color: Colors.white,
                                                fontWeight: FontWeight.bold,
                                                fontSize: 18,
                                              ),
                                            ),
                                          ),
                                        ),
                                        const SizedBox(width: 16),
                                        // Información
                                        Expanded(
                                          child: Column(
                                            crossAxisAlignment: CrossAxisAlignment.start,
                                            children: [
                                              Row(
                                                children: [
                                                  const Icon(
                                                    Icons.location_on,
                                                    size: 16,
                                                    color: Color(0xFF1A237E),
                                                  ),
                                                  const SizedBox(width: 4),
                                                  Expanded(
                                                    child: Text(
                                                      direccion,
                                                      style: const TextStyle(
                                                        fontWeight: FontWeight.bold,
                                                        fontSize: 15,
                                                        color: Colors.black87,
                                                      ),
                                                      maxLines: 2,
                                                      overflow: TextOverflow.ellipsis,
                                                    ),
                                                  ),
                                                ],
                                              ),
                                              const SizedBox(height: 8),
                                              Row(
                                                children: [
                                                  const Icon(
                                                    Icons.home,
                                                    size: 16,
                                                    color: Colors.grey,
                                                  ),
                                                  const SizedBox(width: 4),
                                                  Text(
                                                    'Instalación: $instalacion',
                                                    style: TextStyle(
                                                      fontSize: 14,
                                                      color: Colors.grey.shade700,
                                                    ),
                                                  ),
                                                ],
                                              ),
                                            ],
                                          ),
                                        ),
                                        // Icono de flecha
                                        const Icon(
                                          Icons.chevron_right,
                                          color: Color(0xFF1A237E),
                                          size: 28,
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
