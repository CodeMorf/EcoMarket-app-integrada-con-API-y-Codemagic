import 'package:flutter/material.dart';
import 'package:shop/constants.dart';
import 'package:shop/route/route_constants.dart';
import 'package:shop/services/ecomarket_api_service.dart';
import 'package:shop/services/session_service.dart';

class OrdersScreen extends StatefulWidget {
  const OrdersScreen({super.key});

  @override
  State<OrdersScreen> createState() => _OrdersScreenState();
}

class _OrdersScreenState extends State<OrdersScreen> {
  late Future<List<Map<String, dynamic>>> _future;

  @override
  void initState() {
    super.initState();
    _future = _loadOrders();
  }

  Future<List<Map<String, dynamic>>> _loadOrders() async {
    final token = await SessionService.getToken();
    if (token == null) throw Exception('Debes iniciar sesión para ver tus órdenes.');
    return EcoMarketApiService().orders(token);
  }

  Future<void> _refresh() async {
    setState(() => _future = _loadOrders());
    await _future;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: RefreshIndicator(
          onRefresh: _refresh,
          child: FutureBuilder<List<Map<String, dynamic>>>(
            future: _future,
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Center(child: CircularProgressIndicator());
              }
              if (snapshot.hasError) {
                return ListView(
                  padding: const EdgeInsets.all(defaultPadding),
                  children: [
                    Text('Mis órdenes', style: Theme.of(context).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.w800)),
                    const SizedBox(height: defaultPadding),
                    Text('${snapshot.error}'),
                    const SizedBox(height: defaultPadding),
                    ElevatedButton(onPressed: () => Navigator.pushNamed(context, logInScreenRoute), child: const Text('Iniciar sesión')),
                  ],
                );
              }
              final orders = snapshot.data ?? const [];
              return ListView(
                padding: const EdgeInsets.all(defaultPadding),
                children: [
                  Text('Mis órdenes', style: Theme.of(context).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.w800)),
                  const SizedBox(height: defaultPadding),
                  if (orders.isEmpty) const Text('Aún no tienes órdenes.') else ...orders.map(_orderTile),
                ],
              );
            },
          ),
        ),
      ),
    );
  }

  Widget _orderTile(Map<String, dynamic> order) {
    final id = order['order_uuid'] ?? order['id'] ?? 'Orden';
    final status = order['order_status'] ?? order['status'] ?? 'pendiente';
    final payment = order['payment_status'] ?? 'pendiente';
    final total = order['order_amount'] ?? order['total'] ?? order['amount'] ?? '';
    final tracking = order['tracking'] ?? order['tracking_number'];
    return Card(
      child: ListTile(
        leading: Image.asset('assets/ecomarket/navigation/png/icon-orders.png', height: 34),
        title: Text('Orden #$id'),
        subtitle: Text('Estado: $status · Pago: $payment${tracking != null ? '\nTracking: $tracking' : ''}'),
        trailing: Text(total.toString().isEmpty ? '' : 'RD\$$total'),
      ),
    );
  }
}
