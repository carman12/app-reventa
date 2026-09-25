import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:provider/provider.dart';

import 'datos/almacen.dart';
import 'datos/negocio.dart';
import 'pantallas/inicio.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await initializeDateFormatting('es_CO');
  final negocio = Negocio(AlmacenArchivo());
  await negocio.cargar();
  runApp(AppReventa(negocio: negocio));
}

class AppReventa extends StatelessWidget {
  final Negocio negocio;
  const AppReventa({super.key, required this.negocio});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider.value(
      value: negocio,
      child: MaterialApp(
        title: 'Mi Negocio',
        debugShowCheckedModeBanner: false,
        locale: const Locale('es', 'CO'),
        supportedLocales: const [Locale('es', 'CO')],
        localizationsDelegates: GlobalMaterialLocalizations.delegates,
        theme: ThemeData(
          colorSchemeSeed: const Color(0xFF00796B),
          useMaterial3: true,
        ),
        home: const Inicio(),
      ),
    );
  }
}
