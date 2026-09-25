import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

import '../formato.dart';
import '../logica/cobranza.dart';
import '../modelos/modelos.dart';

Color colorEstado(EstadoCliente e) => switch (e) {
      EstadoCliente.alDia => Colors.green.shade700,
      EstadoCliente.porVencer => Colors.orange.shade800,
      EstadoCliente.moroso => Colors.red.shade700,
    };

class EtiquetaEstado extends StatelessWidget {
  final EstadoCliente estado;
  final int diasAtraso;
  const EtiquetaEstado(this.estado, {super.key, this.diasAtraso = 0});

  @override
  Widget build(BuildContext context) {
    final color = colorEstado(estado);
    final texto = estado == EstadoCliente.moroso && diasAtraso > 0
        ? 'Moroso · $diasAtraso d'
        : estado.texto;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(texto,
          style: TextStyle(color: color, fontWeight: FontWeight.w600, fontSize: 12)),
    );
  }
}

/// Abre WhatsApp con un recordatorio del saldo pendiente.
Future<void> recordarPorWhatsApp(BuildContext context, ResumenCliente r) async {
  final tel = r.cliente.telefono.replaceAll(RegExp(r'[^0-9]'), '');
  if (tel.isEmpty) {
    ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Este cliente no tiene teléfono')));
    return;
  }
  final numero = tel.length == 10 ? '57$tel' : tel;
  final vencido = r.montoVencido > 0
      ? ' De ese valor, ${pesos(r.montoVencido)} ya está vencido.'
      : '';
  final mensaje = 'Hola ${r.cliente.nombre}, te recordamos que tu saldo '
      'pendiente es de ${pesos(r.saldo)}.$vencido ¡Gracias!';
  final ok = await launchUrl(
    Uri.parse('https://wa.me/$numero?text=${Uri.encodeComponent(mensaje)}'),
    mode: LaunchMode.externalApplication,
  );
  if (!ok && context.mounted) {
    ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('No se pudo abrir WhatsApp')));
  }
}
