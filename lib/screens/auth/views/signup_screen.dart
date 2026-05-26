import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:shop/constants.dart';
import 'package:shop/route/route_constants.dart';
import 'package:shop/services/ecomarket_api_service.dart';
import 'package:shop/services/session_service.dart';

class SignUpScreen extends StatefulWidget {
  const SignUpScreen({super.key});

  @override
  State<SignUpScreen> createState() => _SignUpScreenState();
}

class _SignUpScreenState extends State<SignUpScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _phoneController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _accepted = true;
  bool _loading = false;
  String? _error;

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _register() async {
    if (!_formKey.currentState!.validate()) return;
    if (!_accepted) {
      setState(() => _error = 'Debes aceptar los términos y la política de privacidad.');
      return;
    }
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final api = EcoMarketApiService();
      final body = await api.register(
        name: _nameController.text.trim(),
        email: _emailController.text.trim(),
        phone: _phoneController.text.trim(),
        password: _passwordController.text,
      );
      final token = api.extractCustomerToken(body);
      if (token.isNotEmpty) {
        await SessionService.saveSession(token: token, user: api.extractUser(body));
      }
      if (!mounted) return;
      Navigator.pushNamedAndRemoveUntil(context, token.isNotEmpty ? entryPointScreenRoute : logInScreenRoute, (_) => false);
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Cuenta creada correctamente.')));
    } catch (e) {
      setState(() => _error = e.toString());
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _sendOtp() async {
    final phone = _phoneController.text.trim();
    if (phone.isEmpty) {
      setState(() => _error = 'Escribe tu teléfono para enviar el OTP.');
      return;
    }
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      await EcoMarketApiService().sendOtp(phone: phone, purpose: 'register');
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('OTP enviado para registro.')));
    } catch (e) {
      setState(() => _error = e.toString());
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(defaultPadding),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(child: Image.asset('assets/ecomarket/png/ecomarket-logo-primary.png', height: 62)),
              const SizedBox(height: defaultPadding * 2),
              Text('Crear cuenta', style: Theme.of(context).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.w800)),
              const SizedBox(height: 8),
              const Text('Regístrate para comprar, guardar direcciones y crear órdenes reales.'),
              const SizedBox(height: defaultPadding * 1.5),
              Form(
                key: _formKey,
                child: Column(
                  children: [
                    TextFormField(
                      controller: _nameController,
                      decoration: const InputDecoration(hintText: 'Nombre completo', prefixIcon: Icon(Icons.person_outline)),
                      validator: (value) => (value == null || value.trim().isEmpty) ? 'Campo obligatorio' : null,
                    ),
                    const SizedBox(height: defaultPadding),
                    TextFormField(
                      controller: _emailController,
                      keyboardType: TextInputType.emailAddress,
                      decoration: const InputDecoration(hintText: 'Correo electrónico', prefixIcon: Icon(Icons.email_outlined)),
                      validator: emaildValidator.call,
                    ),
                    const SizedBox(height: defaultPadding),
                    TextFormField(
                      controller: _phoneController,
                      keyboardType: TextInputType.phone,
                      decoration: const InputDecoration(hintText: 'Teléfono', prefixIcon: Icon(Icons.phone_outlined)),
                      validator: (value) => (value == null || value.trim().isEmpty) ? 'Campo obligatorio' : null,
                    ),
                    const SizedBox(height: defaultPadding),
                    TextFormField(
                      controller: _passwordController,
                      obscureText: true,
                      decoration: const InputDecoration(hintText: 'Contraseña', prefixIcon: Icon(Icons.lock_outline)),
                      validator: (value) => (value == null || value.length < 8) ? 'Mínimo 8 caracteres' : null,
                    ),
                  ],
                ),
              ),
              Row(
                children: [
                  Checkbox(value: _accepted, onChanged: (value) => setState(() => _accepted = value ?? false)),
                  Expanded(
                    child: Text.rich(
                      TextSpan(
                        text: 'Acepto los ',
                        children: [
                          TextSpan(
                            recognizer: TapGestureRecognizer()..onTap = () {},
                            text: 'términos y privacidad',
                            style: const TextStyle(color: primaryColor, fontWeight: FontWeight.w600),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
              if (_error != null) Text(_error!, style: TextStyle(color: Theme.of(context).colorScheme.error)),
              const SizedBox(height: defaultPadding),
              ElevatedButton(
                onPressed: _loading ? null : _register,
                child: _loading ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(strokeWidth: 2)) : const Text('Crear cuenta'),
              ),
              const SizedBox(height: defaultPadding / 2),
              OutlinedButton.icon(
                onPressed: _loading ? null : _sendOtp,
                icon: const Icon(Icons.sms_outlined),
                label: const Text('Enviar OTP'),
              ),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Text('¿Ya tienes cuenta?'),
                  TextButton(onPressed: () => Navigator.pushNamed(context, logInScreenRoute), child: const Text('Entrar')),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
