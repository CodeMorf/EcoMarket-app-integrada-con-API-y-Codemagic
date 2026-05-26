import 'package:flutter/material.dart';
import 'package:shop/constants.dart';
import 'package:shop/route/route_constants.dart';
import 'package:shop/services/cart_service.dart';
import 'package:shop/services/ecomarket_api_service.dart';
import 'package:shop/services/location_service.dart';
import 'package:shop/services/logihub_api_service.dart';
import 'package:shop/services/session_service.dart';

class CartScreen extends StatefulWidget {
  const CartScreen({super.key});

  @override
  State<CartScreen> createState() => _CartScreenState();
}

class _CartScreenState extends State<CartScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _phoneController = TextEditingController();
  final _addressController = TextEditingController();
  final _sectorController = TextEditingController();
  final _notesController = TextEditingController();
  bool _loading = false;
  String? _error;
  String? _province;
  String? _city;
  String? _zone;
  double? _lat;
  double? _lng;
  double? _shippingTotal;
  List<String> _provinces = [];
  List<String> _cities = [];
  List<String> _zones = [];

  @override
  void initState() {
    super.initState();
    _loadLogiHubProvinces();
  }

  @override
  void dispose() {
    _nameController.dispose();
    _phoneController.dispose();
    _addressController.dispose();
    _sectorController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  Future<void> _loadLogiHubProvinces() async {
    try {
      final provinces = await LogiHubApiService().getProvinces();
      if (mounted) setState(() => _provinces = provinces);
    } catch (_) {}
  }

  Future<void> _loadCities(String province) async {
    setState(() {
      _province = province;
      _city = null;
      _zone = null;
      _cities = [];
      _zones = [];
    });
    try {
      final cities = await LogiHubApiService().getCities(province);
      if (mounted) setState(() => _cities = cities);
    } catch (e) {
      if (mounted) setState(() => _error = 'No se pudieron cargar ciudades: $e');
    }
  }

  Future<void> _loadZones(String city) async {
    setState(() {
      _city = city;
      _zone = null;
      _zones = [];
    });
    try {
      if (_province == null) return;
      final zones = await LogiHubApiService().getZones(province: _province!, city: city);
      if (mounted) setState(() => _zones = zones);
    } catch (e) {
      if (mounted) setState(() => _error = 'No se pudieron cargar zonas: $e');
    }
    _quoteShipping();
  }

  Future<void> _useMyLocation() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final result = await LocationService.getCurrentAddress();
      _addressController.text = result.address;
      _sectorController.text = result.sector;
      _lat = result.latitude;
      _lng = result.longitude;
      if (result.province.isNotEmpty) {
        _province = result.province;
        if (!_provinces.contains(result.province)) _provinces = [..._provinces, result.province];
        await _loadCities(result.province);
      }
      if (result.city.isNotEmpty) {
        _city = result.city;
        if (!_cities.contains(result.city)) _cities = [..._cities, result.city];
      }
      if (result.sector.isNotEmpty) {
        _zone = result.sector;
        if (!_zones.contains(result.sector)) _zones = [..._zones, result.sector];
      }
      setState(() {});
    } catch (e) {
      setState(() => _error = e.toString());
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _quoteShipping() async {
    if (_province == null || _city == null || CartService.instance.items.isEmpty) return;
    try {
      final quote = await LogiHubApiService().quoteCentral(destProvince: _province!, destCity: _city!);
      final data = quote['data'] is Map ? quote['data'] as Map : quote;
      final value = data['total'] ?? data['final_cost'] ?? data['amount'] ?? data['price'] ?? data['cost'];
      final total = double.tryParse(value?.toString() ?? '');
      if (mounted && total != null) setState(() => _shippingTotal = total);
    } catch (_) {
      // Si LogiHub directo falla, dejamos que EcoMarket cotice al crear orden.
    }
  }

  Future<void> _createOrder() async {
    if (CartService.instance.items.isEmpty) return;
    if (!_formKey.currentState!.validate()) return;
    final token = await SessionService.getToken();
    if (token == null) {
      if (!mounted) return;
      Navigator.pushNamed(context, logInScreenRoute);
      return;
    }
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final address = {
        'name': _nameController.text.trim(),
        'phone': _phoneController.text.trim(),
        'address': _addressController.text.trim(),
        'province': _province,
        'city': _city,
        'sector': _zone ?? _sectorController.text.trim(),
        'latitude': _lat,
        'longitude': _lng,
      };
      final api = EcoMarketApiService();
      final order = await api.createOrder(
        customerToken: token,
        shippingAddress: address,
        items: CartService.instance.toApiItems(),
        paymentMethod: 'cash_on_delivery',
        notes: _notesController.text.trim(),
      );
      CartService.instance.clear();
      if (!mounted) return;
      setState(() {});
      showDialog(
        context: context,
        builder: (_) => AlertDialog(
          title: const Text('Orden creada'),
          content: Text('Tu orden fue enviada a EcoMarket.\nReferencia: ${order['order_uuid'] ?? order['id'] ?? 'pendiente'}'),
          actions: [
            TextButton(onPressed: () => Navigator.pop(context), child: const Text('OK')),
          ],
        ),
      );
    } catch (e) {
      setState(() => _error = e.toString());
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final items = CartService.instance.items;
    final subtotal = CartService.instance.subtotal;
    final total = subtotal + (_shippingTotal ?? 0);

    return Scaffold(
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(defaultPadding),
          children: [
            Text('Carrito', style: Theme.of(context).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.w800)),
            const SizedBox(height: defaultPadding / 2),
            if (items.isEmpty)
              const Text('Tu carrito está vacío. Agrega productos desde Inicio.')
            else
              ...items.map(
                (item) => Card(
                  child: ListTile(
                    leading: Image.network(item.product.image, width: 52, height: 52, fit: BoxFit.cover, errorBuilder: (_, __, ___) => const Icon(Icons.shopping_bag)),
                    title: Text(item.product.title, maxLines: 2, overflow: TextOverflow.ellipsis),
                    subtitle: Text('RD\$${item.product.finalPrice.toStringAsFixed(2)} x ${item.quantity}'),
                    trailing: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        IconButton(onPressed: () => setState(() => CartService.instance.updateQuantity(item.product.id!, item.quantity - 1)), icon: const Icon(Icons.remove_circle_outline)),
                        Text('${item.quantity}'),
                        IconButton(onPressed: () => setState(() => CartService.instance.updateQuantity(item.product.id!, item.quantity + 1)), icon: const Icon(Icons.add_circle_outline)),
                      ],
                    ),
                  ),
                ),
              ),
            const SizedBox(height: defaultPadding),
            if (items.isNotEmpty) ...[
              Text('Dirección de entrega', style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700)),
              const SizedBox(height: defaultPadding),
              OutlinedButton.icon(
                onPressed: _loading ? null : _useMyLocation,
                icon: Image.asset('assets/ecomarket/navigation/png/icon-location.png', height: 22),
                label: const Text('Rellenar con mi ubicación'),
              ),
              const SizedBox(height: defaultPadding),
              Form(
                key: _formKey,
                child: Column(
                  children: [
                    TextFormField(controller: _nameController, decoration: const InputDecoration(hintText: 'Nombre de quien recibe'), validator: (v) => v == null || v.trim().isEmpty ? 'Campo obligatorio' : null),
                    const SizedBox(height: defaultPadding),
                    TextFormField(controller: _phoneController, keyboardType: TextInputType.phone, decoration: const InputDecoration(hintText: 'Teléfono'), validator: (v) => v == null || v.trim().isEmpty ? 'Campo obligatorio' : null),
                    const SizedBox(height: defaultPadding),
                    DropdownButtonFormField<String>(
                      value: _province,
                      decoration: const InputDecoration(labelText: 'Provincia LogiHub'),
                      items: _provinces.map((p) => DropdownMenuItem(value: p, child: Text(p))).toList(),
                      onChanged: (value) => value == null ? null : _loadCities(value),
                      validator: (v) => v == null || v.isEmpty ? 'Selecciona provincia' : null,
                    ),
                    const SizedBox(height: defaultPadding),
                    DropdownButtonFormField<String>(
                      value: _city,
                      decoration: const InputDecoration(labelText: 'Ciudad / Municipio'),
                      items: _cities.map((c) => DropdownMenuItem(value: c, child: Text(c))).toList(),
                      onChanged: (value) => value == null ? null : _loadZones(value),
                      validator: (v) => v == null || v.isEmpty ? 'Selecciona ciudad' : null,
                    ),
                    const SizedBox(height: defaultPadding),
                    DropdownButtonFormField<String>(
                      value: _zone,
                      decoration: const InputDecoration(labelText: 'Zona / Sector'),
                      items: _zones.map((z) => DropdownMenuItem(value: z, child: Text(z))).toList(),
                      onChanged: (value) => setState(() => _zone = value),
                    ),
                    const SizedBox(height: defaultPadding),
                    TextFormField(controller: _sectorController, decoration: const InputDecoration(hintText: 'Sector manual si no aparece en LogiHub')),
                    const SizedBox(height: defaultPadding),
                    TextFormField(controller: _addressController, maxLines: 2, decoration: const InputDecoration(hintText: 'Dirección exacta'), validator: (v) => v == null || v.trim().isEmpty ? 'Campo obligatorio' : null),
                    const SizedBox(height: defaultPadding),
                    TextFormField(controller: _notesController, decoration: const InputDecoration(hintText: 'Nota para el delivery (opcional)')),
                  ],
                ),
              ),
              const SizedBox(height: defaultPadding),
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(defaultPadding),
                  child: Column(
                    children: [
                      _priceRow('Subtotal', subtotal),
                      _priceRow('Envío LogiHub', _shippingTotal ?? 0),
                      const Divider(),
                      _priceRow('Total', total, bold: true),
                    ],
                  ),
                ),
              ),
              if (_error != null) Padding(padding: const EdgeInsets.only(top: defaultPadding), child: Text(_error!, style: TextStyle(color: Theme.of(context).colorScheme.error))),
              const SizedBox(height: defaultPadding),
              ElevatedButton(
                onPressed: _loading ? null : _createOrder,
                child: _loading ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(strokeWidth: 2)) : const Text('Crear orden'),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _priceRow(String label, double amount, {bool bold = false}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Text(label, style: TextStyle(fontWeight: bold ? FontWeight.w800 : FontWeight.w400)),
          const Spacer(),
          Text('RD\$${amount.toStringAsFixed(2)}', style: TextStyle(fontWeight: bold ? FontWeight.w800 : FontWeight.w400)),
        ],
      ),
    );
  }
}
