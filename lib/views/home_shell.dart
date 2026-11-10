import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import '../config/api_config.dart';
import 'pendientes_view.dart';
import 'historial_view.dart';
import 'mapa_view.dart';
import '../services/offline_sync_service.dart';

class HomeShell extends StatefulWidget {
  const HomeShell({super.key});

  @override
  State<HomeShell> createState() => _HomeShellState();
}

class _HomeShellState extends State<HomeShell> {
  int _tabIndex = 0;
  bool _cargando = true;
  List<dynamic> _todosLosPedidos = [];
  late String _token;
  late String _nombreOperador;
  bool _inicializado = false;

  get _cambiarEstadoPedidoConOffline => null;

  get _cambiarEstadoPedidoConCoordenadas => null;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!_inicializado) {
      final args = ModalRoute.of(context)!.settings.arguments as Map<String, dynamic>;
      _token = args['token'];
      _nombreOperador = args['nombre'];
      _inicializado = true;
      _cargarPedidos();
    }
  }

 Future<void> _cargarPedidos() async {
    setState(() => _cargando = true);
    try {
      // 1. Primero intentamos sincronizar lo que se quedó guardado offline en SQLite
      await OfflineSyncService.sincronizarConServidor(_token);

      // 2. Luego descargamos la lista actualizada desde Laravel
      final res = await http.get(
        Uri.parse('${ApiConfig.baseUrl}/mobile/pedidos'),
        headers: ApiConfig.headers(token: _token),
      );
      if (res.statusCode == 200) {
        final data = json.decode(res.body);
        setState(() => _todosLosPedidos = data['pedidos'] ?? []);
      }
    } catch (_) {
      // Si entra aquí sin internet, al menos la app no se traba y muestra lo último que tenía
    } finally {
      if (mounted) setState(() => _cargando = false);
    }
  }

  Future<void> _cambiarEstadoPedido(int idPedido, String nuevoEstado) async {
    final res = await http.put(
      Uri.parse('${ApiConfig.baseUrl}/mobile/pedidos/$idPedido/estado'),
      headers: ApiConfig.headers(token: _token),
      body: json.encode({'estado_entrega': nuevoEstado}),
    );

    if (res.statusCode == 200) {
      await _cargarPedidos();
      if (!mounted) return;
      _mostrarModalExito('El pedido #PIP-${idPedido.toString().padLeft(4, '0')} pasó a: $nuevoEstado');
    }
  }

  Future<void> _cambiarEstadoPedidoConGps(int idPedido, String nuevoEstado, double? lat, double? lng) async {
  final bodyData = {
    'estado_entrega': nuevoEstado,
    if (lat != null) 'latitud': lat,
    if (lng != null) 'longitud': lng,
  };

  final res = await http.put(
    Uri.parse('${ApiConfig.baseUrl}/mobile/pedidos/$idPedido/estado'),
    headers: ApiConfig.headers(token: _token),
    body: json.encode(bodyData),
  );

  if (res.statusCode == 200) {
    await _cargarPedidos();
    if (!mounted) return;
    _mostrarModalExito('¡Entrega registrada y ubicación guardada con éxito!');
  }
}

  // Modal idéntico al de "¡Operación Exitosa!" de tu sistema web
  void _mostrarModalExito(String mensaje) {
    showDialog(
      context: context,
      builder: (_) => Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 72,
                height: 72,
                decoration: BoxDecoration(
                  color: const Color(0xFFE6F4EA),
                  shape: BoxShape.circle,
                  border: Border.all(color: const Color(0xFFCEEAD6), width: 2),
                ),
                child: const Icon(Icons.check, size: 42, color: Color(0xFF1E8E3E)),
              ),
              const SizedBox(height: 16),
              const Text('¡Operación Exitosa!',
                  style: TextStyle(fontSize: 20, fontWeight: FontWeight.w800, color: SapacColors.textDark)),
              const SizedBox(height: 8),
              Text(mensaje,
                  textAlign: TextAlign.center,
                  style: const TextStyle(color: SapacColors.textMuted, fontSize: 14)),
              const SizedBox(height: 20),
              ElevatedButton(
                onPressed: () => Navigator.pop(context),
                style: ElevatedButton.styleFrom(
                  backgroundColor: SapacColors.primary,
                  foregroundColor: Colors.white,
                  shape: const StadiumBorder(),
                  padding: const EdgeInsets.symmetric(horizontal: 36, vertical: 12),
                ),
                child: const Text('Aceptar', style: TextStyle(fontWeight: FontWeight.bold)),
              )
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final pendientes = _todosLosPedidos
        .where((p) => p['estado_entrega'] == 'Pendiente' || p['estado_entrega'] == 'En camino')
        .toList();

    final historial = _todosLosPedidos
        .where((p) => p['estado_entrega'] == 'Entregado' || p['estado_entrega'] == 'Cancelado')
        .toList();

    final vistas = [
      PendientesView(
        pedidos: pendientes,
        cargando: _cargando,
        onRefresh: _cargarPedidos,
        onCambiarEstado: _cambiarEstadoPedido,
        onCambiarEstadoConGps: _cambiarEstadoPedidoConGps,
        onCambiarEstadoConCoordenadas: _cambiarEstadoPedidoConCoordenadas,
        onCambiarEstadoOffline: _cambiarEstadoPedidoConOffline,
      ),
      HistorialView(
        pedidos: historial,
        onRefresh: _cargarPedidos,
      ),
      MapaView(pedidosPendientes: pendientes),
    ];

    return Scaffold(
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('CONTROL DE PIPAS SAPAC',
                style: TextStyle(fontSize: 11, fontWeight: FontWeight.w800, color: SapacColors.primary)),
            Text(_nombreOperador,
                style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w800, color: SapacColors.textDark)),
          ],
        ),
        actions: [
          IconButton(
            onPressed: _cargarPedidos,
            icon: const Icon(Icons.refresh, color: SapacColors.primary),
            tooltip: 'Actualizar lista',
          ),
          IconButton(
            onPressed: () => Navigator.pushReplacementNamed(context, '/login'),
            icon: const Icon(Icons.logout, color: SapacColors.danger),
            tooltip: 'Cerrar sesión',
          ),
        ],
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(1),
          child: Container(color: SapacColors.border, height: 1),
        ),
      ),
      body: vistas[_tabIndex],
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _tabIndex,
        onTap: (i) => setState(() => _tabIndex = i),
        backgroundColor: SapacColors.surface,
        selectedItemColor: SapacColors.primary,
        unselectedItemColor: SapacColors.textMuted,
        selectedLabelStyle: const TextStyle(fontWeight: FontWeight.w700),
        items: [
          BottomNavigationBarItem(
            icon: Badge(
              isLabelVisible: pendientes.isNotEmpty,
              label: Text('${pendientes.length}'),
              child: const Icon(Icons.local_shipping_outlined),
            ),
            activeIcon: const Icon(Icons.local_shipping),
            label: 'Por Entregar',
          ),
          const BottomNavigationBarItem(
            icon: Icon(Icons.fact_check_outlined),
            activeIcon: Icon(Icons.fact_check),
            label: 'Entregadas',
          ),
          const BottomNavigationBarItem(
            icon: Icon(Icons.map_outlined),
            activeIcon: Icon(Icons.map),
            label: 'Mapa Ruta',
          ),
        ],
      ),
    );
  }
}