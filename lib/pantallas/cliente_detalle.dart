import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../datos/negocio.dart';
import '../formato.dart';
import '../logica/cobranza.dart';
import '../modelos/modelos.dart';
import '../widgets/estado.dart';
import 'abono_dialogo.dart';
import 'cliente_form.dart';
import 'venta_form.dart';
import 'visor_fotos.dart';

class ClienteDetalle extends StatelessWidget {
  final String clienteId;
  const ClienteDetalle({super.key, required this.clienteId});

  @override
  Widget build(BuildContext context) {
    final negocio = context.watch<Negocio>();
    final cliente = negocio.cliente(clienteId);
    if (cliente == null) return const Scaffold();
    final r = negocio.resumen(cliente);
    final ventas = r.ventas.reversed.toList();

    return Scaffold(
      appBar: AppBar(
        title: Text(cliente.nombre),
        actions: [
          IconButton(
            icon: const Icon(Icons.edit),
            tooltip: 'Editar',
            onPressed: () => Navigator.of(context).push(MaterialPageRoute(
                builder: (_) => ClienteForm(cliente: cliente))),
          ),
          PopupMenuButton<String>(
            onSelected: (_) => _eliminar(context, negocio, cliente),
            itemBuilder: (_) => const [
              PopupMenuItem(value: 'eliminar', child: Text('Eliminar cliente')),
            ],
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        icon: const Icon(Icons.add_shopping_cart),
        label: const Text('Nueva venta'),
        onPressed: () => Navigator.of(context).push(
            MaterialPageRoute(builder: (_) => VentaForm(cliente: cliente))),
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 88),
        children: [
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(children: [
                    Expanded(
                      child: Text(pesos(r.saldo),
                          style: Theme.of(context).textTheme.headlineSmall
                              ?.copyWith(fontWeight: FontWeight.bold)),
                    ),
                    if (r.saldo > 0)
                      EtiquetaEstado(r.estado, diasAtraso: r.diasAtraso),
                  ]),
                  const Text('Saldo pendiente'),
                  if (r.montoVencido > 0)
                    Text('Vencido: ${pesos(r.montoVencido)}',
                        style: TextStyle(color: Colors.red.shade700)),
                  if (r.proximoPago != null)
                    Text('Próximo pago: ${fecha(r.proximoPago!)}'),
                  const Divider(),
                  if (cliente.telefono.isNotEmpty) Text('Cel: ${cliente.telefono}'),
                  if (cliente.sector.isNotEmpty) Text('Sector: ${cliente.sector}'),
                  if (cliente.direccion.isNotEmpty)
                    Text('Dirección: ${cliente.direccion}'),
                  Text('Paga con: ${cliente.formaPago.texto}'
                      '${cliente.formaPago == FormaPago.abonosLibres ? ' (cada ${cliente.plazoAbonoDias} días máx.)' : ''}'),
                  if (cliente.notas.isNotEmpty) Text('Notas: ${cliente.notas}'),
                  if (r.saldo > 0 && cliente.telefono.isNotEmpty) ...[
                    const SizedBox(height: 8),
                    OutlinedButton.icon(
                      icon: const Icon(Icons.chat),
                      label: const Text('Recordar por WhatsApp'),
                      onPressed: () => recordarPorWhatsApp(context, r),
                    ),
                  ],
                ],
              ),
            ),
          ),
          const SizedBox(height: 8),
          Text('Compras', style: Theme.of(context).textTheme.titleMedium),
          if (ventas.isEmpty)
            const Padding(
              padding: EdgeInsets.all(16),
              child: Text('Sin compras registradas.'),
            ),
          for (final v in ventas) _TarjetaVenta(v),
        ],
      ),
    );
  }

  Future<void> _eliminar(
      BuildContext context, Negocio negocio, Cliente cliente) async {
    final ok = await confirmar(context,
        '¿Eliminar a ${cliente.nombre} con todas sus compras y abonos?');
    if (!ok) return;
    await negocio.eliminarCliente(cliente.id);
    if (context.mounted) Navigator.of(context).pop();
  }
}

