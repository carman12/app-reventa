import 'package:flutter/material.dart';

/// Estilo catálogo de moda: fondo blanco, tinta casi negra, frambuesa de
/// acento y paneles rosa suave.
const frambuesa = Color(0xFFD6336C);
const coral = Color(0xFFFF7A59);
const tinta = Color(0xFF1D1B20);
const rosaSuave = Color(0xFFFCE8EF);
const grisSuave = Color(0xFFF5F2F4);
const bordeSuave = Color(0xFFE4DDE1);

ThemeData temaMiNegocio() {
  final base = ColorScheme.fromSeed(
    seedColor: frambuesa,
    dynamicSchemeVariant: DynamicSchemeVariant.vibrant,
  );
  final scheme = base.copyWith(
    primary: frambuesa,
    onPrimary: Colors.white,
    primaryContainer: rosaSuave,
    onPrimaryContainer: const Color(0xFF7A1238),
    tertiary: coral,
    tertiaryContainer: const Color(0xFFFFE6DC),
    onTertiaryContainer: const Color(0xFF6B1F0C),
    surface: Colors.white,
    onSurface: tinta,
  );
  const pildora = StadiumBorder();
  return ThemeData(
    colorScheme: scheme,
    useMaterial3: true,
    scaffoldBackgroundColor: Colors.white,
    appBarTheme: const AppBarTheme(
      backgroundColor: Colors.white,
      foregroundColor: tinta,
      surfaceTintColor: Colors.transparent,
      scrolledUnderElevation: 0,
      titleTextStyle: TextStyle(
          color: tinta, fontSize: 24, fontWeight: FontWeight.w800, letterSpacing: -0.3),
    ),
    tabBarTheme: const TabBarThemeData(
      labelColor: tinta,
      unselectedLabelColor: Color(0xFF7B7479),
      indicatorColor: frambuesa,
      labelStyle: TextStyle(fontWeight: FontWeight.w700),
      dividerColor: bordeSuave,
    ),
    chipTheme: ChipThemeData(
      shape: pildora,
      side: const BorderSide(color: bordeSuave),
      backgroundColor: Colors.white,
      selectedColor: tinta,
      showCheckmark: false,
      labelStyle: WidgetStateTextStyle.resolveWith((s) => s.contains(WidgetState.selected)
          ? const TextStyle(color: Colors.white, fontWeight: FontWeight.w600)
          : const TextStyle(color: tinta, fontWeight: FontWeight.w500)),
      secondaryLabelStyle:
          const TextStyle(color: Colors.white, fontWeight: FontWeight.w600),
      padding: const EdgeInsets.symmetric(horizontal: 6),
    ),
    segmentedButtonTheme: SegmentedButtonThemeData(
      style: ButtonStyle(
        shape: const WidgetStatePropertyAll(pildora),
        side: const WidgetStatePropertyAll(BorderSide(color: tinta)),
        backgroundColor: WidgetStateProperty.resolveWith(
            (s) => s.contains(WidgetState.selected) ? tinta : Colors.white),
        foregroundColor: WidgetStateProperty.resolveWith(
            (s) => s.contains(WidgetState.selected) ? Colors.white : tinta),
        iconColor: const WidgetStatePropertyAll(Colors.white),
      ),
    ),
    floatingActionButtonTheme: const FloatingActionButtonThemeData(
      backgroundColor: tinta,
      foregroundColor: Colors.white,
      shape: pildora,
      elevation: 2,
    ),
    filledButtonTheme: FilledButtonThemeData(
      style: FilledButton.styleFrom(
          shape: pildora, padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 20)),
    ),
    outlinedButtonTheme: OutlinedButtonThemeData(
      style: OutlinedButton.styleFrom(
          shape: pildora, foregroundColor: tinta, side: const BorderSide(color: tinta)),
    ),
    cardTheme: CardThemeData(
      color: grisSuave,
      elevation: 0,
      margin: const EdgeInsets.symmetric(vertical: 4),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
    ),
    inputDecorationTheme: const InputDecorationTheme(
      focusedBorder:
          UnderlineInputBorder(borderSide: BorderSide(color: frambuesa, width: 2)),
      enabledBorder: UnderlineInputBorder(borderSide: BorderSide(color: bordeSuave)),
    ),
    navigationBarTheme: NavigationBarThemeData(
      backgroundColor: Colors.white,
      surfaceTintColor: Colors.transparent,
      indicatorColor: rosaSuave,
      elevation: 0,
      labelTextStyle: WidgetStateProperty.resolveWith((s) => TextStyle(
          fontSize: 12,
          color: tinta,
          fontWeight: s.contains(WidgetState.selected) ? FontWeight.w700 : FontWeight.w400)),
    ),
    dividerTheme: const DividerThemeData(color: bordeSuave),
  );
}

/// Decoración de las barras de búsqueda: píldora gris suave.
InputDecoration decoracionBusqueda(String pista) => InputDecoration(
      prefixIcon: const Icon(Icons.search),
      hintText: pista,
      isDense: true,
      filled: true,
      fillColor: grisSuave,
      border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(30), borderSide: BorderSide.none),
      enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(30), borderSide: BorderSide.none),
      focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(30),
          borderSide: const BorderSide(color: frambuesa)),
    );
