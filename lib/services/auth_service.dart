
import 'package:firebase_auth/firebase_auth.dart';

class AuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;

  Stream<User?> get estadoAutenticacion => _auth.authStateChanges();

  Future<UserCredential> iniciarSesion({
    required String correo,
    required String contrasena,
  }) {
    return _auth.signInWithEmailAndPassword(
      email: correo.trim(),
      password: contrasena,
    );
  }

  Future<UserCredential> registrarUsuario({
    required String correo,
    required String contrasena,
  }) {
    return _auth.createUserWithEmailAndPassword(
      email: correo.trim(),
      password: contrasena,
    );
  }

  Future<void> cerrarSesion() {
    return _auth.signOut();
  }
}
