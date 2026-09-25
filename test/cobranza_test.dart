import 'package:app_reventa/logica/cobranza.dart';
import 'package:app_reventa/modelos/modelos.dart';
import 'package:flutter_test/flutter_test.dart';

const clienteCuotas = Cliente(id: 'c1', nombre: 'Ana');
const clienteLibre = Cliente(
    id: 'c2', nombre: 'Luz', formaPago: FormaPago.abonosLibres, plazoAbonoDias: 15);

Venta ventaEnCuotas({int total = 400000, int n = 4}) => Venta(
      id: 'v1',
      clienteId: 'c1',
      fecha: DateTime(2026, 9, 1),
      descripcion: 'Sábanas',
      total: total,
      formaPago: FormaPago.cuotas,
      cuotas: generarCuotas(
        financiado: total,
        numeroCuotas: n,
        frecuencia: Frecuencia.quincenal,
        primerVencimiento: DateTime(2026, 9, 16),
      ),
    );

Abono abono(int monto, DateTime f, [String venta = 'v1']) =>
    Abono(id: '$monto-$f', ventaId: venta, fecha: f, monto: monto);

void main() {
  group('generarCuotas', () {
    test('reparte el total y la última cuota absorbe el residuo', () {
      final cuotas = generarCuotas(
        financiado: 100000,
        numeroCuotas: 3,
        frecuencia: Frecuencia.semanal,
        primerVencimiento: DateTime(2026, 9, 1),
      );
      expect(cuotas.map((c) => c.monto), [33333, 33333, 33334]);
      expect(cuotas.map((c) => c.vencimiento),
          [DateTime(2026, 9, 1), DateTime(2026, 9, 8), DateTime(2026, 9, 15)]);
    });

    test('mensual respeta el fin de mes', () {
      final cuotas = generarCuotas(
        financiado: 300000,
        numeroCuotas: 3,
        frecuencia: Frecuencia.mensual,
        primerVencimiento: DateTime(2026, 1, 31),
      );
      expect(cuotas.map((c) => c.vencimiento),
          [DateTime(2026, 1, 31), DateTime(2026, 2, 28), DateTime(2026, 3, 31)]);
    });
  });

  group('cuotas con fecha fija', () {
    test('al día cuando la próxima cuota está lejos', () {
      final r = resumirVenta(ventaEnCuotas(), [], clienteCuotas, DateTime(2026, 9, 2));
      expect(r.estado, EstadoCliente.alDia);
      expect(r.saldo, 400000);
    });

    test('por vencer dentro de 7 días', () {
      final r = resumirVenta(ventaEnCuotas(), [], clienteCuotas, DateTime(2026, 9, 10));
      expect(r.estado, EstadoCliente.porVencer);
    });

    test('el día del vencimiento todavía no es moroso', () {
      final r = resumirVenta(ventaEnCuotas(), [], clienteCuotas, DateTime(2026, 9, 16));
      expect(r.estado, EstadoCliente.porVencer);
    });

    test('moroso desde el primer día de atraso', () {
      final r = resumirVenta(ventaEnCuotas(), [], clienteCuotas, DateTime(2026, 9, 17, 8));
      expect(r.estado, EstadoCliente.moroso);
      expect(r.diasAtraso, 1);
      expect(r.montoVencido, 100000);
    });

    test('un abono parcial no cubre la cuota: sigue moroso por lo que falta', () {
      final r = resumirVenta(ventaEnCuotas(), [abono(60000, DateTime(2026, 9, 16))],
          clienteCuotas, DateTime(2026, 9, 20));
      expect(r.estado, EstadoCliente.moroso);
      expect(r.montoVencido, 40000);
      expect(r.saldo, 340000);
    });

    test('pagar la cuota vencida lo pone al día', () {
      final r = resumirVenta(ventaEnCuotas(), [abono(100000, DateTime(2026, 9, 18))],
          clienteCuotas, DateTime(2026, 9, 20));
      expect(r.estado, isNot(EstadoCliente.moroso));
      expect(r.cuotas.first.pagada, isTrue);
    });

    test('los abonos se aplican a las cuotas más antiguas', () {
      final r = resumirVenta(ventaEnCuotas(), [abono(150000, DateTime(2026, 9, 5))],
          clienteCuotas, DateTime(2026, 9, 5));
      expect(r.cuotas.map((c) => c.pagado), [100000, 50000, 0, 0]);
    });

    test('venta pagada completa', () {
      final r = resumirVenta(ventaEnCuotas(), [abono(400000, DateTime(2026, 9, 5))],
          clienteCuotas, DateTime(2027, 1, 1));
      expect(r.pagada, isTrue);
      expect(r.estado, EstadoCliente.alDia);
    });
  });

  group('abonos libres', () {
    final venta = Venta(
      id: 'v2',
      clienteId: 'c2',
      fecha: DateTime(2026, 9, 1),
      descripcion: 'Tenis',
      total: 200000,
      cuotaInicial: 50000,
      formaPago: FormaPago.abonosLibres,
    );

    test('al día dentro del plazo desde la venta', () {
      final r = resumirVenta(venta, [], clienteLibre, DateTime(2026, 9, 5));
      expect(r.estado, EstadoCliente.alDia);
      expect(r.saldo, 150000);
      expect(r.proximoPago, DateTime(2026, 9, 16));
    });

    test('moroso si pasa el plazo sin abonar', () {
      final r = resumirVenta(venta, [], clienteLibre, DateTime(2026, 9, 17));
      expect(r.estado, EstadoCliente.moroso);
      expect(r.diasAtraso, 1);
      expect(r.montoVencido, 150000);
    });

    test('cada abono reinicia el plazo', () {
      final r = resumirVenta(venta, [abono(20000, DateTime(2026, 9, 14), 'v2')],
          clienteLibre, DateTime(2026, 9, 20));
      expect(r.estado, EstadoCliente.alDia);
      expect(r.proximoPago, DateTime(2026, 9, 29));
    });
  });

  test('el cliente toma el peor estado de sus compras', () {
    final r = resumirCliente(
      clienteCuotas,
      [
        ventaEnCuotas(),
        Venta(
          id: 'v3',
          clienteId: 'c1',
          fecha: DateTime(2026, 9, 18),
          descripcion: 'Cobija',
          total: 80000,
          formaPago: FormaPago.cuotas,
          cuotas: generarCuotas(
              financiado: 80000,
              numeroCuotas: 1,
              frecuencia: Frecuencia.mensual,
              primerVencimiento: DateTime(2026, 10, 18)),
        ),
      ],
      [],
      DateTime(2026, 9, 20),
    );
    expect(r.estado, EstadoCliente.moroso);
    expect(r.saldo, 480000);
    expect(r.diasAtraso, 4);
  });

  test('rangos de atraso', () {
    expect(RangoAtraso.hasta30.incluye(1), isTrue);
    expect(RangoAtraso.hasta30.incluye(31), isFalse);
    expect(RangoAtraso.de31a60.incluye(60), isTrue);
    expect(RangoAtraso.masDe60.incluye(61), isTrue);
  });
}
