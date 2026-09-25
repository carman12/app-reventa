import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../datos/negocio.dart';
import '../formato.dart';
import '../modelos/modelos.dart';
import 'cliente_detalle.dart' show confirmar;
import 'exportar_dialogo.dart';

/// Gastos del negocio y cuentas por pagar a proveedores.
class Finanzas extends StatelessWidget {
  const Finanzas({super.key});

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 2,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Finanzas'),
          actions: [
            IconButton(
              icon: const Icon(Icons.table_view),
              tooltip: 'Exportar a Excel',
              onPressed: () => mostrarExportar(context),
            ),
          ],
          bottom: const TabBar(tabs: [
            Tab(text: 'Gastos'),
            Tab(text: 'Cuentas por pagar'),
          ]),
        ),
        body: const TabBarView(children: [_Gastos(), _CuentasPorPagar()]),
      ),
    );
  }
}

const _meses = [
  'enero', 'febrero', 'marzo', 'abril', 'mayo', 'junio', 'julio',
  'agosto', 'septiembre', 'octubre', 'noviembre', 'diciembre'
];

class _Gastos extends StatefulWidget {
  const _Gastos();

  @override
  State<_Gastos> createState() => _GastosState();
}

class _GastosState extends State<_Gastos> {
  DateTime? _mes;
  String? _categoria;

  @override
  Widget build(BuildContext context) {
    final negocio = context.watch<Negocio>();
    final mes = _mes ??= DateTime(negocio.hoy.year, negocio.hoy.month);
    final delMes = negocio.gastos
        .where((g) => g.fecha.year == mes.year && g.fecha.month == mes.month)
        .toList()
      ..sort((a, b) => b.fecha.compareTo(a.fecha));
    final porCategoria = <String, int>{};
    for (final g in delMes) {
      porCategoria[g.categoria] = (porCategoria[g.categoria] ?? 0) + g.monto;
    }
    final lista =
        delMes.where((g) => _categoria == null || g.categoria == _categoria).toList();
    final total = lista.fold<int>(0, (s, g) => s + g.monto);

    return Scaffold(
      floatingActionButton: FloatingActionButton.extended(
        heroTag: 'gasto',
        icon: const Icon(Icons.add),
        label: const Text('Nuevo gasto'),
        onPressed: () => _nuevoGasto(context, negocio),
      ),
      body: ListView(
        padding: const EdgeInsets.only(bottom: 88),
        children: [
          Row(children: [
            IconButton(
              icon: const Icon(Icons.chevron_left),
              tooltip: 'Mes anterior',
              onPressed: () =>
                  setState(() => _mes = DateTime(mes.year, mes.month - 1)),
            ),
            Expanded(
              child: Text('${_meses[mes.month - 1]} ${mes.year}',
                  textAlign: TextAlign.center,
                  style: Theme.of(context).textTheme.titleMedium),
            ),
            IconButton(
              icon: const Icon(Icons.chevron_right),
              tooltip: 'Mes siguiente',
              onPressed: () =>
                  setState(() => _mes = DateTime(mes.year, mes.month + 1)),
            ),
          ]),
          Center(
            child: Text(pesos(total),
                style: Theme.of(context)
                    .textTheme
                    .headlineSmall
                    ?.copyWith(fontWeight: FontWeight.bold)),
          ),
          Center(
              child: Text(_categoria == null
                  ? 'Total de gastos del mes'
                  : 'Gastos en $_categoria')),
          const SizedBox(height: 8),
          if (porCategoria.isNotEmpty)
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 12),
              child: Row(children: [
                for (final c in [null, ...porCategoria.keys])
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 4),
                    child: ChoiceChip(
                      label: Text(c == null
                          ? 'Todas'
                          : '$c · ${pesos(porCategoria[c]!)}'),
                      selected: _categoria == c,
                      onSelected: (_) => setState(() => _categoria = c),
                    ),
                  ),
              ]),
            ),
          if (lista.isEmpty)
            const Padding(
              padding: EdgeInsets.all(32),
              child: Text('No hay gastos en este mes.', textAlign: TextAlign.center),
            ),
          for (final g in lista)
            ListTile(
              title: Text(g.descripcion.isEmpty ? g.categoria : g.descripcion),
              subtitle: Text('${fecha(g.fecha)} · ${g.categoria}'),
              trailing: Text(pesos(g.monto),
                  style: const TextStyle(fontWeight: FontWeight.w600)),
              onLongPress: () async {
                if (await confirmar(context, '¿Eliminar este gasto de ${pesos(g.monto)}?')) {
                  await negocio.eliminarGasto(g.id);
                }
              },
            ),
          if (lista.isNotEmpty)
            const Padding(
              padding: EdgeInsets.all(16),
              child: Text('Mantén presionado un gasto para eliminarlo.',
                  textAlign: TextAlign.center, style: TextStyle(fontSize: 12)),
            ),
        ],
      ),
    );
  }

  Future<void> _nuevoGasto(BuildContext context, Negocio negocio) async {
    final monto = TextEditingController();
    final desc = TextEditingController();
    var categoria = categoriasGasto.first;
    var dia = negocio.hoy;
    await showDialog(
      context: context,
      builder: (c) => StatefulBuilder(
        builder: (c, setState) {
          final valor = leerPesos(monto.text) ?? 0;
          return AlertDialog(
            title: const Text('Nuevo gasto'),
            content: SingleChildScrollView(
              child: Column(mainAxisSize: MainAxisSize.min, children: [
                DropdownButtonFormField<String>(
                  initialValue: categoria,
                  decoration: const InputDecoration(labelText: 'Categoría'),
                  items: [
                    for (final x in categoriasGasto)
                      DropdownMenuItem(value: x, child: Text(x)),
                  ],
                  onChanged: (v) => categoria = v ?? categoria,
                ),
                TextField(
                  controller: monto,
                  autofocus: true,
                  keyboardType: TextInputType.number,
                  inputFormatters: const [FormatoMiles()],
                  decoration:
                      const InputDecoration(labelText: 'Valor', prefixText: r'$ '),
                  onChanged: (_) => setState(() {}),
                ),
                TextField(
                  controller: desc,
                  textCapitalization: TextCapitalization.sentences,
                  decoration: const InputDecoration(
                      labelText: 'Detalle (opcional)', hintText: 'Ej.: Envío a Bello'),
                ),
                TextButton.icon(
                  icon: const Icon(Icons.event),
                  label: Text('Fecha: ${fecha(dia)}'),
                  onPressed: () async {
                    final f = await showDatePicker(
                        context: c,
                        initialDate: dia,
                        firstDate: DateTime(2020),
                        lastDate: DateTime(2100));
                    if (f != null) setState(() => dia = f);
                  },
                ),
              ]),
            ),
            actions: [
              TextButton(
                  onPressed: () => Navigator.pop(c), child: const Text('Cancelar')),
              FilledButton(
                onPressed: valor <= 0
                    ? null
                    : () async {
                        await negocio.registrarGasto(
                            categoria: categoria,
                            monto: valor,
                            descripcion: desc.text.trim(),
                            fecha: dia);
                        if (c.mounted) Navigator.pop(c);
                      },
                child: const Text('Guardar'),
              ),
            ],
          );
        },
      ),
    );
  }
}

