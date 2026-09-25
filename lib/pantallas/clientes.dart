import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../datos/negocio.dart';
import '../formato.dart';
import '../tema.dart';
import '../logica/cobranza.dart';
import '../modelos/modelos.dart';
import '../widgets/estado.dart';
import 'cliente_form.dart';
import 'resumen.dart';

enum Orden { nombre, saldo, atraso }

class Clientes extends StatefulWidget {
  const Clientes({super.key});

  @override
  State<Clientes> createState() => _ClientesState();
}

class _ClientesState extends State<Clientes> {
  String _busqueda = '';
  EstadoCliente? _estado;
  String? _sector;
  bool _soloConSaldo = false;
  Orden _orden = Orden.nombre;

  @override
  Widget build(BuildContext context) {
    final negocio = context.watch<Negocio>();
    final todos = negocio.resumenes();
    final sectores = {
      for (final r in todos)
        if (r.cliente.sector.trim().isNotEmpty) r.cliente.sector.trim()
    }.toList()
      ..sort();
    final q = _busqueda.toLowerCase();
    final lista = todos.where((r) {
      final c = r.cliente;
      if (q.isNotEmpty &&
          !c.nombre.toLowerCase().contains(q) &&
          !c.telefono.contains(q)) {
        return false;
      }
      if (_estado != null && r.estado != _estado) return false;
      if (_sector != null && c.sector.trim() != _sector) return false;
      if (_soloConSaldo && r.saldo <= 0) return false;
      return true;
    }).toList()
      ..sort(switch (_orden) {
        Orden.nombre => (a, b) => a.cliente.nombre
            .toLowerCase()
            .compareTo(b.cliente.nombre.toLowerCase()),
        Orden.saldo => (a, b) => b.saldo.compareTo(a.saldo),
        Orden.atraso => (a, b) => b.diasAtraso.compareTo(a.diasAtraso),
      });

    return Scaffold(
      appBar: AppBar(
        title: const Text('Clientes'),
        actions: [
          PopupMenuButton<Orden>(
            icon: const Icon(Icons.sort),
            tooltip: 'Ordenar',
            initialValue: _orden,
            onSelected: (o) => setState(() => _orden = o),
            itemBuilder: (_) => const [
              PopupMenuItem(value: Orden.nombre, child: Text('Por nombre')),
              PopupMenuItem(value: Orden.saldo, child: Text('Mayor saldo')),
              PopupMenuItem(value: Orden.atraso, child: Text('Más atrasados')),
            ],
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        icon: const Icon(Icons.person_add),
        label: const Text('Nuevo cliente'),
        onPressed: () => Navigator.of(context).push(
            MaterialPageRoute(builder: (_) => const ClienteForm())),
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
            child: TextField(
              decoration: decoracionBusqueda('Buscar por nombre o teléfono'),
              onChanged: (v) => setState(() => _busqueda = v),
            ),
          ),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            child: Row(children: [
              for (final e in [null, ...EstadoCliente.values])
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 4),
                  child: ChoiceChip(
                    label: Text(e?.texto ?? 'Todos'),
                    selected: _estado == e,
                    onSelected: (_) => setState(() => _estado = e),
                  ),
                ),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 4),
                child: ChoiceChip(
                  label: const Text('Con saldo'),
                  selected: _soloConSaldo,
                  onSelected: (v) => setState(() => _soloConSaldo = v),
                ),
              ),
              if (sectores.isNotEmpty)
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 4),
                  child: DropdownButton<String?>(
                    value: sectores.contains(_sector) ? _sector : null,
                    hint: const Text('Sector'),
                    underline: const SizedBox(),
                    items: [
                      const DropdownMenuItem(
                          value: null, child: Text('Todos los sectores')),
                      for (final s in sectores)
                        DropdownMenuItem(value: s, child: Text(s)),
                    ],
                    onChanged: (s) => setState(() => _sector = s),
                  ),
                ),
            ]),
          ),
          Expanded(
            child: lista.isEmpty
                ? Center(
                    child: Text(todos.isEmpty
                        ? 'Aún no hay clientes.\nToca "Nuevo cliente" para empezar.'
                        : 'Ningún cliente coincide con el filtro.',
                        textAlign: TextAlign.center))
                : ListView.builder(
                    padding: const EdgeInsets.only(bottom: 88),
                    itemCount: lista.length,
                    itemBuilder: (_, i) => _FilaCliente(lista[i]),
                  ),
          ),
        ],
      ),
    );
  }
}

class _FilaCliente extends StatelessWidget {
  final ResumenCliente r;
  const _FilaCliente(this.r);

  @override
  Widget build(BuildContext context) {
    return ListTile(
      leading: CircleAvatar(
        backgroundColor: colorEstado(r.estado).withValues(alpha: 0.15),
        child: Text(r.cliente.nombre.isEmpty ? '?' : r.cliente.nombre[0].toUpperCase(),
            style: TextStyle(color: colorEstado(r.estado))),
      ),
      title: Text(r.cliente.nombre),
      subtitle: Text([
        if (r.cliente.sector.isNotEmpty) r.cliente.sector,
        r.cliente.formaPago.texto,
      ].join(' · ')),
      trailing: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          Text(pesos(r.saldo), style: const TextStyle(fontWeight: FontWeight.w600)),
          const SizedBox(height: 4),
          if (r.saldo > 0) EtiquetaEstado(r.estado, diasAtraso: r.diasAtraso),
        ],
      ),
      onTap: () => abrirCliente(context, r.cliente),
    );
  }
}
