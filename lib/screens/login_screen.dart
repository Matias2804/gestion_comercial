
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import '../services/auth_service.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _correoController = TextEditingController();
  final _contrasenaController = TextEditingController();
  final _authService = AuthService();

  bool _esRegistro = false;
  bool _cargando = false;
  bool _ocultarContrasena = true;
  String? _error;

  @override
  void dispose() {
    _correoController.dispose();
    _contrasenaController.dispose();
    super.dispose();
  }

  String _mensajeError(Object error) {
    if (error is FirebaseAuthException) {
      switch (error.code) {
        case 'invalid-email':
          return 'El correo electrónico no tiene un formato válido.';
        case 'user-not-found':
        case 'wrong-password':
        case 'invalid-credential':
          return 'Correo o contraseña incorrectos.';
        case 'email-already-in-use':
          return 'Ya existe una cuenta con ese correo.';
        case 'weak-password':
          return 'La contraseña debe tener al menos 6 caracteres.';
        case 'network-request-failed':
          return 'No se pudo conectar. Revisa tu conexión a internet.';
        case 'too-many-requests':
          return 'Demasiados intentos. Espera un momento y vuelve a intentarlo.';
        default:
          return error.message ?? 'No fue posible completar la operación.';
      }
    }

    return 'Ocurrió un error inesperado. Intenta nuevamente.';
  }

  Future<void> _enviarFormulario() async {
    FocusScope.of(context).unfocus();

    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _cargando = true;
      _error = null;
    });

    try {
      if (_esRegistro) {
        await _authService.registrarUsuario(
          correo: _correoController.text,
          contrasena: _contrasenaController.text,
        );
      } else {
        await _authService.iniciarSesion(
          correo: _correoController.text,
          contrasena: _contrasenaController.text,
        );
      }
    } catch (error) {
      if (mounted) {
        setState(() => _error = _mensajeError(error));
      }
    } finally {
      if (mounted) {
        setState(() => _cargando = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final colorPrincipal = Theme.of(context).colorScheme.primary;

    return Scaffold(
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 420),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    CircleAvatar(
                      radius: 38,
                      backgroundColor: colorPrincipal.withValues(alpha: 0.12),
                      child: Icon(
                        Icons.storefront_rounded,
                        size: 42,
                        color: colorPrincipal,
                      ),
                    ),
                    const SizedBox(height: 20),
                    Text(
                      'Gestión Comercial',
                      textAlign: TextAlign.center,
                      style: Theme.of(context).textTheme.headlineMedium
                          ?.copyWith(fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      _esRegistro
                          ? 'Crea una cuenta para continuar'
                          : 'Ingresa con tu cuenta para continuar',
                      textAlign: TextAlign.center,
                      style: Theme.of(context).textTheme.bodyLarge,
                    ),
                    const SizedBox(height: 32),
                    TextFormField(
                      controller: _correoController,
                      keyboardType: TextInputType.emailAddress,
                      autofillHints: const [AutofillHints.email],
                      decoration: const InputDecoration(
                        labelText: 'Correo electrónico',
                        prefixIcon: Icon(Icons.email_outlined),
                      ),
                      validator: (value) {
                        final correo = value?.trim() ?? '';
                        if (correo.isEmpty) return 'Ingresa tu correo.';
                        if (!RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$')
                            .hasMatch(correo)) {
                          return 'Ingresa un correo válido.';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: _contrasenaController,
                      obscureText: _ocultarContrasena,
                      autofillHints: const [AutofillHints.password],
                      decoration: InputDecoration(
                        labelText: 'Contraseña',
                        prefixIcon: const Icon(Icons.lock_outline),
                        suffixIcon: IconButton(
                          tooltip: _ocultarContrasena
                              ? 'Mostrar contraseña'
                              : 'Ocultar contraseña',
                          onPressed: () => setState(
                            () => _ocultarContrasena = !_ocultarContrasena,
                          ),
                          icon: Icon(
                            _ocultarContrasena
                                ? Icons.visibility_outlined
                                : Icons.visibility_off_outlined,
                          ),
                        ),
                      ),
                      validator: (value) {
                        final contrasena = value ?? '';
                        if (contrasena.isEmpty) {
                          return 'Ingresa tu contraseña.';
                        }
                        if (_esRegistro && contrasena.length < 6) {
                          return 'Usa al menos 6 caracteres.';
                        }
                        return null;
                      },
                    ),
                    if (_error != null) ...[
                      const SizedBox(height: 16),
                      Text(
                        _error!,
                        style: TextStyle(
                          color: Theme.of(context).colorScheme.error,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ],
                    const SizedBox(height: 24),
                    FilledButton(
                      onPressed: _cargando ? null : _enviarFormulario,
                      child: Padding(
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        child: _cargando
                            ? const SizedBox(
                                width: 22,
                                height: 22,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                ),
                              )
                            : Text(
                                _esRegistro
                                    ? 'Crear cuenta'
                                    : 'Iniciar sesión',
                              ),
                      ),
                    ),
                    const SizedBox(height: 12),
                    TextButton(
                      onPressed: _cargando
                          ? null
                          : () => setState(() {
                                _esRegistro = !_esRegistro;
                                _error = null;
                              }),
                      child: Text(
                        _esRegistro
                            ? '¿Ya tienes cuenta? Inicia sesión'
                            : '¿No tienes cuenta? Regístrate',
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