Color colorCuenta(EstadoCuenta e) => switch (e) {
      EstadoCuenta.pendiente => Colors.blueGrey.shade600,
      EstadoCuenta.porVencer => Colors.orange.shade800,
      EstadoCuenta.vencida => Colors.red.shade700,
      EstadoCuenta.pagada => Colors.green.shade700,
    };

class _CuentasPorPagar extends StatefulWidget {
  const _CuentasPorPagar();

  @override
  State<_CuentasPorPagar> createState() => _CuentasPorPagarState();
}

class _CuentasPorPagarState extends State<_CuentasPorPagar> {
  /// null = todas las que tienen saldo.
  EstadoCuenta? _estado;
  String? _proveedor;

  @override
  Widget build(BuildContext context) {
    final negocio = context.watch<Negocio>();
    final hoy = negocio.hoy;
    final todas = negocio.cuentasPorPagar;
    final proveedores = {for (final c in todas) c.proveedor}.toList()..sort();
    final lista = todas.where((c) {
      final e = c.estado(hoy);
      if (_estado == null ? e == EstadoCuenta.pagada : e != _estado) return false;
      return _proveedor == null || c.proveedor == _proveedor;
    }).toList()
      ..sort((a, b) => a.vencimiento.compareTo(b.vencimiento));
    final abiertas = todas.where((c) => c.saldo > 0);
    final totalDeuda = abiertas.fold<int>(0, (s, c) => s + c.saldo);
    final totalVencido = abiertas
        .where((c) => c.estado(hoy) == EstadoCuenta.vencida)
        .fold<int>(0, (s, c) => s + c.saldo);

    return Scaffold(
      floatingActionButton: FloatingActionButton.extended(
        heroTag: 'cuenta',
        icon: const Icon(Icons.add),
        label: const Text('Nueva cuenta'),
        onPressed: () => _nuevaCuenta(context, negocio),
      ),
      body: ListView(
        padding: const EdgeInsets.only(bottom: 88),
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: Row(children: [
              Expanded(child: _Cifra('Le debes a proveedores', pesos(totalDeuda), null)),
              Expanded(
                  child: _Cifra('Vencido', pesos(totalVencido), Colors.red.shade700)),
            ]),
          ),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 12),
            child: Row(children: [
              for (final (e, t) in [
                (null, 'Por pagar'),
                (EstadoCuenta.vencida, 'Vencidas'),
                (EstadoCuenta.porVencer, 'Por vencer'),
                (EstadoCuenta.pagada, 'Pagadas'),
              ])
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 4),
                  child: ChoiceChip(
                    label: Text(t),
                    selected: _estado == e,
                    onSelected: (_) => setState(() => _estado = e),
                  ),
                ),
              if (proveedores.isNotEmpty)
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 4),
                  child: DropdownButton<String?>(
                    value: proveedores.contains(_proveedor) ? _proveedor : null,
                    hint: const Text('Proveedor'),
                    underline: const SizedBox(),
                    items: [
                      const DropdownMenuItem(value: null, child: Text('Todos')),
                      for (final p in proveedores)
                        DropdownMenuItem(value: p, child: Text(p)),
                    ],
                    onChanged: (v) => setState(() => _proveedor = v),
                  ),
                ),
            ]),
          ),
          if (lista.isEmpty)
            const Padding(
              padding: EdgeInsets.all(32),
              child: Text('No hay cuentas en esta lista.', textAlign: TextAlign.center),
            ),
          for (final c in lista)
            ListTile(
              title: Text(c.proveedor),
              subtitle: Text([
                if (c.descripcion.isNotEmpty) c.descripcion,
                'Vence ${fecha(c.vencimiento)}',
              ].join(' · ')),
              trailing: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(pesos(c.saldo > 0 ? c.saldo : c.monto),
                      style: const TextStyle(fontWeight: FontWeight.w600)),
                  Text(c.estado(hoy).texto,
                      style: TextStyle(
                          color: colorCuenta(c.estado(hoy)),
                          fontWeight: FontWeight.w600,
                          fontSize: 12)),
                ],
              ),
              onTap: () => showModalBottomSheet(
                context: context,
                isScrollControlled: true,
                builder: (_) => _DetalleCuenta(cuentaId: c.id),
              ),
            ),
        ],
      ),
    );
  }

  Future<void> _nuevaCuenta(BuildContext context, Negocio negocio) async {
    final proveedor = TextEditingController();
    final desc = TextEditingController();
    final monto = TextEditingController();
    var vence = negocio.hoy.add(const Duration(days: 30));
    final sugeridos = negocio.proveedores();
    await showDialog(
      context: context,
      builder: (c) => StatefulBuilder(
        builder: (c, setState) {
          final valor = leerPesos(monto.text) ?? 0;
          final ok = valor > 0 && proveedor.text.trim().isNotEmpty;
          return AlertDialog(
            title: const Text('Nueva cuenta por pagar'),
            content: SingleChildScrollView(
              child: Column(mainAxisSize: MainAxisSize.min, children: [
                Autocomplete<String>(
                  optionsBuilder: (v) => sugeridos.where(
                      (s) => s.toLowerCase().contains(v.text.toLowerCase())),
                  onSelected: (s) => setState(() => proveedor.text = s),
                  fieldViewBuilder: (_, ctrl, foco, _) => TextField(
                    controller: ctrl,
                    focusNode: foco,
                    autofocus: true,
                    textCapitalization: TextCapitalization.words,
                    decoration: const InputDecoration(labelText: 'Proveedor'),
                    onChanged: (v) => setState(() => proveedor.text = v),
                  ),
                ),
                TextField(
                  controller: desc,
                  textCapitalization: TextCapitalization.sentences,
                  decoration: const InputDecoration(
                      labelText: 'Detalle (opcional)',
                      hintText: 'Ej.: 12 juegos de sábanas'),
                ),
                TextField(
                  controller: monto,
                  keyboardType: TextInputType.number,
                  inputFormatters: const [FormatoMiles()],
                  decoration:
                      const InputDecoration(labelText: 'Valor', prefixText: r'$ '),
                  onChanged: (_) => setState(() {}),
                ),
                TextButton.icon(
                  icon: const Icon(Icons.event),
                  label: Text('Vence: ${fecha(vence)}'),
                  onPressed: () async {
                    final f = await showDatePicker(
                        context: c,
                        initialDate: vence,
                        firstDate: DateTime(2020),
                        lastDate: DateTime(2100));
                    if (f != null) setState(() => vence = f);
                  },
                ),
              ]),
            ),
            actions: [
              TextButton(
                  onPressed: () => Navigator.pop(c), child: const Text('Cancelar')),
              FilledButton(
                onPressed: !ok
                    ? null
                    : () async {
                        await negocio.registrarCuentaPorPagar(
                            proveedor: proveedor.text.trim(),
                            descripcion: desc.text.trim(),
                            monto: valor,
                            vencimiento: vence);
                        if (c.mounted) Navigator.pop(c);
                      },
                child: const Text('Guardar'),
              ),
            ],
          );
        },
      ),
    );
  }
}

