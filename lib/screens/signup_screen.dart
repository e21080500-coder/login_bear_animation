
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:rive/rive.dart';


class SignUpScreen extends StatefulWidget {
  const SignUpScreen({super.key});

  @override
  State<SignUpScreen> createState() => _SignUpScreenState();
}

class _SignUpScreenState extends State<SignUpScreen> {
  // ==========================================
  // FIREBASE
  // ==========================================

  final FirebaseAuth _auth = FirebaseAuth.instance;

  // ==========================================
  // FORMULARIO
  // ==========================================

  final _formKey = GlobalKey<FormState>();

  final TextEditingController _emailCtrl =
      TextEditingController();

  final TextEditingController _passwordCtrl =
      TextEditingController();

  final TextEditingController _confirmCtrl =
      TextEditingController();

  bool _obscurePassword = true;
  bool _obscureConfirm = true;
  bool _isRegistering = false;

  // ==========================================
  // VALIDACIÓN DE CORREO
  // ==========================================

  String? _validateEmail(String? value) {
    final email = (value ?? '').trim();

    if (email.isEmpty) {
      return 'Ingresa tu correo electrónico';
    }

    final regex = RegExp(
      r'^[^\s@]+@[^\s@]+\.[^\s@]+$',
    );

    if (!regex.hasMatch(email)) {
      return 'Ingresa un correo válido';
    }

    return null;
  }

  // ==========================================
  // VALIDACIÓN DE CONTRASEÑA
  // ==========================================

  String? _validatePassword(String? value) {
    final password = value ?? '';

    if (password.isEmpty) {
      return 'Ingresa una contraseña';
    }

    if (password.length < 8) {
      return 'Debe tener mínimo 8 caracteres';
    }

    final regex = RegExp(
      r'^(?=.*[A-Za-z])(?=.*\d)(?=.*[^A-Za-z0-9]).{8,}$',
    );

    if (!regex.hasMatch(password)) {
      return 'Usa letras, números y un símbolo';
    }

    return null;
  }

  // ==========================================
  // CONFIRMAR CONTRASEÑA
  // ==========================================

  String? _validateConfirmation(String? value) {
    if (value == null || value.isEmpty) {
      return 'Confirma tu contraseña';
    }

    if (value != _passwordCtrl.text) {
      return 'Las contraseñas no coinciden';
    }

    return null;
  }

  // ==========================================
  // MENSAJES DE ERROR FIREBASE
  // ==========================================

  String _firebaseErrorMessage(
    FirebaseAuthException error,
  ) {
    switch (error.code) {
      case 'email-already-in-use':
        return 'Ya existe una cuenta con ese correo.';

      case 'invalid-email':
        return 'El correo electrónico no es válido.';

      case 'weak-password':
        return 'La contraseña es demasiado débil.';

      case 'operation-not-allowed':
        return 'El registro por correo no está habilitado.';

      case 'network-request-failed':
        return 'Comprueba tu conexión a Internet.';

      case 'too-many-requests':
        return 'Demasiados intentos. Intenta más tarde.';

      default:
        debugPrint(
          'ERROR FIREBASE SIGN UP: ${error.code}',
        );

        return 'No se pudo crear la cuenta.';
    }
  }

