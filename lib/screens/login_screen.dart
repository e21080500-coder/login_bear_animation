
import 'dart:async';

import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:rive/rive.dart';
import 'signup_screen.dart';
import 'forgot_password_screen.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen>
    with SingleTickerProviderStateMixin {

  // ==========================================
  // FIREBASE AUTHENTICATION
  // ==========================================

  final FirebaseAuth _auth = FirebaseAuth.instance;

  StreamSubscription<User?>? _authSubscription;

  User? _currentUser;

  bool _authReady = false;
  bool _showHome = false;
  bool _isLoggingIn = false;
  bool _isSigningOut = false;

  // ==========================================
  // CONTRASEÑA
  // ==========================================

  bool _obscure = true;

  // ==========================================
  // REMEMBER ME
  // ==========================================

  bool _rememberMe = false;
  bool _isRememberAnimating = false;

  late final AnimationController _rememberController;

  // ==========================================
  // RIVE - OSITO ANIMADO
  // ==========================================

  StateMachineController? _controller;

  SMIBool? _isChecking;
  SMIBool? _isHandsUp;

  SMITrigger? _trigSuccess;
  SMITrigger? _trigFail;

  SMINumber? _numLook;

  // ==========================================
  // TIMER
  // ==========================================

  Timer? _typingDebounce;

  // ==========================================
  // FOCUS NODES
  // ==========================================

  final FocusNode _emailFocus = FocusNode();
  final FocusNode _passwordFocus = FocusNode();

  // ==========================================
  // TEXT CONTROLLERS
  // ==========================================

  final TextEditingController _emailCtrl =
      TextEditingController();

  final TextEditingController _passwordCtrl =
      TextEditingController();

  // ==========================================
  // MENSAJES DE ERROR
  // ==========================================

  String? _emailError;
  String? _passwordError;

  // ==========================================
  // VALIDACIONES
  // ==========================================

  bool isValidEmail(String email) {
    final re = RegExp(
      r'^[^\s@]+@[^\s@]+\.[^\s@]+$',
    );

    return re.hasMatch(email);
  }

  // Conservamos la validación anterior:
  // - Mínimo 8 caracteres
  // - Una letra
  // - Un número
  // - Un carácter especial
  // - No exige mayúsculas

  bool isValidPassword(String password) {
    final re = RegExp(
      r'^(?=.*[A-Za-z])(?=.*\d)(?=.*[^A-Za-z0-9]).{8,}$',
    );

    return re.hasMatch(password);
  }

  // ==========================================
  // MENSAJES
  // ==========================================

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

  String _firebaseErrorMessage(
    FirebaseAuthException error,
  ) {
    switch (error.code) {
      case 'invalid-email':
        return 'El correo electrónico no es válido.';

      case 'invalid-credential':
      case 'invalid-login-credentials':
      case 'user-not-found':
      case 'wrong-password':
        return 'Correo o contraseña incorrectos.';

      case 'user-disabled':
        return 'Esta cuenta ha sido deshabilitada.';

      case 'too-many-requests':
        return 'Demasiados intentos. Intenta más tarde.';

      case 'network-request-failed':
        return 'Comprueba tu conexión a Internet.';

      case 'operation-not-allowed':
        return 'El acceso por correo no está habilitado.';

      default:
        debugPrint(
          'Error Firebase Auth: ${error.code}',
        );

        return 'No se pudo iniciar sesión. Intenta otra vez.';
    }
  }

  // ==========================================
  // LISTENER DE AUTENTICACIÓN FIREBASE
  // ==========================================

  void _listenToAuthChanges() {
    _authSubscription =
        _auth.authStateChanges().listen(
      (User? user) {
        if (!mounted) return;

        debugPrint(
          user == null
              ? 'FIREBASE: sesión cerrada'
              : 'FIREBASE: usuario autenticado',
        );

        setState(() {
          _authReady = true;
          _currentUser = user;

          if (user == null) {
            _showHome = false;
          } else if (!_isLoggingIn) {
            // Sesión restaurada al abrir la app
            // o iniciada fuera del formulario.
            _showHome = true;
          }
        });
      },
      onError: (Object error) {
        debugPrint(
          'Error al escuchar sesión: $error',
        );

        if (!mounted) return;

        setState(() {
          _authReady = true;
        });

        _showMessage(
          'No se pudo comprobar el estado de sesión.',
        );
      },
    );
  }

  // ==========================================
  // REMEMBER ME - ANTI-SPAM
  // ==========================================

  void _toggleRememberMe() {
    if (_isRememberAnimating || _isLoggingIn) {
      return;
    }

    setState(() {
      _isRememberAnimating = true;
      _rememberMe = !_rememberMe;
    });

    if (_rememberMe) {
      _rememberController.forward();
    } else {
      _rememberController.reverse();
    }
  }

  void _onRememberAnimationStatus(
    AnimationStatus status,
  ) {
    if (status == AnimationStatus.completed ||
        status == AnimationStatus.dismissed) {
      if (!mounted) return;

      setState(() {
        _isRememberAnimating = false;
      });

      debugPrint(
        'Remember me: $_rememberMe',
      );
    }
  }

  // ==========================================
  // REINICIAR POSICIÓN DEL OSITO
  // ==========================================

  void _resetBear() {
    _typingDebounce?.cancel();

    _isChecking?.change(false);
    _isHandsUp?.change(false);

    _numLook?.value = 50.0;
  }

  // ==========================================
  // LOGIN REAL CON FIREBASE
  // ==========================================

  Future<void> _onLogin() async {
    // Evitar pulsaciones repetidas.
    if (_isLoggingIn || !_authReady) {
      return;
    }

    final email = _emailCtrl.text.trim();
    final password = _passwordCtrl.text;

    final String? eError = isValidEmail(email)
        ? null
        : 'Invalid Email';

    final String? pError = isValidPassword(password)
        ? null
        : 'Invalid Password';

    setState(() {
      _emailError = eError;
      _passwordError = pError;
    });

    FocusScope.of(context).unfocus();
    _resetBear();

    // Primero comprobar formato local.
    if (eError != null || pError != null) {
      _trigFail?.fire();
      return;
    }

    // Bloquear botón y formulario.
    setState(() {
      _isLoggingIn = true;
    });

    try {
      debugPrint(
        'FIREBASE: intentando iniciar sesión...',
      );

      // Autenticación real.
      final credential =
          await _auth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );

      if (!mounted) return;

      debugPrint(
        'FIREBASE: inicio de sesión exitoso',
      );

      // ANIMACIÓN DEL OSITO: ÉXITO
      _resetBear();
      _trigSuccess?.fire();

      // Tiempo para apreciar la animación
      // antes de mostrar la bienvenida.
      await Future<void>.delayed(
        const Duration(milliseconds: 1400),
      );

      if (!mounted) return;

      setState(() {
        _currentUser =
            credential.user ?? _auth.currentUser;

        _showHome = _currentUser != null;
      });
    } on FirebaseAuthException catch (error) {
      if (!mounted) return;

      final message = _firebaseErrorMessage(error);

      debugPrint(
        'FIREBASE ERROR: ${error.code}',
      );

      // ANIMACIÓN DEL OSITO: ERROR
      _resetBear();
      _trigFail?.fire();

      setState(() {
        if (error.code == 'invalid-email') {
          _emailError = message;
        } else if (
            error.code == 'invalid-credential' ||
            error.code == 'invalid-login-credentials' ||
            error.code == 'user-not-found' ||
            error.code == 'wrong-password') {
          _passwordError = message;
        }
      });

      _showMessage(message);
    } catch (error) {
      if (!mounted) return;

      debugPrint(
        'ERROR INESPERADO LOGIN: $error',
      );

      _resetBear();
      _trigFail?.fire();

      _showMessage(
        'Ocurrió un error al iniciar sesión.',
      );
    } finally {
      if (mounted) {
        setState(() {
          _isLoggingIn = false;
        });
      }
    }
  }

  // ==========================================
  // CERRAR SESIÓN
  // ==========================================

  Future<void> _onSignOut() async {
    if (_isSigningOut) return;

    setState(() {
      _isSigningOut = true;
    });

    try {
      await _auth.signOut();

      if (!mounted) return;

      // Limpiar los campos anteriores.
      _emailCtrl.clear();
      _passwordCtrl.clear();

      _resetBear();

      _rememberMe = false;
      _isRememberAnimating = false;
      _rememberController.reset();

      setState(() {
        _currentUser = null;
        _showHome = false;

        _emailError = null;
        _passwordError = null;

        _obscure = true;
      });

      debugPrint(
        'FIREBASE: sesión cerrada correctamente',
      );
    } on FirebaseAuthException catch (error) {
      if (!mounted) return;

      _showMessage(
        _firebaseErrorMessage(error),
      );
    } catch (error) {
      if (!mounted) return;

      debugPrint(
        'Error al cerrar sesión: $error',
      );

      _showMessage(
        'No se pudo cerrar sesión.',
      );
    } finally {
      if (mounted) {
        setState(() {
          _isSigningOut = false;
        });
      }
    }
  }

  // ==========================================
  // INIT STATE
  // ==========================================

  @override
  void initState() {
    super.initState();

    // Controlador Remember me.
    _rememberController = AnimationController(
      vsync: this,
      duration: const Duration(
        milliseconds: 350,
      ),
    );

    _rememberController.addStatusListener(
      _onRememberAnimationStatus,
    );

    // Escuchar si existe una sesión de Firebase.
    _listenToAuthChanges();

    // Osito al seleccionar Email.
    _emailFocus.addListener(() {
      if (_emailFocus.hasFocus) {
        _isHandsUp?.change(false);
        _numLook?.value = 50.0;
      }
    });

    // Osito al seleccionar Password.
    _passwordFocus.addListener(() {
      if (_passwordFocus.hasFocus) {
        _isHandsUp?.change(true);
        _isChecking?.change(false);
        _numLook?.value = 50.0;

        _typingDebounce?.cancel();
      }
    });
  }

  // ==========================================
  // WIDGET REMEMBER ME
  // ==========================================

  Widget _buildRememberMe() {
    final bool enabled =
        !_isRememberAnimating && !_isLoggingIn;

    return Semantics(
      label: 'Remember me',
      button: true,
      toggled: _rememberMe,
      enabled: enabled,
      child: GestureDetector(
        onTap: enabled ? _toggleRememberMe : null,
        behavior: HitTestBehavior.opaque,
        child: Padding(
          padding: const EdgeInsets.symmetric(
            vertical: 6,
          ),
          child: Row(
            children: [
              AnimatedBuilder(
                animation: _rememberController,
                builder: (context, child) {
                  final double progress =
                      Curves.easeInOut.transform(
                    _rememberController.value,
                  );

                  return Container(
                    width: 58,
                    height: 34,
                    padding: const EdgeInsets.all(4),
                    decoration: BoxDecoration(
                      color: Color.lerp(
                        Colors.grey.shade400,
                        Colors.pinkAccent,
                        progress,
                      ),
                      borderRadius:
                          BorderRadius.circular(30),
                    ),
                    child: Align(
                      alignment: Alignment.lerp(
                        Alignment.centerLeft,
                        Alignment.centerRight,
                        progress,
                      )!,
                      child: Container(
                        width: 26,
                        height: 26,
                        decoration: const BoxDecoration(
                          color: Colors.white,
                          shape: BoxShape.circle,
                        ),
                      ),
                    ),
                  );
                },
              ),

              const SizedBox(width: 12),

              const Text(
                'Remember me',
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ==========================================
  // PANTALLA DE BIENVENIDA
  // ==========================================

  Widget _buildHome() {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Welcome Back'),
        centerTitle: true,
      ),
      body: SafeArea(
        child: Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisAlignment:
                  MainAxisAlignment.center,
              children: [
                const Icon(
                  Icons.check_circle,
                  color: Colors.green,
                  size: 90,
                ),

                const SizedBox(height: 20),

                const Text(
                  '¡Inicio de sesión exitoso!',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                  ),
                ),

                const SizedBox(height: 15),

                const Text(
                  'Bienvenido a la aplicación del osito.',
                  textAlign: TextAlign.center,
                ),

                const SizedBox(height: 15),

                Text(
                  _currentUser?.email ?? '',
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    fontSize: 16,
                    color: Colors.pinkAccent,
                  ),
                ),

                const SizedBox(height: 30),

                SizedBox(
                  width: double.infinity,
                  height: 50,
                  child: ElevatedButton.icon(
                    onPressed: _isSigningOut
                        ? null
                        : _onSignOut,
                    icon: const Icon(Icons.logout),
                    label: Text(
                      _isSigningOut
                          ? 'Cerrando sesión...'
                          : 'Cerrar sesión',
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // ==========================================
  // PANTALLA LOGIN CON OSITO
  // ==========================================

  Widget _buildLogin() {
    final Size size = MediaQuery.of(context).size;

    return Scaffold(
      body: SafeArea(
        child: AbsorbPointer(
          absorbing: _isLoggingIn || _isSigningOut,
          child: SingleChildScrollView(
            child: Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: 20,
              ),
              child: Column(
                children: [

                  // ============================
                  // OSITO ANIMADO RIVE
                  // ============================

                  SizedBox(
                    width: size.width,
                    height: 200,
                    child: RiveAnimation.asset(
                      'assets/login-bear.riv',
                      onInit: (artboard) {
                        _controller =
                            StateMachineController
                                .fromArtboard(
                          artboard,
                          'Login Machine',
                        );

                        if (_controller == null) {
                          debugPrint(
                            'ERROR: No se encontró Login Machine',
                          );
                          return;
                        }

                        artboard.addController(
                          _controller!,
                        );

                        _isChecking =
                            _controller!.getBoolInput(
                          'isChecking',
                        );

                        _isHandsUp =
                            _controller!.getBoolInput(
                          'isHandsUp',
                        );

                        _trigSuccess =
                            _controller!.getTriggerInput(
                          'trigSuccess',
                        );

                        _trigFail =
                            _controller!.getTriggerInput(
                          'trigFail',
                        );

                        _numLook =
                            _controller!.getNumberInput(
                          'numLook',
                        );

                        _numLook?.value = 50.0;

                        debugPrint(
                          'RIVE INICIALIZADO',
                        );
                      },
                    ),
                  ),

                  const SizedBox(height: 10),

                  // ============================
                  // EMAIL
                  // ============================

                  TextField(
                    controller: _emailCtrl,
                    focusNode: _emailFocus,
                    keyboardType:
                        TextInputType.emailAddress,
                    enabled: !_isLoggingIn,
                    onChanged: (value) {
                      if (_emailError != null) {
                        setState(() {
                          _emailError = null;
                        });
                      }

                      _isHandsUp?.change(false);
                      _isChecking?.change(true);

                      final double look =
                          (value.length * 5.0)
                              .clamp(0.0, 100.0)
                              .toDouble();

                      _numLook?.value = look;

                      _typingDebounce?.cancel();

                      _typingDebounce = Timer(
                        const Duration(seconds: 3),
                        () {
                          if (!mounted) return;

                          _isChecking?.change(false);
                          _numLook?.value = 50.0;
                        },
                      );
                    },
                    decoration: InputDecoration(
                      errorText: _emailError,
                      hintText: 'Email',
                      prefixIcon: const Icon(
                        Icons.email,
                      ),
                      border: OutlineInputBorder(
                        borderRadius:
                            BorderRadius.circular(12),
                      ),
                    ),
                  ),

                  const SizedBox(height: 10),

                  // ============================
                  // PASSWORD
                  // ============================

                  TextField(
                    controller: _passwordCtrl,
                    focusNode: _passwordFocus,
                    obscureText: _obscure,
                    enabled: !_isLoggingIn,
                    onChanged: (value) {
                      if (_passwordError != null) {
                        setState(() {
                          _passwordError = null;
                        });
                      }

                      _isHandsUp?.change(
                        value.isNotEmpty,
                      );

                      _isChecking?.change(false);
                      _numLook?.value = 50.0;

                      _typingDebounce?.cancel();
                    },
                    decoration: InputDecoration(
                      errorText: _passwordError,
                      hintText: 'Password',
                      prefixIcon: const Icon(
                        Icons.lock,
                      ),
                      suffixIcon: IconButton(
                        icon: Icon(
                          _obscure
                              ? Icons.visibility
                              : Icons.visibility_off,
                        ),
                        onPressed: () {
                          setState(() {
                            _obscure = !_obscure;
                          });
                        },
                      ),
                      border: OutlineInputBorder(
                        borderRadius:
                            BorderRadius.circular(12),
                      ),
                    ),
                  ),

                  const SizedBox(height: 10),

                  // ============================
                  // REMEMBER ME
                  // ============================

                  _buildRememberMe(),

                  const SizedBox(height: 10),

                  // ============================
                  // FORGOT PASSWORD
                  // ============================

                  Align(
                    alignment: Alignment.centerRight,
                    child: TextButton(
                      onPressed: () {
  Navigator.of(context).push(
    MaterialPageRoute<void>(
      builder: (context) => ForgotPasswordScreen(
        initialEmail: _emailCtrl.text.trim(),
      ),
    ),
  );
},
                      child: const Text(
                        'forgot password?',
                        style: TextStyle(
                          color: Colors.black87,
                          decoration:
                              TextDecoration.underline,
                        ),
                      ),
                    ),
                  ),

                  const SizedBox(height: 10),

                  // ============================
                  // BOTÓN LOGIN
                  // ============================

                  SizedBox(
                    width: double.infinity,
                    height: 50,
                    child: ElevatedButton(
                      onPressed: _isLoggingIn
                          ? null
                          : _onLogin,
                      style: ElevatedButton.styleFrom(
                        backgroundColor:
                            Colors.pinkAccent,
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                          borderRadius:
                              BorderRadius.circular(12),
                        ),
                      ),
                      child: _isLoggingIn
                          ? const SizedBox(
                              width: 22,
                              height: 22,
                              child:
                                  CircularProgressIndicator(
                                strokeWidth: 2,
                                color: Colors.white,
                              ),
                            )
                          : const Text('Login'),
                    ),
                  ),

                  const SizedBox(height: 10),

                  // ============================
                  // SIGN UP
                  // ============================

                  Row(
                    mainAxisAlignment:
                        MainAxisAlignment.center,
                    children: [
                      const Text(
                        "Don't have an account?",
                      ),

                      TextButton(
  onPressed: () {
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (context) => const SignUpScreen(),
      ),
    );
  },
                        child: const Text(
                          'Sign Up',
                          style: TextStyle(
                            color: Colors.black,
                            decoration:
                                TextDecoration.underline,
                            fontWeight: FontWeight.bold,
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
    );
  }

  // ==========================================
  // BUILD
  // ==========================================

  @override
  Widget build(BuildContext context) {
    // Esperamos a que Firebase confirme
    // si ya existe una sesión iniciada.
    if (!_authReady) {
      return const Scaffold(
        body: Center(
          child: CircularProgressIndicator(),
        ),
      );
    }

    // Si Firebase tiene una sesión activa,
    // mostrar la pantalla de bienvenida.
    if (_showHome && _currentUser != null) {
      return _buildHome();
    }

    // Si no hay sesión, mostrar el osito.
    return _buildLogin();
  }

  // ==========================================
  // DISPOSE
  // ==========================================

  @override
  void dispose() {
    _typingDebounce?.cancel();

    _authSubscription?.cancel();

    _rememberController.removeStatusListener(
      _onRememberAnimationStatus,
    );

    _rememberController.dispose();

    _emailCtrl.dispose();
    _passwordCtrl.dispose();

    _emailFocus.dispose();
    _passwordFocus.dispose();

    super.dispose();
  }
}
