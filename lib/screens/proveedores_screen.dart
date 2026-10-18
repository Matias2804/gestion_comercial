
import 'package:flutter/material.dart';
import '../services/api_service.dart';

class ProveedoresScreen extends StatefulWidget {
  const ProveedoresScreen({super.key});

  @override
  State<ProveedoresScreen> createState() => _ProveedoresScreenState();
}

class _ProveedoresScreenState extends State<ProveedoresScreen> {
  List<dynamic> _proveedores = [];
  bool _cargando = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _cargarProveedores();
  }

  Future<void> _cargarProveedores() async {
    setState(() {
      _cargando = true;
      _error = null;
    });

    try {
      final resultado = await ApiService.listarProveedores();

      if (!mounted) return;

      setState(() {
        _proveedores = resultado;
        _cargando = false;
      });
    } catch (e) {
      if (!mounted) return;

      setState(() {
        _error = e.toString();
        _cargando = false;
      });
    }
  }

  void _mostrarMensaje(String mensaje) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(mensaje)),
    );
  }

  Future<void> _mostrarFormulario({
    Map<String, dynamic>? proveedor,
  }) async {
    final esEdicion = proveedor != null;

    final nombreController = TextEditingController(
      text: proveedor?['provider_name']?.toString() ?? '',
    );
    final apellidoController = TextEditingController(
      text: proveedor?['provider_last_name']?.toString() ?? '',
    );
    final correoController = TextEditingController(
      text: proveedor?['provider_mail']?.toString() ?? '',
    );

    String estado =
        proveedor?['provider_state']?.toString() ?? 'Activo';

    final formKey = GlobalKey<FormState>();
    bool guardando = false;

    await showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) {
        return StatefulBuilder(
          builder: (contextDialogo, actualizarDialogo) {
            return AlertDialog(
              title: Text(
                esEdicion ? 'Editar proveedor' : 'Agregar proveedor',
              ),
              content: SingleChildScrollView(
                child: Form(
                  key: formKey,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      TextFormField(
                        controller: nombreController,
                        decoration: const InputDecoration(
                          labelText: 'Nombre',
                          border: OutlineInputBorder(),
                        ),
                        validator: (valor) {
                          if (valor == null || valor.trim().isEmpty) {
                            return 'Ingresa el nombre';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 12),
                      TextFormField(
                        controller: apellidoController,
                        decoration: const InputDecoration(
                          labelText: 'Apellido',
                          border: OutlineInputBorder(),
                        ),
                        validator: (valor) {
                          if (valor == null || valor.trim().isEmpty) {
                            return 'Ingresa el apellido';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 12),
                      TextFormField(
                        controller: correoController,
                        keyboardType: TextInputType.emailAddress,
                        decoration: const InputDecoration(
                          labelText: 'Correo electrónico',
                          border: OutlineInputBorder(),
                        ),
                        validator: (valor) {
                          if (valor == null || valor.trim().isEmpty) {
                            return 'Ingresa el correo';
                          }

                          if (!valor.contains('@') ||
                              !valor.contains('.')) {
                            return 'Ingresa un correo válido';
                          }

                          return null;
                        },
                      ),
                      if (esEdicion) ...[
                        const SizedBox(height: 12),
                        DropdownButtonFormField<String>(
                          initialValue: estado == 'Inactivo'
                              ? 'Inactivo'
                              : 'Activo',
                          decoration: const InputDecoration(
                            labelText: 'Estado',
                            border: OutlineInputBorder(),
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
                          onChanged: (valor) {
                            if (valor != null) {
                              actualizarDialogo(() {
                                estado = valor;
                              });
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
                  onPressed: guardando
                      ? null
                      : () => Navigator.pop(dialogContext),
                  child: const Text('Cancelar'),
                ),
                FilledButton(
                  onPressed: guardando
                      ? null
                      : () async {
                          if (!formKey.currentState!.validate()) {
                            return;
                          }

                          actualizarDialogo(() {
                            guardando = true;
                          });

                          try {
                            if (esEdicion) {
                              final id = int.tryParse(
                                proveedor['providerid'].toString(),
                              );

                              if (id == null) {
                                throw Exception(
                                  'No se pudo identificar al proveedor.',
                                );
                              }

                              await ApiService.editarProveedor(
                                id: id,
                                nombre: nombreController.text.trim(),
                                apellido:
                                    apellidoController.text.trim(),
                                correo: correoController.text.trim(),
                                estado: estado,
                              );
                            } else {
                              await ApiService.agregarProveedor(
                                nombre: nombreController.text.trim(),
                                apellido:
                                    apellidoController.text.trim(),
                                correo: correoController.text.trim(),
                              );
                            }

                            if (!dialogContext.mounted) return;
                            Navigator.pop(dialogContext);

                            _mostrarMensaje(
                              esEdicion
                                  ? 'Solicitud de edición enviada.'
                                  : 'Solicitud de creación enviada.',
                            );

                            await _cargarProveedores();
                          } catch (e) {
                            actualizarDialogo(() {
                              guardando = false;
                            });

                            _mostrarMensaje('Error: $e');
                          }
                        },
                  child: guardando
                      ? const SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                          ),
                        )
                      : Text(esEdicion ? 'Guardar' : 'Agregar'),
                ),
              ],
            );
          },
        );
      },
    );

  
  }

  Future<void> _confirmarEliminacion(
    Map<String, dynamic> proveedor,
  ) async {
    final id = int.tryParse(
      proveedor['providerid'].toString(),
    );

    if (id == null) {
      _mostrarMensaje('No se pudo identificar al proveedor.');
      return;
    }

    final confirmar = await showDialog<bool>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: const Text('Eliminar proveedor'),
          content: Text(
            '¿Deseas eliminar a '
            '${proveedor['provider_name']} '
            '${proveedor['provider_last_name']}?',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext, false),
              child: const Text('Cancelar'),
            ),
            FilledButton(
              onPressed: () => Navigator.pop(dialogContext, true),
              style: FilledButton.styleFrom(
                backgroundColor: Colors.red,
              ),
              child: const Text('Eliminar'),
            ),
          ],
        );
      },
    );

    if (confirmar != true) return;

    try {
      await ApiService.eliminarProveedor(id);
      _mostrarMensaje('Solicitud de eliminación enviada.');
      await _cargarProveedores();
    } catch (e) {
      _mostrarMensaje('Error al eliminar: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Proveedores'),
        actions: [
          IconButton(
            tooltip: 'Actualizar',
            onPressed: _cargarProveedores,
            icon: const Icon(Icons.refresh),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _mostrarFormulario(),
        icon: const Icon(Icons.add),
        label: const Text('Agregar'),
      ),
      body: _cargando
          ? const Center(child: CircularProgressIndicator())
          : _error != null
              ? Center(
                  child: Padding(
                    padding: const EdgeInsets.all(24),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(
                          Icons.error_outline,
                          size: 48,
                          color: Colors.red,
                        ),
                        const SizedBox(height: 12),
                        const Text(
                          'No se pudieron cargar los proveedores.',
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 8),
                        Text(
                          _error!,
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 16),
                        FilledButton(
                          onPressed: _cargarProveedores,
                          child: const Text('Reintentar'),
                        ),
                      ],
                    ),
                  ),
                )
              : _proveedores.isEmpty
                  ? const Center(
                      child: Text('No hay proveedores registrados.'),
                    )
                  : RefreshIndicator(
                      onRefresh: _cargarProveedores,
                      child: ListView.builder(
                        padding: const EdgeInsets.fromLTRB(
                          12,
                          12,
                          12,
                          90,
                        ),
                        itemCount: _proveedores.length,
                        itemBuilder: (context, index) {
                          final proveedor =
                              Map<String, dynamic>.from(
                            _proveedores[index] as Map,
                          );

                          final nombre =
                              proveedor['provider_name']?.toString() ??
                                  '';
                          final apellido =
                              proveedor['provider_last_name']
                                      ?.toString() ??
                                  '';
                          final correo =
                              proveedor['provider_mail']?.toString() ??
                                  '';
                          final estado =
                              proveedor['provider_state']?.toString() ??
                                  'Sin estado';
                          final id =
                              proveedor['providerid']?.toString() ??
                                  'Sin ID';

                          final activo = estado == 'Activo';

                          return Card(
                            margin: const EdgeInsets.only(bottom: 10),
                            child: ListTile(
                              contentPadding: const EdgeInsets.all(12),
                              leading: CircleAvatar(
                                child: Text(
                                  nombre.isNotEmpty
                                      ? nombre[0].toUpperCase()
                                      : '?',
                                ),
                              ),
                              title: Text('$nombre $apellido'),
                              subtitle: Padding(
                                padding: const EdgeInsets.only(top: 6),
                                child: Column(
                                  crossAxisAlignment:
                                      CrossAxisAlignment.start,
                                  children: [
                                    Text('ID: $id'),
                                    Text('Correo: $correo'),
                                    const SizedBox(height: 4),
                                    Text(
                                      'Estado: $estado',
                                      style: TextStyle(
                                        color: activo
                                            ? Colors.green
                                            : Colors.red,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              trailing: PopupMenuButton<String>(
                                tooltip: 'Opciones',
                                onSelected: (opcion) {
                                  if (opcion == 'editar') {
                                    _mostrarFormulario(
                                      proveedor: proveedor,
                                    );
                                  } else if (opcion == 'eliminar') {
                                    _confirmarEliminacion(proveedor);
                                  }
                                },
                                itemBuilder: (context) => const [
                                  PopupMenuItem(
                                    value: 'editar',
                                    child: Row(
                                      children: [
                                        Icon(Icons.edit_outlined),
                                        SizedBox(width: 8),
                                        Text('Editar'),
                                      ],
                                    ),
                                  ),
                                  PopupMenuItem(
                                    value: 'eliminar',
                                    child: Row(
                                      children: [
                                        Icon(
                                          Icons.delete_outline,
                                          color: Colors.red,
                                        ),
                                        SizedBox(width: 8),
                                        Text('Eliminar'),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          );
                        },
                      ),
                    ),
    );
  }
}
