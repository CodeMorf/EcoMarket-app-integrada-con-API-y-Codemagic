import 'dart:convert';

import 'package:http/http.dart' as http;
import 'package:shop/models/category_model.dart';
import 'package:shop/models/product_model.dart';
import 'package:shop/services/ecomarket_config.dart';

class EcoMarketApiException implements Exception {
  final String message;
  final int? statusCode;
  final Object? body;

  EcoMarketApiException(this.message, {this.statusCode, this.body});

  @override
  String toString() => message;
}

class EcoMarketApiService {
  EcoMarketApiService({http.Client? httpClient}) : _httpClient = httpClient ?? http.Client();

  final http.Client _httpClient;

  Map<String, String> _headers({String? customerToken, bool json = true}) {
    final apiKey = EcoMarketConfig.ecomarketApiKey.trim();
    if (apiKey.isEmpty) {
      throw EcoMarketApiException('Falta VITE_ECOMARKET_API_KEY. Configúrala en Codemagic o --dart-define.');
    }

    return {
      'Accept': 'application/json',
      if (json) 'Content-Type': 'application/json',
      'X-ECOMARKET-API-KEY': apiKey,
      'Authorization': 'Bearer $apiKey',
      if (customerToken != null && customerToken.trim().isNotEmpty) 'X-Customer-Token': customerToken.trim(),
    };
  }

  Uri _clientUri(String path, [Map<String, dynamic>? query]) {
    final url = EcoMarketConfig.joinUrl(EcoMarketConfig.clientApiBaseUrl, path);
    final uri = Uri.parse(url);
    return uri.replace(
      queryParameters: {
        ...uri.queryParameters,
        if (query != null)
          ...query.map((key, value) => MapEntry(key, value?.toString() ?? '')),
      }..removeWhere((_, value) => value.isEmpty),
    );
  }

  Uri _apiUri(String path, [Map<String, dynamic>? query]) {
    final url = EcoMarketConfig.joinUrl(EcoMarketConfig.apiBaseUrl, path);
    final uri = Uri.parse(url);
    return uri.replace(
      queryParameters: {
        ...uri.queryParameters,
        if (query != null)
          ...query.map((key, value) => MapEntry(key, value?.toString() ?? '')),
      }..removeWhere((_, value) => value.isEmpty),
    );
  }

  dynamic _decode(http.Response response) {
    final raw = utf8.decode(response.bodyBytes);
    dynamic body;
    try {
      body = raw.isEmpty ? null : jsonDecode(raw);
    } catch (_) {
      body = raw;
    }

    if (response.statusCode < 200 || response.statusCode >= 300) {
      final message = body is Map
          ? (body['message'] ?? body['error'] ?? body['msg'] ?? 'EcoMarket API error').toString()
          : 'EcoMarket API error ${response.statusCode}';
      throw EcoMarketApiException(message, statusCode: response.statusCode, body: body);
    }

    return body;
  }

  dynamic _data(dynamic body) {
    if (body is Map && body.containsKey('data')) return body['data'];
    return body;
  }

  List<dynamic> _asList(dynamic body) {
    final data = _data(body);
    if (data is List) return data;
    if (data is Map) {
      for (final key in const ['products', 'items', 'categories', 'shops', 'brands', 'banners', 'orders', 'addresses', 'methods']) {
        final value = data[key];
        if (value is List) return value;
      }
    }
    return const [];
  }

  Map<String, dynamic> _asMap(dynamic body) {
    final data = _data(body);
    if (data is Map<String, dynamic>) return data;
    if (data is Map) return Map<String, dynamic>.from(data);
    if (body is Map<String, dynamic>) return body;
    if (body is Map) return Map<String, dynamic>.from(body);
    return {'data': body};
  }

  String extractCustomerToken(Map<String, dynamic> body) {
    final candidates = [
      body['customer_token'],
      body['token'],
      body['access_token'],
      body['data'] is Map ? body['data']['customer_token'] : null,
      body['data'] is Map ? body['data']['token'] : null,
      body['data'] is Map ? body['data']['access_token'] : null,
      body['customer'] is Map ? body['customer']['token'] : null,
    ];
    for (final candidate in candidates) {
      final text = candidate?.toString().trim() ?? '';
      if (text.isNotEmpty && text != 'null') return text;
    }
    return '';
  }

