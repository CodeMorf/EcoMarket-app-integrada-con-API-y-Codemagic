import 'package:flutter/material.dart';
import 'package:shop/constants.dart';
import 'package:shop/screens/home/views/components/categories.dart';
import 'package:shop/screens/home/views/components/popular_products.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: CustomScrollView(
          slivers: [
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.all(defaultPadding),
                child: Container(
                  padding: const EdgeInsets.all(defaultPadding),
                  decoration: BoxDecoration(
                    color: primaryColor,
                    borderRadius: BorderRadius.circular(defaultBorderRadious * 1.5),
                  ),
                  child: Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('Compra fácil en EcoMarket', style: Theme.of(context).textTheme.titleLarge?.copyWith(color: Colors.white, fontWeight: FontWeight.w800)),
                            const SizedBox(height: 8),
                            const Text('Productos reales, órdenes conectadas y entregas con LogiHub.', style: TextStyle(color: Colors.white)),
                          ],
                        ),
                      ),
                      Image.asset('assets/ecomarket/commerce/png/icon-delivery.png', width: 74),
                    ],
                  ),
                ),
              ),
            ),
            const SliverToBoxAdapter(child: Categories()),
            const SliverToBoxAdapter(child: PopularProducts()),
            const SliverToBoxAdapter(child: SizedBox(height: defaultPadding)),
          ],
        ),
      ),
    );
  }
}
