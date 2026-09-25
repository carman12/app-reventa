import 'package:app_reventa/logica/cobranza.dart';
import 'package:app_reventa/logica/exportar.dart';
import 'package:app_reventa/modelos/modelos.dart';
import 'package:excel/excel.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('genera un Excel con una hoja por tema y respeta el período', () {
    final hoy = DateTime(2026, 9, 25);
    const cliente = Cliente(id: 'c1', nombre: 'Doris', telefono: '3001234567');
    final venta = Venta(
      id: 'v1',
      clienteId: 'c1',
      fecha: DateTime(2026, 8, 1),
      descripcion: 'Tenis',
      total: 90000,
      formaPago: FormaPago.cuotas,
      cuotas: generarCuotas(
          financiado: 90000,
          numeroCuotas: 2,
          frecuencia: Frecuencia.quincenal,
          primerVencimiento: DateTime(2026, 8, 15)),
    );
    final bytes = generarExcel(
      DatosExportar(
        clientes: const [cliente],
        ventas: [venta],
        abonos: [
          Abono(id: 'a1', ventaId: 'v1', fecha: DateTime(2026, 9, 2), monto: 20000),
        ],
        gastos: [
          Gasto(id: 'g1', fecha: DateTime(2026, 9, 3), categoria: 'Transporte', monto: 15000),
          Gasto(id: 'g2', fecha: DateTime(2026, 8, 3), categoria: 'Publicidad', monto: 50000),
        ],
        cuentas: [
          CuentaPorPagar(
              id: 'p1', proveedor: 'Textiles', monto: 300000,
              fecha: DateTime(2026, 9, 1), vencimiento: DateTime(2026, 9, 20)),
        ],
        productos: const [
          Producto(id: 'x1', seccionId: 's1', nombre: 'Sábanas', precioVenta: 80000, stock: 3),
        ],
        secciones: const [Seccion(id: 's1', nombre: 'Ropa de cama')],
        hoy: hoy,
      ),
      RangoFechas(DateTime(2026, 9, 1), DateTime(2026, 9, 30)),
    );

    final libro = Excel.decodeBytes(bytes);
    expect(libro.tables.keys.toSet(), hojasExcel.toSet());

    // Solo el gasto de septiembre y el abono de septiembre entran al período.
    expect(libro['Gastos'].maxRows, 2);
    expect(libro['Abonos'].maxRows, 2);
    // La venta de agosto queda fuera del período pero el cliente sigue moroso.
    expect(libro['Ventas'].maxRows, 1);
    final moroso = libro['Morosos'].row(1);
    expect((moroso[0]!.value as TextCellValue).value.text, 'Doris');
    expect((moroso[4]!.value as IntCellValue).value, 70000);
    final cuenta = libro['Cuentas por pagar'].row(1);
    expect((cuenta[7]!.value as TextCellValue).value.text, 'Vencida');
  });
}
