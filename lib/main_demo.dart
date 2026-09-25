import 'dart:ui' as ui;

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:intl/date_symbol_data_local.dart';

import 'datos/almacen.dart';
import 'datos/fotos.dart';
import 'datos/negocio.dart';
import 'main.dart';
import 'modelos/modelos.dart';

/// Vista previa para el navegador con datos de ejemplo (no se guarda nada).
Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await initializeDateFormatting('es_CO');
  final n = Negocio(AlmacenMemoria());
  await n.cargar();
  final hoy = DateTime.now();
  final cama = n.secciones[0].id, calzado = n.secciones[1].id, belleza = n.secciones[2].id;
  final fotos = FotosMemoria();
  Future<void> prod(String sec, String nombre,
      {String marca = '', String talla = '', String medida = '', String color = '',
      String proveedor = '', int compra = 0, required int venta, required int stock,
      List<(IconData, Color, Color)> ilustraciones = const []}) async {
    final refs = <String>[];
    for (var i = 0; i < ilustraciones.length; i++) {
      final (icono, a, b) = ilustraciones[i];
      refs.add(await fotos.guardar(
          await _fotoEjemplo(nombre, 'Foto ${i + 1} de ${ilustraciones.length}', icono, a, b)));
    }
    await n.guardarProducto(Producto(
        id: '', seccionId: sec, nombre: nombre, marca: marca, talla: talla,
        medida: medida, color: color, proveedor: proveedor,
        precioCompra: compra, precioVenta: venta, stock: stock, fotos: refs));
  }
  const azul = Color(0xFF4F7CAC), azulClaro = Color(0xFFB9D3EE);
  const rosa = Color(0xFFD6336C), rosaClaro = Color(0xFFFFD1DF);
  const coral = Color(0xFFFF7A59), crema = Color(0xFFFFE8D6);
  const gris = Color(0xFF6D6875), grisClaro = Color(0xFFE5DDEA);
  const negro = Color(0xFF2B2D42), cafe = Color(0xFF8D5B4C);
  await prod(cama, 'Juego de sábanas estampado', medida: 'Doble', color: 'Azul',
      proveedor: 'Textiles Medellín', compra: 45000, venta: 80000, stock: 6,
      ilustraciones: [(Icons.bed, azul, azulClaro), (Icons.local_florist, azulClaro, azul), (Icons.king_bed, azul, crema)]);
  await prod(cama, 'Juego de sábanas liso', medida: 'Sencilla', color: 'Blanco',
      proveedor: 'Textiles Medellín', compra: 35000, venta: 60000, stock: 1);
  await prod(cama, 'Edredón reversible', medida: 'Queen', color: 'Gris',
      proveedor: 'Hogar Textil', compra: 90000, venta: 150000, stock: 3,
      ilustraciones: [(Icons.king_bed, gris, grisClaro), (Icons.cloud, grisClaro, gris)]);
  await prod(cama, 'Cobija térmica', medida: 'Doble', color: 'Beige',
      proveedor: 'Hogar Textil', compra: 40000, venta: 70000, stock: 0);
  await prod(calzado, 'Tenis deportivos', marca: 'Adidas', talla: '38', color: 'Negro',
      proveedor: 'Calzado El Paso', compra: 110000, venta: 180000, stock: 2,
      ilustraciones: [(Icons.directions_run, negro, rosaClaro), (Icons.sports, rosa, negro), (Icons.hiking, negro, grisClaro)]);
  await prod(calzado, 'Tenis deportivos', marca: 'Adidas', talla: '40', color: 'Negro',
      proveedor: 'Calzado El Paso', compra: 110000, venta: 180000, stock: 4);
  await prod(calzado, 'Botas de cuero', marca: 'Vélez', talla: '37', color: 'Café',
      proveedor: 'Calzado El Paso', compra: 190000, venta: 320000, stock: 1,
      ilustraciones: [(Icons.hiking, cafe, crema), (Icons.star, crema, cafe)]);
  await prod(calzado, 'Sandalias', talla: '36', color: 'Dorado', compra: 25000,
      venta: 50000, stock: 8,
      ilustraciones: [(Icons.beach_access, coral, crema)]);
  await prod(belleza, 'Kit de maquillaje', marca: 'Vogue', compra: 30000,
      venta: 55000, stock: 5,
      ilustraciones: [(Icons.brush, rosa, rosaClaro), (Icons.face_retouching_natural, rosaClaro, rosa)]);
  await prod(belleza, 'Crema corporal', marca: 'Nivea', compra: 12000,
      venta: 22000, stock: 10);
  DateTime hace(int d) => hoy.subtract(Duration(days: d));
  List<ItemVenta> items(List<(String, String)> nombreYTalla) => [
        for (final (nombre, talla) in nombreYTalla)
          for (final p in n.productos)
            if (p.nombre == nombre && (talla.isEmpty || p.talla == talla))
              ItemVenta(productoId: p.id, nombre: p.nombre, cantidad: 1,
                  precioUnitario: p.precioVenta)
      ];

  final doris = await n.guardarCliente(const Cliente(
      id: '', nombre: 'Doris Martínez', telefono: '3001234567', sector: 'La Floresta'));
  final v1 = await n.registrarVenta(
      cliente: doris, descripcion: 'Juego de sábanas estampado, Edredón reversible',
      total: 230000, items: items([('Juego de sábanas estampado', ''), ('Edredón reversible', '')]), cuotaInicial: 40000, numeroCuotas: 4,
      frecuencia: Frecuencia.quincenal, fecha: hace(50), primerVencimiento: hace(35));
  await n.registrarAbono(ventaId: v1.id, monto: 50000, fecha: hace(34), medio: 'Nequi');

  final luz = await n.guardarCliente(const Cliente(
      id: '', nombre: 'Luz Ángela Rojas', telefono: '3157654321', sector: 'Centro',
      formaPago: FormaPago.abonosLibres, plazoAbonoDias: 15));
  final v2 = await n.registrarVenta(
      cliente: luz, descripcion: 'Tenis deportivos', total: 180000,
      items: items([('Tenis deportivos', '38')]), fecha: hace(30));
  await n.registrarAbono(ventaId: v2.id, monto: 30000, fecha: hace(12));

  final carlos = await n.guardarCliente(const Cliente(
      id: '', nombre: 'Carlos Pérez', telefono: '3209876543', sector: 'La Floresta'));
  await n.registrarVenta(
      cliente: carlos, descripcion: 'Botas de cuero', total: 320000,
      items: items([('Botas de cuero', '')]),
      numeroCuotas: 4, frecuencia: Frecuencia.mensual, fecha: hace(100),
      primerVencimiento: hace(70));

  final sandra = await n.guardarCliente(const Cliente(
      id: '', nombre: 'Sandra Gómez', telefono: '3014445566', sector: 'Belén'));
  final v4 = await n.registrarVenta(
      cliente: sandra, descripcion: 'Edredón reversible', total: 150000,
      items: items([('Edredón reversible', '')]),
      numeroCuotas: 3, frecuencia: Frecuencia.quincenal, fecha: hace(20),
      primerVencimiento: hace(5));
  await n.registrarAbono(ventaId: v4.id, monto: 50000, fecha: hace(5), medio: 'Daviplata');

  await n.guardarCliente(const Cliente(
      id: '', nombre: 'Mónica Ruiz', telefono: '3112223344', sector: 'Centro'));

  await n.registrarGasto(categoria: 'Transporte', monto: 18000,
      descripcion: 'Envíos a Bello', fecha: hace(2));
  await n.registrarGasto(categoria: 'Bolsas y empaque', monto: 25000, fecha: hace(6));
  await n.registrarGasto(categoria: 'Publicidad', monto: 40000,
      descripcion: 'Pauta en Instagram', fecha: hace(10));
  await n.registrarGasto(categoria: 'Transporte', monto: 12000, fecha: hace(14));
  final c1 = await n.registrarCuentaPorPagar(
      proveedor: 'Textiles Medellín', descripcion: '12 juegos de sábanas',
      monto: 540000, fecha: hace(25), vencimiento: hoy.add(const Duration(days: 4)));
  await n.pagarCuenta(c1.id, 200000, fecha: hace(10));
  await n.registrarCuentaPorPagar(
      proveedor: 'Calzado El Paso', descripcion: '6 pares de tenis',
      monto: 660000, fecha: hace(40), vencimiento: hace(3));
  await n.registrarCuentaPorPagar(
      proveedor: 'Hogar Textil', descripcion: 'Edredones', monto: 270000,
      fecha: hace(5), vencimiento: hoy.add(const Duration(days: 25)));

  runApp(AppReventa(negocio: n, fotos: fotos));
}

