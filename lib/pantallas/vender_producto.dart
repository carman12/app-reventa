import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../datos/negocio.dart';
import '../formato.dart';
import '../modelos/modelos.dart';
import '../tema.dart';
import 'venta_form.dart';

/// Elige a qué cliente se le vende el producto y abre la venta con el
/// producto ya agregado.
Future<void> venderProducto(BuildContext context, Producto p) async {
  if (p.sinStock) {
    ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('${p.nombre} está agotado')));
    return;
  }
  final cliente = await showModalBottomSheet<Cliente>(
    context: context,
    isScrollControlled: true,
    builder: (_) => _SelectorCliente(producto: p),
  );
  if (cliente == null || !context.mounted) return;
  await Navigator.of(context).push(MaterialPageRoute(
    builder: (_) => VentaForm(
      cliente: cliente,
      itemInicial: ItemVenta(
          productoId: p.id, nombre: p.nombre, cantidad: 1, precioUnitario: p.precioVenta),
    ),
  ));
}

class _SelectorCliente extends StatefulWidget {
  final Producto producto;
  const _SelectorCliente({required this.producto});

  @override
  State<_SelectorCliente> createState() => _SelectorClienteState();
}

class _SelectorClienteState extends State<_SelectorCliente> {
  String _q = '';

  @override
  Widget build(BuildContext context) {
    final negocio = context.read<Negocio>();
    final lista = negocio.clientes
        .where((c) => '${c.nombre} ${c.telefono}'.toLowerCase().contains(_q.toLowerCase()))
        .toList()
      ..sort((a, b) => a.nombre.compareTo(b.nombre));
    return SizedBox(
      height: MediaQuery.of(context).size.height * 0.75,
      child: Column(children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 4),
          child: Text('¿A quién le vendes ${widget.producto.nombre}?',
              style: Theme.of(context).textTheme.titleMedium),
        ),
        Text(pesos(widget.producto.precioVenta)),
        Padding(
          padding: const EdgeInsets.all(16),
          child: TextField(
            autofocus: true,
            decoration: decoracionBusqueda('Buscar cliente'),
            onChanged: (v) => setState(() => _q = v),
          ),
        ),
        Expanded(
          child: lista.isEmpty
              ? const Center(
                  child: Text('No hay clientes. Créalos en la pestaña Clientes.'))
              : ListView(children: [
                  for (final c in lista)
                    ListTile(
                      leading: CircleAvatar(
                          child: Text(c.nombre.isEmpty ? '?' : c.nombre[0].toUpperCase())),
                      title: Text(c.nombre),
                      subtitle: Text(c.formaPago.texto),
                      trailing: Text(pesos(negocio.resumen(c).saldo)),
                      onTap: () => Navigator.pop(context, c),
                    ),
                ]),
        ),
      ]),
    );
  }
}

/// Clientes que han comprado un producto, con cantidad y fecha.
class CompradoresProducto extends StatelessWidget {
  final String productoId;
  const CompradoresProducto({super.key, required this.productoId});

  @override
  Widget build(BuildContext context) {
    final negocio = context.watch<Negocio>();
    final compras = [
      for (final v in negocio.ventas)
        for (final it in v.items)
          if (it.productoId == productoId) (v, it)
    ]..sort((a, b) => b.$1.fecha.compareTo(a.$1.fecha));
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Quién lo ha comprado', style: Theme.of(context).textTheme.titleMedium),
        if (compras.isEmpty)
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 8),
            child: Text('Todavía nadie. Usa "Vender a un cliente".'),
          ),
        for (final (v, it) in compras)
          ListTile(
            contentPadding: EdgeInsets.zero,
            title: Text(negocio.cliente(v.clienteId)?.nombre ?? 'Cliente eliminado'),
            subtitle: Text(fecha(v.fecha)),
            trailing: Text('${it.cantidad} × ${pesos(it.precioUnitario)}'),
          ),
      ],
    );
  }
}