class _Cifra extends StatelessWidget {
  final String titulo, valor;
  final Color? color;
  const _Cifra(this.titulo, this.valor, this.color);

  @override
  Widget build(BuildContext context) => Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(titulo, style: Theme.of(context).textTheme.bodySmall),
          FittedBox(
            child: Text(valor,
                style: Theme.of(context)
                    .textTheme
                    .titleLarge
                    ?.copyWith(color: color, fontWeight: FontWeight.bold)),
          ),
        ],
      );
}

class _DetalleCuenta extends StatelessWidget {
  final String cuentaId;
  const _DetalleCuenta({required this.cuentaId});

  @override
  Widget build(BuildContext context) {
    final negocio = context.watch<Negocio>();
    final c = negocio.cuentasPorPagar.where((x) => x.id == cuentaId).firstOrNull;
    if (c == null) return const SizedBox.shrink();
    final e = c.estado(negocio.hoy);
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(c.proveedor, style: Theme.of(context).textTheme.titleLarge),
          if (c.descripcion.isNotEmpty) Text(c.descripcion),
          const SizedBox(height: 8),
          Text('Total ${pesos(c.monto)} · Pagado ${pesos(c.pagado)}'),
          Text('Saldo ${pesos(c.saldo)}',
              style: const TextStyle(fontWeight: FontWeight.bold)),
          Text('Vence ${fecha(c.vencimiento)} · ${e.texto}',
              style: TextStyle(color: colorCuenta(e))),
          if (c.pagos.isNotEmpty) ...[
            const Divider(),
            const Text('Pagos', style: TextStyle(fontWeight: FontWeight.w600)),
            for (final p in c.pagos)
              Row(children: [
                Expanded(child: Text(fecha(p.fecha))),
                Text(pesos(p.monto)),
                IconButton(
                  icon: const Icon(Icons.delete_outline, size: 18),
                  tooltip: 'Borrar pago',
                  onPressed: () => negocio.eliminarPagoCuenta(c.id, p.id),
                ),
              ]),
          ],
          const SizedBox(height: 12),
          Row(children: [
            if (c.saldo > 0)
              FilledButton.icon(
                icon: const Icon(Icons.payments),
                label: const Text('Registrar pago'),
                onPressed: () => _pagar(context, negocio, c),
              ),
            const Spacer(),
            TextButton(
              onPressed: () async {
                if (await confirmar(context, '¿Eliminar esta cuenta por pagar?')) {
                  await negocio.eliminarCuenta(c.id);
                  if (context.mounted) Navigator.pop(context);
                }
              },
              child: const Text('Eliminar'),
            ),
          ]),
        ],
      ),
    );
  }

  Future<void> _pagar(BuildContext context, Negocio negocio, CuentaPorPagar c) async {
    final monto = TextEditingController(text: miles(c.saldo));
    await showDialog(
      context: context,
      builder: (d) => StatefulBuilder(builder: (d, setState) {
        final v = leerPesos(monto.text) ?? 0;
        final error = v <= 0
            ? 'Escribe el valor'
            : v > c.saldo
                ? 'Supera el saldo (${pesos(c.saldo)})'
                : null;
        return AlertDialog(
          title: Text('Pago a ${c.proveedor}'),
          content: TextField(
            controller: monto,
            autofocus: true,
            keyboardType: TextInputType.number,
            inputFormatters: const [FormatoMiles()],
            decoration: InputDecoration(
                labelText: 'Valor', prefixText: r'$ ', errorText: error),
            onChanged: (_) => setState(() {}),
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(d), child: const Text('Cancelar')),
            FilledButton(
              onPressed: error != null
                  ? null
                  : () async {
                      await negocio.pagarCuenta(c.id, v);
                      if (d.mounted) Navigator.pop(d);
                    },
              child: const Text('Guardar'),
            ),
          ],
        );
      }),
    );
  }
}
