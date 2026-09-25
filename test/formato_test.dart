import 'package:app_reventa/formato.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:intl/date_symbol_data_local.dart';

void main() {
  setUpAll(() => initializeDateFormatting('es_CO'));

  test('pesos colombianos sin decimales', () {
    expect(pesos(150000), r'$ 150.000');
    expect(pesos(1250000), r'$ 1.250.000');
  });

  test('lee valores escritos con puntos', () {
    expect(leerPesos('150.000'), 150000);
    expect(leerPesos(''), isNull);
  });
}