  void _showMessage(String message) {
    if (!mounted) return;

    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          content: Text(message),
          behavior: SnackBarBehavior.floating,
        ),
      );
  }

  // ==========================================
  // REGISTRAR USUARIO EN FIREBASE
  // ==========================================

  Future<void> _registerUser() async {
    // Evita pulsaciones repetidas.
    if (_isRegistering) return;

    FocusScope.of(context).unfocus();

    // Validar todos los campos.
    if (!_formKey.currentState!.validate()) {
      return;
    }

    setState(() {
      _isRegistering = true;
    });

    try {
      debugPrint(
        'FIREBASE: creando nuevo usuario...',
      );

      final credential =
          await _auth.createUserWithEmailAndPassword(
        email: _emailCtrl.text.trim(),
        password: _passwordCtrl.text,
      );

      if (!mounted) return;

      debugPrint(
        'FIREBASE: usuario creado correctamente',
      );

      debugPrint(
        'UID: ${credential.user?.uid}',
      );

      // Firebase inicia la sesión automáticamente.
      //
      // LoginScreen escucha authStateChanges()
      // y mostrará Welcome Back.
      //
      // Regresamos a LoginScreen, que ahora
      // detectará al usuario autenticado.

      Navigator.of(context).pop();
    } on FirebaseAuthException catch (error) {
      if (!mounted) return;

      _showMessage(
        _firebaseErrorMessage(error),
      );
    } catch (error) {
      if (!mounted) return;

      debugPrint(
        'ERROR INESPERADO EN REGISTRO: $error',
      );

      _showMessage(
        'Ocurrió un error al registrar la cuenta.',
      );
    } finally {
      if (mounted) {
        setState(() {
          _isRegistering = false;
        });
      }
    }
  }

  // ==========================================
  // BUILD
  // ==========================================

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: !_isRegistering,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Sign Up'),
          centerTitle: true,
        ),

        body: SafeArea(
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(
                maxWidth: 500,
              ),

              child: SingleChildScrollView(
                padding: const EdgeInsets.all(20),

                child: Form(
                  key: _formKey,

                  autovalidateMode:
                      AutovalidateMode.onUserInteraction,

                  child: Column(
                    crossAxisAlignment:
                        CrossAxisAlignment.stretch,

                    children: [
                      // ==========================
                      // OSITO RIVE
                      // ==========================

                      const SizedBox(
                        height: 160,
                        child: RiveAnimation.asset(
                          'assets/login-bear.riv',
                        ),
                      ),

                      const SizedBox(height: 12),

                      // ==========================
                      // TÍTULO
                      // ==========================

                      const Text(
                        'Create Account',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: 27,
                          fontWeight: FontWeight.bold,
                        ),
                      ),

                      const SizedBox(height: 8),

                      const Text(
                        'Regístrate para comenzar',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: 15,
                          color: Colors.grey,
                        ),
                      ),

                      const SizedBox(height: 25),

                      // ==========================
                      // EMAIL
                      // ==========================

                      TextFormField(
                        controller: _emailCtrl,
                        enabled: !_isRegistering,
                        keyboardType:
                            TextInputType.emailAddress,
                        textInputAction:
                            TextInputAction.next,
                        autofillHints: const [
                          AutofillHints.email,
                        ],

                        validator: _validateEmail,

                        decoration: InputDecoration(
                          labelText: 'Email',
                          hintText: 'Correo electrónico',
                          prefixIcon: const Icon(
                            Icons.email,
                          ),
                          border: OutlineInputBorder(
                            borderRadius:
                                BorderRadius.circular(12),
                          ),
                        ),
                      ),

                      const SizedBox(height: 15),

                      // ==========================
                      // PASSWORD
                      // ==========================

                      TextFormField(
                        controller: _passwordCtrl,
                        enabled: !_isRegistering,
                        obscureText: _obscurePassword,
                        textInputAction:
                            TextInputAction.next,

                        validator: _validatePassword,

                        decoration: InputDecoration(
                          labelText: 'Password',
                          hintText: 'Contraseña',
                          prefixIcon: const Icon(
                            Icons.lock,
                          ),

                          suffixIcon: IconButton(
                            onPressed: _isRegistering
                                ? null
                                : () {
                                    setState(() {
                                      _obscurePassword =
                                          !_obscurePassword;
                                    });
                                  },
                            icon: Icon(
                              _obscurePassword
                                  ? Icons.visibility
                                  : Icons.visibility_off,
                            ),
                          ),

                          border: OutlineInputBorder(
                            borderRadius:
                                BorderRadius.circular(12),
                          ),
                        ),
                      ),

                      const SizedBox(height: 10),

                      const Text(
                        'Mínimo 8 caracteres, con letras, números y un símbolo.',
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.grey,
                        ),
                      ),

                      const SizedBox(height: 15),

                      // ==========================
                      // CONFIRMAR PASSWORD
                      // ==========================

                      TextFormField(
                        controller: _confirmCtrl,
                        enabled: !_isRegistering,
                        obscureText: _obscureConfirm,
                        textInputAction:
                            TextInputAction.done,

                        validator:
                            _validateConfirmation,

                        onFieldSubmitted: (_) {
                          if (!_isRegistering) {
                            _registerUser();
                          }
                        },

                        decoration: InputDecoration(
                          labelText: 'Confirm Password',
                          hintText:
                              'Repite tu contraseña',

                          prefixIcon: const Icon(
                            Icons.lock_outline,
                          ),

                          suffixIcon: IconButton(
                            onPressed: _isRegistering
                                ? null
                                : () {
                                    setState(() {
                                      _obscureConfirm =
                                          !_obscureConfirm;
                                    });
                                  },

                            icon: Icon(
                              _obscureConfirm
                                  ? Icons.visibility
                                  : Icons.visibility_off,
                            ),
                          ),

                          border: OutlineInputBorder(
                            borderRadius:
                                BorderRadius.circular(12),
                          ),
                        ),
                      ),

                      const SizedBox(height: 25),

                      // ==========================
                      // BOTÓN CREAR CUENTA
                      // ==========================

                      SizedBox(
                        height: 50,
                        child: ElevatedButton(
                          onPressed: _isRegistering
                              ? null
                              : _registerUser,

                          style: ElevatedButton.styleFrom(
                            backgroundColor:
                                Colors.pinkAccent,
                            foregroundColor:
                                Colors.white,

                            shape: RoundedRectangleBorder(
                              borderRadius:
                                  BorderRadius.circular(12),
                            ),
                          ),

                          child: _isRegistering
                              ? const SizedBox(
                                  width: 22,
                                  height: 22,
                                  child:
                                      CircularProgressIndicator(
                                    color: Colors.white,
                                    strokeWidth: 2,
                                  ),
                                )
                              : const Text(
                                  'Create Account',
                                ),
                        ),
                      ),

                      const SizedBox(height: 15),

                      // ==========================
                      // REGRESAR A LOGIN
                      // ==========================

                      Row(
                        mainAxisAlignment:
                            MainAxisAlignment.center,

                        children: [
                          const Text(
                            'Already have an account?',
                          ),

                          TextButton(
                            onPressed: _isRegistering
                                ? null
                                : () {
                                    Navigator.of(
                                      context,
                                    ).pop();
                                  },

                            child: const Text(
                              'Login',
                              style: TextStyle(
                                color: Colors.pinkAccent,
                                fontWeight:
                                    FontWeight.bold,
                              ),
                            ),
                          ),
                        ],
                      ),

                      const SizedBox(height: 20),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  // ==========================================
  // DISPOSE
  // ==========================================

  @override
  void dispose() {
    _emailCtrl.dispose();
    _passwordCtrl.dispose();
    _confirmCtrl.dispose();

    super.dispose();
  }
}
