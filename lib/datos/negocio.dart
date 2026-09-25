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
  bool cargado = false;

  Negocio(this._almacen, {DateTime Function()? ahora})
      : _ahora = ahora ?? DateTime.now;

  DateTime get hoy => _ahora();
  List<Cliente> get clientes => List.unmodifiable(_clientes);
  List<Venta> get ventas => List.unmodifiable(_ventas);
  List<Abono> get abonos => List.unmodifiable(_abonos);

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
    );
    _ventas.add(venta);
    await _guardar();
    return venta;
  }

  Future<void> eliminarVenta(String ventaId) async {
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
