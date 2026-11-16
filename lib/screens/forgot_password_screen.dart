
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';

class ForgotPasswordScreen extends StatefulWidget {
  final String initialEmail;

  const ForgotPasswordScreen({
    super.key,
    this.initialEmail = '',
  });

  @override
  State<ForgotPasswordScreen> createState() =>
      _ForgotPasswordScreenState();
}

class _ForgotPasswordScreenState
    extends State<ForgotPasswordScreen> {
  final _formKey = GlobalKey<FormState>();

  late final TextEditingController _emailCtrl;

  bool _isSending = false;
  bool _sent = false;

  @override
  void initState() {
    super.initState();

    _emailCtrl = TextEditingController(
      text: widget.initialEmail,
    );
  }

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

  String _errorMessage(FirebaseAuthException error) {
    switch (error.code) {
      case 'invalid-email':
        return 'El correo no es válido.';

      case 'too-many-requests':
        return 'Demasiados intentos. Intenta más tarde.';

      case 'network-request-failed':
        return 'Comprueba tu conexión a Internet.';

      default:
        debugPrint('Error Firebase: ${error.code}');
        return 'No se pudo procesar la solicitud.';
    }
  }

  Future<void> _sendResetEmail() async {
    if (_isSending || _sent) return;

    if (!_formKey.currentState!.validate()) {
      return;
    }

    FocusScope.of(context).unfocus();

    setState(() {
      _isSending = true;
    });

    try {
      await FirebaseAuth.instance.sendPasswordResetEmail(
        email: _emailCtrl.text.trim(),
      );

      if (!mounted) return;

      setState(() {
        _sent = true;
      });

      debugPrint(
        'FIREBASE: solicitud de recuperación procesada',
      );
    } on FirebaseAuthException catch (error) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(_errorMessage(error)),
        ),
      );
    } catch (error) {
      if (!mounted) return;

      debugPrint('Error: $error');

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Ocurrió un error. Intenta nuevamente.',
          ),
        ),
      );
    } finally {
      if (mounted) {
        setState(() {
          _isSending = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Forgot Password'),
        centerTitle: true,
      ),
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(
              maxWidth: 500,
            ),
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(24),
              child: _sent
                  ? _buildSuccess()
                  : _buildForm(),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildForm() {
    return Form(
      key: _formKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const Icon(
            Icons.lock_reset,
            size: 85,
            color: Colors.pinkAccent,
          ),

          const SizedBox(height: 20),

          const Text(
            'Reset Password',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 25,
              fontWeight: FontWeight.bold,
            ),
          ),

          const SizedBox(height: 12),

          const Text(
            'Escribe tu correo electrónico para '
            'recibir instrucciones de recuperación.',
            textAlign: TextAlign.center,
          ),

          const SizedBox(height: 30),

          TextFormField(
            controller: _emailCtrl,
            enabled: !_isSending,
            keyboardType: TextInputType.emailAddress,
            textInputAction: TextInputAction.done,
            validator: _validateEmail,
            onFieldSubmitted: (_) {
              _sendResetEmail();
            },
            decoration: InputDecoration(
              labelText: 'Email',
              prefixIcon: const Icon(Icons.email),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
          ),

          const SizedBox(height: 25),

          SizedBox(
            height: 50,
            child: ElevatedButton(
              onPressed: _isSending
                  ? null
                  : _sendResetEmail,
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.pinkAccent,
                foregroundColor: Colors.white,
              ),
              child: _isSending
                  ? const SizedBox(
                      height: 22,
                      width: 22,
                      child: CircularProgressIndicator(
                        color: Colors.white,
                        strokeWidth: 2,
                      ),
                    )
                  : const Text(
                      'Send Reset Email',
                    ),
            ),
          ),

          const SizedBox(height: 15),

          TextButton(
            onPressed: _isSending
                ? null
                : () => Navigator.of(context).pop(),
            child: const Text('Back to Login'),
          ),
        ],
      ),
    );
  }

  Widget _buildSuccess() {
    return Column(
      children: [
        const Icon(
          Icons.mark_email_read,
          size: 90,
          color: Colors.green,
        ),

        const SizedBox(height: 20),

        const Text(
          'Solicitud procesada',
          textAlign: TextAlign.center,
          style: TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.bold,
          ),
        ),

        const SizedBox(height: 15),

        const Text(
          'Si existe una cuenta con ese correo, '
          'recibirás instrucciones para cambiar '
          'tu contraseña.\n\n'
          'Revisa también la carpeta de spam.',
          textAlign: TextAlign.center,
        ),

        const SizedBox(height: 30),

        SizedBox(
          width: double.infinity,
          height: 50,
          child: ElevatedButton(
            onPressed: () {
              Navigator.of(context).pop();
            },
            child: const Text('Back to Login'),
          ),
        ),
      ],
    );
  }

  @override
  void dispose() {
    _emailCtrl.dispose();
    super.dispose();
  }
}
