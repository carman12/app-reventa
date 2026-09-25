import 'package:flutter/material.dart';
import 'package:intl/date_symbol_data_local.dart';

import 'datos/almacen.dart';
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
  Future<void> prod(String sec, String nombre,
          {String marca = '', String talla = '', String medida = '', String color = '',
          String proveedor = '', int compra = 0, required int venta, required int stock}) =>
      n.guardarProducto(Producto(
          id: '', seccionId: sec, nombre: nombre, marca: marca, talla: talla,
          medida: medida, color: color, proveedor: proveedor,
          precioCompra: compra, precioVenta: venta, stock: stock));
  await prod(cama, 'Juego de sábanas estampado', medida: 'Doble', color: 'Azul',
      proveedor: 'Textiles Medellín', compra: 45000, venta: 80000, stock: 6);
  await prod(cama, 'Juego de sábanas liso', medida: 'Sencilla', color: 'Blanco',
      proveedor: 'Textiles Medellín', compra: 35000, venta: 60000, stock: 1);
  await prod(cama, 'Edredón reversible', medida: 'Queen', color: 'Gris',
      proveedor: 'Hogar Textil', compra: 90000, venta: 150000, stock: 3);
  await prod(cama, 'Cobija térmica', medida: 'Doble', color: 'Beige',
      proveedor: 'Hogar Textil', compra: 40000, venta: 70000, stock: 0);
  await prod(calzado, 'Tenis deportivos', marca: 'Adidas', talla: '38', color: 'Negro',
      proveedor: 'Calzado El Paso', compra: 110000, venta: 180000, stock: 2);
  await prod(calzado, 'Tenis deportivos', marca: 'Adidas', talla: '40', color: 'Negro',
      proveedor: 'Calzado El Paso', compra: 110000, venta: 180000, stock: 4);
  await prod(calzado, 'Botas de cuero', marca: 'Vélez', talla: '37', color: 'Café',
      proveedor: 'Calzado El Paso', compra: 190000, venta: 320000, stock: 1);
  await prod(calzado, 'Sandalias', talla: '36', color: 'Dorado', compra: 25000,
      venta: 50000, stock: 8);
  await prod(belleza, 'Kit de maquillaje', marca: 'Vogue', compra: 30000,
      venta: 55000, stock: 5);
  await prod(belleza, 'Crema corporal', marca: 'Nivea', compra: 12000,
      venta: 22000, stock: 10);
  DateTime hace(int d) => hoy.subtract(Duration(days: d));

  final doris = await n.guardarCliente(const Cliente(
      id: '', nombre: 'Doris Martínez', telefono: '3001234567', sector: 'La Floresta'));
  final v1 = await n.registrarVenta(
      cliente: doris, descripcion: 'Juego de sábanas doble + cobija',
      total: 240000, cuotaInicial: 40000, numeroCuotas: 4,
      frecuencia: Frecuencia.quincenal, fecha: hace(50), primerVencimiento: hace(35));
  await n.registrarAbono(ventaId: v1.id, monto: 50000, fecha: hace(34), medio: 'Nequi');

  final luz = await n.guardarCliente(const Cliente(
      id: '', nombre: 'Luz Ángela Rojas', telefono: '3157654321', sector: 'Centro',
      formaPago: FormaPago.abonosLibres, plazoAbonoDias: 15));
  final v2 = await n.registrarVenta(
      cliente: luz, descripcion: 'Tenis talla 38', total: 180000, fecha: hace(30));
  await n.registrarAbono(ventaId: v2.id, monto: 30000, fecha: hace(12));

  final carlos = await n.guardarCliente(const Cliente(
      id: '', nombre: 'Carlos Pérez', telefono: '3209876543', sector: 'La Floresta'));
  await n.registrarVenta(
      cliente: carlos, descripcion: 'Botas de cuero', total: 320000,
      numeroCuotas: 4, frecuencia: Frecuencia.mensual, fecha: hace(100),
      primerVencimiento: hace(70));

  final sandra = await n.guardarCliente(const Cliente(
      id: '', nombre: 'Sandra Gómez', telefono: '3014445566', sector: 'Belén'));
  final v4 = await n.registrarVenta(
      cliente: sandra, descripcion: 'Edredón king + fundas', total: 150000,
      numeroCuotas: 3, frecuencia: Frecuencia.quincenal, fecha: hace(20),
      primerVencimiento: hace(5));
  await n.registrarAbono(ventaId: v4.id, monto: 50000, fecha: hace(5), medio: 'Daviplata');

  await n.guardarCliente(const Cliente(
      id: '', nombre: 'Mónica Ruiz', telefono: '3112223344', sector: 'Centro'));

  runApp(AppReventa(negocio: n));
}
