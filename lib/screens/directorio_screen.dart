import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:share_plus/share_plus.dart';
import '../main.dart';

class DirectorioScreen extends StatefulWidget {
  const DirectorioScreen({super.key});

  @override
  State<DirectorioScreen> createState() => _DirectorioScreenState();
}

class _DirectorioScreenState extends State<DirectorioScreen> {
  List<Map<String, dynamic>> _allPersonal = [];
  List<Map<String, dynamic>> _filteredPersonal = [];
  bool _isLoading = true;
  final TextEditingController _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _loadPersonal();
    _searchController.addListener(_filterPersonal);
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadPersonal() async {
    try {
      final data = await supabase
          .from('personal')
          .select('id_codigo, nombre_completo, celular_corporativo, celular_personal')
          .order('id_codigo', ascending: true);

      if (mounted) {
        // Filtrar contactos VACANTE sin números de teléfono
        final filteredData = (data as List).where((personal) {
          final nombre = (personal['nombre_completo'] ?? '').toString().toUpperCase().trim();
          final celularCorp = (personal['celular_corporativo'] ?? '').toString().trim();
          final celularPers = (personal['celular_personal'] ?? '').toString().trim();

          // Si es VACANTE y no tiene teléfonos, excluir
          if (nombre == 'VACANTE' && celularCorp.isEmpty && celularPers.isEmpty) {
            return false;
          }
          return true;
        }).toList();

        // Ordenar también en la aplicación para asegurar el orden correcto
        final sortedData = List<Map<String, dynamic>>.from(filteredData);
        sortedData.sort((a, b) {
          final codA = (a['id_codigo'] ?? '').toString().toUpperCase();
          final codB = (b['id_codigo'] ?? '').toString().toUpperCase();
          return codA.compareTo(codB);
        });

        setState(() {
          _allPersonal = sortedData;
          _filteredPersonal = sortedData;
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
            content: Text('Error al cargar el directorio: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  void _filterPersonal() {
    final query = _searchController.text.toLowerCase();
    
    setState(() {
      if (query.isEmpty) {
        _filteredPersonal = List<Map<String, dynamic>>.from(_allPersonal);
      } else {
        _filteredPersonal = _allPersonal.where((personal) {
          final codigo = personal['id_codigo']?.toString().toLowerCase() ?? '';
          final nombre = personal['nombre_completo']?.toString().toLowerCase() ?? '';
          final celularCorp = personal['celular_corporativo']?.toString().toLowerCase() ?? '';
          final celularPers = personal['celular_personal']?.toString().toLowerCase() ?? '';
          
          return codigo.contains(query) ||
              nombre.contains(query) ||
              celularCorp.contains(query) ||
              celularPers.contains(query);
        }).toList();
      }
    });
  }

  Future<void> _makeCall(String phoneNumber) async {
    if (phoneNumber.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Este número no está disponible'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    final uri = Uri(scheme: 'tel', path: phoneNumber);
    try {
      if (await canLaunchUrl(uri)) {
        await launchUrl(uri);
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('No se pudo realizar la llamada'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _sendSMS(String phoneNumber) async {
    if (phoneNumber.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Este número no está disponible'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    final uri = Uri(scheme: 'sms', path: phoneNumber);
    try {
      if (await canLaunchUrl(uri)) {
        await launchUrl(uri);
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('No se pudo enviar el SMS'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _shareContact(Map<String, dynamic> personal) async {
    final codigo = personal['id_codigo']?.toString() ?? '';
    final nombre = personal['nombre_completo']?.toString() ?? '';
    final celularCorp = personal['celular_corporativo']?.toString() ?? '';
    final celularPers = personal['celular_personal']?.toString() ?? '';

    final shareText = StringBuffer();
    shareText.writeln('📇 CONTACTO DIRECTORIO');
    shareText.writeln('─' * 30);
    shareText.writeln('Código: $codigo');
    shareText.writeln('Nombre: $nombre');
    
    if (celularCorp.isNotEmpty) {
      shareText.writeln('📞 Corporativo: $celularCorp');
    }
    
    if (celularPers.isNotEmpty) {
      shareText.writeln('📱 Personal: $celularPers');
    }

    try {
      await Share.share(
        shareText.toString(),
        subject: 'Contacto: $nombre',
      );
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error al compartir: ${e.toString()}'),
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
        title: const Text('DIRECTORIO TELEFÓNICO'),
        backgroundColor: const Color(0xFF1A237E),
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      body: Column(
        children: [
          // Buscador
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: const Color(0xFF1A237E).withValues(alpha: 0.05),
              border: Border(
                bottom: BorderSide(
                  color: Colors.grey.shade300,
                  width: 1,
                ),
              ),
            ),
            child: TextField(
              controller: _searchController,
              decoration: InputDecoration(
                hintText: 'Buscar por código, nombre o teléfono...',
                prefixIcon: const Icon(Icons.search, color: Color(0xFF1A237E)),
                suffixIcon: _searchController.text.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.clear),
                        onPressed: () {
                          _searchController.clear();
                        },
                      )
                    : null,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide: const BorderSide(color: Color(0xFF1A237E)),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide: BorderSide(
                    color: Colors.grey.shade300,
                  ),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide: const BorderSide(
                    color: Color(0xFF1A237E),
                    width: 2,
                  ),
                ),
                contentPadding: const EdgeInsets.symmetric(vertical: 12),
              ),
              onChanged: (_) {
                setState(() {});
              },
            ),
          ),
          
          // Contador de resultados
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Row(
              children: [
                Text(
                  'Resultados: ${_filteredPersonal.length} de ${_allPersonal.length}',
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey.shade600,
                  ),
                ),
              ],
            ),
          ),
          
          // Lista de personal
          Expanded(
            child: _isLoading
                ? const Center(
                    child: CircularProgressIndicator(
                      valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF1A237E)),
                    ),
                  )
                : _filteredPersonal.isEmpty
                    ? Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.person_off,
                              size: 64,
                              color: Colors.grey.shade400,
                            ),
                            const SizedBox(height: 16),
                            Text(
                              'No se encontraron resultados',
                              style: TextStyle(
                                fontSize: 16,
                                color: Colors.grey.shade600,
                              ),
                            ),
                          ],
                        ),
                      )
                    : ListView.builder(
                        itemCount: _filteredPersonal.length,
                        itemBuilder: (context, index) {
                          final personal = _filteredPersonal[index];
                          final celularCorp =
                              personal['celular_corporativo']?.toString() ?? '';
                          final celularPers =
                              personal['celular_personal']?.toString() ?? '';

                          return Card(
                            margin: const EdgeInsets.symmetric(
                              horizontal: 12,
                              vertical: 6,
                            ),
                            elevation: 1,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8),
                              side: BorderSide(
                                color: Colors.grey.shade200,
                                width: 1,
                              ),
                            ),
                            child: Padding(
                              padding: const EdgeInsets.all(12),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  // Código y Nombre
                                  Row(
                                    children: [
                                      Container(
                                        padding: const EdgeInsets.symmetric(
                                          horizontal: 8,
                                          vertical: 4,
                                        ),
                                        decoration: BoxDecoration(
                                          color: const Color(0xFF1A237E)
                                              .withValues(alpha: 0.1),
                                          borderRadius:
                                              BorderRadius.circular(4),
                                        ),
                                        child: Text(
                                          personal['id_codigo']?.toString() ?? '',
                                          style: const TextStyle(
                                            fontSize: 11,
                                            fontWeight: FontWeight.bold,
                                            color: Color(0xFF1A237E),
                                          ),
                                        ),
                                      ),
                                      const SizedBox(width: 12),
                                      Expanded(
                                        child: Text(
                                          personal['nombre_completo']
                                                  ?.toString() ??
                                              'Sin nombre',
                                          style: const TextStyle(
                                            fontSize: 14,
                                            fontWeight: FontWeight.bold,
                                            color: Color(0xFF1A237E),
                                          ),
                                          maxLines: 1,
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                      ),
                                      IconButton(
                                        padding: const EdgeInsets.all(4),
                                        constraints: const BoxConstraints(
                                          minWidth: 36,
                                          minHeight: 36,
                                        ),
                                        icon: const Icon(
                                          Icons.share,
                                          size: 20,
                                        ),
                                        color: const Color(0xFF1A237E),
                                        onPressed: () {
                                          _shareContact(personal);
                                        },
                                        tooltip: 'Compartir contacto',
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 12),
                                  
                                  // Teléfono Corporativo
                                  if (celularCorp.isNotEmpty)
                                    Padding(
                                      padding: const EdgeInsets.only(bottom: 8),
                                      child: Row(
                                        children: [
                                          Icon(
                                            Icons.phone,
                                            size: 18,
                                            color: Colors.green.shade600,
                                          ),
                                          const SizedBox(width: 8),
                                          Expanded(
                                            child: Column(
                                              crossAxisAlignment:
                                                  CrossAxisAlignment.start,
                                              children: [
                                                Container(
                                                  padding: const EdgeInsets
                                                      .symmetric(
                                                    horizontal: 6,
                                                    vertical: 2,
                                                  ),
                                                  decoration: BoxDecoration(
                                                    color: Colors.green.shade100,
                                                    borderRadius:
                                                        BorderRadius.circular(
                                                          4,
                                                        ),
                                                  ),
                                                  child: Text(
                                                    'CORPORATIVO',
                                                    style: TextStyle(
                                                      fontSize: 10,
                                                      fontWeight:
                                                          FontWeight.bold,
                                                      color:
                                                          Colors.green.shade700,
                                                    ),
                                                  ),
                                                ),
                                                const SizedBox(height: 4),
                                                Text(
                                                  celularCorp,
                                                  style: const TextStyle(
                                                    fontSize: 13,
                                                  ),
                                                ),
                                              ],
                                            ),
                                          ),
                                          Row(
                                            mainAxisSize: MainAxisSize.min,
                                            children: [
                                              IconButton(
                                                padding:
                                                    const EdgeInsets.all(4),
                                                constraints:
                                                    const BoxConstraints(
                                                  minWidth: 36,
                                                  minHeight: 36,
                                                ),
                                                icon: const Icon(
                                                  Icons.call,
                                                  size: 18,
                                                ),
                                                color: Colors.green.shade600,
                                                onPressed: () {
                                                  _makeCall(celularCorp);
                                                },
                                                tooltip: 'Llamar',
                                              ),
                                              IconButton(
                                                padding:
                                                    const EdgeInsets.all(4),
                                                constraints:
                                                    const BoxConstraints(
                                                  minWidth: 36,
                                                  minHeight: 36,
                                                ),
                                                icon: const Icon(
                                                  Icons.sms,
                                                  size: 18,
                                                ),
                                                color: Colors.blue.shade600,
                                                onPressed: () {
                                                  _sendSMS(celularCorp);
                                                },
                                                tooltip: 'SMS',
                                              ),
                                            ],
                                          ),
                                        ],
                                      ),
                                    ),
                                  
                                  // Teléfono Personal
                                  if (celularPers.isNotEmpty)
                                    Row(
                                      children: [
                                        Icon(
                                          Icons.smartphone,
                                          size: 18,
                                          color: Colors.orange.shade600,
                                        ),
                                        const SizedBox(width: 8),
                                        Expanded(
                                          child: Column(
                                            crossAxisAlignment:
                                                CrossAxisAlignment.start,
                                            children: [
                                              Container(
                                                padding: const EdgeInsets
                                                    .symmetric(
                                                  horizontal: 6,
                                                  vertical: 2,
                                                ),
                                                decoration: BoxDecoration(
                                                  color:
                                                      Colors.orange.shade100,
                                                  borderRadius:
                                                      BorderRadius.circular(
                                                        4,
                                                      ),
                                                ),
                                                child: Text(
                                                  'PERSONAL',
                                                  style: TextStyle(
                                                    fontSize: 10,
                                                    fontWeight:
                                                        FontWeight.bold,
                                                    color: Colors.orange
                                                        .shade700,
                                                  ),
                                                ),
                                              ),
                                              const SizedBox(height: 4),
                                              Text(
                                                celularPers,
                                                style: const TextStyle(
                                                  fontSize: 13,
                                                ),
                                              ),
                                            ],
                                          ),
                                        ),
                                        Row(
                                          mainAxisSize: MainAxisSize.min,
                                          children: [
                                            IconButton(
                                              padding: const EdgeInsets.all(4),
                                              constraints: const BoxConstraints(
                                                minWidth: 36,
                                                minHeight: 36,
                                              ),
                                              icon: const Icon(
                                                Icons.call,
                                                size: 18,
                                              ),
                                              color: Colors.orange.shade600,
                                              onPressed: () {
                                                _makeCall(celularPers);
                                              },
                                              tooltip: 'Llamar',
                                            ),
                                            IconButton(
                                              padding: const EdgeInsets.all(4),
                                              constraints: const BoxConstraints(
                                                minWidth: 36,
                                                minHeight: 36,
                                              ),
                                              icon: const Icon(
                                                Icons.sms,
                                                size: 18,
                                              ),
                                              color: Colors.blue.shade600,
                                              onPressed: () {
                                                _sendSMS(celularPers);
                                              },
                                              tooltip: 'SMS',
                                            ),
                                          ],
                                        ),
                                      ],
                                    ),
                                  
                                  // Mensaje si no hay teléfonos
                                  if (celularCorp.isEmpty && celularPers.isEmpty)
                                    Text(
                                      'Sin números de teléfono',
                                      style: TextStyle(
                                        fontSize: 12,
                                        color: Colors.grey.shade500,
                                        fontStyle: FontStyle.italic,
                                      ),
                                    ),
                                ],
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
