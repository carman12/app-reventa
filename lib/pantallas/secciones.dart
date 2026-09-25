import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../datos/negocio.dart';
import '../modelos/modelos.dart';

/// El administrador crea, renombra, ordena y elimina secciones del inventario.
class Secciones extends StatelessWidget {
  const Secciones({super.key});

  @override
  Widget build(BuildContext context) {
    final negocio = context.watch<Negocio>();
    final lista = negocio.secciones;
    return Scaffold(
      appBar: AppBar(title: const Text('Secciones del inventario')),
      floatingActionButton: FloatingActionButton.extended(
        icon: const Icon(Icons.add),
        label: const Text('Nueva sección'),
        onPressed: () => _editar(context, negocio, null),
      ),
      body: ListView.builder(
        padding: const EdgeInsets.only(bottom: 88),
        itemCount: lista.length,
        itemBuilder: (_, i) {
          final s = lista[i];
          final n = negocio.productosEnSeccion(s.id);
          return ListTile(
            title: Text(s.nombre),
            subtitle: Text('$n producto${n == 1 ? '' : 's'}'),
            onTap: () => _editar(context, negocio, s),
            trailing: Row(mainAxisSize: MainAxisSize.min, children: [
              IconButton(
                icon: const Icon(Icons.arrow_upward),
                tooltip: 'Subir',
                onPressed: i == 0 ? null : () => negocio.moverSeccion(s.id, -1),
              ),
              IconButton(
                icon: const Icon(Icons.arrow_downward),
                tooltip: 'Bajar',
                onPressed: i == lista.length - 1
                    ? null
                    : () => negocio.moverSeccion(s.id, 1),
              ),
              IconButton(
                icon: const Icon(Icons.delete_outline),
                tooltip: 'Eliminar',
                onPressed: () async {
                  final ok = await negocio.eliminarSeccion(s.id);
                  if (!ok && context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                        content: Text(
                            'Primero mueve o elimina los $n productos de ${s.nombre}')));
                  }
                },
              ),
            ]),
          );
        },
      ),
    );
  }

  Future<void> _editar(BuildContext context, Negocio negocio, Seccion? s) async {
    final ctrl = TextEditingController(text: s?.nombre);
    final nombre = await showDialog<String>(
      context: context,
      builder: (c) => AlertDialog(
        title: Text(s == null ? 'Nueva sección' : 'Renombrar sección'),
        content: TextField(
          controller: ctrl,
          autofocus: true,
          textCapitalization: TextCapitalization.sentences,
          decoration: const InputDecoration(hintText: 'Ej.: Toallas'),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(c), child: const Text('Cancelar')),
          FilledButton(
              onPressed: () => Navigator.pop(c, ctrl.text.trim()),
              child: const Text('Guardar')),
        ],
      ),
    );
    if (nombre != null && nombre.isNotEmpty) {
      await negocio.guardarSeccion(nombre, id: s?.id);
    }
  }
}
