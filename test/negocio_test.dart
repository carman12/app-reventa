import 'package:app_reventa/datos/almacen.dart';
import 'package:app_reventa/datos/negocio.dart';
import 'package:app_reventa/modelos/modelos.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('guarda y vuelve a cargar clientes, ventas y abonos', () async {
    final almacen = AlmacenMemoria();
    final hoy = DateTime(2026, 9, 25);
    final n = Negocio(almacen, ahora: () => hoy);
    await n.cargar();
    final c = await n.guardarCliente(
        const Cliente(id: '', nombre: 'Marta', telefono: '3001234567'));
    final v = await n.registrarVenta(
        cliente: c, descripcion: 'Sábanas', total: 120000, numeroCuotas: 3,
        frecuencia: Frecuencia.quincenal);
    await n.registrarAbono(ventaId: v.id, monto: 40000);

    final otra = Negocio(almacen, ahora: () => hoy);
    await otra.cargar();
    expect(otra.clientes.single.nombre, 'Marta');
    expect(otra.ventas.single.cuotas.length, 3);
    expect(otra.ventas.single.cuotas.first.vencimiento, DateTime(2026, 10, 10));
    expect(otra.resumen(otra.clientes.single).saldo, 80000);
  });

  test('eliminar un cliente borra sus ventas y abonos', () async {
    final n = Negocio(AlmacenMemoria());
    await n.cargar();
    final c = await n.guardarCliente(const Cliente(id: '', nombre: 'Rosa'));
    final v = await n.registrarVenta(cliente: c, descripcion: '', total: 50000);
    await n.registrarAbono(ventaId: v.id, monto: 10000);
    await n.eliminarCliente(c.id);
    expect(n.clientes, isEmpty);
    expect(n.ventas, isEmpty);
    expect(n.abonos, isEmpty);
  });
}
