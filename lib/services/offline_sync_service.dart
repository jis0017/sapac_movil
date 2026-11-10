// TODO Implement this library.
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:path/path.dart';
import 'package:sqflite/sqflite.dart';
import '../config/api_config.dart';
import 'package:flutter/material.dart';
import 'package:sapac_movil/services/offline_sync_service.dart';

class OfflineSyncService {
  static Database? _database;

  // Inicializar o abrir la base de datos local SQLite
  static Future<Database> get database async {
    if (_database != null) return _database!;
    final dbPath = await getDatabasesPath();
    final path = join(dbPath, 'sapac_offline.db');

    _database = await openDatabase(
      path,
      version: 1,
      onCreate: (db, version) async {
        await db.execute('''
          CREATE TABLE cola_offline (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            id_pedido INTEGER,
            estado_entrega TEXT,
            latitud REAL,
            longitud REAL,
            fecha TEXT
          )
        ''');
      },
    );
    return _database!;
  }

  // 1. Guardar localmente cuando el celular esté sin internet
  static Future<void> guardarEntregaLocal(int idPedido, String estado, double? lat, double? lng) async {
    final db = await database;
    await db.insert('cola_offline', {
      'id_pedido': idPedido,
      'estado_entrega': estado,
      'latitud': lat,
      'longitud': lng,
      'fecha': DateTime.now().toIso8601String(),
    }, conflictAlgorithm: ConflictAlgorithm.replace);
  }

  // 2. Intentar enviar los datos pendientes a Laravel automáticamente
  static Future<void> sincronizarConServidor(String token) async {
    final db = await database;
    final List<Map<String, dynamic>> pendientes = await db.query('cola_offline');

    if (pendientes.isEmpty) return;

    for (var item in pendientes) {
      final int registroId = item['id'];
      final int idPedido = item['id_pedido'];
      final String estadoEntrega = item['estado_entrega'];
      final double? lat = item['latitud'];
      final double? lng = item['longitud'];

      try {
        final res = await http.put(
          Uri.parse('${ApiConfig.baseUrl}/mobile/pedidos/$idPedido/estado'),
          headers: ApiConfig.headers(token: token),
          body: json.encode({
            'estado_entrega': estadoEntrega,
            if (lat != null) 'latitud': lat,
            if (lng != null) 'longitud': lng,
          }),
        );

        // Si Laravel responde con éxito (200), borramos el registro local de la cola
        if (res.statusCode == 200) {
          await db.delete(
            'cola_offline',
            where: 'id = ?',
            whereArgs: [registroId],
          );
        }
      } catch (e) {
        // Si sigue sin haber internet, el ciclo se detiene y se queda a salvo en SQLite local
        break;
      }
    }
  }

  // Obtener cuántas entregas están pendientes de sincronizar
  static Future<int> obtenerPendientesCount() async {
    final db = await database;
    final result = await db.rawQuery('SELECT COUNT(*) as count FROM cola_offline');
    return Sqflite.firstIntValue(result) ?? 0;
  }
}

Future<void> _cambiarEstadoPedidoConOffline(int idPedido, String nuevoEstado, double? lat, double? lng) async {
    try {
      final res = await http.put(
        Uri.parse('${ApiConfig.baseUrl}/mobile/pedidos/$idPedido/estado'),
        headers: ApiConfig.headers(token: _token),
        body: json.encode({
          'estado_entrega': nuevoEstado,
          if (lat != null) 'latitud': lat,
          if (lng != null) 'longitud': lng,
        }),
      );

      if (res.statusCode == 200) {
        await _cargarPedidos();
        if (!mounted) return;
        _mostrarModalExito('¡Entrega registrada con éxito en el sistema!');
      } else {
        throw Exception('Error del servidor');
      }
    } catch (e) {
      // SI NO HAY INTERNET: Lo guardamos localmente en SQLite
      await OfflineSyncService.guardarEntregaLocal(idPedido, nuevoEstado, lat, lng);
      await _cargarPedidos();
      if (!mounted) return;
      _mostrarModalExito('Sin red: Entrega guardada localmente. Se sincronizará al tener señal.');
    }
  }