Future<bool> confirmar(BuildContext context, String pregunta) async =>
    await showDialog<bool>(
      context: context,
      builder: (c) => AlertDialog(
        content: Text(pregunta),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(c, false),
              child: const Text('Cancelar')),
          FilledButton(
              onPressed: () => Navigator.pop(c, true),
              child: const Text('Eliminar')),
        ],
      ),
    ) ??
    false;

class _TarjetaVenta extends StatelessWidget {
  final ResumenVenta r;
  const _TarjetaVenta(this.r);

  @override
  Widget build(BuildContext context) {
    final negocio = context.read<Negocio>();
    final v = r.venta;
    final abonos = negocio.abonosDeVenta(v.id);
    final fotos = [
      for (final it in v.items)
        if (negocio.producto(it.productoId)?.fotos.firstOrNull case final f?) (it, f)
    ];
    return Card(
      child: ExpansionTile(
        leading: fotos.isEmpty
            ? null
            : GestureDetector(
                onTap: () => VisorFotos.abrir(context,
                    fotos: [for (final (_, f) in fotos) f],
                    titulo: v.descripcion.isEmpty ? 'Compra' : v.descripcion),
                child: MiniaturaFoto(fotos.first.$2),
              ),
        title: Text(v.descripcion.isEmpty ? 'Compra' : v.descripcion),
        subtitle: Text('${fecha(v.fecha)} · Total ${pesos(v.total)}'),
        trailing: r.pagada
            ? Text('Pagada', style: TextStyle(color: Colors.green.shade700))
            : Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(pesos(r.saldo)),
                  EtiquetaEstado(r.estado, diasAtraso: r.diasAtraso),
                ],
              ),
        childrenPadding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
        expandedCrossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (v.cuotaInicial > 0) Text('Cuota inicial: ${pesos(v.cuotaInicial)}'),
          Text('Abonado: ${pesos(r.abonado)} de ${pesos(v.financiado)}'),
          if (r.cuotas.isNotEmpty) ...[
            const SizedBox(height: 8),
            const Text('Cuotas', style: TextStyle(fontWeight: FontWeight.w600)),
            for (final c in r.cuotas)
              Row(children: [
                Icon(
                  c.pagada ? Icons.check_circle : Icons.radio_button_unchecked,
                  size: 16,
                  color: c.pagada
                      ? Colors.green.shade700
                      : c.cuota.vencimiento.isBefore(soloFecha(negocio.hoy))
                          ? Colors.red.shade700
                          : null,
                ),
                const SizedBox(width: 6),
                Expanded(
                    child: Text(
                        '${c.cuota.numero}. ${fecha(c.cuota.vencimiento)}')),
                Text(c.pagada
                    ? pesos(c.cuota.monto)
                    : c.pagado > 0
                        ? 'Faltan ${pesos(c.pendiente)}'
                        : pesos(c.cuota.monto)),
              ]),
          ] else if (!r.pagada && r.proximoPago != null)
            Text('Debe abonar antes del ${fecha(r.proximoPago!)}'),
          if (abonos.isNotEmpty) ...[
            const SizedBox(height: 8),
            const Text('Abonos', style: TextStyle(fontWeight: FontWeight.w600)),
            for (final a in abonos)
              Row(children: [
                Expanded(child: Text('${fecha(a.fecha)} · ${a.medio}')),
                Text(pesos(a.monto)),
                IconButton(
                  icon: const Icon(Icons.delete_outline, size: 18),
                  tooltip: 'Borrar abono',
                  visualDensity: VisualDensity.compact,
                  onPressed: () async {
                    if (await confirmar(context,
                        '¿Borrar el abono de ${pesos(a.monto)}?')) {
                      await negocio.eliminarAbono(a.id);
                    }
                  },
                ),
              ]),
          ],
          const SizedBox(height: 8),
          Row(children: [
            if (!r.pagada)
              FilledButton.icon(
                icon: const Icon(Icons.payments),
                label: const Text('Registrar abono'),
                onPressed: () => mostrarAbono(context, r),
              ),
            const Spacer(),
            TextButton(
              onPressed: () async {
                if (await confirmar(context,
                    '¿Eliminar esta compra y sus abonos?')) {
                  await negocio.eliminarVenta(v.id);
                }
              },
              child: const Text('Eliminar'),
            ),
          ]),
        ],
      ),
    );
  }
}
