import 'package:flutter/material.dart';
import 'package:shop/constants.dart';
import 'package:shop/route/route_constants.dart';
import 'package:shop/services/ecomarket_api_service.dart';
import 'package:shop/services/session_service.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailPhoneController = TextEditingController();
  final _passwordController = TextEditingController();
  final _otpController = TextEditingController();
  bool _loading = false;
  String? _error;

  @override
  void dispose() {
    _emailPhoneController.dispose();
    _passwordController.dispose();
    _otpController.dispose();
    super.dispose();
  }

  Future<void> _login() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final api = EcoMarketApiService();
      final body = await api.login(
        emailOrPhone: _emailPhoneController.text.trim(),
        password: _passwordController.text,
      );
      final token = api.extractCustomerToken(body);
      if (token.isEmpty) {
        throw EcoMarketApiException('Login correcto, pero la API no devolvió customer_token.');
      }
      await SessionService.saveSession(token: token, user: api.extractUser(body));
      if (!mounted) return;
      Navigator.pushNamedAndRemoveUntil(context, entryPointScreenRoute, (_) => false);
    } catch (e) {
      setState(() => _error = e.toString());
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _sendOtp() async {
    final phone = _emailPhoneController.text.trim();
    if (phone.isEmpty) {
      setState(() => _error = 'Escribe tu teléfono para enviar el OTP.');
      return;
    }
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      await EcoMarketApiService().sendOtp(phone: phone, purpose: 'login');
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('OTP enviado. Revisa tu teléfono.')));
    } catch (e) {
      setState(() => _error = e.toString());
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }


  Future<void> _verifyOtp() async {
    final phone = _emailPhoneController.text.trim();
    final code = _otpController.text.trim();
    if (phone.isEmpty || code.isEmpty) {
      setState(() => _error = 'Escribe teléfono y código OTP.');
      return;
    }
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final api = EcoMarketApiService();
      final body = await api.verifyOtp(phone: phone, code: code, purpose: 'login');
      final token = api.extractCustomerToken(body);
      if (token.isNotEmpty) {
        await SessionService.saveSession(token: token, user: api.extractUser(body));
        if (!mounted) return;
        Navigator.pushNamedAndRemoveUntil(context, entryPointScreenRoute, (_) => false);
      } else {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('OTP verificado. Ahora entra con tu contraseña.')));
      }
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
              Text('Iniciar sesión', style: Theme.of(context).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.w800)),
              const SizedBox(height: 8),
              const Text('Entra con tu correo o teléfono para ver tus órdenes, direcciones y carrito.'),
              const SizedBox(height: defaultPadding * 1.5),
              Form(
                key: _formKey,
                child: Column(
                  children: [
                    TextFormField(
                      controller: _emailPhoneController,
                      keyboardType: TextInputType.emailAddress,
                      textInputAction: TextInputAction.next,
                      decoration: const InputDecoration(
                        hintText: 'Correo o teléfono',
                        prefixIcon: Icon(Icons.person_outline),
                      ),
                      validator: (value) => (value == null || value.trim().isEmpty) ? 'Campo obligatorio' : null,
                    ),
                    const SizedBox(height: defaultPadding),
                    TextFormField(
                      controller: _passwordController,
                      obscureText: true,
                      decoration: const InputDecoration(
                        hintText: 'Contraseña',
                        prefixIcon: Icon(Icons.lock_outline),
                      ),
                      validator: (value) => (value == null || value.length < 6) ? 'Mínimo 6 caracteres' : null,
                    ),
                  ],
                ),
              ),
              if (_error != null) ...[
                const SizedBox(height: defaultPadding),
                Text(_error!, style: TextStyle(color: Theme.of(context).colorScheme.error)),
              ],
              Align(
                alignment: Alignment.centerRight,
                child: TextButton(
                  onPressed: _loading ? null : () => Navigator.pushNamed(context, passwordRecoveryScreenRoute),
                  child: const Text('Olvidé mi contraseña'),
                ),
              ),
              ElevatedButton(
                onPressed: _loading ? null : _login,
                child: _loading ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(strokeWidth: 2)) : const Text('Entrar'),
              ),
              const SizedBox(height: defaultPadding / 2),
              TextFormField(
                controller: _otpController,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(hintText: 'Código OTP (opcional)', prefixIcon: Icon(Icons.verified_outlined)),
              ),
              const SizedBox(height: defaultPadding / 2),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: _loading ? null : _sendOtp,
                      icon: const Icon(Icons.sms_outlined),
                      label: const Text('Enviar OTP'),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: _loading ? null : _verifyOtp,
                      icon: const Icon(Icons.verified_user_outlined),
                      label: const Text('Verificar'),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: defaultPadding),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Text('¿No tienes cuenta?'),
                  TextButton(
                    onPressed: () => Navigator.pushNamed(context, signUpScreenRoute),
                    child: const Text('Registrarme'),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
