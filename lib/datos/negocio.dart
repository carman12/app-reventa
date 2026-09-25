import 'package:flutter/foundation.dart';
import 'package:uuid/uuid.dart';

import '../logica/cobranza.dart';
import '../modelos/modelos.dart';
import 'almacen.dart';

/// Estado de la app: clientes, ventas y abonos, con guardado automático.
class Negocio extends ChangeNotifier {
  final Almacen _almacen;
  final DateTime Function() _ahora;
  static const _uuid = Uuid();

  final List<Cliente> _clientes = [];
  final List<Venta> _ventas = [];
  final List<Abono> _abonos = [];
  final List<Seccion> _secciones = [];
  final List<Producto> _productos = [];
  bool cargado = false;

  static const seccionesIniciales = ['Ropa de cama', 'Calzado', 'Belleza'];

  Negocio(this._almacen, {DateTime Function()? ahora})
      : _ahora = ahora ?? DateTime.now;

  DateTime get hoy => _ahora();
  List<Cliente> get clientes => List.unmodifiable(_clientes);
  List<Venta> get ventas => List.unmodifiable(_ventas);
  List<Abono> get abonos => List.unmodifiable(_abonos);
  List<Seccion> get secciones =>
      List.unmodifiable([..._secciones]..sort((a, b) => a.orden.compareTo(b.orden)));
  List<Producto> get productos => List.unmodifiable(_productos);

  Future<void> cargar() async {
    final d = await _almacen.leer();
    if (d != null) {
      _clientes.addAll([
        for (final j in d['clientes'] ?? []) Cliente.fromJson(Map.from(j))
      ]);
      _ventas.addAll(
          [for (final j in d['ventas'] ?? []) Venta.fromJson(Map.from(j))]);
      _abonos.addAll(
          [for (final j in d['abonos'] ?? []) Abono.fromJson(Map.from(j))]);
      _secciones.addAll(
          [for (final j in d['secciones'] ?? []) Seccion.fromJson(Map.from(j))]);
      _productos.addAll(
          [for (final j in d['productos'] ?? []) Producto.fromJson(Map.from(j))]);
    }
    if (d == null || d['secciones'] == null) {
      for (var i = 0; i < seccionesIniciales.length; i++) {
        _secciones.add(
            Seccion(id: _uuid.v4(), nombre: seccionesIniciales[i], orden: i));
      }
    }
    cargado = true;
    notifyListeners();
  }

  Future<void> _guardar() async {
    notifyListeners();
    await _almacen.guardar({
      'version': 1,
      'clientes': [for (final c in _clientes) c.toJson()],
      'ventas': [for (final v in _ventas) v.toJson()],
      'abonos': [for (final a in _abonos) a.toJson()],
      'secciones': [for (final x in _secciones) x.toJson()],
      'productos': [for (final p in _productos) p.toJson()],
    });
  }

  Cliente? cliente(String id) {
    for (final c in _clientes) {
      if (c.id == id) return c;
    }
    return null;
  }

  ResumenCliente resumen(Cliente c) => resumirCliente(c, _ventas, _abonos, hoy);

  List<ResumenCliente> resumenes() => [for (final c in _clientes) resumen(c)];

  List<Abono> abonosDeVenta(String ventaId) =>
      _abonos.where((a) => a.ventaId == ventaId).toList()
        ..sort((a, b) => b.fecha.compareTo(a.fecha));

  Future<Cliente> guardarCliente(Cliente c) async {
    final nuevo = c.id.isEmpty ? c.copyWithId(_uuid.v4()) : c;
    final i = _clientes.indexWhere((x) => x.id == nuevo.id);
    if (i >= 0) {
      _clientes[i] = nuevo;
    } else {
      _clientes.add(nuevo);
    }
    await _guardar();
    return nuevo;
  }

  Future<void> eliminarCliente(String id) async {
    final ventasIds =
        _ventas.where((v) => v.clienteId == id).map((v) => v.id).toSet();
    _abonos.removeWhere((a) => ventasIds.contains(a.ventaId));
    _ventas.removeWhere((v) => v.clienteId == id);
    _clientes.removeWhere((c) => c.id == id);
    await _guardar();
  }

