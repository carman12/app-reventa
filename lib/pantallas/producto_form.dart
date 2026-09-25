import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';

import '../datos/fotos.dart';
import '../datos/negocio.dart';
import '../formato.dart';
import '../modelos/modelos.dart';
import 'cliente_detalle.dart' show confirmar;
import 'vender_producto.dart';
import 'visor_fotos.dart';

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
  late final List<String> _fotos = [...?p?.fotos];

  /// Fotos agregadas en esta edición: si no se guarda, se borran.
  final List<String> _nuevas = [];

  /// Fotos quitadas en esta edición: se borran solo al guardar.
  final List<String> _quitadas = [];
  bool _guardado = false;
  bool _cargandoFoto = false;

  late AlmacenFotos _almacen;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _almacen = context.read<AlmacenFotos>();
  }

  @override
  void dispose() {
    if (!_guardado) {
      for (final f in _nuevas) {
        _almacen.borrar(f);
      }
    }
    super.dispose();
  }

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
                  for (final f in [...await negocio.eliminarProducto(p!.id), ..._nuevas]) {
                    await _almacen.borrar(f);
                  }
                  _guardado = true;
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
            _seccionFotos(context),
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
            if (p != null) ...[
              const SizedBox(height: 8),
              OutlinedButton.icon(
                icon: const Icon(Icons.person_add_alt),
                label: const Text('Vender a un cliente'),
                onPressed: () => venderProducto(context, negocio.producto(p!.id) ?? p!),
              ),
              const SizedBox(height: 24),
              CompradoresProducto(productoId: p!.id),
            ],
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
          fotos: List.of(_fotos),
        ));
    _guardado = true;
    for (final f in _quitadas) {
      await _almacen.borrar(f);
    }
    if (mounted) Navigator.of(context).pop();
  }

  Widget _seccionFotos(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: SizedBox(
        height: 104,
        child: ListView(
          scrollDirection: Axis.horizontal,
          children: [
            for (var i = 0; i < _fotos.length; i++)
              Padding(
                padding: const EdgeInsets.only(right: 8),
                child: Stack(children: [
                  GestureDetector(
                    onTap: () => VisorFotos.abrir(context,
                        fotos: List.of(_fotos),
                        inicial: i,
                        titulo: _nombre.text.isEmpty ? 'Fotos' : _nombre.text),
                    child: MiniaturaFoto(_fotos[i], tamano: 96),
                  ),
                  Positioned(
                    top: 2,
                    right: 2,
                    child: InkWell(
                      onTap: () => setState(() {
                        final f = _fotos.removeAt(i);
                        _nuevas.contains(f) ? _nuevas.remove(f) : _quitadas.add(f);
                        if (!_quitadas.contains(f)) {
                          _almacen.borrar(f);
                        }
                      }),
                      child: const CircleAvatar(
                        radius: 12,
                        backgroundColor: Colors.black54,
                        child: Icon(Icons.close, size: 16, color: Colors.white),
                      ),
                    ),
                  ),
                  if (i == 0)
                    Positioned(
                      left: 4,
                      bottom: 4,
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                            color: Colors.black54,
                            borderRadius: BorderRadius.circular(6)),
                        child: const Text('Portada',
                            style: TextStyle(color: Colors.white, fontSize: 11)),
                      ),
                    ),
                ]),
              ),
            if (_cargandoFoto)
              const SizedBox(
                  width: 96, child: Center(child: CircularProgressIndicator())),
            if (!kIsWeb)
              _BotonFoto(
                icono: Icons.photo_camera_outlined,
                texto: 'Tomar foto',
                alTocar: () => _agregar(ImageSource.camera),
              ),
            _BotonFoto(
              icono: Icons.photo_library_outlined,
              texto: 'Galería',
              alTocar: () => _agregar(ImageSource.gallery),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _agregar(ImageSource origen) async {
    final picker = ImagePicker();
    final List<XFile> archivos;
    try {
      archivos = origen == ImageSource.camera
          ? [
              ?await picker.pickImage(
                  source: origen, maxWidth: 1600, imageQuality: 80)
            ]
          : await picker.pickMultiImage(maxWidth: 1600, imageQuality: 80);
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
            content: Text('No se pudo abrir la cámara o la galería. '
                'Revisa los permisos de la app.')));
      }
      return;
    }
    if (archivos.isEmpty) return;
    setState(() => _cargandoFoto = true);
    for (final a in archivos) {
      final ref = await _almacen.guardar(await a.readAsBytes());
      _fotos.add(ref);
      _nuevas.add(ref);
    }
    if (mounted) setState(() => _cargandoFoto = false);
  }
}

class _BotonFoto extends StatelessWidget {
  final IconData icono;
  final String texto;
  final VoidCallback alTocar;
  const _BotonFoto({required this.icono, required this.texto, required this.alTocar});

  @override
  Widget build(BuildContext context) {
    final esquema = Theme.of(context).colorScheme;
    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: InkWell(
        onTap: alTocar,
        borderRadius: BorderRadius.circular(8),
        child: Container(
          width: 96,
          decoration: BoxDecoration(
            border: Border.all(color: esquema.primary),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icono, color: esquema.primary),
              const SizedBox(height: 4),
              Text(texto, style: TextStyle(color: esquema.primary, fontSize: 12)),
            ],
          ),
        ),
      ),
    );
  }
}
