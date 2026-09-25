/// Reglas de cobranza: cómo se generan las cuotas y cuándo un cliente
/// está al día, por vencer o moroso. No depende de Flutter para poder
/// probarse fácilmente.
library;

import '../modelos/modelos.dart';

/// Días antes del vencimiento en que una cuota pasa a "por vencer".
const diasAvisoPorVencer = 7;

DateTime soloFecha(DateTime d) => DateTime(d.year, d.month, d.day);

int diasEntre(DateTime desde, DateTime hasta) =>
    soloFecha(hasta).difference(soloFecha(desde)).inDays;

/// Suma meses respetando el fin de mes (31 de enero + 1 mes = 28/29 de febrero).
DateTime sumarMeses(DateTime d, int meses) {
  final mes0 = d.month - 1 + meses;
  final anio = d.year + mes0 ~/ 12;
  final mes = mes0 % 12 + 1;
  final ultimoDia = DateTime(anio, mes + 1, 0).day;
  return DateTime(anio, mes, d.day > ultimoDia ? ultimoDia : d.day);
}

DateTime siguienteVencimiento(DateTime d, Frecuencia f, int n) => switch (f) {
      Frecuencia.semanal => soloFecha(d).add(Duration(days: 7 * n)),
      Frecuencia.quincenal => soloFecha(d).add(Duration(days: 15 * n)),
      Frecuencia.mensual => sumarMeses(soloFecha(d), n),
    };

/// Reparte [financiado] en [numeroCuotas] cuotas; la última absorbe el residuo
/// para que la suma cuadre exacto.
List<Cuota> generarCuotas({
  required int financiado,
  required int numeroCuotas,
  required Frecuencia frecuencia,
  required DateTime primerVencimiento,
}) {
  if (numeroCuotas < 1) throw ArgumentError('Debe haber al menos una cuota');
  if (financiado <= 0) return const [];
  final base = financiado ~/ numeroCuotas;
  return [
    for (var i = 0; i < numeroCuotas; i++)
      Cuota(
        numero: i + 1,
        vencimiento: siguienteVencimiento(primerVencimiento, frecuencia, i),
        monto: i == numeroCuotas - 1
            ? financiado - base * (numeroCuotas - 1)
            : base,
      ),
  ];
}

class EstadoCuota {
  final Cuota cuota;
  final int pagado;
  const EstadoCuota(this.cuota, this.pagado);
  int get pendiente => cuota.monto - pagado;
  bool get pagada => pendiente <= 0;
}

class ResumenVenta {
  final Venta venta;
  final int abonado;
  final int saldo;
  final int montoVencido;
  final int diasAtraso;
  final EstadoCliente estado;
  final List<EstadoCuota> cuotas;

  /// Próxima fecha en que el cliente debe pagar algo (null si ya pagó todo).
  final DateTime? proximoPago;

  const ResumenVenta({
    required this.venta,
    required this.abonado,
    required this.saldo,
    required this.montoVencido,
    required this.diasAtraso,
    required this.estado,
    required this.cuotas,
    required this.proximoPago,
  });

  bool get pagada => saldo <= 0;
}

