import 'package:flutter/material.dart';
import 'package:shop/constants.dart';
import 'package:shop/route/route_constants.dart';
import 'package:shop/services/ecomarket_api_service.dart';
import 'package:shop/services/session_service.dart';

class AddressesScreen extends StatefulWidget {
  const AddressesScreen({super.key});

  @override
  State<AddressesScreen> createState() => _AddressesScreenState();
}

class _AddressesScreenState extends State<AddressesScreen> {
  late Future<List<Map<String, dynamic>>> _future;

  @override
  void initState() {
    super.initState();
    _future = _load();
  }

  Future<List<Map<String, dynamic>>> _load() async {
    final token = await SessionService.getToken();
    if (token == null) throw Exception('Debes iniciar sesión para ver tus direcciones.');
    return EcoMarketApiService().addresses(token);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Mis direcciones')),
      body: FutureBuilder<List<Map<String, dynamic>>>(
        future: _future,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) return const Center(child: CircularProgressIndicator());
          if (snapshot.hasError) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(defaultPadding),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text('${snapshot.error}', textAlign: TextAlign.center),
                    const SizedBox(height: defaultPadding),
                    ElevatedButton(onPressed: () => Navigator.pushNamed(context, logInScreenRoute), child: const Text('Iniciar sesión')),
                  ],
                ),
              ),
            );
          }
          final addresses = snapshot.data ?? const [];
          return ListView(
            padding: const EdgeInsets.all(defaultPadding),
            children: [
              if (addresses.isEmpty) const Text('No tienes direcciones guardadas. Puedes guardar una al crear una orden.'),
              ...addresses.map(
                (address) => Card(
                  child: ListTile(
                    leading: Image.asset('assets/ecomarket/navigation/png/icon-location.png', height: 30),
                    title: Text((address['contact_person_name'] ?? address['name'] ?? 'Dirección').toString()),
                    subtitle: Text((address['address'] ?? '').toString()),
                  ),
                ),
              ),
              const SizedBox(height: defaultPadding),
              ElevatedButton(onPressed: () => Navigator.pushNamed(context, cartScreenRoute), child: const Text('Crear dirección en checkout')),
            ],
          );
        },
      ),
    );
  }
}
