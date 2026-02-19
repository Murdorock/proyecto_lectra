import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import '../main.dart';
import '../services/user_session.dart';
import 'reporte_totales_lectura_screen.dart';
import 'cierre_jornada_screen.dart';
import 'control_descargas_screen.dart';
import 'historicos_screen.dart';
import 'rangos_screen.dart';
import 'coordenadas_screen.dart';
import 'refutar_errores_screen.dart';
import 'aproximado_lectura_screen.dart';
import 'llegadas_tarde_screen.dart';
import 'controles_reparto_screen.dart';
import 'rangos_repartida_screen.dart';
import 'inconsistencias_screen.dart';
import 'contingencia_lectura_screen.dart';
import 'registro_formacion_screen.dart';
import 'operacion_lectura_screen.dart';
import 'inconsistencias_offline_screen.dart';
import 'certificaciones_reparto_offline_screen.dart';
import 'entrega_correrias_screen.dart';
import 'directorio_screen.dart';
import 'registro_llegada_screen.dart';
import 'quejas_screen.dart';
import 'consulta_retenidos_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  String _userName = '';
  String _userRole = '';
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadUserData();
  }

  Future<void> _loadUserData() async {
    try {
      // Verificar que la sesión sea válida
      final sessionValid = await UserSession().ensureSessionValid();
      
      if (!sessionValid) {
        // Sesión inválida, redirigir al login
        if (mounted) {
          Navigator.of(context).pushReplacementNamed('/login');
        }
        return;
      }
      
      final user = supabase.auth.currentUser;
      if (user != null) {
        final profileData = await supabase
            .from('perfiles')
            .select('nombre_completo, rol, codigo_sup_aux')
            .eq('email', user.email!)
            .maybeSingle();

        if (profileData != null && mounted) {
          // Actualizar la sesión con los datos más recientes
          UserSession().setUserData(
            codigoSupAux: profileData['codigo_sup_aux'] ?? '',
            nombreCompleto: profileData['nombre_completo'] ?? '',
            email: user.email ?? '',
            rol: profileData['rol'],
          );
          
          setState(() {
            _userName = profileData['nombre_completo'] ?? user.email ?? 'Usuario';
            _userRole = profileData['rol'] ?? '';
            _isLoading = false;
          });
        }
      } else {
        // No hay usuario autenticado, redirigir al login
        if (mounted) {
          UserSession().clear();
          Navigator.of(context).pushReplacementNamed('/login');
        }
      }
    } catch (e) {
      if (mounted) {
        // Error al cargar datos, verificar sesión
        final hasSession = supabase.auth.currentSession != null;
        if (!hasSession) {
          UserSession().clear();
          Navigator.of(context).pushReplacementNamed('/login');
        } else {
          setState(() {
            _userName = supabase.auth.currentUser?.email ?? 'Usuario';
            _userRole = '';
            _isLoading = false;
          });
        }
      }
    }
  }

  List<Widget> _getMenuButtons(BuildContext context) {
    // Botones comunes para todos los roles
    final commonButtons = <Widget>[
      _buildMenuButton(
        context,
        icon: Icons.search,
        label: 'CONSULTA\nRETENIDOS',
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => const ConsultaRetenidosScreen(),
            ),
          );
        },
      ),
    ];

    // Botones para LECTOR (sin REGISTRO FORMACIÓN)
    final lectorButtons = <Widget>[
      _buildMenuButton(
        context,
        icon: Icons.straighten,
        label: 'RANGOS LECTURA',
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => const RangosScreen(),
            ),
          );
        },
      ),
      _buildMenuButton(
        context,
        icon: Icons.location_on,
        label: 'COORDENADAS',
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => const CoordenadasScreen(),
            ),
          );
        },
      ),
      _buildMenuButton(
        context,
        icon: Icons.error_outline,
        label: 'REFUTAR ERRORES',
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => const RefutarErroresScreen(),
            ),
          );
        },
      ),
      _buildMenuButton(
        context,
        icon: Icons.local_shipping,
        label: 'CONTROLES REPARTO',
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => const ControlesRepartoScreen(),
            ),
          );
        },
      ),
      _buildMenuButton(
        context,
        icon: Icons.table_chart,
        label: 'RANGOS REPARTIDA',
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => const RangosRepartidaScreen(),
            ),
          );
        },
      ),
      _buildMenuButton(
        context,
        icon: Icons.offline_bolt,
        label: 'INCONSISTENCIAS OFFLINE',
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => const InconsistenciasOfflineScreen(),
            ),
          );
        },
      ),
      _buildMenuButton(
        context,
        icon: Icons.assignment_turned_in,
        label: 'CERTIFICACIONES REPARTO',
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => const CertificacionesRepartoOfflineScreen(),
            ),
          );
        },
      ),
      _buildMenuButton(
        context,
        icon: Icons.flash_on,
        label: 'CONTINGENCIA',
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => const ContingenciaLecturaScreen(),
            ),
          );
        },
      ),
      _buildMenuButton(
        context,
        icon: Icons.login,
        label: 'REGISTRO\nDE LLEGADA',
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => const RegistroLlegadaScreen(),
            ),
          );
        },
      ),
    ];
    final supervisorButtons = [
      _buildMenuButton(
        context,
        icon: Icons.receipt_long,
        label: 'REPORTE TOTALES LECTURA',
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => const ReporteTotalesLecturaScreen(),
            ),
          );
        },
      ),
      _buildMenuButton(
        context,
        icon: Icons.download,
        label: 'CONTROL DESCARGAS',
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => const ControlDescargasScreen(),
            ),
          );
        },
      ),
      _buildMenuButton(
        context,
        icon: Icons.history,
        label: 'HISTORICOS',
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => const HistoricosScreen(),
            ),
          );
        },
      ),
      _buildMenuButton(
        context,
        icon: Icons.straighten,
        label: 'RANGOS LECTURA',
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => const RangosScreen(),
            ),
          );
        },
      ),
      _buildMenuButton(
        context,
        icon: Icons.calculate,
        label: 'APROXIMADO\nLECTURA',
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => const AproximadoLecturaScreen(),
            ),
          );
        },
      ),
      _buildMenuButton(
        context,
        icon: Icons.location_on,
        label: 'COORDENADAS',
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => const CoordenadasScreen(),
            ),
          );
        },
      ),
      _buildMenuButton(
        context,
        icon: Icons.error_outline,
        label: 'REFUTAR ERRORES',
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => const RefutarErroresScreen(),
            ),
          );
        },
      ),
      _buildMenuButton(
        context,
        icon: Icons.access_time,
        label: 'LLEGADAS TARDE',
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => const LlegadasTardeScreen(),
            ),
          );
        },
      ),
      _buildMenuButton(
        context,
        icon: Icons.work_off,
        label: 'INICIO - CIERRE JORNADA',
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => const CierreJornadaScreen(),
            ),
          );
        },
      ),
      _buildMenuButton(
        context,
        icon: Icons.local_shipping,
        label: 'CONTROLES\nREPARTO',
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => const ControlesRepartoScreen(),
            ),
          );
        },
      ),
      _buildMenuButton(
        context,
        icon: Icons.table_chart,
        label: 'RANGOS\nREPARTIDA',
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => const RangosRepartidaScreen(),
            ),
          );
        },
      ),
      _buildMenuButton(
        context,
        icon: Icons.offline_bolt,
        label: 'INCONSISTENCIAS OFFLINE',
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => const InconsistenciasOfflineScreen(),
            ),
          );
        },
      ),
      _buildMenuButton(
        context,
        icon: Icons.assignment_turned_in,
        label: 'CERTIFICACIONES REPARTO',
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => const CertificacionesRepartoOfflineScreen(),
            ),
          );
        },
      ),
      _buildMenuButton(
        context,
        icon: Icons.flash_on,
        label: 'CONTINGENCIA\nLECTURA',
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => const ContingenciaLecturaScreen(),
            ),
          );
        },
      ),
      _buildMenuButton(
        context,
        icon: Icons.school,
        label: 'REGISTRO\nFORMACIÓN',
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => const RegistroFormacionScreen(),
            ),
          );
        },
      ),
      _buildMenuButton(
        context,
        icon: Icons.contact_phone,
        label: 'DIRECTORIO\nTELEFÓNICO',
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => const DirectorioScreen(),
            ),
          );
        },
      ),
      _buildMenuButton(
        context,
        icon: Icons.report_problem,
        label: 'QUEJAS',
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => const QuejasScreen(),
            ),
          );
        },
      ),
      _buildMenuButton(
        context,
        icon: Icons.login,
        label: 'REGISTRO\nDE LLEGADA',
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => const RegistroLlegadaScreen(),
            ),
          );
        },
      ),
      if (_userRole.toUpperCase() == 'ADMINISTRADOR')
        _buildMenuButton(
          context,
          icon: Icons.assignment,
          label: 'OPERACIÓN LECTURA',
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => const OperacionLecturaScreen(),
              ),
            );
          },
        ),
    ];

    // Retornar botones según el rol
    if (_userRole.toUpperCase() == 'LECTOR') {
      return [...commonButtons, ...lectorButtons];
    } else if (_userRole.toUpperCase() == 'ADMINISTRADOR') {
      // ADMINISTRADOR tiene acceso a todos los botones, incluyendo INCONSISTENCIAS e INCONSISTENCIAS OFFLINE
      return <Widget>[
        ...commonButtons,
        ...supervisorButtons,
        _buildMenuButton(
          context,
          icon: Icons.warning_amber,
          label: 'INCONSISTENCIAS',
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => const InconsistenciasScreen(),
              ),
            );
          },
        ),
        _buildMenuButton(
          context,
          icon: Icons.local_shipping,
          label: 'ENTREGA CORRERIAS',
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => const EntregaCorreriasScreen(),
              ),
            );
          },
        ),
      ];
    } else {
      // Por defecto SUPERVISOR o cualquier otro rol
      return [...commonButtons, ...supervisorButtons];
    }
  }

  @override
  Widget build(BuildContext context) {
    
    return Scaffold(
      appBar: AppBar(
        title: const Text('LECTRA - Menú Principal'),
        backgroundColor: const Color(0xFF1A237E),
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: const Icon(Icons.settings),
            onPressed: () async {
              try {
                // Listar archivos en la carpeta actualizaciones
                final archivos = await supabase.storage
                    .from('cold')
                    .list(path: 'actualizaciones');
                
                if (!mounted) return;
                
                if (archivos.isEmpty) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('No hay actualizaciones disponibles'),
                      backgroundColor: Colors.orange,
                    ),
                  );
                  return;
                }
                
                // Mostrar diálogo con archivos disponibles
                showDialog(
                  context: context,
                  builder: (context) => AlertDialog(
                    title: const Text('Actualizaciones Disponibles'),
                    content: SizedBox(
                      width: double.maxFinite,
                      child: ListView.builder(
                        shrinkWrap: true,
                        itemCount: archivos.length,
                        itemBuilder: (context, index) {
                          final archivo = archivos[index];
                          return ListTile(
                            leading: const Icon(Icons.android, color: Color(0xFF1A237E)),
                            title: Text(archivo.name),
                            subtitle: Text(
                              'Tamaño: ${(archivo.metadata?['size'] ?? 0) ~/ 1024 ~/ 1024} MB',
                            ),
                            onTap: () async {
                              Navigator.pop(context);
                              
                              // Obtener URL del archivo
                              final url = supabase.storage
                                  .from('cold')
                                  .getPublicUrl('actualizaciones/${archivo.name}');
                              
                              final uri = Uri.parse(url);
                              if (await canLaunchUrl(uri)) {
                                await launchUrl(uri, mode: LaunchMode.externalApplication);
                              } else {
                                if (context.mounted) {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    const SnackBar(
                                      content: Text('No se pudo abrir el archivo'),
                                      backgroundColor: Colors.red,
                                    ),
                                  );
                                }
                              }
                            },
                          );
                        },
                      ),
                    ),
                    actions: [
                      TextButton(
                        onPressed: () => Navigator.pop(context),
                        child: const Text('Cancelar'),
                      ),
                    ],
                  ),
                );
                
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
            },
            tooltip: 'Actualizar aplicación',
          ),
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () async {
              final shouldLogout = await showDialog<bool>(
                context: context,
                builder: (context) => AlertDialog(
                  title: const Text('Cerrar sesión'),
                  content: const Text('¿Estás seguro que deseas cerrar sesión?'),
                  actions: [
                    TextButton(
                      onPressed: () => Navigator.pop(context, false),
                      child: const Text('Cancelar'),
                    ),
                    TextButton(
                      onPressed: () => Navigator.pop(context, true),
                      child: const Text('Si'),
                    ),
                  ],
                ),
              );
              
              if (shouldLogout == true && mounted) {
                await supabase.auth.signOut();
                UserSession().clear(); // Limpiar sesión
                if (mounted) {
                  Navigator.of(context).pushReplacementNamed('/login');
                }
              }
            },
            tooltip: 'Cerrar sesión',
          ),
        ],
      ),
      body: Stack(
        children: [
          Column(
            children: [
              // Header con información del usuario
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: const Color(0xFF1A237E).withValues(alpha: 0.05),
                  border: Border(
                    bottom: BorderSide(
                      color: Colors.grey.shade300,
                      width: 1,
                    ),
                  ),
                ),
                child: _isLoading
                    ? const Center(
                        child: SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF1A237E)),
                          ),
                        ),
                      )
                    : Column(
                        children: [
                          Text(
                            'Bienvenido',
                            style: TextStyle(
                              fontSize: 16,
                              color: Colors.grey.shade700,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            _userName,
                            style: const TextStyle(
                              fontSize: 14,
                              color: Color(0xFF1A237E),
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
              ),
              
              // Grid de botones del menú
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: GridView.count(
                    crossAxisCount: 3,
                    mainAxisSpacing: 16,
                    crossAxisSpacing: 16,
                    children: _getMenuButtons(context),
                  ),
                ),
              ),
              
              // Footer con versión
              Container(
                padding: const EdgeInsets.all(16),
                child: Text(
                  'LECTRA v4.1 - Gestión de Reportes',
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey.shade600,
                  ),
                  textAlign: TextAlign.center,
                ),
              ),
            ],
          ),
          
          // Overlay de carga que bloquea toda la vista durante la verificación
          if (_isLoading)
            Container(
              color: Colors.white,
              child: Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Container(
                      padding: const EdgeInsets.all(24),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(16),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.1),
                            blurRadius: 20,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const CircularProgressIndicator(
                            valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF1A237E)),
                            strokeWidth: 3,
                          ),
                          const SizedBox(height: 24),
                          const Text(
                            'Verificando opciones de usuario',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w500,
                              color: Color(0xFF1A237E),
                            ),
                            textAlign: TextAlign.center,
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'Por favor espere...',
                            style: TextStyle(
                              fontSize: 14,
                              color: Colors.grey.shade600,
                            ),
                            textAlign: TextAlign.center,
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildMenuButton(
    BuildContext context, {
    required IconData icon,
    required String label,
    required VoidCallback onTap,
  }) {
    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(12),
      elevation: 2,
      shadowColor: const Color(0xFF1A237E).withValues(alpha: 0.2),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Container(
          decoration: BoxDecoration(
            border: Border.all(
              color: const Color(0xFF1A237E).withValues(alpha: 0.2),
              width: 1.5,
            ),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: const Color(0xFF1A237E).withValues(alpha: 0.1),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  icon,
                  size: 32,
                  color: const Color(0xFF1A237E),
                ),
              ),
              const SizedBox(height: 12),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 8.0),
                child: Text(
                  label,
                  style: const TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF1A237E),
                    height: 1.2,
                  ),
                  textAlign: TextAlign.center,
                  maxLines: 3,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