ResumenVenta resumirVenta(
  Venta venta,
  List<Abono> abonosDeLaVenta,
  Cliente cliente,
  DateTime hoy,
) {
  final abonado = abonosDeLaVenta.fold<int>(0, (s, a) => s + a.monto);
  final saldo = venta.financiado - abonado;
  final dia = soloFecha(hoy);

  if (saldo <= 0) {
    return ResumenVenta(
      venta: venta,
      abonado: abonado,
      saldo: 0,
      montoVencido: 0,
      diasAtraso: 0,
      estado: EstadoCliente.alDia,
      cuotas: [for (final c in venta.cuotas) EstadoCuota(c, c.monto)],
      proximoPago: null,
    );
  }

  if (venta.formaPago == FormaPago.cuotas && venta.cuotas.isNotEmpty) {
    // Los abonos se aplican a las cuotas más antiguas primero.
    var restante = abonado;
    final estados = <EstadoCuota>[];
    for (final c in venta.cuotas) {
      final aplicado = restante >= c.monto ? c.monto : restante;
      restante -= aplicado;
      estados.add(EstadoCuota(c, aplicado));
    }
    final pendientes = estados.where((e) => !e.pagada).toList();
    final vencidas =
        pendientes.where((e) => e.cuota.vencimiento.isBefore(dia)).toList();
    final montoVencido = vencidas.fold<int>(0, (s, e) => s + e.pendiente);
    final diasAtraso =
        vencidas.isEmpty ? 0 : diasEntre(vencidas.first.cuota.vencimiento, dia);
    final proximo = pendientes.first.cuota.vencimiento;
    final estado = vencidas.isNotEmpty
        ? EstadoCliente.moroso
        : diasEntre(dia, proximo) <= diasAvisoPorVencer
            ? EstadoCliente.porVencer
            : EstadoCliente.alDia;
    return ResumenVenta(
      venta: venta,
      abonado: abonado,
      saldo: saldo,
      montoVencido: montoVencido,
      diasAtraso: diasAtraso,
      estado: estado,
      cuotas: estados,
      proximoPago: proximo,
    );
  }

  // Abonos libres: el cliente debe abonar algo cada [plazoAbonoDias] días,
  // contados desde el último abono (o desde la venta si aún no abona).
  final fechas = [venta.fecha, for (final a in abonosDeLaVenta) a.fecha]
    ..sort();
  final limite =
      soloFecha(fechas.last).add(Duration(days: cliente.plazoAbonoDias));
  final atraso = diasEntre(limite, dia);
  final estado = atraso > 0
      ? EstadoCliente.moroso
      : -atraso <= diasAvisoPorVencer
          ? EstadoCliente.porVencer
          : EstadoCliente.alDia;
  return ResumenVenta(
    venta: venta,
    abonado: abonado,
    saldo: saldo,
    montoVencido: atraso > 0 ? saldo : 0,
    diasAtraso: atraso > 0 ? atraso : 0,
    estado: estado,
    cuotas: const [],
    proximoPago: limite,
  );
}

class ResumenCliente {
  final Cliente cliente;
  final List<ResumenVenta> ventas;
  const ResumenCliente(this.cliente, this.ventas);

  Iterable<ResumenVenta> get abiertas => ventas.where((v) => !v.pagada);

  int get saldo => abiertas.fold(0, (s, v) => s + v.saldo);
  int get montoVencido => abiertas.fold(0, (s, v) => s + v.montoVencido);
  int get diasAtraso =>
      abiertas.fold(0, (m, v) => v.diasAtraso > m ? v.diasAtraso : m);

  EstadoCliente get estado {
    if (abiertas.any((v) => v.estado == EstadoCliente.moroso)) {
      return EstadoCliente.moroso;
    }
    if (abiertas.any((v) => v.estado == EstadoCliente.porVencer)) {
      return EstadoCliente.porVencer;
    }
    return EstadoCliente.alDia;
  }

  DateTime? get proximoPago {
    final fechas = [
      for (final v in abiertas)
        if (v.proximoPago != null) v.proximoPago!
    ]..sort();
    return fechas.isEmpty ? null : fechas.first;
  }
}

ResumenCliente resumirCliente(
  Cliente cliente,
  List<Venta> ventas,
  List<Abono> abonos,
  DateTime hoy,
) {
  final propias = ventas.where((v) => v.clienteId == cliente.id).toList()
    ..sort((a, b) => a.fecha.compareTo(b.fecha));
  return ResumenCliente(cliente, [
    for (final v in propias)
      resumirVenta(
          v, abonos.where((a) => a.ventaId == v.id).toList(), cliente, hoy),
  ]);
}

/// Rango de atraso para filtrar morosos.
enum RangoAtraso { hasta30, de31a60, masDe60 }

extension RangoAtrasoTexto on RangoAtraso {
  String get texto => switch (this) {
        RangoAtraso.hasta30 => '1 a 30 días',
        RangoAtraso.de31a60 => '31 a 60 días',
        RangoAtraso.masDe60 => 'Más de 60 días',
      };

  bool incluye(int dias) => switch (this) {
        RangoAtraso.hasta30 => dias >= 1 && dias <= 30,
        RangoAtraso.de31a60 => dias >= 31 && dias <= 60,
        RangoAtraso.masDe60 => dias > 60,
      };
}
