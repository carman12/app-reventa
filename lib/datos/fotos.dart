import 'dart:io';
import 'dart:typed_data';

import 'package:flutter/widgets.dart';
import 'package:path_provider/path_provider.dart';
import 'package:uuid/uuid.dart';

/// Dónde se guardan las fotos de los productos. Cada foto se identifica
/// con una referencia (el nombre del archivo) que se guarda en el producto.
abstract class AlmacenFotos {
  Future<String> guardar(Uint8List bytes);
  ImageProvider imagen(String ref);
  Future<void> borrar(String ref);
}

/// Fotos como archivos .jpg dentro de la app, en el celular.
class FotosArchivo implements AlmacenFotos {
  static const _uuid = Uuid();
  Directory? _dir;

  Future<Directory> _carpeta() async {
    if (_dir != null) return _dir!;
    final base = await getApplicationDocumentsDirectory();
    final d = Directory('${base.path}/fotos');
    await d.create(recursive: true);
    return _dir = d;
  }

  /// Hay que llamarla antes de mostrar imágenes.
  Future<void> preparar() => _carpeta();

  @override
  Future<String> guardar(Uint8List bytes) async {
    final ref = '${_uuid.v4()}.jpg';
    await File('${(await _carpeta()).path}/$ref').writeAsBytes(bytes, flush: true);
    return ref;
  }

  @override
  ImageProvider imagen(String ref) => FileImage(File('${_dir!.path}/$ref'));

  @override
  Future<void> borrar(String ref) async {
    final f = File('${(await _carpeta()).path}/$ref');
    if (await f.exists()) await f.delete();
  }
}

/// Fotos en memoria (vista previa en el navegador y pruebas).
class FotosMemoria implements AlmacenFotos {
  static const _uuid = Uuid();
  final Map<String, Uint8List> _datos = {};

  @override
  Future<String> guardar(Uint8List bytes) async {
    final ref = _uuid.v4();
    _datos[ref] = bytes;
    return ref;
  }

  @override
  ImageProvider imagen(String ref) => MemoryImage(_datos[ref] ?? _vacia);

  @override
  Future<void> borrar(String ref) async => _datos.remove(ref);

  bool contiene(String ref) => _datos.containsKey(ref);
}

// PNG transparente de 1x1 para referencias que ya no existen.
final _vacia = Uint8List.fromList(const [
  137, 80, 78, 71, 13, 10, 26, 10, 0, 0, 0, 13, 73, 72, 68, 82, 0, 0, 0, 1, 0, 0,
  0, 1, 8, 6, 0, 0, 0, 31, 21, 196, 137, 0, 0, 0, 13, 73, 68, 65, 84, 120, 156,
  99, 0, 1, 0, 0, 5, 0, 1, 13, 10, 45, 180, 0, 0, 0, 0, 73, 69, 78, 68, 174, 66,
  96, 130
]);