  Map<String, dynamic>? extractUser(Map<String, dynamic> body) {
    final data = body['data'];
    if (data is Map && data['customer'] is Map) return Map<String, dynamic>.from(data['customer']);
    if (data is Map && data['user'] is Map) return Map<String, dynamic>.from(data['user']);
    if (body['customer'] is Map) return Map<String, dynamic>.from(body['customer']);
    if (body['user'] is Map) return Map<String, dynamic>.from(body['user']);
    return data is Map ? Map<String, dynamic>.from(data) : null;
  }

  Future<List<ProductModel>> getProducts({int limit = 20, String? query, int? categoryId, int page = 1}) async {
    final response = await _httpClient.get(
      _clientUri('/products', {
        'limit': limit,
        'page': page,
        if (query != null && query.trim().isNotEmpty) 'q': query.trim(),
        if (categoryId != null) 'category_id': categoryId,
      }),
      headers: _headers(),
    );
    final body = _decode(response);
    return _asList(body)
        .whereType<Map>()
        .map((item) => ProductModel.fromEcoMarketJson(Map<String, dynamic>.from(item)))
        .where((product) => product.title.trim().isNotEmpty)
        .toList();
  }

  Future<ProductModel> getProduct(int id) async {
    final response = await _httpClient.get(_clientUri('/products/$id'), headers: _headers());
    return ProductModel.fromEcoMarketJson(_asMap(_decode(response)));
  }

  Future<List<CategoryModel>> getCategories() async {
    final response = await _httpClient.get(_clientUri('/categories'), headers: _headers());
    final body = _decode(response);
    return _asList(body)
        .whereType<Map>()
        .map((item) => CategoryModel.fromEcoMarketJson(Map<String, dynamic>.from(item)))
        .where((category) => category.title.trim().isNotEmpty)
        .toList();
  }

  Future<Map<String, dynamic>> catalogBootstrap() async {
    final response = await _httpClient.get(_clientUri('/catalog/bootstrap'), headers: _headers());
    return _asMap(_decode(response));
  }

  Future<Map<String, dynamic>> appConfig() async {
    final response = await _httpClient.get(_clientUri('/app/config'), headers: _headers());
    return _asMap(_decode(response));
  }

  Future<Map<String, dynamic>> login({required String emailOrPhone, required String password}) async {
    final response = await _httpClient.post(
      _clientUri('/auth/login'),
      headers: _headers(),
      body: jsonEncode({'email_or_phone': emailOrPhone, 'password': password}),
    );
    return _asMap(_decode(response));
  }

  Future<Map<String, dynamic>> register({
    required String name,
    required String email,
    required String phone,
    required String password,
  }) async {
    final response = await _httpClient.post(
      _clientUri('/auth/register'),
      headers: _headers(),
      body: jsonEncode({'name': name, 'email': email, 'phone': phone, 'password': password}),
    );
    return _asMap(_decode(response));
  }

  Future<Map<String, dynamic>> sendOtp({required String phone, String purpose = 'login'}) async {
    final response = await _httpClient.post(
      _clientUri('/auth/send-otp'),
      headers: _headers(),
      body: jsonEncode({'phone': phone, 'purpose': purpose}),
    );
    return _asMap(_decode(response));
  }

  Future<Map<String, dynamic>> verifyOtp({required String phone, required String code, String purpose = 'login'}) async {
    final response = await _httpClient.post(
      _clientUri('/auth/verify-otp'),
      headers: _headers(),
      body: jsonEncode({'phone': phone, 'code': code, 'purpose': purpose}),
    );
    return _asMap(_decode(response));
  }

  Future<Map<String, dynamic>> me(String customerToken) async {
    final response = await _httpClient.get(_clientUri('/customers/me'), headers: _headers(customerToken: customerToken));
    return _asMap(_decode(response));
  }

  Future<List<Map<String, dynamic>>> addresses(String customerToken) async {
    final response = await _httpClient.get(_clientUri('/addresses'), headers: _headers(customerToken: customerToken));
    return _asList(_decode(response)).whereType<Map>().map((e) => Map<String, dynamic>.from(e)).toList();
  }

