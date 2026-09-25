import 'package:app_reventa/datos/almacen.dart';
import 'package:app_reventa/datos/fotos.dart';
import 'package:app_reventa/datos/negocio.dart';
import 'package:app_reventa/main.dart';
import 'package:app_reventa/modelos/modelos.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:intl/date_symbol_data_local.dart';

void main() {
  testWidgets('muestra un cliente moroso en la pestaña Morosos', (t) async {
    await initializeDateFormatting('es_CO');
    final n = Negocio(AlmacenMemoria(), ahora: () => DateTime(2026, 9, 25));
    await n.cargar();
    final c = await n.guardarCliente(const Cliente(id: '', nombre: 'Doris'));
    await n.registrarVenta(
      cliente: c,
      descripcion: 'Tenis',
      total: 90000,
      numeroCuotas: 2,
      fecha: DateTime(2026, 8, 1),
      primerVencimiento: DateTime(2026, 8, 15),
    );

    await t.pumpWidget(AppReventa(negocio: n, fotos: FotosMemoria()));
    expect(find.text('1 cliente moroso'), findsOneWidget);

    await t.tap(find.text('Morosos').last);
    await t.pumpAndSettle();
    expect(find.text('Doris'), findsOneWidget);
    expect(find.text('Moroso · 41 d'), findsOneWidget);
  });
}
