import 'package:flutter/material.dart';
import 'package:shop/components/network_image_with_loader.dart';
import 'package:shop/constants.dart';
import 'package:shop/models/product_model.dart';
import 'package:shop/route/route_constants.dart';
import 'package:shop/services/cart_service.dart';
import 'package:shop/services/ecomarket_api_service.dart';

class ProductDetailsScreen extends StatefulWidget {
  const ProductDetailsScreen({super.key, this.productId, this.isProductAvailable = true});

  final int? productId;
  final bool isProductAvailable;

  @override
  State<ProductDetailsScreen> createState() => _ProductDetailsScreenState();
}

class _ProductDetailsScreenState extends State<ProductDetailsScreen> {
  late Future<ProductModel> _future;
  int _qty = 1;

  @override
  void initState() {
    super.initState();
    if (widget.productId == null) {
      _future = Future.error('Producto inválido.');
    } else {
      _future = EcoMarketApiService().getProduct(widget.productId!);
    }
  }

  void _addToCart(ProductModel product) {
    CartService.instance.add(product, quantity: _qty);
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('${product.title} agregado al carrito.')));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      bottomNavigationBar: SafeArea(
        minimum: const EdgeInsets.all(defaultPadding),
        child: FutureBuilder<ProductModel>(
          future: _future,
          builder: (context, snapshot) {
            final product = snapshot.data;
            return Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: product == null ? null : () => _addToCart(product),
                    child: const Text('Agregar'),
                  ),
                ),
                const SizedBox(width: defaultPadding),
                Expanded(
                  child: ElevatedButton(
                    onPressed: product == null
                        ? null
                        : () {
                            _addToCart(product);
                            Navigator.pushNamed(context, cartScreenRoute);
                          },
                    child: const Text('Comprar'),
                  ),
                ),
              ],
            );
          },
        ),
      ),
      body: SafeArea(
        child: FutureBuilder<ProductModel>(
          future: _future,
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator());
            }
            if (snapshot.hasError) {
              return Center(child: Padding(padding: const EdgeInsets.all(defaultPadding), child: Text('No se pudo cargar el producto: ${snapshot.error}')));
            }
            final product = snapshot.data!;
            return ListView(
              padding: const EdgeInsets.all(defaultPadding),
              children: [
                Row(
                  children: [
                    IconButton(onPressed: () => Navigator.pop(context), icon: const Icon(Icons.arrow_back)),
                    const Spacer(),
                    Image.asset('assets/ecomarket/png/ecomarket-logo-primary.png', height: 34),
                  ],
                ),
                const SizedBox(height: defaultPadding),
                AspectRatio(
                  aspectRatio: 1,
                  child: NetworkImageWithLoader(product.image, radius: defaultBorderRadious * 1.5),
                ),
                const SizedBox(height: defaultPadding),
                Text(product.brandName.toUpperCase(), style: Theme.of(context).textTheme.bodySmall),
                const SizedBox(height: 6),
                Text(product.title, style: Theme.of(context).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.w800)),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Text('RD\$${product.finalPrice.toStringAsFixed(2)}', style: Theme.of(context).textTheme.titleLarge?.copyWith(color: primaryColor, fontWeight: FontWeight.w800)),
                    if (product.priceAfetDiscount != null) ...[
                      const SizedBox(width: 8),
                      Text('RD\$${product.price.toStringAsFixed(2)}', style: const TextStyle(decoration: TextDecoration.lineThrough)),
                    ],
                    const Spacer(),
                    Text(product.stock == null ? 'Stock disponible' : 'Stock: ${product.stock}'),
                  ],
                ),
                const SizedBox(height: defaultPadding),
                Row(
                  children: [
                    const Text('Cantidad'),
                    const Spacer(),
                    IconButton(onPressed: _qty > 1 ? () => setState(() => _qty--) : null, icon: const Icon(Icons.remove_circle_outline)),
                    Text('$_qty', style: Theme.of(context).textTheme.titleMedium),
                    IconButton(onPressed: () => setState(() => _qty++), icon: const Icon(Icons.add_circle_outline)),
                  ],
                ),
                const Divider(),
                Text('Descripción', style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700)),
                const SizedBox(height: 8),
                Text(product.description?.isNotEmpty == true ? product.description! : 'Producto de EcoMarket.'),
                const SizedBox(height: defaultPadding),
                ListTile(
                  contentPadding: EdgeInsets.zero,
                  leading: Image.asset('assets/ecomarket/commerce/png/icon-delivery.png', height: 34),
                  title: const Text('Entrega con LogiHub'),
                  subtitle: const Text('La tarifa y dirección se confirman en checkout.'),
                ),
              ],
            );
          },
        ),
      ),
    );
  }
}
