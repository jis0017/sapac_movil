import 'package:flutter/material.dart';
import 'config/api_config.dart';
import 'views/login_view.dart';
import 'views/home_shell.dart';

void main() {
  runApp(const SapacPipasApp());
}

class SapacPipasApp extends StatelessWidget {
  const SapacPipasApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'SAPAC Operadores',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        scaffoldBackgroundColor: SapacColors.bg,
        primaryColor: SapacColors.primary,
        colorScheme: ColorScheme.fromSeed(
          seedColor: SapacColors.primary,
          primary: SapacColors.primary,
          surface: SapacColors.surface,
        ),
        fontFamily: 'Segoe UI',
        appBarTheme: const AppBarTheme(
          backgroundColor: SapacColors.surface,
          foregroundColor: SapacColors.textDark,
          elevation: 0,
          centerTitle: false,
        ),
      ),
      // Ruta inicial (Login)
      initialRoute: '/login',
      // Mapa de rutas estilo web.php
      routes: {
        '/login': (context) => const LoginView(),
        '/home': (context) => const HomeShell(),
      },
    );
  }
}