import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import '../config/api_config.dart';

class LoginView extends StatefulWidget {
  const LoginView({super.key});

  @override
  State<LoginView> createState() => _LoginViewState();
}

class _LoginViewState extends State<LoginView> {
  final _usuarioCtrl = TextEditingController();
  final _passCtrl = TextEditingController();
  bool _cargando = false;
  String? _errorMsg;

  Future<void> _iniciarSesion() async {
    if (_usuarioCtrl.text.isEmpty || _passCtrl.text.isEmpty) {
      setState(() => _errorMsg = 'Ingresa tu usuario y contraseña.');
      return;
    }

    setState(() {
      _cargando = true;
      _errorMsg = null;
    });

    try {
      final res = await http.post(
        Uri.parse('${ApiConfig.baseUrl}/mobile/login'),
        headers: ApiConfig.headers(),
        body: json.encode({
          'usuario_trabajador': _usuarioCtrl.text.trim(),
          'password': _passCtrl.text.trim(),
        }),
      );

      final data = json.decode(res.body);

      if (res.statusCode == 200 && data['success'] == true) {
        if (!mounted) return;
        Navigator.pushReplacementNamed(
          context,
          '/home',
          arguments: {
            'token': data['token'],
            'nombre': data['trabajador']['nombre'],
            'rol': data['trabajador']['rol'],
          },
        );
      } else {
        setState(() => _errorMsg = data['message'] ?? 'Error al iniciar sesión.');
      }
    } catch (e) {
      setState(() => _errorMsg = 'No se pudo conectar con el servidor Ngrok.');
    } finally {
      if (mounted) setState(() => _cargando = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [Color(0xFFF8FBFF), Color(0xFFEAF2FF), Color(0xFFEEF8F6)],
          ),
        ),
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: Container(
              constraints: const BoxConstraints(maxWidth: 420),
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: SapacColors.surface,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: SapacColors.border),
                boxShadow: const [
                  BoxShadow(
                    color: Color(0x180F172A),
                    blurRadius: 30,
                    offset: Offset(0, 12),
                  )
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        width: 44,
                        height: 44,
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(8),
                          gradient: const LinearGradient(
                            colors: [SapacColors.primary, SapacColors.success],
                          ),
                        ),
                        child: const Icon(Icons.water_drop, color: Colors.white),
                      ),
                      const SizedBox(width: 12),
                      const Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('SAPAC ACATIC',
                              style: TextStyle(
                                  fontWeight: FontWeight.w800,
                                  fontSize: 18,
                                  color: SapacColors.textDark)),
                          Text('Módulo Operativo de Pipas',
                              style: TextStyle(
                                  fontSize: 12, color: SapacColors.textMuted)),
                        ],
                      )
                    ],
                  ),
                  const SizedBox(height: 24),
                  if (_errorMsg != null)
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(12),
                      margin: const EdgeInsets.only(bottom: 16),
                      decoration: BoxDecoration(
                        color: const Color(0xFFFEE2E2),
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: const Color(0xFFFECACA)),
                      ),
                      child: Text(_errorMsg!,
                          style: const TextStyle(
                              color: SapacColors.danger,
                              fontWeight: FontWeight.w600,
                              fontSize: 13)),
                    ),
                  const Text('Usuario de Operador',
                      style: TextStyle(
                          fontWeight: FontWeight.w600,
                          fontSize: 13,
                          color: SapacColors.textDark)),
                  const SizedBox(height: 6),
                  TextField(
                    controller: _usuarioCtrl,
                    decoration: InputDecoration(
                      hintText: 'Ej. pipas_acatic',
                      prefixIcon: const Icon(Icons.person_outline),
                      filled: true,
                      fillColor: SapacColors.surfaceSoft,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                        borderSide: const BorderSide(color: SapacColors.border),
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  const Text('Contraseña',
                      style: TextStyle(
                          fontWeight: FontWeight.w600,
                          fontSize: 13,
                          color: SapacColors.textDark)),
                  const SizedBox(height: 6),
                  TextField(
                    controller: _passCtrl,
                    obscureText: true,
                    decoration: InputDecoration(
                      hintText: '••••••••',
                      prefixIcon: const Icon(Icons.lock_outline),
                      filled: true,
                      fillColor: SapacColors.surfaceSoft,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                        borderSide: const BorderSide(color: SapacColors.border),
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),
                  SizedBox(
                    width: double.infinity,
                    height: 48,
                    child: ElevatedButton(
                      onPressed: _cargando ? null : _iniciarSesion,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: SapacColors.primary,
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8)),
                      ),
                      child: _cargando
                          ? const SizedBox(
                              width: 22,
                              height: 22,
                              child: CircularProgressIndicator(
                                  color: Colors.white, strokeWidth: 2.5))
                          : const Text('INGRESAR A RUTA',
                              style: TextStyle(
                                  fontWeight: FontWeight.w700, fontSize: 15)),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}