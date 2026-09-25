import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:share_plus/share_plus.dart';

import '../datos/negocio.dart';
import '../formato.dart';
import '../logica/exportar.dart';

enum _Periodo { esteMes, mesPasado, todo, elegir }

/// Elige el período y comparte el Excel por WhatsApp, correo, Drive, etc.
Future<void> mostrarExportar(BuildContext context) async {
  final negocio = context.read<Negocio>();
  final hoy = negocio.hoy;
  var periodo = _Periodo.esteMes;
  DateTimeRange? elegido;

  RangoFechas? rango() => switch (periodo) {
        _Periodo.esteMes =>
          RangoFechas(DateTime(hoy.year, hoy.month), DateTime(hoy.year, hoy.month + 1, 0)),
        _Periodo.mesPasado =>
          RangoFechas(DateTime(hoy.year, hoy.month - 1), DateTime(hoy.year, hoy.month, 0)),
        _Periodo.todo => null,
        _Periodo.elegir =>
          elegido == null ? null : RangoFechas(elegido!.start, elegido!.end),
      };

  final exportar = await showDialog<bool>(
    context: context,
    builder: (c) => StatefulBuilder(builder: (c, setState) {
      final r = rango();
      return AlertDialog(
        title: const Text('Exportar a Excel'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Un archivo con hojas de resumen, clientes, morosos, ventas, '
                'abonos, gastos, cuentas por pagar e inventario.'),
            const SizedBox(height: 12),
            const Text('Ventas, abonos y gastos del período:',
                style: TextStyle(fontWeight: FontWeight.w600)),
            RadioGroup<_Periodo>(
              groupValue: periodo,
              onChanged: (v) async {
                if (v == _Periodo.elegir) {
                  final f = await showDateRangePicker(
                      context: c,
                      firstDate: DateTime(2020),
                      lastDate: DateTime(2100),
                      initialDateRange: elegido);
                  if (f == null) return;
                  elegido = f;
                }
                setState(() => periodo = v ?? periodo);
              },
              child: Column(children: [
                for (final (p, t) in [
                  (_Periodo.esteMes, 'Este mes'),
                  (_Periodo.mesPasado, 'Mes pasado'),
                  (_Periodo.todo, 'Todo'),
                  (
                    _Periodo.elegir,
                    elegido == null
                        ? 'Elegir fechas…'
                        : '${fecha(elegido!.start)} a ${fecha(elegido!.end)}'
                  ),
                ])
                  RadioListTile<_Periodo>(
                      value: p, title: Text(t), dense: true, contentPadding: EdgeInsets.zero),
              ]),
            ),
            if (r != null)
              Text('Del ${fecha(r.desde)} al ${fecha(r.hasta)}',
                  style: Theme.of(c).textTheme.bodySmall),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(c), child: const Text('Cancelar')),
          FilledButton.icon(
            icon: const Icon(Icons.share),
            onPressed: () => Navigator.pop(c, true),
            label: const Text('Exportar'),
          ),
        ],
      );
    }),
  );
  if (exportar != true || !context.mounted) return;

  final bytes = Uint8List.fromList(generarExcel(
    DatosExportar(
      clientes: negocio.clientes,
      ventas: negocio.ventas,
      abonos: negocio.abonos,
      gastos: negocio.gastos,
      cuentas: negocio.cuentasPorPagar,
      productos: negocio.productos,
      secciones: negocio.secciones,
      hoy: hoy,
    ),
    rango(),
  ));
  final nombre = nombreArchivoExcel(hoy);
  await SharePlus.instance.share(ShareParams(
    title: 'Cuentas de Mi Negocio',
    files: [
      XFile.fromData(bytes,
          name: nombre,
          mimeType:
              'application/vnd.openxmlformats-officedocument.spreadsheetml.sheet')
    ],
    fileNameOverrides: [nombre],
  ));
}
