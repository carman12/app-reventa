import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

import '../datos/negocio.dart';
import '../modelos/modelos.dart';

class ClienteForm extends StatefulWidget {
  final Cliente? cliente;
  const ClienteForm({super.key, this.cliente});

  @override
  State<ClienteForm> createState() => _ClienteFormState();
}

class _ClienteFormState extends State<ClienteForm> {
  final _form = GlobalKey<FormState>();
  late final _nombre = TextEditingController(text: widget.cliente?.nombre);
  late final _telefono = TextEditingController(text: widget.cliente?.telefono);
  late final _sector = TextEditingController(text: widget.cliente?.sector);
  late final _direccion = TextEditingController(text: widget.cliente?.direccion);
  late final _notas = TextEditingController(text: widget.cliente?.notas);
  late final _plazo = TextEditingController(
      text: '${widget.cliente?.plazoAbonoDias ?? 15}');
  late FormaPago _forma = widget.cliente?.formaPago ?? FormaPago.cuotas;

  @override
  Widget build(BuildContext context) {
    final editando = widget.cliente != null;
    return Scaffold(
      appBar: AppBar(title: Text(editando ? 'Editar cliente' : 'Nuevo cliente')),
      body: Form(
        key: _form,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            TextFormField(
              controller: _nombre,
              decoration: const InputDecoration(labelText: 'Nombre *'),
              textCapitalization: TextCapitalization.words,
              validator: (v) =>
                  (v == null || v.trim().isEmpty) ? 'Escribe el nombre' : null,
            ),
            TextFormField(
              controller: _telefono,
              decoration: const InputDecoration(
                  labelText: 'Celular', hintText: '3001234567'),
              keyboardType: TextInputType.phone,
            ),
            TextFormField(
              controller: _sector,
              decoration: const InputDecoration(
                  labelText: 'Barrio o sector', hintText: 'Para filtrar y cobrar por zona'),
              textCapitalization: TextCapitalization.words,
            ),
            TextFormField(
              controller: _direccion,
              decoration: const InputDecoration(labelText: 'Dirección'),
            ),
            const SizedBox(height: 16),
            Text('¿Cómo paga?', style: Theme.of(context).textTheme.titleSmall),
            const SizedBox(height: 8),
            SegmentedButton<FormaPago>(
              segments: const [
                ButtonSegment(value: FormaPago.cuotas, label: Text('Cuotas fijas')),
                ButtonSegment(
                    value: FormaPago.abonosLibres, label: Text('Abonos libres')),
              ],
              selected: {_forma},
              onSelectionChanged: (s) => setState(() => _forma = s.first),
            ),
            if (_forma == FormaPago.abonosLibres)
              TextFormField(
                controller: _plazo,
                decoration: const InputDecoration(
                  labelText: 'Días máximos entre abonos',
                  helperText: 'Si pasa este tiempo sin abonar, queda moroso',
                ),
                keyboardType: TextInputType.number,
                inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                validator: (v) => (int.tryParse(v ?? '') ?? 0) < 1
                    ? 'Escribe un número de días'
                    : null,
              ),
            TextFormField(
              controller: _notas,
              decoration: const InputDecoration(labelText: 'Notas'),
              maxLines: 3,
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
    final c = Cliente(
      id: widget.cliente?.id ?? '',
      nombre: _nombre.text.trim(),
      telefono: _telefono.text.trim(),
      sector: _sector.text.trim(),
      direccion: _direccion.text.trim(),
      notas: _notas.text.trim(),
      formaPago: _forma,
      plazoAbonoDias: int.tryParse(_plazo.text) ?? 15,
    );
    await context.read<Negocio>().guardarCliente(c);
    if (mounted) Navigator.of(context).pop();
  }
}
