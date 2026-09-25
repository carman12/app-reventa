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

  group('inventario', () {
    test('crea las secciones iniciales la primera vez', () async {
      final n = Negocio(AlmacenMemoria());
      await n.cargar();
      expect(n.secciones.map((s) => s.nombre), Negocio.seccionesIniciales);
    });

    test('vender descuenta stock y eliminar la venta lo devuelve', () async {
      final n = Negocio(AlmacenMemoria());
      await n.cargar();
      final p = await n.guardarProducto(Producto(
          id: '', seccionId: n.secciones.first.id, nombre: 'Sábanas',
          precioVenta: 80000, stock: 5));
      final c = await n.guardarCliente(const Cliente(id: '', nombre: 'Ana'));
      final v = await n.registrarVenta(
          cliente: c, descripcion: 'Sábanas', total: 160000,
          items: [ItemVenta(productoId: p.id, nombre: p.nombre, cantidad: 2, precioUnitario: 80000)]);
      expect(n.producto(p.id)!.stock, 3);
      await n.eliminarVenta(v.id);
      expect(n.producto(p.id)!.stock, 5);
    });

    test('venta de contado queda pagada', () async {
      final n = Negocio(AlmacenMemoria());
      await n.cargar();
      final c = await n.guardarCliente(const Cliente(id: '', nombre: 'Eva'));
      await n.registrarVenta(cliente: c, descripcion: '', total: 50000, cuotaInicial: 50000);
      expect(n.resumen(c).saldo, 0);
      expect(n.resumen(c).ventas.single.pagada, isTrue);
    });

    test('no elimina una sección con productos y permite reordenar', () async {
      final n = Negocio(AlmacenMemoria());
      await n.cargar();
      final cama = n.secciones.first;
      await n.guardarProducto(Producto(id: '', seccionId: cama.id, nombre: 'Cobija', stock: 1));
      expect(await n.eliminarSeccion(cama.id), isFalse);
      await n.moverSeccion(cama.id, 1);
      expect(n.secciones[1].id, cama.id);
      final nueva = await n.guardarSeccion('Toallas');
      expect(n.secciones.last.id, nueva.id);
      expect(await n.eliminarSeccion(nueva.id), isTrue);
    });

    test('guarda y recarga productos y secciones', () async {
      final almacen = AlmacenMemoria();
      final n = Negocio(almacen);
      await n.cargar();
      await n.guardarSeccion('Toallas');
      await n.guardarProducto(Producto(
          id: '', seccionId: n.secciones.first.id, nombre: 'Tenis', talla: '38', stock: 2));
      final otra = Negocio(almacen);
      await otra.cargar();
      expect(otra.secciones.length, 4);
      expect(otra.productos.single.talla, '38');
    });
  });
}
