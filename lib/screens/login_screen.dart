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

        // Al entrar al email, comienza mirando al centro
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

        // Ya no está mirando el campo de email
        _isChecking?.change(false);

        // Regresar mirada al centro
        _numLook?.value = 50.0;

        // Cancelar cualquier timer pendiente
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
                    // ------------------------------------
                    // Crear controlador de la máquina
                    // ------------------------------------
                    _controller = StateMachineController.fromArtboard(
                      artboard,
                      'Login Machine',
                    );

                    if (_controller == null) {
                      debugPrint(
                        'ERROR: No se encontró la máquina "Login Machine".',
                      );
                      return;
                    }

                    // Agregar controlador al artboard
                    artboard.addController(_controller!);

                    // ------------------------------------
                    // OBTENER INPUTS DE RIVE
                    // ------------------------------------
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

                    // ------------------------------------
                    // DEBUG
                    // ------------------------------------
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
                focusNode: _emailFocus,

                keyboardType: TextInputType.emailAddress,

                onChanged: (value) {
                  // --------------------------------------
                  // 1. Bajar las manos
                  // --------------------------------------
                  _isHandsUp?.change(false);

                  // --------------------------------------
                  // 2. ACTIVAR EL ESTADO DE MIRAR
                  // --------------------------------------
                  _isChecking?.change(true);

                  // --------------------------------------
                  // 3. CALCULAR LA POSICIÓN DE LOS OJOS
                  // --------------------------------------
                  //
                  // Rango de numLook:
                  // 0   = extremo izquierdo
                  // 50  = centro
                  // 100 = extremo derecho
                  //
                  // Cada carácter mueve un poco la mirada.
                  //
                  final double look =
                      (value.length * 5.0)
                          .clamp(0.0, 100.0)
                          .toDouble();

                  // --------------------------------------
                  // 4. ACTUALIZAR LOS OJOS
                  // --------------------------------------
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

                  // --------------------------------------
                  // 5. REINICIAR TIMER
                  // --------------------------------------
                  //
                  // Cada vez que escribe o borra:
                  // se cancela el timer anterior
                  //
                  _typingDebounce?.cancel();

                  // --------------------------------------
                  // 6. ESPERAR 3 SEGUNDOS
                  // --------------------------------------
                  _typingDebounce = Timer(
                    const Duration(seconds: 3),
                    () {
                      if (!mounted) return;

                      // Dejar de mirar el campo
                      _isChecking?.change(false);

                      // Regresar los ojos al centro
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
                  hintText: 'Email',

                  prefixIcon: const Icon(Icons.email),

                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),

              const SizedBox(height: 10),

              // ==========================================
              // CAMPO CONTRASEÑA
              // ==========================================
              TextField(
                focusNode: _passwordFocus,

                obscureText: _obscure,

                keyboardType: TextInputType.text,

                onChanged: (value) {
                  // --------------------------------------
                  // Si hay contraseña, cubrir ojos
                  // --------------------------------------
                  _isHandsUp?.change(value.isNotEmpty);

                  // --------------------------------------
                  // Ya no mirar el email
                  // --------------------------------------
                  _isChecking?.change(false);

                  // --------------------------------------
                  // Regresar mirada al centro
                  // --------------------------------------
                  _numLook?.value = 50.0;

                  // Cancelar timer
                  _typingDebounce?.cancel();
                },

                decoration: InputDecoration(
                  hintText: 'Contraseña',

                  prefixIcon: const Icon(Icons.lock),

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
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
            ],
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
    _emailFocus.dispose();
    _passwordFocus.dispose();

    _typingDebounce?.cancel();

    super.dispose();
  }
}