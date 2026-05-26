import 'package:flutter/material.dart';
import 'package:shop/components/product/product_card.dart';
import 'package:shop/constants.dart';
import 'package:shop/models/product_model.dart';
import 'package:shop/route/route_constants.dart';
import 'package:shop/services/ecomarket_api_service.dart';

class SearchScreen extends StatefulWidget {
  const SearchScreen({super.key});

  @override
  State<SearchScreen> createState() => _SearchScreenState();
}

class _SearchScreenState extends State<SearchScreen> {
  final _controller = TextEditingController();
  Future<List<ProductModel>>? _future;

  @override
  void initState() {
    super.initState();
    _future = EcoMarketApiService().getProducts(limit: 20);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _search() {
    setState(() => _future = EcoMarketApiService().getProducts(limit: 30, query: _controller.text.trim()));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.all(defaultPadding),
              child: Row(
                children: [
                  IconButton(onPressed: () => Navigator.pop(context), icon: const Icon(Icons.arrow_back)),
                  Expanded(
                    child: TextField(
                      controller: _controller,
                      textInputAction: TextInputAction.search,
                      onSubmitted: (_) => _search(),
                      decoration: const InputDecoration(hintText: 'Buscar productos reales'),
                    ),
                  ),
                  IconButton(onPressed: _search, icon: const Icon(Icons.search)),
                ],
              ),
            ),
            Expanded(
              child: FutureBuilder<List<ProductModel>>(
                future: _future,
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) return const Center(child: CircularProgressIndicator());
                  if (snapshot.hasError) return Center(child: Padding(padding: const EdgeInsets.all(defaultPadding), child: Text('Error al buscar: ${snapshot.error}')));
                  final products = snapshot.data ?? const [];
                  if (products.isEmpty) return const Center(child: Text('No encontramos productos.'));
                  return GridView.builder(
                    padding: const EdgeInsets.all(defaultPadding),
                    gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(crossAxisCount: 2, childAspectRatio: .64, mainAxisSpacing: defaultPadding, crossAxisSpacing: defaultPadding),
                    itemCount: products.length,
                    itemBuilder: (context, index) => ProductCard(
                      image: products[index].image,
                      brandName: products[index].brandName,
                      title: products[index].title,
                      price: products[index].price,
                      priceAfetDiscount: products[index].priceAfetDiscount,
                      dicountpercent: products[index].dicountpercent,
                      press: () => Navigator.pushNamed(context, productDetailsScreenRoute, arguments: products[index].id),
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}
