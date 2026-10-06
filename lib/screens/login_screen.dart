
import 'dart:async';

import 'package:flutter/material.dart';
import 'package:rive/rive.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen>
    with SingleTickerProviderStateMixin {

  // ==========================================
  // CONTRASEÑA
  // ==========================================

  bool _obscure = true;

  // ==========================================
  // REMEMBER ME
  // ==========================================

  bool _rememberMe = false;

  // Bandera para evitar pulsaciones repetidas
  bool _isRememberAnimating = false;

  // Controlador de la animación del interruptor
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
  // CONTROLLERS
  // ==========================================

  final TextEditingController _emailCtrl =
      TextEditingController();

  final TextEditingController _passwordCtrl =
      TextEditingController();

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

  // Mínimo 8 caracteres, una letra,
  // un número y un símbolo.
  // Ejemplo válido: jasj@.2828

  bool isValidPassword(String password) {
    final re = RegExp(
      r'^(?=.*[A-Za-z])(?=.*\d)(?=.*[^A-Za-z0-9]).{8,}$',
    );

    return re.hasMatch(password);
  }

  // ==========================================
  // REMEMBER ME - CONTROL ANTI-SPAM
  // ==========================================

  void _toggleRememberMe() {

    // Si la animación está ejecutándose,
    // ignoramos cualquier nuevo toque.
    if (_isRememberAnimating) {
      return;
    }

    setState(() {
      _isRememberAnimating = true;
      _rememberMe = !_rememberMe;
    });

    // Iniciar animación según el estado.
    if (_rememberMe) {
      _rememberController.forward();
    } else {
      _rememberController.reverse();
    }
  }

  // Escucha exactamente cuándo termina
  // la animación del interruptor.
  void _onRememberAnimationStatus(
    AnimationStatus status,
  ) {

    if (status == AnimationStatus.completed ||
        status == AnimationStatus.dismissed) {

      if (!mounted) return;

      setState(() {
        // Se vuelve a permitir la interacción.
        _isRememberAnimating = false;
      });

      debugPrint(
        'Remember me: $_rememberMe',
      );

      debugPrint(
        'Animación terminada. Toques habilitados.',
      );
    }
  }

  // ==========================================
  // BOTÓN LOGIN
  // ==========================================

  void _onLogin() {

    final email = _emailCtrl.text.trim();
    final password = _passwordCtrl.text.trim();

    final String? eError =
        isValidEmail(email)
            ? null
            : 'Invalid Email';

    final String? pError =
        isValidPassword(password)
            ? null
            : 'Invalid Password';

    setState(() {
      _emailError = eError;
      _passwordError = pError;
    });

    // Cerrar el teclado
    FocusScope.of(context).unfocus();

    // Cancelar timer
    _typingDebounce?.cancel();

    // Reiniciar posición del oso
    _isChecking?.change(false);
    _isHandsUp?.change(false);
    _numLook?.value = 50.0;

    // Animación de resultado
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

    // ==========================================
    // CONTROLADOR DE REMEMBER ME
    // ==========================================

    _rememberController = AnimationController(
      vsync: this,
      duration: const Duration(
        milliseconds: 350,
      ),
    );

    // Detectar cuándo termina la animación.
    _rememberController.addStatusListener(
      _onRememberAnimationStatus,
    );

    // ==========================================
    // FOCO DEL EMAIL
    // ==========================================

    _emailFocus.addListener(() {
      if (_emailFocus.hasFocus) {

        // El oso baja las manos.
        _isHandsUp?.change(false);

        // Mirada al centro.
        _numLook?.value = 50.0;
      }
    });

    // ==========================================
    // FOCO DE LA CONTRASEÑA
    // ==========================================

    _passwordFocus.addListener(() {
      if (_passwordFocus.hasFocus) {

        // El oso se tapa los ojos.
        _isHandsUp?.change(true);

        // Deja de mirar el correo.
        _isChecking?.change(false);

        // Regresa al centro.
        _numLook?.value = 50.0;

        _typingDebounce?.cancel();
      }
    });
  }

  // ==========================================
  // WIDGET REMEMBER ME
  // ==========================================

  Widget _buildRememberMe() {

    return Semantics(
      label: 'Remember me',
      button: true,
      toggled: _rememberMe,
      enabled: !_isRememberAnimating,

      child: GestureDetector(

        // ANTI-SPAM:
        // Si está animándose, no acepta toques.
        onTap: _isRememberAnimating
            ? null
            : _toggleRememberMe,

        behavior: HitTestBehavior.opaque,

        child: Padding(
          padding: const EdgeInsets.symmetric(
            vertical: 6,
          ),

          child: Row(
            children: [

              // INTERRUPTOR ANIMADO
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

                      // Gris cuando está desactivado.
                      // Rosa cuando está activado.
                      color: Color.lerp(
                        Colors.grey.shade400,
                        Colors.pinkAccent,
                        progress,
                      ),

                      borderRadius:
                          BorderRadius.circular(30),
                    ),

                    child: Align(

                      // Movimiento del círculo
                      // de izquierda a derecha.
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

              // TEXTO
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
  // BUILD
  // ==========================================

  @override
  Widget build(BuildContext context) {

    final Size size =
        MediaQuery.of(context).size;

    return Scaffold(

      body: SafeArea(

        child: SingleChildScrollView(

          child: Padding(
            padding: const EdgeInsets.symmetric(
              horizontal: 20,
            ),

            child: Column(
              children: [

                // ==================================
                // OSITO ANIMADO
                // ==================================

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

                // ==================================
                // EMAIL
                // ==================================

                TextField(
                  controller: _emailCtrl,
                  focusNode: _emailFocus,

                  keyboardType:
                      TextInputType.emailAddress,

                  onChanged: (value) {

                    if (_emailError != null) {
                      setState(() {
                        _emailError = null;
                      });
                    }

                    // Bajar manos
                    _isHandsUp?.change(false);

                    // Oso mira el email
                    _isChecking?.change(true);

                    final double look =
                        (value.length * 5.0)
                            .clamp(0.0, 100.0)
                            .toDouble();

                    if (_numLook != null) {
                      _numLook!.value = look;
                    }

                    _typingDebounce?.cancel();

                    // Después de 3 segundos
                    // sin escribir, el oso deja
                    // de mirar el email.
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

                // ==================================
                // PASSWORD
                // ==================================

                TextField(
                  controller: _passwordCtrl,
                  focusNode: _passwordFocus,

                  obscureText: _obscure,

                  keyboardType: TextInputType.text,

                  onChanged: (value) {

                    if (_passwordError != null) {

                      setState(() {
                        _passwordError = null;
                      });
                    }

                    // El oso se tapa los ojos.
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

                    // Mostrar y ocultar contraseña
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

                // ==================================
                // REMEMBER ME - NUEVA FUNCIÓN
                // ==================================

                _buildRememberMe(),

                const SizedBox(height: 10),

                // ==================================
                // FORGOT PASSWORD
                // ==================================

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

                // ==================================
                // BOTÓN LOGIN
                // ==================================

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

                // ==================================
                // SIGN UP
                // ==================================

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

    // Liberar controlador de animación
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
