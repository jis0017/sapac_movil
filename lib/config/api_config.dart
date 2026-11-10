import 'package:flutter/material.dart';

class ApiConfig {
  // Reemplaza este link cada vez que reinicies Ngrok (sin diagonal al final)
  static const String baseUrl = 'https://cloud-distress-doorpost.ngrok-free.dev/api';

  // Encabezados obligatorios (incluye salto de bloqueo de Ngrok y JSON para Laravel)
  static Map<String, String> headers({String? token}) {
    return {
      'Accept': 'application/json',
      'Content-Type': 'application/json',
      'ngrok-skip-browser-warning': 'true',
      if (token != null) 'Authorization': 'Bearer $token',
    };
  }
}

// Paleta exacta extraída de tu style.css (:root)
class SapacColors {
  static const Color bg = Color(0xFFF5F7FB);          // --admin-bg
  static const Color surface = Color(0xFFFFFFFF);     // --admin-surface
  static const Color surfaceSoft = Color(0xFFF8FAFC); // --admin-surface-soft
  static const Color border = Color(0xFFDBE4EF);      // --admin-border
  static const Color textDark = Color(0xFF1F2937);    // --admin-text
  static const Color textMuted = Color(0xFF6B7280);   // --admin-muted
  static const Color primary = Color(0xFF2563EB);     // --admin-primary
  static const Color primaryDark = Color(0xFF1D4ED8); // --admin-primary-dark
  static const Color success = Color(0xFF0F766E);     // --admin-success
  static const Color warning = Color(0xFFD97706);     // --admin-warning
  static const Color danger = Color(0xFFDC2626);      // --admin-danger
}
