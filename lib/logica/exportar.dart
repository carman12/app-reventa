/// Genera el archivo de Excel con una hoja por tema. No depende de Flutter.
library;

import 'package:excel/excel.dart';

import '../modelos/modelos.dart';
import 'cobranza.dart';

class RangoFechas {
  final DateTime desde;
  final DateTime hasta;
  const RangoFechas(this.desde, this.hasta);

  bool incluye(DateTime d) {
    final x = soloFecha(d);
    return !x.isBefore(soloFecha(desde)) && !x.isAfter(soloFecha(hasta));
  }
}

class DatosExportar {
  final List<Cliente> clientes;
  final List<Venta> ventas;
  final List<Abono> abonos;
  final List<Gasto> gastos;
  final List<CuentaPorPagar> cuentas;
  final List<Producto> productos;
  final List<Seccion> secciones;
  final DateTime hoy;

  const DatosExportar({
    required this.clientes,
    required this.ventas,
    required this.abonos,
    required this.gastos,
    required this.cuentas,
    required this.productos,
    required this.secciones,
    required this.hoy,
  });
}

/// Nombres de las hojas, en el orden en que aparecen.
const hojasExcel = [
  'Resumen',
  'Clientes',
  'Morosos',
  'Ventas',
  'Abonos',
  'Gastos',
  'Cuentas por pagar',
  'Inventario',
];

