import 'package:flutter/material.dart';
import '../config/api_config.dart';

class HistorialView extends StatelessWidget {
  final List<dynamic> pedidos;
  final Future<void> Function() onRefresh;

  const HistorialView({super.key, required this.pedidos, required this.onRefresh});

  @override
  Widget build(BuildContext context) {
    if (pedidos.isEmpty) {
      return const Center(
        child: Text('Aún no hay pipas finalizadas en tu historial.',
            style: TextStyle(color: SapacColors.textMuted)),
      );
    }

    return RefreshIndicator(
      onRefresh: onRefresh,
      child: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: pedidos.length,
        itemBuilder: (context, index) {
          final pipa = pedidos[index];
          final entregado = pipa['estado_entrega'] == 'Entregado';

          return Container(
            margin: const EdgeInsets.only(bottom: 10),
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: SapacColors.surface,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: SapacColors.border),
            ),
            child: ListTile(
              contentPadding: EdgeInsets.zero,
              leading: CircleAvatar(
                backgroundColor: entregado ? const Color(0xFFD1E7DD) : const Color(0xFFF8D7DA),
                child: Icon(
                  entregado ? Icons.check : Icons.close,
                  color: entregado ? SapacColors.success : SapacColors.danger,
                ),
              ),
              title: Text(pipa['solicitante'] ?? '',
                  style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 14)),
              subtitle: Text('${pipa['domicilio_entrega']}\n${pipa['capacidad_litros']} Lts',
                  style: const TextStyle(fontSize: 12, color: SapacColors.textMuted)),
              trailing: Text(
                pipa['estado_entrega'].toString().toUpperCase(),
                style: TextStyle(
                  fontWeight: FontWeight.w800,
                  fontSize: 11,
                  color: entregado ? SapacColors.success : SapacColors.danger,
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}