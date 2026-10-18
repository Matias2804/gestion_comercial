
import 'package:flutter/material.dart';
import '../services/api_service.dart';

class CategoriasScreen extends StatefulWidget {
  const CategoriasScreen({super.key});

  @override
  State<CategoriasScreen> createState() => _CategoriasScreenState();
}

class _CategoriasScreenState extends State<CategoriasScreen> {
  late Future<List<dynamic>> _categoriasFuture;
  bool _procesando = false;

  @override
  void initState() {
    super.initState();
    _cargarCategorias();
  }

  void _cargarCategorias() {
    _categoriasFuture = ApiService.listarCategorias();
  }

  void _actualizar() {
    setState(_cargarCategorias);
  }

  void _mensaje(String texto) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(texto)),
    );
  }

  Future<void> _formulario({
    Map<String, dynamic>? categoria,
  }) async {
    final editar = categoria != null;
    final nombreController = TextEditingController(
      text: categoria?['category_name']?.toString() ?? '',
    );
    final formKey = GlobalKey<FormState>();
    var estado =
        categoria?['category_state']?.toString() ?? 'Activa';

    final confirmado = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: Text(editar ? 'Editar categoría' : 'Nueva categoría'),
          content: Form(
            key: formKey,
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextFormField(
                    controller: nombreController,
                    autofocus: true,
                    decoration: const InputDecoration(
                      labelText: 'Nombre de la categoría',
                      prefixIcon: Icon(Icons.category_outlined),
                    ),
                    validator: (valor) {
                      if (valor == null || valor.trim().isEmpty) {
                        return 'Ingresa un nombre';
                      }
                      return null;
                    },
                  ),
                  if (editar) ...[
                    const SizedBox(height: 16),
                    DropdownButtonFormField<String>(
                      initialValue:
                          estado == 'Inactiva' ? 'Inactiva' : 'Activa',
                      decoration: const InputDecoration(
                        labelText: 'Estado',
                      ),
                      items: const [
                        DropdownMenuItem(
                          value: 'Activa',
                          child: Text('Activa'),
                        ),
                        DropdownMenuItem(
                          value: 'Inactiva',
                          child: Text('Inactiva'),
                        ),
                      ],
                      onChanged: (valor) {
                        if (valor != null) {
                          setDialogState(() => estado = valor);
                        }
                      },
                    ),
                  ],
                ],
              ),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext, false),
              child: const Text('Cancelar'),
            ),
            FilledButton(
              onPressed: () {
                if (formKey.currentState!.validate()) {
                  Navigator.pop(dialogContext, true);
                }
              },
              child: Text(editar ? 'Guardar' : 'Crear'),
            ),
          ],
        ),
      ),
    );

    if (confirmado != true) {
      nombreController.dispose();
      return;
    }

    setState(() => _procesando = true);

    try {
      final nombre = nombreController.text.trim();

      if (editar) {
        await ApiService.editarCategoria(
          id: int.parse(categoria['category_id'].toString()),
          nombre: nombre,
          estado: estado,
        );
        _mensaje('Solicitud de edición enviada.');
      } else {
        await ApiService.agregarCategoria(nombre: nombre);
        _mensaje('Solicitud de creación enviada.');
      }

      _actualizar();
    } catch (error) {
      _mensaje('No se pudo guardar la categoría: $error');
    } finally {
      nombreController.dispose();
      if (mounted) setState(() => _procesando = false);
    }
  }

  Future<void> _eliminar(Map<String, dynamic> categoria) async {
    final confirmar = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Eliminar categoría'),
        content: Text(
          '¿Deseas eliminar "${categoria['category_name']}"?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: const Text('Cancelar'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(dialogContext, true),
            child: const Text('Eliminar'),
          ),
        ],
      ),
    );

    if (confirmar != true) return;

    setState(() => _procesando = true);

    try {
      await ApiService.eliminarCategoria(
        int.parse(categoria['category_id'].toString()),
      );
      _mensaje('Solicitud de eliminación enviada.');
      _actualizar();
    } catch (error) {
      _mensaje('No se pudo eliminar la categoría: $error');
    } finally {
      if (mounted) setState(() => _procesando = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Categorías'),
        actions: [
          IconButton(
            tooltip: 'Actualizar',
            onPressed: _actualizar,
            icon: const Icon(Icons.refresh),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _procesando ? null : () => _formulario(),
        icon: const Icon(Icons.add),
        label: const Text('Agregar categoría'),
      ),
      body: Stack(
        children: [
          FutureBuilder<List<dynamic>>(
            future: _categoriasFuture,
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Center(
                  child: CircularProgressIndicator(),
                );
              }

              if (snapshot.hasError) {
                return Center(
                  child: Padding(
                    padding: const EdgeInsets.all(24),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.cloud_off_outlined, size: 48),
                        const SizedBox(height: 12),
                        const Text(
                          'No se pudieron cargar las categorías.',
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 12),
                        FilledButton(
                          onPressed: _actualizar,
                          child: const Text('Reintentar'),
                        ),
                      ],
                    ),
                  ),
                );
              }

              final categorias = snapshot.data ?? [];

              if (categorias.isEmpty) {
                return const Center(
                  child: Text('No hay categorías registradas.'),
                );
              }

              return RefreshIndicator(
                onRefresh: () async {
                  _actualizar();
                  await _categoriasFuture;
                },
                child: ListView.builder(
                  padding: const EdgeInsets.fromLTRB(12, 12, 12, 88),
                  itemCount: categorias.length,
                  itemBuilder: (context, index) {
                    final categoria = Map<String, dynamic>.from(
                      categorias[index] as Map,
                    );

                    final nombre =
                        categoria['category_name']?.toString() ?? '';
                    final estado =
                        categoria['category_state']?.toString() ?? 'Sin estado';

                    return Card(
                      margin: const EdgeInsets.only(bottom: 10),
                      child: ListTile(
                        leading: CircleAvatar(
                          backgroundColor:
                              Theme.of(context).colorScheme.primaryContainer,
                          child: Icon(
                            Icons.category_outlined,
                            color: Theme.of(context)
                                .colorScheme
                                .onPrimaryContainer,
                          ),
                        ),
                        title: Text(
                          nombre,
                          style: const TextStyle(
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        subtitle: Text(
                          'ID: ${categoria['category_id']} · $estado',
                        ),
                        trailing: Wrap(
                          children: [
                            IconButton(
                              tooltip: 'Editar',
                              onPressed: _procesando
                                  ? null
                                  : () => _formulario(categoria: categoria),
                              icon: const Icon(Icons.edit_outlined),
                            ),
                            IconButton(
                              tooltip: 'Eliminar',
                              onPressed: _procesando
                                  ? null
                                  : () => _eliminar(categoria),
                              icon: const Icon(
                                Icons.delete_outline,
                                color: Colors.red,
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
              );
            },
          ),
          if (_procesando)
            Container(
              color: Colors.black12,
              child: const Center(
                child: CircularProgressIndicator(),
              ),
            ),
        ],
      ),
    );
  }
}
