import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'config/supabase_config.dart';
import 'screens/login_screen.dart';
import 'screens/home_screen.dart';
import 'services/user_session.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  await Supabase.initialize(
    url: SupabaseConfig.supabaseUrl,
    anonKey: SupabaseConfig.supabaseAnonKey,
    authOptions: const FlutterAuthClientOptions(
      authFlowType: AuthFlowType.pkce,
      autoRefreshToken: true,
    ),
  );
  
  runApp(const LectraApp());
}

// Getter para acceder fácilmente a Supabase
final supabase = Supabase.instance.client;

class LectraApp extends StatefulWidget {
  const LectraApp({super.key});

  @override
  State<LectraApp> createState() => _LectraAppState();
}

class _LectraAppState extends State<LectraApp> {
  final GlobalKey<NavigatorState> _navigatorKey = GlobalKey<NavigatorState>();
  
  @override
  void initState() {
    super.initState();
    _setupAuthListener();
  }
  
  void _setupAuthListener() {
    // Escuchar cambios en el estado de autenticación
    supabase.auth.onAuthStateChange.listen((data) {
      final event = data.event;
      final session = data.session;
      
      if (event == AuthChangeEvent.signedOut || 
          (event == AuthChangeEvent.tokenRefreshed && session == null)) {
        // Sesión cerrada o expirada
        UserSession().clear();
        _navigatorKey.currentState?.pushNamedAndRemoveUntil(
          '/login',
          (route) => false,
        );
      }
    });
  }
  
  Widget _getInitialScreen() {
    // Verificar si hay una sesión activa
    final session = supabase.auth.currentSession;
    if (session != null) {
      return const HomeScreen();
    }
    return const LoginScreen();
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      navigatorKey: _navigatorKey,
      title: 'LECTRA',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        primaryColor: const Color(0xFF1A237E),
        scaffoldBackgroundColor: Colors.white,
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFF1A237E),
          primary: const Color(0xFF1A237E),
        ),
        useMaterial3: true,
      ),
      home: _getInitialScreen(),
      routes: {
        '/login': (context) => const LoginScreen(),
        '/home': (context) => const HomeScreen(),
      },
    );
  }
}
