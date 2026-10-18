
import 'package:flutter/material.dart';

import '../services/auth_service.dart';
import 'categorias_screen.dart';
import 'productos_screen.dart';
import 'proveedores_screen.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final authService = AuthService();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Gestión Comercial'),
        actions: [
          IconButton(
            tooltip: 'Cerrar sesión',
            onPressed: () async {
              await authService.cerrarSesion();
            },
            icon: const Icon(Icons.logout),
          ),
        ],
      ),
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Icon(
                Icons.storefront_rounded,
                size: 72,
                color: Theme.of(context).colorScheme.primary,
              ),
              const SizedBox(height: 16),
              Text(
                'Gestión Comercial',
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
              ),
              const SizedBox(height: 8),
              const Text(
                'Selecciona el módulo que deseas consultar.',
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 28),

              // Módulo de productos.
              FilledButton.icon(
                onPressed: () {
                  Navigator.of(context).push(
                    MaterialPageRoute<void>(
                      builder: (_) => const ProductosScreen(),
                    ),
                  );
                },
                icon: const Icon(Icons.inventory_2_outlined),
                label: const Text('Administrar productos'),
              ),
              const SizedBox(height: 12),

              // Módulo de proveedores.
              OutlinedButton.icon(
                onPressed: () {
                  Navigator.of(context).push(
                    MaterialPageRoute<void>(
                      builder: (_) => const ProveedoresScreen(),
                    ),
                  );
                },
                icon: const Icon(Icons.people_outline),
                label: const Text('Administrar proveedores'),
              ),
              const SizedBox(height: 12),

              // Módulo de categorías.
              OutlinedButton.icon(
                onPressed: () {
                  Navigator.of(context).push(
                    MaterialPageRoute<void>(
                      builder: (_) => const CategoriasScreen(),
                    ),
                  );
                },
                icon: const Icon(Icons.category_outlined),
                label: const Text('Administrar categorías'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
