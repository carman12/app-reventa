import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

import '../datos/negocio.dart';
import '../formato.dart';
import '../logica/cobranza.dart';
import '../modelos/modelos.dart';

class VentaForm extends StatefulWidget {
  final Cliente cliente;
  const VentaForm({super.key, required this.cliente});

  @override
  State<VentaForm> createState() => _VentaFormState();
}

class _VentaFormState extends State<VentaForm> {
  final _form = GlobalKey<FormState>();
  final _descripcion = TextEditingController();
  final _total = TextEditingController();
  final _inicial = TextEditingController(text: '0');
  final _numCuotas = TextEditingController(text: '4');
  Frecuencia _frecuencia = Frecuencia.quincenal;
  late DateTime _fecha = soloFecha(context.read<Negocio>().hoy);
  DateTime? _primerVencimiento;
  final List<ItemVenta> _items = [];

  bool get _enCuotas => widget.cliente.formaPago == FormaPago.cuotas;
  int get _totalValor => leerPesos(_total.text) ?? 0;
  int get _inicialValor => leerPesos(_inicial.text) ?? 0;
  int get _n => int.tryParse(_numCuotas.text) ?? 0;
  DateTime get _primera =>
      _primerVencimiento ?? siguienteVencimiento(_fecha, _frecuencia, 1);

  @override
  Widget build(BuildContext context) {
    final financiado = _totalValor - _inicialValor;
    final vistaPrevia = _enCuotas && financiado > 0 && _n >= 1 && _n <= 60
        ? generarCuotas(
            financiado: financiado,
            numeroCuotas: _n,
            frecuencia: _frecuencia,
            primerVencimiento: _primera)
        : const <Cuota>[];

    return Scaffold(
      appBar: AppBar(title: Text('Venta a ${widget.cliente.nombre}')),
      body: Form(
        key: _form,
        onChanged: () => setState(() {}),
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            _productos(context),
            TextFormField(
              controller: _descripcion,
              decoration: const InputDecoration(
                  labelText: '¿Qué compró?',
                  hintText: 'Ej.: Juego de sábanas doble + tenis talla 38'),
              textCapitalization: TextCapitalization.sentences,
            ),
            TextFormField(
              controller: _total,
              decoration:
                  const InputDecoration(labelText: 'Valor total *', prefixText: r'$ '),
              keyboardType: TextInputType.number,
              inputFormatters: [FilteringTextInputFormatter.digitsOnly],
              validator: (_) => _totalValor <= 0 ? 'Escribe el valor' : null,
            ),
            TextFormField(
              controller: _inicial,
              decoration: const InputDecoration(
                  labelText: 'Pago inicial (lo que pagó hoy)',
                  helperText: 'Si pagó todo, la venta queda de contado',
                  prefixText: r'$ '),
              keyboardType: TextInputType.number,
              inputFormatters: [FilteringTextInputFormatter.digitsOnly],
              validator: (_) => _inicialValor > _totalValor
                  ? 'No puede ser mayor que el total'
                  : null,
            ),
            TextButton.icon(
              icon: const Icon(Icons.event),
              label: Text('Fecha de la venta: ${fecha(_fecha)}'),
              onPressed: () async {
                final f = await showDatePicker(
                    context: context,
                    initialDate: _fecha,
                    firstDate: DateTime(2020),
                    lastDate: DateTime.now());
                if (f != null) setState(() => _fecha = f);
              },
            ),
            const SizedBox(height: 8),
            if (financiado <= 0 && _totalValor > 0)
              const Card(
                child: Padding(
                  padding: EdgeInsets.all(12),
                  child: Text('Venta de contado: no queda saldo pendiente.'),
                ),
              )
            else if (_enCuotas) ...[
              Text('Cuotas', style: Theme.of(context).textTheme.titleSmall),
              const SizedBox(height: 8),
              SegmentedButton<Frecuencia>(
                segments: [
                  for (final f in Frecuencia.values)
                    ButtonSegment(value: f, label: Text(f.texto)),
                ],
                selected: {_frecuencia},
                onSelectionChanged: (s) => setState(() => _frecuencia = s.first),
              ),
              TextFormField(
                controller: _numCuotas,
                decoration: const InputDecoration(labelText: 'Número de cuotas'),
                keyboardType: TextInputType.number,
                inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                validator: (_) =>
                    _n < 1 || _n > 60 ? 'Entre 1 y 60 cuotas' : null,
              ),
              TextButton.icon(
                icon: const Icon(Icons.event_repeat),
                label: Text('Primera cuota: ${fecha(_primera)}'),
                onPressed: () async {
                  final f = await showDatePicker(
                      context: context,
                      initialDate: _primera,
                      firstDate: _fecha,
                      lastDate: DateTime(_fecha.year + 3));
                  if (f != null) setState(() => _primerVencimiento = f);
                },
              ),
              for (final c in vistaPrevia)
                ListTile(
                  dense: true,
                  leading: Text('${c.numero}.'),
                  title: Text(fecha(c.vencimiento)),
                  trailing: Text(pesos(c.monto)),
                ),
            ] else
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(12),
                  child: Text(
                      '${widget.cliente.nombre} paga con abonos libres: debe '
                      'abonar algo al menos cada ${widget.cliente.plazoAbonoDias} días.'),
                ),
              ),
            const SizedBox(height: 24),
            FilledButton(onPressed: _guardar, child: const Text('Guardar venta')),
          ],
        ),
      ),
    );
  }

  Future<void> _guardar() async {
    if (!_form.currentState!.validate()) return;
    await context.read<Negocio>().registrarVenta(
          cliente: widget.cliente,
          descripcion: _descripcion.text.trim(),
          total: _totalValor,
          cuotaInicial: _inicialValor,
          numeroCuotas: _enCuotas ? _n : 1,
          frecuencia: _frecuencia,
          primerVencimiento: _enCuotas ? _primera : null,
          fecha: _fecha,
          items: List.of(_items),
        );
    if (mounted) Navigator.of(context).pop();
  }

  /// Productos del inventario incluidos en la venta; el total se calcula solo.
  Widget _productos(BuildContext context) {
    final negocio = context.watch<Negocio>();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        for (var i = 0; i < _items.length; i++)
          Row(children: [
            Expanded(
              child: Text(
                  '${_items[i].nombre}\n${pesos(_items[i].precioUnitario)} c/u'),
            ),
            IconButton(
              icon: const Icon(Icons.remove_circle_outline),
              tooltip: 'Quitar uno',
              onPressed: () => _cambiarCantidad(i, -1),
            ),
            Text('${_items[i].cantidad}'),
            IconButton(
              icon: const Icon(Icons.add_circle_outline),
              tooltip: 'Agregar uno',
              onPressed: (negocio.producto(_items[i].productoId)?.stock ?? 0) >
                      _items[i].cantidad
                  ? () => _cambiarCantidad(i, 1)
                  : null,
            ),
          ]),
        OutlinedButton.icon(
          icon: const Icon(Icons.inventory_2_outlined),
          label: Text(_items.isEmpty
              ? 'Elegir productos del inventario'
              : 'Agregar otro producto'),
          onPressed: () => _elegirProducto(negocio),
        ),
      ],
    );
  }

  void _cambiarCantidad(int i, int d) {
    setState(() {
      final it = _items[i];
      final n = it.cantidad + d;
      if (n <= 0) {
        _items.removeAt(i);
      } else {
        _items[i] = ItemVenta(
            productoId: it.productoId,
            nombre: it.nombre,
            cantidad: n,
            precioUnitario: it.precioUnitario);
      }
      _recalcular();
    });
  }

  void _recalcular() {
    if (_items.isEmpty) return;
    _total.text = '${_items.fold<int>(0, (s, it) => s + it.subtotal)}';
    _descripcion.text = _items
        .map((it) => it.cantidad > 1 ? '${it.cantidad} × ${it.nombre}' : it.nombre)
        .join(', ');
  }

  Future<void> _elegirProducto(Negocio negocio) async {
    final elegido = await showModalBottomSheet<Producto>(
      context: context,
      isScrollControlled: true,
      builder: (_) => _SelectorProducto(
          productos: negocio.productos
              .where((p) => !p.sinStock && !_items.any((it) => it.productoId == p.id))
              .toList()),
    );
    if (elegido == null) return;
    setState(() {
      _items.add(ItemVenta(
          productoId: elegido.id,
          nombre: elegido.nombre,
          cantidad: 1,
          precioUnitario: elegido.precioVenta));
      _recalcular();
    });
  }
}