List<int> generarExcel(DatosExportar d, RangoFechas? rango) {
  final excel = Excel.createExcel();
  final original = excel.getDefaultSheet();
  bool enRango(DateTime f) => rango == null || rango.incluye(f);
  final nombreCliente = {for (final c in d.clientes) c.id: c.nombre};
  final ventaPorId = {for (final v in d.ventas) v.id: v};
  final seccion = {for (final s in d.secciones) s.id: s.nombre};
  final resumenes = [
    for (final c in d.clientes) resumirCliente(c, d.ventas, d.abonos, d.hoy)
  ]..sort((a, b) => a.cliente.nombre.compareTo(b.cliente.nombre));

  final negrita = CellStyle(bold: true, backgroundColorHex: ExcelColor.fromHexString('#D8EFEA'));
  final dinero = CellStyle(numberFormat: NumFormat.standard_3);

  CellValue? celda(Object? v) => switch (v) {
        null => null,
        _Pesos p => IntCellValue(p.valor),
        int n => IntCellValue(n),
        DateTime f => DateCellValue.fromDateTime(f),
        _ => TextCellValue('$v'),
      };

  void hoja(String nombre, List<String> encabezados, Iterable<List<Object?>> filas) {
    final s = excel[nombre];
    for (var c = 0; c < encabezados.length; c++) {
      s.updateCell(CellIndex.indexByColumnRow(columnIndex: c, rowIndex: 0),
          TextCellValue(encabezados[c]),
          cellStyle: negrita);
      s.setColumnWidth(c, encabezados[c].length < 12 ? 14 : encabezados[c].length + 4);
    }
    var r = 1;
    for (final fila in filas) {
      for (var c = 0; c < fila.length; c++) {
        final v = fila[c];
        s.updateCell(CellIndex.indexByColumnRow(columnIndex: c, rowIndex: r), celda(v),
            cellStyle: v is _Pesos ? dinero : null);
      }
      r++;
    }
  }

  // Resumen
  final ventasRango = d.ventas.where((v) => enRango(v.fecha)).toList();
  final abonosRango = d.abonos.where((a) => enRango(a.fecha)).toList();
  final gastosRango = d.gastos.where((g) => enRango(g.fecha)).toList();
  int sum(Iterable<int> xs) => xs.fold<int>(0, (s, x) => s + x);
  hoja('Resumen', ['Concepto', 'Valor'], [
    [
      'Período',
      rango == null
          ? 'Todo'
          : '${_f(rango.desde)} a ${_f(rango.hasta)}'
    ],
    ['Generado el', _f(d.hoy)],
    ['Ventas del período', _Pesos(sum(ventasRango.map((v) => v.total)))],
    [
      'Cobrado en el período (iniciales + abonos)',
      _Pesos(sum(ventasRango.map((v) => v.cuotaInicial)) +
          sum(abonosRango.map((a) => a.monto)))
    ],
    ['Gastos del período', _Pesos(sum(gastosRango.map((g) => g.monto)))],
    ['Saldo por cobrar hoy', _Pesos(sum(resumenes.map((r) => r.saldo)))],
    ['Vencido hoy', _Pesos(sum(resumenes.map((r) => r.montoVencido)))],
    [
      'Clientes morosos',
      resumenes.where((r) => r.estado == EstadoCliente.moroso).length
    ],
    ['Por pagar a proveedores', _Pesos(sum(d.cuentas.map((c) => c.saldo > 0 ? c.saldo : 0)))],
    [
      'Inventario a precio de venta',
      _Pesos(sum(d.productos.map((p) => p.stock * p.precioVenta)))
    ],
  ]);

  hoja('Clientes', [
    'Nombre', 'Celular', 'Sector', 'Dirección', 'Forma de pago', 'Saldo',
    'Vencido', 'Días de atraso', 'Estado', 'Próximo pago'
  ], [
    for (final r in resumenes)
      [
        r.cliente.nombre,
        r.cliente.telefono,
        r.cliente.sector,
        r.cliente.direccion,
        r.cliente.formaPago.texto,
        _Pesos(r.saldo),
        _Pesos(r.montoVencido),
        r.diasAtraso,
        r.saldo > 0 ? r.estado.texto : 'Sin deuda',
        r.proximoPago,
      ]
  ]);

  hoja('Morosos', ['Nombre', 'Celular', 'Sector', 'Días de atraso', 'Vencido', 'Saldo total'], [
    for (final r in [...resumenes.where((r) => r.estado == EstadoCliente.moroso)]
      ..sort((a, b) => b.diasAtraso.compareTo(a.diasAtraso)))
      [
        r.cliente.nombre,
        r.cliente.telefono,
        r.cliente.sector,
        r.diasAtraso,
        _Pesos(r.montoVencido),
        _Pesos(r.saldo),
      ]
  ]);

  final saldoVenta = {
    for (final r in resumenes)
      for (final v in r.ventas) v.venta.id: v.saldo
  };
  hoja('Ventas', [
    'Fecha', 'Cliente', 'Detalle', 'Total', 'Pago inicial', 'Forma de pago',
    'Cuotas', 'Saldo hoy'
  ], [
    for (final v in ventasRango..sort((a, b) => a.fecha.compareTo(b.fecha)))
      [
        v.fecha,
        nombreCliente[v.clienteId] ?? '',
        v.descripcion,
        _Pesos(v.total),
        _Pesos(v.cuotaInicial),
        v.financiado <= 0 ? 'Contado' : v.formaPago.texto,
        v.cuotas.length,
        _Pesos(saldoVenta[v.id] ?? 0),
      ]
  ]);

  hoja('Abonos', ['Fecha', 'Cliente', 'Compra', 'Valor', 'Medio de pago'], [
    for (final a in abonosRango..sort((a, b) => a.fecha.compareTo(b.fecha)))
      [
        a.fecha,
        nombreCliente[ventaPorId[a.ventaId]?.clienteId] ?? '',
        ventaPorId[a.ventaId]?.descripcion ?? '',
        _Pesos(a.monto),
        a.medio,
      ]
  ]);

  hoja('Gastos', ['Fecha', 'Categoría', 'Detalle', 'Valor'], [
    for (final g in gastosRango..sort((a, b) => a.fecha.compareTo(b.fecha)))
      [g.fecha, g.categoria, g.descripcion, _Pesos(g.monto)]
  ]);

  hoja('Cuentas por pagar', [
    'Proveedor', 'Detalle', 'Fecha', 'Vence', 'Total', 'Pagado', 'Saldo', 'Estado'
  ], [
    for (final c in [...d.cuentas]..sort((a, b) => a.vencimiento.compareTo(b.vencimiento)))
      [
        c.proveedor,
        c.descripcion,
        c.fecha,
        c.vencimiento,
        _Pesos(c.monto),
        _Pesos(c.pagado),
        _Pesos(c.saldo),
        c.estado(d.hoy).texto,
      ]
  ]);

  hoja('Inventario', [
    'Sección', 'Producto', 'Marca', 'Talla', 'Medida', 'Color', 'Material',
    'Proveedor', 'Precio compra', 'Precio venta', 'Stock', 'Estado'
  ], [
    for (final p in [...d.productos]
      ..sort((a, b) => '${seccion[a.seccionId]}${a.nombre}'
          .compareTo('${seccion[b.seccionId]}${b.nombre}')))
      [
        seccion[p.seccionId] ?? '',
        p.nombre,
        p.marca,
        p.talla,
        p.medida,
        p.color,
        p.material,
        p.proveedor,
        _Pesos(p.precioCompra),
        _Pesos(p.precioVenta),
        p.stock,
        p.sinStock ? 'Agotado' : p.stockBajo ? 'Stock bajo' : 'Disponible',
      ]
  ]);

  excel.setDefaultSheet('Resumen');
  if (original != null && !hojasExcel.contains(original)) excel.delete(original);
  return excel.encode()!;
}

String nombreArchivoExcel(DateTime hoy) =>
    'mi-negocio-${hoy.year}-${hoy.month.toString().padLeft(2, '0')}-${hoy.day.toString().padLeft(2, '0')}.xlsx';

String _f(DateTime d) =>
    '${d.day.toString().padLeft(2, '0')}/${d.month.toString().padLeft(2, '0')}/${d.year}';

/// Marca un número como pesos para darle formato de miles en Excel.
class _Pesos {
  final int valor;
  const _Pesos(this.valor);
}
