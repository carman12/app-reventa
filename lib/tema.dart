import 'package:flutter/material.dart';

/// Paleta de Mi Negocio: frambuesa como color principal y coral de acento.
const frambuesa = Color(0xFFD6336C);
const coral = Color(0xFFFF7A59);

ThemeData temaMiNegocio() {
  final base = ColorScheme.fromSeed(
    seedColor: frambuesa,
    dynamicSchemeVariant: DynamicSchemeVariant.vibrant,
  );
  final scheme = base.copyWith(
    primary: frambuesa,
    onPrimary: Colors.white,
    tertiary: coral,
    tertiaryContainer: const Color(0xFFFFE0D6),
    onTertiaryContainer: const Color(0xFF6B1F0C),
  );
  return ThemeData(
    colorScheme: scheme,
    useMaterial3: true,
    appBarTheme: AppBarTheme(
      backgroundColor: scheme.primary,
      foregroundColor: scheme.onPrimary,
      iconTheme: IconThemeData(color: scheme.onPrimary),
      actionsIconTheme: IconThemeData(color: scheme.onPrimary),
    ),
    tabBarTheme: TabBarThemeData(
      labelColor: scheme.onPrimary,
      unselectedLabelColor: scheme.onPrimary.withValues(alpha: 0.75),
      indicatorColor: scheme.onPrimary,
      dividerColor: Colors.transparent,
    ),
    floatingActionButtonTheme: FloatingActionButtonThemeData(
      backgroundColor: scheme.tertiary,
      foregroundColor: Colors.white,
    ),
    navigationBarTheme: NavigationBarThemeData(
      indicatorColor: scheme.primaryContainer,
    ),
    chipTheme: ChipThemeData(
      selectedColor: scheme.primaryContainer,
    ),
  );
}
