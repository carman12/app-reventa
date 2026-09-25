import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../datos/fotos.dart';

/// Miniatura cuadrada de una foto, o un ícono si no hay foto.
class MiniaturaFoto extends StatelessWidget {
  final String? ref;
  final double tamano;
  const MiniaturaFoto(this.ref, {super.key, this.tamano = 48});

  @override
  Widget build(BuildContext context) {
    final esquema = Theme.of(context).colorScheme;
    return ClipRRect(
      borderRadius: BorderRadius.circular(8),
      child: SizedBox.square(
        dimension: tamano,
        child: ref == null
            ? ColoredBox(
                color: esquema.primaryContainer,
                child: Icon(Icons.photo_outlined,
                    color: esquema.onPrimaryContainer, size: tamano * 0.45),
              )
            : Image(
                image: context.read<AlmacenFotos>().imagen(ref!),
                fit: BoxFit.cover,
                gaplessPlayback: true,
              ),
      ),
    );
  }
}

/// Carrusel a pantalla completa: desliza entre fotos, pellizca o toca dos
/// veces para hacer zoom.
class VisorFotos extends StatefulWidget {
  final List<String> fotos;
  final int inicial;
  final String titulo;
  final String? detalle;
  final VoidCallback? alEditar;
  final VoidCallback? alVender;

  const VisorFotos({
    super.key,
    required this.fotos,
    this.inicial = 0,
    required this.titulo,
    this.detalle,
    this.alEditar,
    this.alVender,
  });

  static Future<void> abrir(BuildContext context,
          {required List<String> fotos,
          int inicial = 0,
          required String titulo,
          String? detalle,
          VoidCallback? alEditar,
          VoidCallback? alVender}) =>
      Navigator.of(context).push(MaterialPageRoute(
        builder: (_) => VisorFotos(
            fotos: fotos,
            inicial: inicial,
            titulo: titulo,
            detalle: detalle,
            alEditar: alEditar,
            alVender: alVender),
      ));

  @override
  State<VisorFotos> createState() => _VisorFotosState();
}

class _VisorFotosState extends State<VisorFotos> {
  late final _paginas = PageController(initialPage: widget.inicial);
  late int _actual = widget.inicial;
  bool _conZoom = false;

  @override
  Widget build(BuildContext context) {
    final almacen = context.read<AlmacenFotos>();
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: Text(widget.titulo),
        actions: [
          if (widget.alEditar != null)
            IconButton(
              icon: const Icon(Icons.edit),
              tooltip: 'Editar producto',
              onPressed: () {
                Navigator.of(context).pop();
                widget.alEditar!();
              },
            ),
        ],
      ),
      body: Column(
        children: [
          Expanded(
            child: PageView.builder(
              controller: _paginas,
              physics: _conZoom
                  ? const NeverScrollableScrollPhysics()
                  : const PageScrollPhysics(),
              itemCount: widget.fotos.length,
              onPageChanged: (i) => setState(() => _actual = i),
              itemBuilder: (_, i) => _FotoConZoom(
                imagen: almacen.imagen(widget.fotos[i]),
                alCambiarZoom: (z) => setState(() => _conZoom = z),
              ),
            ),
          ),
          if (widget.fotos.length > 1)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 12),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  for (var i = 0; i < widget.fotos.length; i++)
                    AnimatedContainer(
                      duration: const Duration(milliseconds: 200),
                      margin: const EdgeInsets.symmetric(horizontal: 3),
                      width: i == _actual ? 18 : 8,
                      height: 8,
                      decoration: BoxDecoration(
                        color: i == _actual ? Theme.of(context).colorScheme.primary : const Color(0xFFE4DDE1),
                        borderRadius: BorderRadius.circular(4),
                      ),
                    ),
                ],
              ),
            ),
          SafeArea(
            top: false,
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  if (widget.detalle != null)
                    Text(widget.detalle!,
                        textAlign: TextAlign.center,
                        style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
                  if (widget.alVender != null) ...[
                    const SizedBox(height: 12),
                    FilledButton.icon(
                      icon: const Icon(Icons.person_add_alt),
                      label: const Text('Vender a un cliente'),
                      onPressed: () {
                        Navigator.of(context).pop();
                        widget.alVender!();
                      },
                    ),
                  ],
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _FotoConZoom extends StatefulWidget {
  final ImageProvider imagen;
  final ValueChanged<bool> alCambiarZoom;
  const _FotoConZoom({required this.imagen, required this.alCambiarZoom});

  @override
  State<_FotoConZoom> createState() => _FotoConZoomState();
}

class _FotoConZoomState extends State<_FotoConZoom> {
  final _transformacion = TransformationController();
  TapDownDetails? _toque;

  void _avisarZoom() =>
      widget.alCambiarZoom(_transformacion.value.getMaxScaleOnAxis() > 1.01);

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onDoubleTapDown: (d) => _toque = d,
      onDoubleTap: () {
        if (_transformacion.value.getMaxScaleOnAxis() > 1.01) {
          _transformacion.value = Matrix4.identity();
        } else {
          final p = _toque?.localPosition ?? Offset.zero;
          _transformacion.value = Matrix4.identity()
            ..translateByDouble(-p.dx * 1.5, -p.dy * 1.5, 0, 1)
            ..scaleByDouble(2.5, 2.5, 1, 1);
        }
        _avisarZoom();
      },
      child: InteractiveViewer(
        transformationController: _transformacion,
        minScale: 1,
        maxScale: 5,
        onInteractionEnd: (_) => _avisarZoom(),
        child: Center(child: Image(image: widget.imagen, fit: BoxFit.contain)),
      ),
    );
  }
}
