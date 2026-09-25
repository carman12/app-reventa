import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../datos/negocio.dart';
import '../formato.dart';
import '../modelos/modelos.dart';
import 'producto_form.dart';
import 'secciones.dart';

enum FiltroStock { todos, conStock, stockBajo, sinStock }

extension FiltroStockTexto on FiltroStock {
  String get texto => switch (this) {
        FiltroStock.todos => 'Todo',
        FiltroStock.conStock => 'Con stock',
        FiltroStock.stockBajo => 'Stock bajo',
        FiltroStock.sinStock => 'Agotados',
      };
}

enum OrdenProducto { nombre, precioMenor, precioMayor, stock }

/// Filtros combinables del inventario.
class FiltrosProducto {
  String? marca, talla, medida, color, proveedor;
  int? precioMin, precioMax;

  int get activos => [marca, talla, medida, color, proveedor, precioMin, precioMax]
      .where((x) => x != null)
      .length;

  bool cumple(Producto p) =>
      (marca == null || p.marca == marca) &&
      (talla == null || p.talla == talla) &&
      (medida == null || p.medida == medida) &&
      (color == null || p.color == color) &&
      (proveedor == null || p.proveedor == proveedor) &&
      (precioMin == null || p.precioVenta >= precioMin!) &&
      (precioMax == null || p.precioVenta <= precioMax!);
}

class Inventario extends StatefulWidget {
  const Inventario({super.key});

  @override
  State<Inventario> createState() => _InventarioState();
}

class _InventarioState extends State<Inventario> {
  String _busqueda = '';
  String? _seccionId;
  FiltroStock _stock = FiltroStock.todos;
  OrdenProducto _orden = OrdenProducto.nombre;
  FiltrosProducto _filtros = FiltrosProducto();

  @override
  Widget build(BuildContext context) {
    final negocio = context.watch<Negocio>();
    final secciones = negocio.secciones;
    if (_seccionId != null && negocio.seccion(_seccionId!) == null) {
      _seccionId = null;
    }
    final q = _busqueda.toLowerCase();
    final lista = negocio.productos.where((p) {
      if (_seccionId != null && p.seccionId != _seccionId) return false;
      if (q.isNotEmpty &&
          ![p.nombre, p.marca, p.color, p.talla, p.medida]
              .any((t) => t.toLowerCase().contains(q))) {
        return false;
      }
      final okStock = switch (_stock) {
        FiltroStock.todos => true,
        FiltroStock.conStock => !p.sinStock,
        FiltroStock.stockBajo => p.stockBajo,
        FiltroStock.sinStock => p.sinStock,
      };
      return okStock && _filtros.cumple(p);
    }).toList()
      ..sort(switch (_orden) {
        OrdenProducto.nombre => (a, b) =>
            a.nombre.toLowerCase().compareTo(b.nombre.toLowerCase()),
        OrdenProducto.precioMenor => (a, b) => a.precioVenta.compareTo(b.precioVenta),
        OrdenProducto.precioMayor => (a, b) => b.precioVenta.compareTo(a.precioVenta),
        OrdenProducto.stock => (a, b) => a.stock.compareTo(b.stock),
      });
    final unidades = lista.fold<int>(0, (s, p) => s + p.stock);
    final valor = lista.fold<int>(0, (s, p) => s + p.stock * p.precioVenta);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Inventario'),
        actions: [
          IconButton(
            icon: Badge(
              isLabelVisible: _filtros.activos > 0,
              label: Text('${_filtros.activos}'),
              child: const Icon(Icons.filter_list),
            ),
            tooltip: 'Filtrar',
            onPressed: () => _abrirFiltros(negocio.productos),
          ),
          PopupMenuButton<Object>(
            icon: const Icon(Icons.more_vert),
            onSelected: (v) {
              if (v is OrdenProducto) setState(() => _orden = v);
              if (v == 'secciones') {
                Navigator.of(context).push(
                    MaterialPageRoute(builder: (_) => const Secciones()));
              }
            },
            itemBuilder: (_) => [
              const PopupMenuItem(value: 'secciones', child: Text('Configurar secciones')),
              const PopupMenuDivider(),
              for (final (o, t) in [
                (OrdenProducto.nombre, 'Ordenar por nombre'),
                (OrdenProducto.precioMenor, 'Menor precio'),
                (OrdenProducto.precioMayor, 'Mayor precio'),
                (OrdenProducto.stock, 'Menos stock primero'),
              ])
                CheckedPopupMenuItem(value: o, checked: _orden == o, child: Text(t)),
            ],
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        icon: const Icon(Icons.add),
        label: const Text('Nuevo producto'),
        onPressed: () => Navigator.of(context).push(MaterialPageRoute(
            builder: (_) => ProductoForm(seccionInicial: _seccionId))),
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
            child: TextField(
              decoration: const InputDecoration(
                prefixIcon: Icon(Icons.search),
                hintText: 'Buscar por nombre, marca, color o talla',
                border: OutlineInputBorder(),
                isDense: true,
              ),
              onChanged: (v) => setState(() => _busqueda = v),
            ),
          ),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.fromLTRB(12, 8, 12, 0),
            child: Row(children: [
              for (final s in [null, ...secciones])
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 4),
                  child: ChoiceChip(
                    label: Text(s?.nombre ?? 'Todas'),
                    selected: _seccionId == s?.id,
                    onSelected: (_) => setState(() => _seccionId = s?.id),
                  ),
                ),
            ]),
          ),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
            child: Row(children: [
              for (final f in FiltroStock.values)
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 4),
                  child: FilterChip(
                    label: Text(f.texto),
                    selected: _stock == f,
                    onSelected: (_) => setState(() => _stock = f),
                  ),
                ),
            ]),
          ),
          if (lista.isNotEmpty)
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 4),
              child: Text(
                  '${lista.length} producto${lista.length == 1 ? '' : 's'} · '
                  '$unidades unidades · ${pesos(valor)} a precio de venta',
                  style: Theme.of(context).textTheme.bodySmall),
            ),
          Expanded(
            child: lista.isEmpty
                ? Center(
                    child: Text(
                        negocio.productos.isEmpty
                            ? 'Aún no hay productos.\nToca "Nuevo producto" para agregar el primero.'
                            : 'Ningún producto coincide con el filtro.',
                        textAlign: TextAlign.center))
                : ListView.builder(
                    padding: const EdgeInsets.only(bottom: 88),
                    itemCount: lista.length,
                    itemBuilder: (_, i) => _FilaProducto(lista[i]),
                  ),
          ),
        ],
      ),
    );
  }

  Future<void> _abrirFiltros(List<Producto> productos) async {
    final r = await showModalBottomSheet<FiltrosProducto>(
      context: context,
      isScrollControlled: true,
      builder: (_) => _HojaFiltros(productos: productos, actual: _filtros),
    );
    if (r != null) setState(() => _filtros = r);
  }
}

