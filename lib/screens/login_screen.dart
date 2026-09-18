import 'package:flutter/material.dart';
import 'package:rive/rive.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  // Control para mostrar u ocultar la contraseña
  bool _obscure = true;

  // Cerebro de la animación
  StateMachineController? _controller;

  // Entradas de la máquina de estados
  SMIBool? _isChecking;
  SMIBool? _isHandsUp;
  SMITrigger? _trigSuccess;
  SMITrigger? _trigFail;

  @override
  Widget build(BuildContext context) {
    // Para obtener el tamaño de la pantalla
    final Size size = MediaQuery.of(context).size;

    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: Column(
            children: [
              // =========================
              // ANIMACIÓN DEL OSITO
              // =========================
              SizedBox(
                width: size.width,
                height: 200,
                child: RiveAnimation.asset(
                  'assets/login-bear.riv',

                  // Conectar la máquina de estados
                  onInit: (artboard) {
                    _controller = StateMachineController.fromArtboard(
                      artboard,
                      'Login Machine',
                    );

                    // Verificar que el controlador se haya creado
                    if (_controller == null) return;

                    // Agregar el controlador al artboard
                    artboard.addController(_controller!);

                    // Vincular las variables de la animación
                    _isChecking =
                        _controller!.findSMI('isChecking');

                    _isHandsUp =
                        _controller!.findSMI('isHandsUp');

                    _trigSuccess =
                        _controller!.findSMI('trigSuccess');

                    _trigFail =
                        _controller!.findSMI('trigFail');
                  },
                ),
              ),

              const SizedBox(height: 10),

              // =========================
              // CAMPO DE EMAIL
              // =========================
              TextField(
                onChanged: (value) {
                  // Al escribir el email,
                  // el osito NO se tapa los ojos
                  if (_isHandsUp != null) {
                    _isHandsUp!.change(false);
                  }

                  // El osito mira hacia el email
                  if (_isChecking != null) {
                    _isChecking!.change(true);
                  }
                },

                // Teclado para email
                keyboardType: TextInputType.emailAddress,

                decoration: InputDecoration(
                  hintText: 'Email',
                  prefixIcon: const Icon(Icons.email),

                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),

              const SizedBox(height: 10),

              // =========================
              // CAMPO DE CONTRASEÑA
              // =========================
              TextField(
                // Ocultar o mostrar contraseña
                obscureText: _obscure,

                // Al escribir en contraseña
                onChanged: (value) {
                  // Si hay texto en la contraseña,
                  // el osito se tapa los ojos
                  if (_isHandsUp != null) {
                    _isHandsUp!.change(value.isNotEmpty);
                  }

                  // Deja de mirar hacia el email
                  if (_isChecking != null) {
                    _isChecking!.change(false);
                  }
                },

                // Teclado para contraseña
                keyboardType: TextInputType.text,

                decoration: InputDecoration(
                  hintText: 'Contraseña',

                  prefixIcon: const Icon(Icons.lock),

                  // Botón para mostrar/ocultar contraseña
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
}