import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:provider/provider.dart';

import 'datos/almacen.dart';
import 'datos/fotos.dart';
import 'datos/negocio.dart';
import 'pantallas/inicio.dart';
import 'tema.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await initializeDateFormatting('es_CO');
  final negocio = Negocio(kIsWeb ? AlmacenMemoria() : AlmacenArchivo());
  await negocio.cargar();
  final AlmacenFotos fotos;
  if (kIsWeb) {
    fotos = FotosMemoria();
  } else {
    fotos = FotosArchivo();
    await (fotos as FotosArchivo).preparar();
  }
  runApp(AppReventa(negocio: negocio, fotos: fotos));
}

class AppReventa extends StatelessWidget {
  final Negocio negocio;
  final AlmacenFotos fotos;
  const AppReventa({super.key, required this.negocio, required this.fotos});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider.value(value: negocio),
        Provider.value(value: fotos),
      ],
      child: MaterialApp(
        title: 'Mi Negocio',
        debugShowCheckedModeBanner: false,
        locale: const Locale('es', 'CO'),
        supportedLocales: const [Locale('es', 'CO')],
        localizationsDelegates: GlobalMaterialLocalizations.delegates,
        theme: temaMiNegocio(),
        home: const Inicio(),
      ),
    );
  }
}
