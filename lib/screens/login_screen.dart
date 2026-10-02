import 'dart:async';

import 'package:flutter/material.dart';
import 'package:rive/rive.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  // ==========================================
  // CONTRASEÑA
  // ==========================================

  bool _obscure = true;

  // ==========================================
  // RIVE
  // ==========================================

  StateMachineController? _controller;

  // Entradas de la máquina de estados
  SMIBool? _isChecking;
  SMIBool? _isHandsUp;
  SMITrigger? _trigSuccess;
  SMITrigger? _trigFail;
  SMINumber? _numLook;

  // ==========================================
  // TIMER PARA DETECTAR QUE DEJÓ DE ESCRIBIR
  // ==========================================

  Timer? _typingDebounce;

  // ==========================================
  // FOCUS NODES
  // ==========================================

  final FocusNode _emailFocus = FocusNode();
  final FocusNode _passwordFocus = FocusNode();

  // ==========================================
  // CONTROLLERS
  // ==========================================

  final TextEditingController _emailCtrl = TextEditingController();
  final TextEditingController _passwordCtrl = TextEditingController();

  // ==========================================
  // ERRORES
  // ==========================================

  String? _emailError;
  String? _passwordError;

  // ==========================================
  // VALIDADORES
  // ==========================================

  bool isValidEmail(String email) {
    final re = RegExp(
      r'^[^\s@]+@[^\s@]+\.[^\s@]+$',
    );

    return re.hasMatch(email);
  }

  // La contraseña necesita:
  // - Mínimo 8 caracteres
  // - Al menos una letra
  // - Al menos un número
  // - Al menos un carácter especial
  //
  // NO necesita mayúscula obligatoriamente.
  //
  // Ejemplo válido: jasj@.2828
  bool isValidPassword(String password) {
    final re = RegExp(
      r'^(?=.*[A-Za-z])(?=.*\d)(?=.*[^A-Za-z0-9]).{8,}$',
    );

    return re.hasMatch(password);
  }

  // ==========================================
  // ACCIÓN DEL BOTÓN LOGIN
  // ==========================================

  void _onLogin() {
    final email = _emailCtrl.text.trim();
    final password = _passwordCtrl.text.trim();

    final String? eError =
        isValidEmail(email) ? null : 'Invalid Email';

    final String? pError =
        isValidPassword(password) ? null : 'Invalid Password';

    setState(() {
      _emailError = eError;
      _passwordError = pError;
    });

    // Cerrar teclado
    FocusScope.of(context).unfocus();

    // Cancelar timer
    _typingDebounce?.cancel();

    // Regresar oso a posición normal
    _isChecking?.change(false);
    _isHandsUp?.change(false);
    _numLook?.value = 50.0;

    // Activar animación correspondiente
    if (eError == null && pError == null) {
      _trigSuccess?.fire();
    } else {
      _trigFail?.fire();
    }
  }

  // ==========================================
  // INIT STATE
  // ==========================================

  @override
  void initState() {
    super.initState();

    // ------------------------------------------
    // Cuando cambia el foco del EMAIL
    // ------------------------------------------

    _emailFocus.addListener(() {
      if (_emailFocus.hasFocus) {
        // El osito baja las manos
        _isHandsUp?.change(false);

        // Mirada inicial al centro
        _numLook?.value = 50.0;
      }
    });

    // ------------------------------------------
    // Cuando cambia el foco de CONTRASEÑA
    // ------------------------------------------

    _passwordFocus.addListener(() {
      if (_passwordFocus.hasFocus) {
        // El osito se tapa los ojos
        _isHandsUp?.change(true);

        // Ya no mira el email
        _isChecking?.change(false);

        // Regresar mirada al centro
        _numLook?.value = 50.0;

        // Cancelar timer pendiente
        _typingDebounce?.cancel();
      }
    });
  }

  // ==========================================
  // BUILD
  // ==========================================

  @override
  Widget build(BuildContext context) {
    final Size size = MediaQuery.of(context).size;

    return Scaffold(
      body: SafeArea(
        child: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Column(
              children: [
                // ==========================================
                // OSITO
                // ==========================================

                SizedBox(
                  width: size.width,
                  height: 200,
                  child: RiveAnimation.asset(
                    'assets/login-bear.riv',
                    onInit: (artboard) {
                      // Crear controlador de la máquina
                      _controller =
                          StateMachineController.fromArtboard(
                        artboard,
                        'Login Machine',
                      );

                      if (_controller == null) {
                        debugPrint(
                          'ERROR: No se encontró la máquina "Login Machine".',
                        );
                        return;
                      }

                      // Agregar controlador
                      artboard.addController(_controller!);

                      // Obtener inputs
                      _isChecking =
                          _controller!.getBoolInput('isChecking');

                      _isHandsUp =
                          _controller!.getBoolInput('isHandsUp');

                      _trigSuccess =
                          _controller!.getTriggerInput('trigSuccess');

                      _trigFail =
                          _controller!.getTriggerInput('trigFail');

                      _numLook =
                          _controller!.getNumberInput('numLook');

                      // DEBUG
                      debugPrint('==============================');
                      debugPrint('RIVE INICIALIZADO');

                      debugPrint(
                        'isChecking: ${_isChecking != null}',
                      );

                      debugPrint(
                        'isHandsUp: ${_isHandsUp != null}',
                      );

                      debugPrint(
                        'trigSuccess: ${_trigSuccess != null}',
                      );

                      debugPrint(
                        'trigFail: ${_trigFail != null}',
                      );

                      debugPrint(
                        'numLook: ${_numLook != null}',
                      );

                      if (_numLook != null) {
                        debugPrint(
                          'numLook inicial: ${_numLook!.value}',
                        );

                        // Mirada inicial al centro
                        _numLook!.value = 50.0;
                      }

                      debugPrint('==============================');
                    },
                  ),
                ),

                const SizedBox(height: 10),

                // ==========================================
                // CAMPO EMAIL
                // ==========================================

                TextField(
                  controller: _emailCtrl,
                  focusNode: _emailFocus,
                  keyboardType: TextInputType.emailAddress,

                  onChanged: (value) {
                    // Quitar error mientras vuelve a escribir
                    if (_emailError != null) {
                      setState(() {
                        _emailError = null;
                      });
                    }

                    // Bajar las manos
                    _isHandsUp?.change(false);

                    // Activar estado de mirar
                    _isChecking?.change(true);

                    // Calcular posición de los ojos
                    final double look =
                        (value.length * 5.0)
                            .clamp(0.0, 100.0)
                            .toDouble();

                    // Actualizar los ojos
                    if (_numLook != null) {
                      _numLook!.value = look;

                      debugPrint(
                        'EMAIL: "$value"',
                      );

                      debugPrint(
                        'CARACTERES: ${value.length}',
                      );

                      debugPrint(
                        'numLook: ${_numLook!.value}',
                      );
                    } else {
                      debugPrint(
                        'ERROR: numLook es NULL',
                      );
                    }

                    // Reiniciar timer
                    _typingDebounce?.cancel();

                    // Esperar 3 segundos
                    _typingDebounce = Timer(
                      const Duration(seconds: 3),
                      () {
                        if (!mounted) return;

                        // Dejar de mirar el campo
                        _isChecking?.change(false);

                        // Regresar ojos al centro
                        _numLook?.value = 50.0;

                        debugPrint(
                          '3 segundos sin escribir -> '
                          'isChecking = false',
                        );

                        debugPrint(
                          'Mirada regresada a 50',
                        );
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

                // ==========================================
                // CAMPO CONTRASEÑA
                // ==========================================

                TextField(
                  controller: _passwordCtrl,
                  focusNode: _passwordFocus,
                  obscureText: _obscure,
                  keyboardType: TextInputType.text,

                  onChanged: (value) {
                    // Quitar el mensaje de error
                    // cuando vuelva a escribir
                    if (_passwordError != null) {
                      setState(() {
                        _passwordError = null;
                      });
                    }

                    // Si hay contraseña, cubrir ojos
                    _isHandsUp?.change(value.isNotEmpty);

                    // Ya no mirar el email
                    _isChecking?.change(false);

                    // Regresar mirada al centro
                    _numLook?.value = 50.0;

                    // Cancelar timer
                    _typingDebounce?.cancel();
                  },

                  decoration: InputDecoration(
                    errorText: _passwordError,
                    hintText: 'Password',

                    prefixIcon: const Icon(
                      Icons.lock,
                    ),

                    // Mostrar / ocultar contraseña
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

                // ==========================================
                // OLVIDÉ LA CONTRASEÑA
                // ==========================================

                SizedBox(
                  width: size.width,
                  child: const Text(
                    'forgot password?',
                    textAlign: TextAlign.right,
                    style: TextStyle(
                      decoration:
                          TextDecoration.underline,
                    ),
                  ),
                ),

                const SizedBox(height: 10),

                // ==========================================
                // BOTÓN LOGIN
                // ==========================================

                MaterialButton(
                  minWidth: size.width,
                  height: 50,
                  color: Colors.pinkAccent,

                  shape: RoundedRectangleBorder(
                    borderRadius:
                        BorderRadius.circular(12),
                  ),

                  onPressed: _onLogin,

                  child: const Text(
                    'Login',
                    style: TextStyle(
                      color: Colors.white,
                    ),
                  ),
                ),

                const SizedBox(height: 10),

                // ==========================================
                // SIGN UP
                // ==========================================

                SizedBox(
                  width: size.width,
                  child: Row(
                    mainAxisAlignment:
                        MainAxisAlignment.center,

                    children: [
                      const Text(
                        "Don't have an account?",
                      ),

                      TextButton(
                        onPressed: () {
                          // Acción para registrarse
                        },

                        child: const Text(
                          'Sign Up',
                          style: TextStyle(
                            color: Colors.black,
                            decoration:
                                TextDecoration.underline,
                            fontWeight:
                                FontWeight.bold,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 20),
              ],
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
    _typingDebounce?.cancel();

    _emailCtrl.dispose();
    _passwordCtrl.dispose();

    _emailFocus.dispose();
    _passwordFocus.dispose();

    super.dispose();
  }
}