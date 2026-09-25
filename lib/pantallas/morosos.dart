import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../datos/negocio.dart';
import '../formato.dart';
import '../logica/cobranza.dart';
import '../modelos/modelos.dart';
import '../widgets/estado.dart';
import 'resumen.dart';

class Morosos extends StatefulWidget {
  const Morosos({super.key});

  @override
  State<Morosos> createState() => _MorososState();
}

class _MorososState extends State<Morosos> {
  RangoAtraso? _rango;

  @override
  Widget build(BuildContext context) {
    final todos = context
        .watch<Negocio>()
        .resumenes()
        .where((r) => r.estado == EstadoCliente.moroso)
        .toList()
      ..sort((a, b) => b.diasAtraso.compareTo(a.diasAtraso));
    final lista = todos
        .where((r) => _rango == null || _rango!.incluye(r.diasAtraso))
        .toList();
    final totalVencido = lista.fold<int>(0, (s, r) => s + r.montoVencido);

    return Scaffold(
      appBar: AppBar(title: const Text('Morosos')),
      body: Column(
        children: [
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            child: Row(children: [
              for (final rango in [null, ...RangoAtraso.values])
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 4),
                  child: ChoiceChip(
                    label: Text(rango?.texto ?? 'Todos'),
                    selected: _rango == rango,
                    onSelected: (_) => setState(() => _rango = rango),
                  ),
                ),
            ]),
          ),
          if (lista.isNotEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Text(
                  '${lista.length} cliente${lista.length == 1 ? '' : 's'} · '
                  'Vencido ${pesos(totalVencido)}',
                  style: Theme.of(context).textTheme.titleSmall),
            ),
          Expanded(
            child: lista.isEmpty
                ? const Center(child: Text('Nadie está atrasado. ¡Bien!'))
                : ListView.builder(
                    itemCount: lista.length,
                    itemBuilder: (_, i) {
                      final r = lista[i];
                      return ListTile(
                        title: Text(r.cliente.nombre),
                        subtitle: Text(
                            'Vencido ${pesos(r.montoVencido)} · Saldo ${pesos(r.saldo)}'),
                        leading: EtiquetaEstado(r.estado, diasAtraso: r.diasAtraso),
                        trailing: r.cliente.telefono.isEmpty
                            ? null
                            : IconButton(
                                icon: const Icon(Icons.chat),
                                tooltip: 'Recordar por WhatsApp',
                                onPressed: () => recordarPorWhatsApp(context, r),
                              ),
                        onTap: () => abrirCliente(context, r.cliente),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }
}