/// Dibuja una foto de ejemplo (degradado, ícono y nombre) para la vista previa.
Future<Uint8List> _fotoEjemplo(
    String nombre, String pie, IconData icono, Color a, Color b) async {
  const w = 900.0, h = 1100.0;
  final rec = ui.PictureRecorder();
  final c = Canvas(rec);
  c.drawRect(
      const Rect.fromLTWH(0, 0, w, h),
      Paint()
        ..shader = ui.Gradient.linear(Offset.zero, const Offset(w, h), [a, b]));
  final icon = TextPainter(
    text: TextSpan(
        text: String.fromCharCode(icono.codePoint),
        style: TextStyle(
            fontFamily: icono.fontFamily,
            package: icono.fontPackage,
            fontSize: 420,
            color: Colors.white.withValues(alpha: 0.92))),
    textDirection: TextDirection.ltr,
  )..layout();
  icon.paint(c, Offset((w - icon.width) / 2, 250));
  for (final (texto, y, tam) in [(nombre, 800.0, 56.0), (pie, 880.0, 36.0)]) {
    final t = TextPainter(
      text: TextSpan(
          text: texto,
          style: TextStyle(
              color: Colors.white, fontSize: tam, fontWeight: FontWeight.w600,
              shadows: const [Shadow(blurRadius: 12, color: Colors.black38)])),
      textDirection: TextDirection.ltr,
      textAlign: TextAlign.center,
    )..layout(maxWidth: w - 80);
    t.paint(c, Offset((w - t.width) / 2, y));
  }
  final img = await rec.endRecording().toImage(w.toInt(), h.toInt());
  final data = await img.toByteData(format: ui.ImageByteFormat.png);
  return data!.buffer.asUint8List();
}
