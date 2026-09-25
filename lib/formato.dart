import 'package:intl/intl.dart';

final _pesos = NumberFormat.currency(
    locale: 'es_CO', symbol: r'$', decimalDigits: 0, customPattern: '¤ #,##0');
final _fecha = DateFormat('d MMM yyyy', 'es_CO');

/// Formato de pesos colombianos: $ 150.000
String pesos(int valor) => _pesos.format(valor).replaceAll(' ', ' ');

String fecha(DateTime d) => _fecha.format(d);

/// Convierte "150.000" o "150000" en 150000.
int? leerPesos(String texto) {
  final limpio = texto.replaceAll(RegExp(r'[^0-9]'), '');
  return limpio.isEmpty ? null : int.parse(limpio);
}
