import 'dart:convert';
import 'dart:io';

import 'package:path_provider/path_provider.dart';

/// Dónde se guardan los datos. En esta etapa es un archivo en el celular;
/// en la etapa de sincronización se reemplaza por la nube.
abstract class Almacen {
  Future<Map<String, dynamic>?> leer();
  Future<void> guardar(Map<String, dynamic> datos);
}

class AlmacenArchivo implements Almacen {
  Future<File> _archivo() async {
    final dir = await getApplicationDocumentsDirectory();
    return File('${dir.path}/reventa.json');
  }

  @override
  Future<Map<String, dynamic>?> leer() async {
    final f = await _archivo();
    if (!await f.exists()) return null;
    return jsonDecode(await f.readAsString()) as Map<String, dynamic>;
  }

  @override
  Future<void> guardar(Map<String, dynamic> datos) async {
    final f = await _archivo();
    // Escribe primero a un temporal para no dañar el archivo si se corta.
    final tmp = File('${f.path}.tmp');
    await tmp.writeAsString(jsonEncode(datos), flush: true);
    await tmp.rename(f.path);
  }
}

class AlmacenMemoria implements Almacen {
  Map<String, dynamic>? datos;
  AlmacenMemoria([this.datos]);

  @override
  Future<Map<String, dynamic>?> leer() async => datos;

  @override
  Future<void> guardar(Map<String, dynamic> d) async =>
      datos = jsonDecode(jsonEncode(d)) as Map<String, dynamic>;
}
