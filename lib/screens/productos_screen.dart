
import 'package:flutter/material.dart';
import '../services/api_service.dart';

class ProductosScreen extends StatefulWidget {
  const ProductosScreen({super.key});

  @override
  State<ProductosScreen> createState() => _ProductosScreenState();
}

class _ProductosScreenState extends State<ProductosScreen> {
  late Future<List<dynamic>> _productosFuture;
  bool _guardando = false;

  @override
  void initState() {
    super.initState();
    _cargarProductos();
  }

  void _cargarProductos() {
    _productosFuture = ApiService.listarProductos();
  }

  void _actualizarLista() {
    setState(_cargarProductos);
  }

  String _precio(dynamic valor) {
    final numero = valor is num
        ? valor.toInt()
        : int.tryParse(valor.toString()) ?? 0;
    final texto = numero.toString().replaceAllMapped(
      RegExp(r'\B(?=(\d{3})+(?!\d))'),
      (_) => '.',
    );
    return '\$$texto';
  }

  void _mensaje(String texto) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(texto)),
    );
  }

  Future<void> _formulario({
    Map<String, dynamic>? producto,
  }) async {
    final esEdicion = producto != null;
    final nombreController = TextEditingController(
      text: producto?['product_name']?.toString() ?? '',
    );
    final precioController = TextEditingController(
      text: producto?['product_price']?.toString() ?? '',
    );
    final imagenController = TextEditingController(
      text: producto?['product_image']?.toString() ?? '',
    );
    final formKey = GlobalKey<FormState>();

    var estado = producto?['product_state']?.toString() ?? 'Activo';

    final confirmado = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: Text(esEdicion ? 'Editar producto' : 'Nuevo producto'),
          content: SingleChildScrollView(
            child: Form(
              key: formKey,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextFormField(
                    controller: nombreController,
                    decoration: const InputDecoration(
                      labelText: 'Nombre del producto',
                    ),
                    validator: (v) => v == null || v.trim().isEmpty
                        ? 'Ingresa un nombre'
                        : null,
                  ),
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: precioController,
                    keyboardType: TextInputType.number,
                    decoration: const InputDecoration(
                      labelText: 'Precio en pesos',
                    ),
                    validator: (v) {
                      final n = int.tryParse(v?.trim() ?? '');
                      if (n == null || n < 0) {
                        return 'Ingresa un precio válido';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: imagenController,
                    keyboardType: TextInputType.url,
                    decoration: const InputDecoration(
                      labelText: 'URL de la imagen',
                    ),
                    validator: (v) {
                      final uri = Uri.tryParse(v?.trim() ?? '');
                      if (uri == null ||
                          !uri.hasScheme ||
                          (uri.scheme != 'https' && uri.scheme != 'http') ||
                          uri.host.isEmpty) {
                        return 'Ingresa una URL válida';
                      }
                      return null;
                    },
                  ),
                  if (esEdicion) ...[
                    const SizedBox(height: 12),
                    DropdownButtonFormField<String>(
                      initialValue: estado == 'Inactivo' ? 'Inactivo' : 'Activo',
                      decoration: const InputDecoration(
                        labelText: 'Estado',
                      ),
                      items: const [
                        DropdownMenuItem(
                          value: 'Activo',
                          child: Text('Activo'),
                        ),
                        DropdownMenuItem(
                          value: 'Inactivo',
                          child: Text('Inactivo'),
                        ),
                      ],
                      onChanged: (v) {
                        if (v != null) {
                          setDialogState(() => estado = v);
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
              child: Text(esEdicion ? 'Guardar' : 'Crear'),
            ),
          ],
        ),
      ),
    );

    if (confirmado != true) {
      nombreController.dispose();
      precioController.dispose();
      imagenController.dispose();
      return;
    }

    setState(() => _guardando = true);

    try {
      final nombre = nombreController.text.trim();
      final precio = int.parse(precioController.text.trim());
      final imagen = imagenController.text.trim();

      if (esEdicion) {
        await ApiService.editarProducto(
          id: int.parse(producto['product_id'].toString()),
          nombre: nombre,
          precio: precio,
          imagen: imagen,
          estado: estado,
        );
        _mensaje('Solicitud de edición enviada.');
      } else {
        await ApiService.agregarProducto(
          nombre: nombre,
          precio: precio,
          imagen: imagen,
        );
        _mensaje('Solicitud de creación enviada.');
      }

      _actualizarLista();
    } catch (e) {
      _mensaje('No se pudo guardar el producto: $e');
    } finally {
      nombreController.dispose();
      precioController.dispose();
      imagenController.dispose();
      if (mounted) setState(() => _guardando = false);
    }
  }

  Future<void> _eliminar(Map<String, dynamic> producto) async {
    final confirmar = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Eliminar producto'),
        content: Text(
          '¿Deseas eliminar "${producto['product_name']}"? '
          'Esta acción afectará los datos del servidor.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancelar'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Eliminar'),
          ),
        ],
      ),
    );

    if (confirmar != true) return;

    setState(() => _guardando = true);

    try {
      await ApiService.eliminarProducto(
        int.parse(producto['product_id'].toString()),
      );
      _mensaje('Solicitud de eliminación enviada.');
      _actualizarLista();
    } catch (e) {
      _mensaje('No se pudo eliminar el producto: $e');
    } finally {
      if (mounted) setState(() => _guardando = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Productos'),
        actions: [
          IconButton(
            tooltip: 'Actualizar',
            onPressed: _actualizarLista,
            icon: const Icon(Icons.refresh),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _guardando ? null : () => _formulario(),
        icon: const Icon(Icons.add),
        label: const Text('Agregar'),
      ),
      body: Stack(
        children: [
          FutureBuilder<List<dynamic>>(
            future: _productosFuture,
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Center(child: CircularProgressIndicator());
              }

              if (snapshot.hasError) {
                return Center(
                  child: Padding(
                    padding: const EdgeInsets.all(24),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Text('No se pudieron cargar los productos.'),
                        const SizedBox(height: 12),
                        FilledButton(
                          onPressed: _actualizarLista,
                          child: const Text('Reintentar'),
                        ),
                      ],
                    ),
                  ),
                );
              }

              final productos = snapshot.data ?? [];

              if (productos.isEmpty) {
                return const Center(
                  child: Text('No hay productos registrados.'),
                );
              }

              return RefreshIndicator(
                onRefresh: () async {
                  _actualizarLista();
                  await _productosFuture;
                },
                child: ListView.builder(
                  padding: const EdgeInsets.fromLTRB(12, 12, 12, 88),
                  itemCount: productos.length,
                  itemBuilder: (context, index) {
                    final p = Map<String, dynamic>.from(
                      productos[index] as Map,
                    );
                    final imagen = p['product_image']?.toString() ?? '';

                    return Card(
                      clipBehavior: Clip.antiAlias,
                      margin: const EdgeInsets.only(bottom: 12),
                      child: Padding(
                        padding: const EdgeInsets.all(10),
                        child: Row(
                          children: [
                            ClipRRect(
                              borderRadius: BorderRadius.circular(8),
                              child: Image.network(
                                imagen,
                                width: 76,
                                height: 76,
                                fit: BoxFit.cover,
                                errorBuilder: (_, __, ___) => const SizedBox(
                                  width: 76,
                                  height: 76,
                                  child: Icon(Icons.image_not_supported),
                                ),
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    p['product_name']?.toString() ?? '',
                                    style: const TextStyle(
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(_precio(p['product_price'])),
                                  Text(
                                    'ID: ${p['product_id']} · '
                                    '${p['product_state'] ?? 'Sin estado'}',
                                  ),
                                  const SizedBox(height: 4),
                                  Wrap(
                                    spacing: 4,
                                    children: [
                                      IconButton(
                                        tooltip: 'Editar',
                                        visualDensity: VisualDensity.compact,
                                        onPressed: _guardando
                                            ? null
                                            : () => _formulario(producto: p),
                                        icon: const Icon(Icons.edit_outlined),
                                      ),
                                      IconButton(
                                        tooltip: 'Eliminar',
                                        visualDensity: VisualDensity.compact,
                                        onPressed: _guardando
                                            ? null
                                            : () => _eliminar(p),
                                        icon: const Icon(
                                          Icons.delete_outline,
                                          color: Colors.red,
                                        ),
                                      ),
                                    ],
                                  ),
                                ],
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
          if (_guardando)
            Container(
              color: Colors.black12,
              child: const Center(child: CircularProgressIndicator()),
            ),
        ],
      ),
    );
  }
}