  Future<Venta> registrarVenta({
    required Cliente cliente,
    required String descripcion,
    required int total,
    int cuotaInicial = 0,
    int numeroCuotas = 1,
    Frecuencia frecuencia = Frecuencia.quincenal,
    DateTime? primerVencimiento,
    DateTime? fecha,
    List<ItemVenta> items = const [],
  }) async {
    final f = fecha ?? hoy;
    final financiado = total - cuotaInicial;
    final venta = Venta(
      id: _uuid.v4(),
      clienteId: cliente.id,
      fecha: f,
      descripcion: descripcion,
      total: total,
      cuotaInicial: cuotaInicial,
      formaPago: cliente.formaPago,
      cuotas: cliente.formaPago == FormaPago.cuotas
          ? generarCuotas(
              financiado: financiado,
              numeroCuotas: numeroCuotas,
              frecuencia: frecuencia,
              primerVencimiento:
                  primerVencimiento ?? siguienteVencimiento(f, frecuencia, 1),
            )
          : const [],
      items: items,
    );
    for (final it in items) {
      _moverStock(it.productoId, -it.cantidad);
    }
    _ventas.add(venta);
    await _guardar();
    return venta;
  }

  Future<void> eliminarVenta(String ventaId) async {
    // Devuelve al inventario lo que se había vendido.
    for (final v in _ventas.where((v) => v.id == ventaId)) {
      for (final it in v.items) {
        _moverStock(it.productoId, it.cantidad);
      }
    }
    _abonos.removeWhere((a) => a.ventaId == ventaId);
    _ventas.removeWhere((v) => v.id == ventaId);
    await _guardar();
  }

  Future<void> registrarAbono({
    required String ventaId,
    required int monto,
    String medio = 'Efectivo',
    DateTime? fecha,
  }) async {
    _abonos.add(Abono(
      id: _uuid.v4(),
      ventaId: ventaId,
      fecha: fecha ?? hoy,
      monto: monto,
      medio: medio,
    ));
    await _guardar();
  }

  Future<void> eliminarAbono(String abonoId) async {
    _abonos.removeWhere((a) => a.id == abonoId);
    await _guardar();
  }

  // --- Inventario ---

  Seccion? seccion(String id) {
    for (final x in _secciones) {
      if (x.id == id) return x;
    }
    return null;
  }

  Producto? producto(String id) {
    for (final p in _productos) {
      if (p.id == id) return p;
    }
    return null;
  }

  int productosEnSeccion(String seccionId) =>
      _productos.where((p) => p.seccionId == seccionId).length;

  Future<Seccion> guardarSeccion(String nombre, {String? id}) async {
    final i = id == null ? -1 : _secciones.indexWhere((x) => x.id == id);
    late Seccion s;
    if (i >= 0) {
      s = _secciones[i].copyWith(nombre: nombre);
      _secciones[i] = s;
    } else {
      final orden = _secciones.fold<int>(-1, (m, x) => x.orden > m ? x.orden : m) + 1;
      s = Seccion(id: _uuid.v4(), nombre: nombre, orden: orden);
      _secciones.add(s);
    }
    await _guardar();
    return s;
  }

  /// Solo se puede eliminar una sección vacía, para no perder productos.
  Future<bool> eliminarSeccion(String id) async {
    if (productosEnSeccion(id) > 0) return false;
    _secciones.removeWhere((x) => x.id == id);
    await _guardar();
    return true;
  }

  /// Mueve una sección una posición arriba (-1) o abajo (+1).
  Future<void> moverSeccion(String id, int direccion) async {
    final orden = secciones.toList();
    final i = orden.indexWhere((x) => x.id == id);
    final j = i + direccion;
    if (i < 0 || j < 0 || j >= orden.length) return;
    final tmp = orden[i];
    orden[i] = orden[j];
    orden[j] = tmp;
    _secciones
      ..clear()
      ..addAll([for (var k = 0; k < orden.length; k++) orden[k].copyWith(orden: k)]);
    await _guardar();
  }

  Future<Producto> guardarProducto(Producto p) async {
    final nuevo = p.id.isEmpty ? p.copyWith(id: _uuid.v4()) : p;
    final i = _productos.indexWhere((x) => x.id == nuevo.id);
    if (i >= 0) {
      _productos[i] = nuevo;
    } else {
      _productos.add(nuevo);
    }
    await _guardar();
    return nuevo;
  }

  Future<void> eliminarProducto(String id) async {
    _productos.removeWhere((p) => p.id == id);
    await _guardar();
  }

  Future<void> ajustarStock(String productoId, int cambio) async {
    _moverStock(productoId, cambio);
    await _guardar();
  }

  void _moverStock(String productoId, int cambio) {
    final i = _productos.indexWhere((p) => p.id == productoId);
    if (i < 0) return;
    final nuevo = _productos[i].stock + cambio;
    _productos[i] = _productos[i].copyWith(stock: nuevo < 0 ? 0 : nuevo);
  }
}

extension on Cliente {
  Cliente copyWithId(String id) => Cliente(
        id: id,
        nombre: nombre,
        telefono: telefono,
        sector: sector,
        direccion: direccion,
        notas: notas,
        formaPago: formaPago,
        plazoAbonoDias: plazoAbonoDias,
      );
}
