import 'package:flutter/services.dart';
import 'package:intl/intl.dart';

final _pesos = NumberFormat.currency(
    locale: 'es_CO', symbol: r'$', decimalDigits: 0, customPattern: '¤ #,##0');
final _miles = NumberFormat('#,##0', 'es_CO');
final _fecha = DateFormat('d MMM yyyy', 'es_CO');

/// Formato de pesos colombianos: $ 150.000 (el espacio no se parte).
String pesos(int valor) =>
    _pesos.format(valor).replaceAll(RegExp(r'\s'), ' ');

/// Número con puntos de miles, sin signo: 150000 → "150.000".
String miles(int valor) => _miles.format(valor);

String fecha(DateTime d) => _fecha.format(d);

/// Convierte "150.000" o "150000" en 150000.
int? leerPesos(String texto) {
  final limpio = texto.replaceAll(RegExp(r'[^0-9]'), '');
  return limpio.isEmpty ? null : int.parse(limpio);
}

/// Pone los puntos de miles mientras se escribe un valor en pesos.
/// Solo acepta dígitos y deja el cursor en el mismo dígito donde estaba.
class FormatoMiles extends TextInputFormatter {
  const FormatoMiles();

  @override
  TextEditingValue formatEditUpdate(
      TextEditingValue anterior, TextEditingValue nuevo) {
    final digitos = nuevo.text.replaceAll(RegExp(r'[^0-9]'), '');
    if (digitos.isEmpty) return const TextEditingValue();
    // Máximo 15 dígitos para no desbordar el entero.
    final recortado = digitos.length > 15 ? digitos.substring(0, 15) : digitos;
    final texto = miles(int.parse(recortado));

    // Cuántos dígitos quedaban a la derecha del cursor.
    final cursor = nuevo.selection.end.clamp(0, nuevo.text.length);
    final aLaDerecha =
        nuevo.text.substring(cursor).replaceAll(RegExp(r'[^0-9]'), '').length;
    var pos = texto.length;
    for (var vistos = 0; pos > 0 && vistos < aLaDerecha; pos--) {
      if (RegExp(r'[0-9]').hasMatch(texto[pos - 1])) vistos++;
    }
    return TextEditingValue(
        text: texto, selection: TextSelection.collapsed(offset: pos));
  }
}

/// Texto inicial de un campo de pesos: vacío si no hay valor.
String textoPesos(int? valor) => valor == null ? '' : miles(valor);