class _FilaProducto extends StatelessWidget {
  final Producto p;
  const _FilaProducto(this.p);

  @override
  Widget build(BuildContext context) {
    final negocio = context.read<Negocio>();
    final detalle = [
      negocio.seccion(p.seccionId)?.nombre ?? '',
      p.marca,
      if (p.talla.isNotEmpty) 'Talla ${p.talla}',
      p.medida,
      p.color,
    ].where((t) => t.isNotEmpty).join(' · ');
    final colorStock = p.sinStock
        ? Colors.red.shade700
        : p.stockBajo
            ? Colors.orange.shade800
            : Colors.green.shade700;
    return ListTile(
      title: Text(p.nombre),
      subtitle: Text(detalle),
      trailing: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          Text(pesos(p.precioVenta),
              style: const TextStyle(fontWeight: FontWeight.w600)),
          Text(p.sinStock ? 'Agotado' : '${p.stock} und.',
              style: TextStyle(color: colorStock, fontWeight: FontWeight.w600)),
        ],
      ),
      onTap: () => Navigator.of(context).push(
          MaterialPageRoute(builder: (_) => ProductoForm(producto: p))),
    );
  }
}

class _HojaFiltros extends StatefulWidget {
  final List<Producto> productos;
  final FiltrosProducto actual;
  const _HojaFiltros({required this.productos, required this.actual});

  @override
  State<_HojaFiltros> createState() => _HojaFiltrosState();
}

class _HojaFiltrosState extends State<_HojaFiltros> {
  late final f = FiltrosProducto()
    ..marca = widget.actual.marca
    ..talla = widget.actual.talla
    ..medida = widget.actual.medida
    ..color = widget.actual.color
    ..proveedor = widget.actual.proveedor
    ..precioMin = widget.actual.precioMin
    ..precioMax = widget.actual.precioMax;
  late final _min = TextEditingController(text: f.precioMin?.toString() ?? '');
  late final _max = TextEditingController(text: f.precioMax?.toString() ?? '');

  List<String> _valores(String Function(Producto) campo) => {
        for (final p in widget.productos)
          if (campo(p).trim().isNotEmpty) campo(p).trim()
      }.toList()
        ..sort();

  Widget _selector(String etiqueta, String? valor, String Function(Producto) campo,
      void Function(String?) cambiar) {
    final opciones = _valores(campo);
    if (opciones.isEmpty) return const SizedBox.shrink();
    return DropdownButtonFormField<String?>(
      initialValue: opciones.contains(valor) ? valor : null,
      decoration: InputDecoration(labelText: etiqueta),
      items: [
        const DropdownMenuItem(value: null, child: Text('Cualquiera')),
        for (final o in opciones) DropdownMenuItem(value: o, child: Text(o)),
      ],
      onChanged: (v) => setState(() => cambiar(v)),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.fromLTRB(
          16, 16, 16, 16 + MediaQuery.of(context).viewInsets.bottom),
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text('Filtrar productos', style: Theme.of(context).textTheme.titleMedium),
            _selector('Marca', f.marca, (p) => p.marca, (v) => f.marca = v),
            _selector('Talla', f.talla, (p) => p.talla, (v) => f.talla = v),
            _selector('Medida', f.medida, (p) => p.medida, (v) => f.medida = v),
            _selector('Color', f.color, (p) => p.color, (v) => f.color = v),
            _selector('Proveedor', f.proveedor, (p) => p.proveedor, (v) => f.proveedor = v),
            Row(children: [
              Expanded(
                child: TextField(
                  controller: _min,
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(
                      labelText: 'Precio desde', prefixText: r'$ '),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: TextField(
                  controller: _max,
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(
                      labelText: 'Precio hasta', prefixText: r'$ '),
                ),
              ),
            ]),
            const SizedBox(height: 16),
            Row(children: [
              TextButton(
                onPressed: () => Navigator.pop(context, FiltrosProducto()),
                child: const Text('Quitar filtros'),
              ),
              const Spacer(),
              FilledButton(
                onPressed: () {
                  f.precioMin = leerPesos(_min.text);
                  f.precioMax = leerPesos(_max.text);
                  Navigator.pop(context, f);
                },
                child: const Text('Aplicar'),
              ),
            ]),
          ],
        ),
      ),
    );
  }
}
