import 'package:app_reventa/formato.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:intl/date_symbol_data_local.dart';

void main() {
  setUpAll(() => initializeDateFormatting('es_CO'));

  test('pesos colombianos sin decimales', () {
    expect(pesos(150000), '\$\u00a0150.000');
    expect(pesos(1250000), '\$\u00a01.250.000');
  });

  test('lee valores escritos con puntos', () {
    expect(leerPesos('150.000'), 150000);
    expect(leerPesos(''), isNull);
  });

  formatoMilesTests();
}

TextEditingValue _escribir(String texto, [int? cursor]) => const FormatoMiles()
    .formatEditUpdate(
        TextEditingValue.empty,
        TextEditingValue(
            text: texto,
            selection: TextSelection.collapsed(offset: cursor ?? texto.length)));

void formatoMilesTests() {
  test('pone puntos de miles mientras se escribe', () {
    expect(_escribir('1').text, '1');
    expect(_escribir('1500').text, '1.500');
    expect(_escribir('150000').text, '150.000');
    expect(_escribir('1250000').text, '1.250.000');
    expect(_escribir('').text, '');
    expect(_escribir('12a3').text, '123');
  });

  test('al borrar un punto se reacomoda y el cursor queda en su dígito', () {
    // "1.500" → el usuario borra el "5": queda "1.00" → "100".
    final v = _escribir('1.00', 2);
    expect(v.text, '100');
    expect(v.selection.end, 1);
    // Cursor al final al escribir normal.
    expect(_escribir('15000').selection.end, '15.000'.length);
  });
}