class _SelectorProducto extends StatefulWidget {
  final List<Producto> productos;
  const _SelectorProducto({required this.productos});

  @override
  State<_SelectorProducto> createState() => _SelectorProductoState();
}

class _SelectorProductoState extends State<_SelectorProducto> {
  String _q = '';

  @override
  Widget build(BuildContext context) {
    final lista = widget.productos
        .where((p) => '${p.nombre} ${p.marca} ${p.color} ${p.talla} ${p.medida}'
            .toLowerCase()
            .contains(_q.toLowerCase()))
        .toList()
      ..sort((a, b) => a.nombre.compareTo(b.nombre));
    return SizedBox(
      height: MediaQuery.of(context).size.height * 0.75,
      child: Column(children: [
        Padding(
          padding: const EdgeInsets.all(16),
          child: TextField(
            autofocus: true,
            decoration: const InputDecoration(
                prefixIcon: Icon(Icons.search),
                hintText: 'Buscar producto con stock',
                border: OutlineInputBorder(),
                isDense: true),
            onChanged: (v) => setState(() => _q = v),
          ),
        ),
        Expanded(
          child: lista.isEmpty
              ? const Center(child: Text('No hay productos con stock'))
              : ListView(children: [
                  for (final p in lista)
                    ListTile(
                      title: Text(p.nombre),
                      subtitle: Text([p.marca, p.talla, p.medida, p.color]
                          .where((t) => t.isNotEmpty)
                          .join(' · ')),
                      trailing: Text('${pesos(p.precioVenta)}\n${p.stock} und.',
                          textAlign: TextAlign.end),
                      onTap: () => Navigator.pop(context, p),
                    ),
                ]),
        ),
      ]),
    );
  }
}
