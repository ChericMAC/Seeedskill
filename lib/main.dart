import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'theme/app_theme.dart';
import 'screens/auth_screen.dart';
import 'screens/main_shell.dart';
import 'services/supabase_service.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await Supabase.initialize(
    url: 'URL de Supabase',  // ← tu URL
    anonKey: 'Llave de supabase',                     // ← tu anon key
  );

  // Intentar restaurar sesión guardada localmente
  final hasSession = await AuthService.restoreSession();

  runApp(SparkApp(startLoggedIn: hasSession));
}

class SparkApp extends StatelessWidget {
  final bool startLoggedIn;
  const SparkApp({super.key, required this.startLoggedIn});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'SeeedSkill',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.dark,
      home: startLoggedIn ? const MainShell() : const AuthScreen(),
    );
  }
}