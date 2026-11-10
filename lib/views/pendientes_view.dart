import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import '../config/api_config.dart';
import 'package:geolocator/geolocator.dart';

class PendientesView extends StatelessWidget {
  final List<dynamic> pedidos;
  final bool cargando;
  final Future<void> Function() onRefresh;
  final Function(int, String, double?, double?) onCambiarEstado; // Recibe ID, estado, lat y lng

  const PendientesView({
    super.key,
    required this.pedidos,
    required this.cargando,
    required this.onRefresh,
    required this.onCambiarEstado,
  });

  Future<void> _llamarTelefono(String telefono) async {
    final uri = Uri.parse('tel:$telefono');
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri);
    }
  }

  // Función para marcar entregado capturando coordenadas reales del celular
  Future<void> _marcarEntregadoConUbicacion(
      int idPedido, 
      Function(int, String, double?, double?) onCambiarEstadoConCoordenadas
  ) async {
    double? lat;
    double? lng;

    try {
      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
      }

      if (permission == LocationPermission.whileInUse || permission == LocationPermission.always) {
        Position position = await Geolocator.getCurrentPosition(
          desiredAccuracy: LocationAccuracy.high,
        );
        lat = position.latitude;
        lng = position.longitude;
      }
    } catch (e) {
      lat = null;
      lng = null;
    }

    onCambiarEstadoConCoordenadas(idPedido, 'Entregado', lat, lng);
  }

  @override
  Widget build(BuildContext context) {
    if (cargando) {
      return const Center(child: CircularProgressIndicator());
    }

    if (pedidos.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.check_circle_outline, size: 64, color: SapacColors.success),
            const SizedBox(height: 12),
            const Text('¡Todo al día!',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800, color: SapacColors.textDark)),
            const Text('No tienes pipas pendientes por entregar.',
                style: TextStyle(color: SapacColors.textMuted)),
            const SizedBox(height: 16),
            OutlinedButton.icon(
              onPressed: onRefresh,
              icon: const Icon(Icons.refresh),
              label: const Text('Volver a consultar'),
            )
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: onRefresh,
      child: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: pedidos.length,
        itemBuilder: (context, index) {
          final pipa = pedidos[index];
          final enCamino = pipa['estado_entrega'] == 'En camino';

          return Container(
            margin: const EdgeInsets.only(bottom: 14),
            decoration: BoxDecoration(
              color: SapacColors.surface,
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: SapacColors.border),
              boxShadow: const [
                BoxShadow(color: Color(0x0F0F172A), blurRadius: 16, offset: Offset(0, 6))
              ],
            ),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(
                          color: SapacColors.surfaceSoft,
                          borderRadius: BorderRadius.circular(6),
                          border: Border.all(color: SapacColors.border),
                        ),
                        child: Text(
                          '#PIP-${pipa['id_pedido'].toString().padLeft(4, '0')}',
                          style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 12),
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(
                          color: enCamino ? const Color(0xFFE0F2FE) : const Color(0xFFFEF3C7),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Text(
                          pipa['estado_entrega'].toString().toUpperCase(),
                          style: TextStyle(
                            fontWeight: FontWeight.w800,
                            fontSize: 11,
                            color: enCamino ? SapacColors.primary : SapacColors.warning,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Text(
                    pipa['solicitante'] ?? 'CIUDADANO',
                    style: const TextStyle(
                        fontSize: 16, fontWeight: FontWeight.w800, color: SapacColors.textDark),
                  ),
                  const SizedBox(height: 6),
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Icon(Icons.location_on, size: 18, color: SapacColors.primary),
                      const SizedBox(width: 6),
                      Expanded(
                        child: Text(
                          pipa['domicilio_entrega'] ?? '',
                          style: const TextStyle(
                              fontWeight: FontWeight.w600, color: SapacColors.textDark),
                        ),
                      ),
                    ],
                  ),
                  if (pipa['observaciones'] != null && pipa['observaciones'].toString().isNotEmpty) ...[
                    const SizedBox(height: 6),
                    Text(
                      'Ref: ${pipa['observaciones']}',
                      style: const TextStyle(fontSize: 12, color: SapacColors.textMuted),
                    ),
                  ],
                  const SizedBox(height: 10),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Row(
                        children: [
                          const Icon(Icons.water_drop, size: 16, color: SapacColors.primary),
                          const SizedBox(width: 4),
                          Text('${pipa['capacidad_litros']} Lts',
                              style: const TextStyle(fontWeight: FontWeight.w700)),
                        ],
                      ),
                      TextButton.icon(
                        onPressed: () => _llamarTelefono(pipa['telefono'].toString()),
                        icon: const Icon(Icons.phone, size: 16, color: SapacColors.success),
                        label: Text(pipa['telefono'] ?? 'Llamar',
                            style: const TextStyle(
                                fontWeight: FontWeight.w700, color: SapacColors.success)),
                      ),
                    ],
                  ),
                  const Divider(color: SapacColors.border),
                  Row(
                    children: [
                      if (!enCamino)
                        Expanded(
                          child: OutlinedButton.icon(
                            onPressed: () => onCambiarEstado(pipa['id_pedido'], 'En camino', null, null),
                            icon: const Icon(Icons.directions_bus, size: 16),
                            label: const Text('En Ruta'),
                          ),
                        ),
                      if (!enCamino) const SizedBox(width: 8),
                      Expanded(
                        child: OutlinedButton.icon(
                          onPressed: () => onCambiarEstado(pipa['id_pedido'], 'Cancelado', null, null),
                          style: OutlinedButton.styleFrom(foregroundColor: SapacColors.danger),
                          icon: const Icon(Icons.cancel_outlined, size: 16),
                          label: const Text('Cancelar'),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: ElevatedButton.icon(
                          onPressed: () => _marcarEntregadoConUbicacion(
                            pipa['id_pedido'], 
                            (id, estado, lat, lng) {
                              onCambiarEstado(id, estado, lat, lng);
                            }
                          ),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: SapacColors.success,
                            foregroundColor: Colors.white,
                          ),
                          icon: const Icon(Icons.check_circle, size: 16),
                          label: const Text('Entregado'),
                        ),
                      ),
                    ],
                  )
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}