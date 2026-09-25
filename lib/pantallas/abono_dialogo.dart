import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../datos/negocio.dart';
import '../formato.dart';
import '../logica/cobranza.dart';

const mediosDePago = ['Efectivo', 'Nequi', 'Daviplata', 'Transferencia'];

Future<void> mostrarAbono(BuildContext context, ResumenVenta r) {
  // Sugiere lo que falta de la próxima cuota, o el saldo si es abono libre.
  final siguiente = r.cuotas.where((c) => !c.pagada).firstOrNull;
  final sugerido = siguiente?.pendiente ?? r.saldo;
  final monto = TextEditingController(text: miles(sugerido));
  var medio = mediosDePago.first;
  var dia = context.read<Negocio>().hoy;

  return showDialog(
    context: context,
    builder: (c) => StatefulBuilder(
      builder: (c, setState) {
        final valor = leerPesos(monto.text) ?? 0;
        final error = valor <= 0
            ? 'Escribe el valor'
            : valor > r.saldo
                ? 'Supera el saldo (${pesos(r.saldo)})'
                : null;
        return AlertDialog(
          title: const Text('Registrar abono'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Saldo: ${pesos(r.saldo)}'),
              TextField(
                controller: monto,
                autofocus: true,
                keyboardType: TextInputType.number,
                inputFormatters: const [FormatoMiles()],
                decoration: InputDecoration(
                    labelText: 'Valor', prefixText: r'$ ', errorText: error),
                onChanged: (_) => setState(() {}),
              ),
              DropdownButtonFormField<String>(
                initialValue: medio,
                decoration: const InputDecoration(labelText: 'Medio de pago'),
                items: [
                  for (final m in mediosDePago)
                    DropdownMenuItem(value: m, child: Text(m)),
                ],
                onChanged: (m) => medio = m ?? medio,
              ),
              TextButton.icon(
                icon: const Icon(Icons.event),
                label: Text('Fecha: ${fecha(dia)}'),
                onPressed: () async {
                  final f = await showDatePicker(
                    context: c,
                    initialDate: dia,
                    firstDate: DateTime(2020),
                    lastDate: DateTime.now(),
                  );
                  if (f != null) setState(() => dia = f);
                },
              ),
            ],
          ),
          actions: [
            TextButton(
                onPressed: () => Navigator.pop(c), child: const Text('Cancelar')),
            FilledButton(
              onPressed: error != null
                  ? null
                  : () async {
                      await context.read<Negocio>().registrarAbono(
                          ventaId: r.venta.id,
                          monto: valor,
                          medio: medio,
                          fecha: dia);
                      if (c.mounted) Navigator.pop(c);
                    },
              child: const Text('Guardar'),
            ),
          ],
        );
      },
    ),
  );
}
