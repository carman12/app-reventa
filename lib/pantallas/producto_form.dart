import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

import '../datos/negocio.dart';
import '../formato.dart';
import '../modelos/modelos.dart';
import 'cliente_detalle.dart' show confirmar;

class ProductoForm extends StatefulWidget {
  final Producto? producto;
  final String? seccionInicial;
  const ProductoForm({super.key, this.producto, this.seccionInicial});

  @override
  State<ProductoForm> createState() => _ProductoFormState();
}

class _ProductoFormState extends State<ProductoForm> {
  final _form = GlobalKey<FormState>();
  late final p = widget.producto;
  late final _nombre = TextEditingController(text: p?.nombre);
  late final _marca = TextEditingController(text: p?.marca);
  late final _talla = TextEditingController(text: p?.talla);
  late final _medida = TextEditingController(text: p?.medida);
  late final _color = TextEditingController(text: p?.color);
  late final _material = TextEditingController(text: p?.material);
  late final _proveedor = TextEditingController(text: p?.proveedor);
  late final _compra = TextEditingController(text: _num(p?.precioCompra));
  late final _venta = TextEditingController(text: _num(p?.precioVenta));
  late final _stock = TextEditingController(text: '${p?.stock ?? 1}');
  late final _minimo = TextEditingController(text: '${p?.stockMinimo ?? 1}');
  String? _seccionId;

  static String _num(int? v) => v == null || v == 0 ? '' : '$v';

  @override
  Widget build(BuildContext context) {
    final negocio = context.watch<Negocio>();
    final secciones = negocio.secciones;
    _seccionId ??= p?.seccionId ??
        widget.seccionInicial ??
        (secciones.isEmpty ? null : secciones.first.id);
    final compra = leerPesos(_compra.text) ?? 0;
    final venta = leerPesos(_venta.text) ?? 0;

    Widget texto(TextEditingController c, String etiqueta, {String? pista}) =>
        TextFormField(
          controller: c,
          decoration: InputDecoration(labelText: etiqueta, hintText: pista),
          textCapitalization: TextCapitalization.sentences,
        );

    Widget numero(TextEditingController c, String etiqueta,
            {bool dinero = false, String? Function(String?)? validar}) =>
        TextFormField(
          controller: c,
          decoration: InputDecoration(
              labelText: etiqueta, prefixText: dinero ? r'$ ' : null),
          keyboardType: TextInputType.number,
          inputFormatters: [FilteringTextInputFormatter.digitsOnly],
          validator: validar,
          onChanged: (_) => setState(() {}),
        );

    return Scaffold(
      appBar: AppBar(
        title: Text(p == null ? 'Nuevo producto' : 'Editar producto'),
        actions: [
          if (p != null)
            IconButton(
              icon: const Icon(Icons.delete_outline),
              tooltip: 'Eliminar producto',
              onPressed: () async {
                if (await confirmar(context, '¿Eliminar ${p!.nombre}?')) {
                  await negocio.eliminarProducto(p!.id);
                  if (context.mounted) Navigator.of(context).pop();
                }
              },
            ),
        ],
      ),
      body: Form(
        key: _form,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            DropdownButtonFormField<String>(
              initialValue: _seccionId,
              decoration: const InputDecoration(labelText: 'Sección *'),
              items: [
                for (final s in secciones)
                  DropdownMenuItem(value: s.id, child: Text(s.nombre)),
              ],
              onChanged: (v) => setState(() => _seccionId = v),
              validator: (v) => v == null ? 'Elige una sección' : null,
            ),
            TextFormField(
              controller: _nombre,
              decoration: const InputDecoration(
                  labelText: 'Nombre *', hintText: 'Ej.: Juego de sábanas estampado'),
              textCapitalization: TextCapitalization.sentences,
              validator: (v) =>
                  (v == null || v.trim().isEmpty) ? 'Escribe el nombre' : null,
            ),
            texto(_marca, 'Marca'),
            Row(children: [
              Expanded(child: texto(_talla, 'Talla', pista: '38, M…')),
              const SizedBox(width: 12),
              Expanded(child: texto(_medida, 'Medida', pista: 'Doble, Queen…')),
            ]),
            Row(children: [
              Expanded(child: texto(_color, 'Color')),
              const SizedBox(width: 12),
              Expanded(child: texto(_material, 'Material')),
            ]),
            texto(_proveedor, 'Proveedor'),
            Row(children: [
              Expanded(child: numero(_compra, 'Precio de compra', dinero: true)),
              const SizedBox(width: 12),
              Expanded(
                child: numero(_venta, 'Precio de venta *',
                    dinero: true,
                    validar: (_) =>
                        (leerPesos(_venta.text) ?? 0) <= 0 ? 'Escribe el precio' : null),
              ),
            ]),
            if (compra > 0 && venta > 0)
              Padding(
                padding: const EdgeInsets.only(top: 8),
                child: Text(
                  'Ganancia por unidad: ${pesos(venta - compra)}'
                  '${venta > compra ? ' (${((venta - compra) * 100 / compra).round()}%)' : ''}',
                  style: TextStyle(
                      color: venta >= compra ? Colors.green.shade700 : Colors.red.shade700),
                ),
              ),
            const SizedBox(height: 8),
            Row(children: [
              IconButton.filledTonal(
                icon: const Icon(Icons.remove),
                tooltip: 'Quitar uno',
                onPressed: () => setState(() {
                  final n = (int.tryParse(_stock.text) ?? 0) - 1;
                  _stock.text = '${n < 0 ? 0 : n}';
                }),
              ),
              const SizedBox(width: 8),
              Expanded(child: numero(_stock, 'Unidades en stock')),
              const SizedBox(width: 8),
              IconButton.filledTonal(
                icon: const Icon(Icons.add),
                tooltip: 'Agregar uno',
                onPressed: () => setState(() =>
                    _stock.text = '${(int.tryParse(_stock.text) ?? 0) + 1}'),
              ),
            ]),
            TextFormField(
              controller: _minimo,
              decoration: const InputDecoration(
                labelText: 'Avisar stock bajo desde',
                helperText: 'Se marca "stock bajo" con esta cantidad o menos',
              ),
              keyboardType: TextInputType.number,
              inputFormatters: [FilteringTextInputFormatter.digitsOnly],
            ),
            const SizedBox(height: 24),
            FilledButton(onPressed: _guardar, child: const Text('Guardar')),
          ],
        ),
      ),
    );
  }

  Future<void> _guardar() async {
    if (!_form.currentState!.validate()) return;
    await context.read<Negocio>().guardarProducto(Producto(
          id: p?.id ?? '',
          seccionId: _seccionId!,
          nombre: _nombre.text.trim(),
          marca: _marca.text.trim(),
          talla: _talla.text.trim(),
          medida: _medida.text.trim(),
          color: _color.text.trim(),
          material: _material.text.trim(),
          proveedor: _proveedor.text.trim(),
          precioCompra: leerPesos(_compra.text) ?? 0,
          precioVenta: leerPesos(_venta.text) ?? 0,
          stock: int.tryParse(_stock.text) ?? 0,
          stockMinimo: int.tryParse(_minimo.text) ?? 1,
        ));
    if (mounted) Navigator.of(context).pop();
  }
}
