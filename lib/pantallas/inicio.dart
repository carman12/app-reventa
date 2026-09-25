import 'package:flutter/material.dart';

import 'clientes.dart';
import 'finanzas.dart';
import 'inventario.dart';
import 'morosos.dart';
import 'resumen.dart';

class Inicio extends StatefulWidget {
  const Inicio({super.key});

  @override
  State<Inicio> createState() => _InicioState();
}

class _InicioState extends State<Inicio> {
  int _pestana = 0;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: IndexedStack(
        index: _pestana,
        children: [
          Resumen(irA: (i) => setState(() => _pestana = i)),
          const Clientes(),
          const Morosos(),
          const Inventario(),
          const Finanzas(),
        ],
      ),
      bottomNavigationBar: NavigationBar(
        height: 68,
        selectedIndex: _pestana,
        onDestinationSelected: (i) => setState(() => _pestana = i),
        destinations: const [
          NavigationDestination(icon: Icon(Icons.home_outlined), label: 'Inicio'),
          NavigationDestination(icon: Icon(Icons.people_outline), label: 'Clientes'),
          NavigationDestination(
              icon: Icon(Icons.warning_amber_outlined), label: 'Morosos'),
          NavigationDestination(
              icon: Icon(Icons.inventory_2_outlined), label: 'Inventario'),
          NavigationDestination(
              icon: Icon(Icons.account_balance_wallet_outlined), label: 'Finanzas'),
        ],
      ),
    );
  }
}
