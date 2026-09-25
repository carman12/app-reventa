import 'package:app_reventa/tema.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('los filtros se leen seleccionados y sin seleccionar',
      (tester) async {
    await tester.pumpWidget(MaterialApp(
      theme: temaMiNegocio(),
      home: Scaffold(
        body: Row(children: [
          ChoiceChip(label: const Text('Todas'), selected: true, onSelected: (_) {}),
          ChoiceChip(label: const Text('Zapatos'), selected: false, onSelected: (_) {}),
          ActionChip(label: const Text('Sección'), onPressed: () {}),
        ]),
      ),
    ));
    Color? color(String t) =>
        tester.widget<RichText>(find.descendant(of: find.text(t), matching: find.byType(RichText)).first)
            .text
            .style
            ?.color;
    // RichText dentro de Text hereda el DefaultTextStyle del chip.
    Color? efectivo(String t) {
      final el = tester.element(find.text(t));
      return color(t) ?? DefaultTextStyle.of(el).style.color;
    }

    expect(efectivo('Todas'), Colors.white);
    expect(efectivo('Zapatos'), tinta);
    expect(efectivo('Sección'), tinta);
  });
}
