import 'package:flutter/material.dart';
import 'package:shop/constants.dart';
import 'package:shop/route/screen_export.dart';
import 'package:shop/services/ecomarket_api_service.dart';
import 'package:shop/services/session_service.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  late Future<Map<String, dynamic>?> _future;

  @override
  void initState() {
    super.initState();
    _future = _loadUser();
  }

  Future<Map<String, dynamic>?> _loadUser() async {
    final token = await SessionService.getToken();
    if (token == null) return null;
    try {
      final me = await EcoMarketApiService().me(token);
      return EcoMarketApiService().extractUser(me) ?? me;
    } catch (_) {
      return SessionService.getUser();
    }
  }

  Future<void> _logout() async {
    await SessionService.clear();
    if (!mounted) return;
    Navigator.pushNamedAndRemoveUntil(context, logInScreenRoute, (_) => false);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: FutureBuilder<Map<String, dynamic>?>(
        future: _future,
        builder: (context, snapshot) {
          final user = snapshot.data;
          final logged = user != null;
          final name = user?['name']?.toString() ?? 'Invitado EcoMarket';
          final email = user?['email']?.toString() ?? 'Inicia sesión para ver tus datos';
          return ListView(
            padding: const EdgeInsets.all(defaultPadding),
            children: [
              Center(child: Image.asset('assets/ecomarket/png/ecomarket-logo-primary.png', height: 48)),
              const SizedBox(height: defaultPadding),
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(defaultPadding),
                  child: Row(
                    children: [
                      CircleAvatar(radius: 30, backgroundColor: primaryColor, child: Text(name.substring(0, 1).toUpperCase(), style: const TextStyle(color: Colors.white, fontSize: 24))),
                      const SizedBox(width: defaultPadding),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(name, style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w800)),
                            Text(email),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: defaultPadding),
              if (!logged) ElevatedButton(onPressed: () => Navigator.pushNamed(context, logInScreenRoute), child: const Text('Iniciar sesión')),
              _tile('Mis órdenes', 'assets/ecomarket/navigation/png/icon-orders.png', () => Navigator.pushNamed(context, ordersScreenRoute)),
              _tile('Direcciones', 'assets/ecomarket/navigation/png/icon-location.png', () => Navigator.pushNamed(context, addressesScreenRoute)),
              _tile('Notificaciones', 'assets/ecomarket/navigation/png/icon-notifications.png', () => Navigator.pushNamed(context, enableNotificationScreenRoute)),
              _tile('Soporte', 'assets/ecomarket/commerce/png/icon-help.png', () {}),
              _tile('Configuración', 'assets/ecomarket/commerce/png/icon-settings.png', () => Navigator.pushNamed(context, preferencesScreenRoute)),
              const SizedBox(height: defaultPadding),
              if (logged)
                ListTile(
                  onTap: _logout,
                  leading: Image.asset('assets/ecomarket/commerce/png/icon-logout.png', height: 26),
                  title: const Text('Cerrar sesión', style: TextStyle(color: errorColor)),
                ),
            ],
          );
        },
      ),
    );
  }

  Widget _tile(String text, String icon, VoidCallback onTap) {
    return Card(
      child: ListTile(
        onTap: onTap,
        leading: Image.asset(icon, height: 28),
        title: Text(text),
        trailing: const Icon(Icons.chevron_right),
      ),
    );
  }
}
