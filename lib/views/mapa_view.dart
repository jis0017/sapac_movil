import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import '../config/api_config.dart';

class MapaView extends StatelessWidget {
  final List<dynamic> pedidosPendientes;

  const MapaView({super.key, required this.pedidosPendientes});

  Future<void> _abrirEnGoogleMaps(String domicilio) async {
    final query = Uri.encodeComponent('$domicilio, Acatic, Jalisco, Mexico');
    // Enlace universal para que abra la navegación GPS nativa o la app de Google Maps
    final url = Uri.parse('https://www.google.com/maps/dir/?api=1&destination=$query&travelmode=driving');
    if (await canLaunchUrl(url)) {
      await launchUrl(url, mode: LaunchMode.externalApplication);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (pedidosPendientes.isEmpty) {
      return const Center(
        child: Text(
          'No hay ubicaciones pendientes en la ruta.',
          style: TextStyle(color: SapacColors.textMuted, fontWeight: FontWeight.w600),
        ),
      );
    }

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        // Tarjeta superior estilo mapa satelital / radar institucional
        Container(
          height: 140,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            gradient: const LinearGradient(
              colors: [Color(0xFF0F172A), Color(0xFF1E3A8F)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            boxShadow: const [
              BoxShadow(color: Color(0x180F172A), blurRadius: 12, offset: Offset(0, 4))
            ],
          ),
          child: Stack(
            children: [
              // Elemento visual decorativo tipo rejilla de mapa
              Positioned.fill(
                child: Opacity(
                  opacity: 0.15,
                  child: Container(
                    decoration: BoxDecoration(
                      image: const DecorationImage(
                        image: NetworkImage('https://images.unsplash.com/photo-1526778548025-fa2f459cd5c1?auto=format&fit=crop&w=600&q=80'),
                        fit: BoxFit.cover,
                      ),
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.all(18),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.2),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: const Icon(Icons.satellite_alt, color: Colors.white, size: 22),
                        ),
                        const SizedBox(width: 10),
                        const Text(
                          'RADAR DE RUTA ACTIVA',
                          style: TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.w800,
                            fontSize: 13,
                            letterSpacing: 0.5,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Text(
                      '${pedidosPendientes.length} destinos pendientes de abastecimiento en Acatic.',
                      style: const TextStyle(color: Color(0xFF93C5FD), fontSize: 13, fontWeight: FontWeight.w600),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),
        const Text(
          'Puntos de Entrega Asignados:',
          style: TextStyle(fontWeight: FontWeight.w800, fontSize: 14, color: SapacColors.textDark),
        ),
        const SizedBox(height: 10),
        // Listado de destinos con botón directo a Google Maps
        ...pedidosPendientes.map((pipa) => Container(
              margin: const EdgeInsets.only(bottom: 12),
              decoration: BoxDecoration(
                color: SapacColors.surface,
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: SapacColors.border),
                boxShadow: const [
                  BoxShadow(color: Color(0x0A0F172A), blurRadius: 10, offset: Offset(0, 4))
                ],
              ),
              child: Padding(
                padding: const EdgeInsets.all(14),
                child: Row(
                  children: [
                    Container(
                      width: 42,
                      height: 42,
                      decoration: BoxDecoration(
                        color: const Color(0xFFEAF2FF),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: const Icon(Icons.pin_drop, color: SapacColors.primary),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            pipa['solicitante'] ?? 'CIUDADANO',
                            style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 14, color: SapacColors.textDark),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            pipa['domicilio_entrega'] ?? '',
                            style: const TextStyle(fontSize: 12, color: SapacColors.textMuted, fontWeight: FontWeight.w600),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'Volumen: ${pipa['capacidad_litros']} Lts',
                            style: const TextStyle(fontSize: 11, color: SapacColors.primary, fontWeight: FontWeight.w700),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 8),
                    ElevatedButton.icon(
                      onPressed: () => _abrirEnGoogleMaps(pipa['domicilio_entrega'] ?? ''),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: SapacColors.primary,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                      ),
                      icon: const Icon(Icons.navigation, size: 16),
                      label: const Text('Ir', style: TextStyle(fontWeight: FontWeight.w700)),
                    ),
                  ],
                ),
              ),
            )),
      ],
    );
  }
}