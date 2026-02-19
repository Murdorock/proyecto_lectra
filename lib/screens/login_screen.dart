import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../main.dart';
import '../services/user_session.dart';
import 'home_screen.dart';
import 'package:url_launcher/url_launcher.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  bool _obscurePassword = true;
  bool _isLoading = false;
  
  // Versión actual de la app
  static const String APP_VERSION = '4.2';
  
  // Variable para almacenar la versión requerida
  String? _requiredVersion;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  @override
  void initState() {
    super.initState();
    _checkVersionOnInit();
  }

  // Verificar la versión cuando se carga la pantalla
  Future<void> _checkVersionOnInit() async {
    await _fetchRequiredVersion();
    if (_requiredVersion != null && !_isVersionValid()) {
      _showVersionUpdateDialog();
    }
  }

  // Obtener la versión requerida desde Supabase
  Future<void> _fetchRequiredVersion() async {
    try {
      final versionData = await supabase
          .from('app_version')
          .select('version_requerida, url_descarga')
          .maybeSingle();

      if (versionData != null) {
        setState(() {
          _requiredVersion = versionData['version_requerida'];
        });
      }
    } catch (e) {
      print('Error al obtener versión: $e');
      // Si hay error, continuamos normalmente
    }
  }

  // Validar si la versión de la app es correcta
  bool _isVersionValid() {
    if (_requiredVersion == null) return true;
    
    try {
      List<int> currentParts = APP_VERSION.split('.').map(int.parse).toList();
      List<int> requiredParts = _requiredVersion!.split('.').map(int.parse).toList();
      
      // Comparar versiones
      for (int i = 0; i < currentParts.length && i < requiredParts.length; i++) {
        if (currentParts[i] < requiredParts[i]) {
          return false;
        } else if (currentParts[i] > requiredParts[i]) {
          return true;
        }
      }
      return true;
    } catch (e) {
      return true;
    }
  }

  // Mostrar diálogo de actualización obligatoria
  void _showVersionUpdateDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        title: const Text(
          'Actualización Requerida',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Tu versión de la app está desactualizada.',
              style: TextStyle(fontSize: 14),
            ),
            const SizedBox(height: 12),
            RichText(
              text: TextSpan(
                style: const TextStyle(color: Colors.black87, fontSize: 14),
                children: [
                  const TextSpan(text: 'Versión actual: '),
                  TextSpan(
                    text: APP_VERSION,
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                  const TextSpan(text: '\nVersión requerida: '),
                  TextSpan(
                    text: _requiredVersion ?? 'desconocida',
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            const Text(
              'Por favor, actualiza la app para continuar.',
              style: TextStyle(fontSize: 13, color: Colors.red),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => exit(0),
            child: const Text('Salir'),
          ),
          ElevatedButton(
            onPressed: () => _openAppStore(),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF1A237E),
            ),
            child: const Text('Actualizar', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  // Abrir Supabase para descargar la actualización
  Future<void> _openAppStore() async {
    try {
      // Reemplaza 'com.tu.app.id' con el ID real de tu app
      const playStoreUrl = 'https://txeuzsypnwesscganktp.supabase.co/storage/v1/object/public/cold/actualizaciones/lectra_nueva_version.apk';
      
      if (await canLaunchUrl(Uri.parse(playStoreUrl))) {
        await launchUrl(
          Uri.parse(playStoreUrl),
          mode: LaunchMode.externalApplication,
        );
      }
    } catch (e) {
      _showSnackBar('No se pudo abrir Supabase', isError: true);
    }
  }

  Future<void> _handleLogin() async {
    // Verificar versión antes de intentar login
    if (_requiredVersion != null && !_isVersionValid()) {
      _showVersionUpdateDialog();
      return;
    }

    final email = _emailController.text.trim();
    final password = _passwordController.text.trim();
    
    // Validación de campos vacíos
    if (email.isEmpty || password.isEmpty) {
      _showSnackBar('Por favor, completa todos los campos', isError: true);
      return;
    }

    // Validar formato de email
    if (!_isValidEmail(email)) {
      _showSnackBar('Por favor, ingresa un correo electrónico válido', isError: true);
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      // Intentar iniciar sesión con Supabase
      final response = await supabase.auth.signInWithPassword(
        email: email,
        password: password,
      );

      if (response.user != null) {
        // Verificar si el usuario existe en la tabla perfiles
        final profileData = await supabase
            .from('perfiles')
            .select('email, nombre_completo, codigo_sup_aux')
            .eq('email', email)
            .maybeSingle();

        if (profileData != null) {
          // Obtener también el rol del usuario
          final perfilCompleto = await supabase
              .from('perfiles')
              .select('email, nombre_completo, codigo_sup_aux, rol')
              .eq('email', email)
              .maybeSingle();
          
          // Guardar datos del usuario en la sesión
          UserSession().setUserData(
            codigoSupAux: perfilCompleto?['codigo_sup_aux'] ?? '',
            nombreCompleto: perfilCompleto?['nombre_completo'] ?? '',
            email: perfilCompleto?['email'] ?? '',
            rol: perfilCompleto?['rol'],
          );
          
          // Login exitoso
          if (mounted) {
            _showSnackBar('¡Bienvenido!', isError: false);
            // Navegar a la pantalla principal
            Navigator.pushReplacement(
              context,
              MaterialPageRoute(builder: (_) => const HomeScreen()),
            );
          }
        } else {
          _showSnackBar('Usuario no encontrado en perfiles', isError: true);
          await supabase.auth.signOut();
        }
      }
    } on AuthException catch (e) {
      // Errores específicos de autenticación
      String errorMessage = 'Error al iniciar sesión';
      
      if (e.message.contains('Invalid login credentials')) {
        errorMessage = 'Credenciales incorrectas';
      } else if (e.message.contains('Email not confirmed')) {
        errorMessage = 'Por favor, confirma tu correo electrónico';
      } else {
        errorMessage = e.message;
      }
      
      _showSnackBar(errorMessage, isError: true);
    } catch (e) {
      // Otros errores
      _showSnackBar('Error de conexión. Verifica tu internet', isError: true);
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  bool _isValidEmail(String email) {
    return RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$').hasMatch(email);
  }

  void _showSnackBar(String message, {required bool isError}) {
    if (!mounted) return;
    
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: isError ? Colors.red : const Color(0xFF1A237E),
        duration: const Duration(seconds: 3),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    // Detectar si el teclado está visible
    final bool isKeyboardVisible = MediaQuery.of(context).viewInsets.bottom > 0;
    
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Stack(
          children: [
            // Texto "creado por diego m." en la esquina inferior derecha (oculto cuando el teclado está activo)
            if (!isKeyboardVisible)
              Positioned(
                bottom: 16,
                right: 16,
                child: Text(
                  'desarrollado por diego m.',
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey.shade600,
                    fontStyle: FontStyle.italic,
                  ),
                ),
              ),
            // Contenido principal
            Center(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: 32.0),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                // Logo circular con icono de edificios
                Container(
                  width: 120,
                  height: 120,
                  decoration: BoxDecoration(
                    color: const Color(0xFF1A237E), // Azul oscuro
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: const Color(0xFF1A237E).withValues(alpha: 0.3),
                        blurRadius: 20,
                        offset: const Offset(0, 10),
                      ),
                    ],
                  ),
                  child: const Icon(
                    Icons.apartment,
                    size: 60,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: 40),
                
                // Título de bienvenida
                const Text(
                  '¡Bienvenido!',
                  style: TextStyle(
                    fontSize: 32,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF1A237E),
                  ),
                ),
                const SizedBox(height: 8),
                
                // Subtítulo
                const Text(
                  'Gestión de Reportes',
                  style: TextStyle(
                    fontSize: 18,
                    color: Colors.grey,
                    fontWeight: FontWeight.w400,
                  ),
                ),
                const SizedBox(height: 48),
                
                // Campo de correo electrónico
                Container(
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: Colors.grey.shade300,
                      width: 1.5,
                    ),
                  ),
                  child: TextField(
                    controller: _emailController,
                    keyboardType: TextInputType.emailAddress,
                    decoration: InputDecoration(
                      hintText: 'Correo electrónico',
                      hintStyle: TextStyle(color: Colors.grey.shade400),
                      prefixIcon: Icon(
                        Icons.email_outlined,
                        color: Colors.grey.shade600,
                      ),
                      border: InputBorder.none,
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 16,
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 20),
                
                // Campo de contraseña
                Container(
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: Colors.grey.shade300,
                      width: 1.5,
                    ),
                  ),
                  child: TextField(
                    controller: _passwordController,
                    obscureText: _obscurePassword,
                    keyboardType: TextInputType.text,
                    decoration: InputDecoration(
                      hintText: 'Contraseña',
                      hintStyle: TextStyle(color: Colors.grey.shade400),
                      prefixIcon: Icon(
                        Icons.lock_outline,
                        color: Colors.grey.shade600,
                      ),
                      suffixIcon: IconButton(
                        icon: Icon(
                          _obscurePassword
                              ? Icons.visibility_off_outlined
                              : Icons.visibility_outlined,
                          color: Colors.grey.shade600,
                        ),
                        onPressed: () {
                          setState(() {
                            _obscurePassword = !_obscurePassword;
                          });
                        },
                      ),
                      border: InputBorder.none,
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 16,
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 32),
                
                // Botón de iniciar sesión
                SizedBox(
                  width: double.infinity,
                  height: 56,
                  child: ElevatedButton(
                    onPressed: _isLoading ? null : _handleLogin,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF1A237E),
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      elevation: 2,
                      disabledBackgroundColor: const Color(0xFF1A237E).withValues(alpha: 0.6),
                    ),
                    child: _isLoading
                        ? const SizedBox(
                            width: 24,
                            height: 24,
                            child: CircularProgressIndicator(
                              strokeWidth: 2.5,
                              valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                            ),
                          )
                        : const Text(
                            'Iniciar Sesión',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              letterSpacing: 0.5,
                            ),
                          ),
                  ),
                ),
                const SizedBox(height: 40),
                
                // Versión
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 24,
                    vertical: 12,
                  ),
                  decoration: BoxDecoration(
                    border: Border.all(
                      color: Colors.grey.shade300,
                      width: 1.5,
                    ),
                    borderRadius: BorderRadius.circular(30),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        Icons.info_outline,
                        size: 18,
                        color: Colors.grey.shade600,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        'Versión: 4.2',
                        style: TextStyle(
                          color: Colors.grey.shade600,
                          fontSize: 14,
                        ),
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
      ),
    );
  }
}
