import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../datos/negocio.dart';
import '../formato.dart';
import '../logica/cobranza.dart';
import '../modelos/modelos.dart';
import 'cliente_detalle.dart';
import 'exportar_dialogo.dart';

class Resumen extends StatelessWidget {
  final void Function(int pestana) irA;
  const Resumen({super.key, required this.irA});

  @override
  Widget build(BuildContext context) {
    final negocio = context.watch<Negocio>();
    final rs = negocio.resumenes();
    final porCobrar = rs.fold<int>(0, (s, r) => s + r.saldo);
    final vencido = rs.fold<int>(0, (s, r) => s + r.montoVencido);
    final morosos = rs.where((r) => r.estado == EstadoCliente.moroso).length;
    final hoy = soloFecha(negocio.hoy);
    final estaSemana = rs
        .where((r) =>
            r.proximoPago != null &&
            r.estado != EstadoCliente.moroso &&
            diasEntre(hoy, r.proximoPago!) <= diasAvisoPorVencer)
        .toList()
      ..sort((a, b) => a.proximoPago!.compareTo(b.proximoPago!));

    return Scaffold(
      appBar: AppBar(
        title: const Text('Mi Negocio'),
        actions: [
          IconButton(
            icon: const Icon(Icons.table_view),
            tooltip: 'Exportar a Excel',
            onPressed: () => mostrarExportar(context),
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Row(children: [
            Expanded(child: _Dato('Por cobrar', pesos(porCobrar), null)),
            const SizedBox(width: 12),
            Expanded(
                child: _Dato('Vencido', pesos(vencido), Colors.red.shade700)),
          ]),
          const SizedBox(height: 12),
          Card(
            child: ListTile(
              leading: Icon(Icons.warning_amber, color: Colors.red.shade700),
              title: Text('$morosos cliente${morosos == 1 ? '' : 's'} moroso${morosos == 1 ? '' : 's'}'),
              trailing: const Icon(Icons.chevron_right),
              onTap: () => irA(2),
            ),
          ),
          Builder(builder: (_) {
            final bajos = negocio.productos
                .where((p) => p.sinStock || p.stockBajo)
                .length;
            if (bajos == 0) return const SizedBox.shrink();
            return Card(
              child: ListTile(
                leading: Icon(Icons.inventory_2_outlined,
                    color: Colors.orange.shade800),
                title: Text('$bajos producto${bajos == 1 ? '' : 's'} por reponer'),
                subtitle: const Text('Agotados o con stock bajo'),
                trailing: const Icon(Icons.chevron_right),
                onTap: () => irA(3),
              ),
            );
          }),
          Builder(builder: (_) {
            final gastosMes = negocio.gastos
                .where((g) => g.fecha.year == hoy.year && g.fecha.month == hoy.month)
                .fold<int>(0, (s, g) => s + g.monto);
            final porPagar = negocio.cuentasPorPagar
                .where((c) => c.saldo > 0 && diasEntre(hoy, c.vencimiento) <= diasAvisoPorVencer)
                .fold<int>(0, (s, c) => s + c.saldo);
            return Card(
              child: ListTile(
                leading: const Icon(Icons.account_balance_wallet_outlined),
                title: Text('Gastos del mes: ${pesos(gastosMes)}'),
                subtitle: Text(porPagar > 0
                    ? 'Pagar a proveedores esta semana o vencido: ${pesos(porPagar)}'
                    : 'Sin pagos a proveedores esta semana'),
                trailing: const Icon(Icons.chevron_right),
                onTap: () => irA(4),
              ),
            );
          }),
          const SizedBox(height: 16),
          Text('Cobros de los próximos $diasAvisoPorVencer días',
              style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: 8),
          if (estaSemana.isEmpty)
            const Padding(
              padding: EdgeInsets.all(16),
              child: Text('No hay cobros pendientes esta semana.'),
            ),
          for (final r in estaSemana)
            Card(
              child: ListTile(
                title: Text(r.cliente.nombre),
                subtitle: Text('Paga el ${fecha(r.proximoPago!)}'),
                trailing: Text(pesos(r.saldo)),
                onTap: () => abrirCliente(context, r.cliente),
              ),
            ),
        ],
      ),
    );
  }
}

class _Dato extends StatelessWidget {
  final String titulo;
  final String valor;
  final Color? color;
  const _Dato(this.titulo, this.valor, this.color);

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(titulo, style: Theme.of(context).textTheme.bodySmall),
            const SizedBox(height: 4),
            FittedBox(
              child: Text(valor,
                  style: Theme.of(context)
                      .textTheme
                      .titleLarge
                      ?.copyWith(color: color, fontWeight: FontWeight.bold)),
            ),
          ],
        ),
      ),
    );
  }
}

void abrirCliente(BuildContext context, Cliente c) => Navigator.of(context)
    .push(MaterialPageRoute(builder: (_) => ClienteDetalle(clienteId: c.id)));

