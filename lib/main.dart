
import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:login_bear_animation/screens/login_screen.dart';

import 'firebase_options.dart';

// ==========================================
// INICIALIZACIÓN DE FIREBASE
// ==========================================

Future<void> main() async {
  // Asegura que Flutter esté inicializado.
  WidgetsFlutterBinding.ensureInitialized();

  try {
    // Inicializar Firebase con la configuración
    // generada por flutterfire configure.
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );

    // Mensaje para comprobar la Fase 1.
    debugPrint('✅ FIREBASE INICIALIZADO CORRECTAMENTE');

    // Mostrar la aplicación del osito.
    runApp(const MyApp());
  } catch (e) {
    // Si Firebase falla, mostrar el error
    // en lugar de abrir el Login sin conexión.
    debugPrint('❌ ERROR AL INICIALIZAR FIREBASE: $e');

    runApp(
      MaterialApp(
        debugShowCheckedModeBanner: false,
        home: Scaffold(
          body: Center(
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Text(
                'No se pudo inicializar Firebase.\n\n$e',
                textAlign: TextAlign.center,
              ),
            ),
          ),
        ),
      ),
    );
  }
}

// ==========================================
// APLICACIÓN PRINCIPAL
// ==========================================

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,

      title: 'Rive Animated Login',

      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(
          seedColor: Colors.deepPurple,
        ),
      ),

      // Conservamos la pantalla del osito.
      home: const LoginScreen(),
    );
  }
}
