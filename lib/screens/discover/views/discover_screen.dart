import 'package:flutter/material.dart';
import 'package:shop/constants.dart';
import 'package:shop/models/category_model.dart';
import 'package:shop/services/ecomarket_api_service.dart';

class DiscoverScreen extends StatefulWidget {
  const DiscoverScreen({super.key});

  @override
  State<DiscoverScreen> createState() => _DiscoverScreenState();
}

class _DiscoverScreenState extends State<DiscoverScreen> {
  late Future<List<CategoryModel>> _future;

  @override
  void initState() {
    super.initState();
    _future = EcoMarketApiService().getCategories();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: FutureBuilder<List<CategoryModel>>(
          future: _future,
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator());
            }
            if (snapshot.hasError) {
              return Center(child: Padding(padding: const EdgeInsets.all(defaultPadding), child: Text('No se pudieron cargar categorías: ${snapshot.error}')));
            }
            final categories = snapshot.data ?? const [];
            return ListView(
              padding: const EdgeInsets.all(defaultPadding),
              children: [
                Text('Categorías', style: Theme.of(context).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.w800)),
                const SizedBox(height: defaultPadding / 2),
                const Text('Categorías reales cargadas desde EcoMarket.'),
                const SizedBox(height: defaultPadding),
                ...categories.map(
                  (category) => Card(
                    child: ListTile(
                      leading: Image.asset('assets/ecomarket/navigation/png/icon-categories.png', height: 30),
                      title: Text(category.title),
                      subtitle: category.subCategories?.isNotEmpty == true ? Text('${category.subCategories!.length} subcategorías') : null,
                      trailing: const Icon(Icons.chevron_right),
                    ),
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }
}