  Future<Map<String, dynamic>> createAddress(String customerToken, Map<String, dynamic> address) async {
    final response = await _httpClient.post(
      _clientUri('/addresses'),
      headers: _headers(customerToken: customerToken),
      body: jsonEncode(address),
    );
    return _asMap(_decode(response));
  }

  Future<Map<String, dynamic>> cartQuote(List<Map<String, dynamic>> items, {String? couponCode, int? addressId}) async {
    final response = await _httpClient.post(
      _clientUri('/cart/quote'),
      headers: _headers(),
      body: jsonEncode({
        'items': items,
        if (couponCode != null && couponCode.trim().isNotEmpty) 'coupon_code': couponCode.trim(),
        if (addressId != null) 'address_id': addressId,
      }),
    );
    return _asMap(_decode(response));
  }

  Future<List<Map<String, dynamic>>> paymentMethods() async {
    final response = await _httpClient.get(_clientUri('/payments/methods'), headers: _headers());
    return _asList(_decode(response)).whereType<Map>().map((e) => Map<String, dynamic>.from(e)).toList();
  }

  Future<List<Map<String, dynamic>>> deliveryMethods() async {
    final response = await _httpClient.get(_clientUri('/delivery-methods'), headers: _headers());
    return _asList(_decode(response)).whereType<Map>().map((e) => Map<String, dynamic>.from(e)).toList();
  }

  Future<Map<String, dynamic>> createOrder({
    required String customerToken,
    required Map<String, dynamic> shippingAddress,
    required List<Map<String, dynamic>> items,
    String paymentMethod = 'cash_on_delivery',
    String? notes,
  }) async {
    final response = await _httpClient.post(
      _clientUri('/orders'),
      headers: {
        ..._headers(customerToken: customerToken),
        'X-Idempotency-Key': 'flutter-${DateTime.now().millisecondsSinceEpoch}',
      },
      body: jsonEncode({
        'shipping_address': shippingAddress,
        'payment': {'method': paymentMethod, 'status': 'Pending'},
        'items': items,
        if (notes != null && notes.trim().isNotEmpty) 'notes': notes.trim(),
        'source': 'flutter_app',
      }),
    );
    return _asMap(_decode(response));
  }

  Future<List<Map<String, dynamic>>> orders(String customerToken) async {
    final response = await _httpClient.get(_clientUri('/orders'), headers: _headers(customerToken: customerToken));
    return _asList(_decode(response)).whereType<Map>().map((e) => Map<String, dynamic>.from(e)).toList();
  }

  Future<Map<String, dynamic>> shippingTrack(String tracking, {String? customerToken}) async {
    final response = await _httpClient.get(
      _clientUri('/shipping/track', {'tracking': tracking}),
      headers: _headers(customerToken: customerToken),
    );
    return _asMap(_decode(response));
  }

  Future<Map<String, dynamic>> registerDevice({
    required String customerToken,
    required String deviceToken,
    String platform = 'android',
    String appVersion = '1.0.0',
  }) async {
    final response = await _httpClient.post(
      _clientUri('/devices/register'),
      headers: _headers(customerToken: customerToken),
      body: jsonEncode({
        'device_token': deviceToken,
        'platform': platform,
        'device_id': 'flutter-${DateTime.now().millisecondsSinceEpoch}',
        'app_version': appVersion,
      }),
    );
    return _asMap(_decode(response));
  }

  Future<Map<String, dynamic>> logihubQuote(Map<String, dynamic> payload) async {
    final response = await _httpClient.post(
      _apiUri('/integrations/shipping/logihub/quote'),
      headers: _headers(),
      body: jsonEncode(payload),
    );
    return _asMap(_decode(response));
  }

  Future<Map<String, dynamic>> logihubCreate(Map<String, dynamic> payload) async {
    final response = await _httpClient.post(
      _apiUri('/integrations/shipping/logihub/create'),
      headers: _headers(),
      body: jsonEncode(payload),
    );
    return _asMap(_decode(response));
  }
}
