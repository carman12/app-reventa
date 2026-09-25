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
                  labelText: 'Cuota inicial (lo que pagó hoy)', prefixText: r'$ '),
              keyboardType: TextInputType.number,
              inputFormatters: [FilteringTextInputFormatter.digitsOnly],
              validator: (_) => _inicialValor >= _totalValor && _totalValor > 0
                  ? 'Si pagó todo, no es venta a crédito'
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
            if (_enCuotas) ...[
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
        );
    if (mounted) Navigator.of(context).pop();
  }
}
