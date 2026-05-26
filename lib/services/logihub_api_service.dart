import 'dart:convert';

import 'package:http/http.dart' as http;
import 'package:shop/services/ecomarket_config.dart';

class LogiHubApiException implements Exception {
  final String message;
  final int? statusCode;
  final Object? body;

  LogiHubApiException(this.message, {this.statusCode, this.body});

  @override
  String toString() => 'LogiHubApiException($statusCode): $message';
}

class LogiHubApiService {
  LogiHubApiService({http.Client? httpClient}) : _httpClient = httpClient ?? http.Client();

  final http.Client _httpClient;

  Map<String, String> _headers({bool json = false}) {
    final key = EcoMarketConfig.logihubApiKey.trim();
    if (key.isEmpty) {
      throw LogiHubApiException('Falta VITE_LOGIHUB_API_KEY. Configúrala en Codemagic o --dart-define.');
    }
    return {
      'X-API-Key': key,
      'Accept': 'application/json',
      if (json) 'Content-Type': 'application/json',
    };
  }

  Uri _uri(String path, [Map<String, dynamic>? query]) {
    final uri = Uri.parse(EcoMarketConfig.joinUrl(EcoMarketConfig.logihubBaseUrl, path));
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
          ? (body['message'] ?? body['error'] ?? body['msg'] ?? 'LogiHub API error').toString()
          : 'LogiHub API error ${response.statusCode}';
      throw LogiHubApiException(message, statusCode: response.statusCode, body: body);
    }
    return body;
  }

  List<String> _extractNames(dynamic body) {
    dynamic data = body;
    if (body is Map) data = body['data'] ?? body['items'] ?? body['locations'] ?? body['provinces'] ?? body['cities'] ?? body['zones'];
    if (data is Map) data = data['items'] ?? data['locations'] ?? data['provinces'] ?? data['cities'] ?? data['zones'] ?? data.values.firstOrNull;
    if (data is List) {
      return data.map((item) {
        if (item is String) return item;
        if (item is Map) {
          return (item['name'] ?? item['province'] ?? item['city'] ?? item['zone'] ?? item['title'] ?? item['label'] ?? '').toString();
        }
        return item.toString();
      }).where((value) => value.trim().isNotEmpty).toSet().toList();
    }
    return const [];
  }

  Future<Map<String, dynamic>> accountSummary() async {
    final response = await _httpClient.get(_uri('/account/summary.php'), headers: _headers());
    final body = _decode(response);
    return body is Map ? Map<String, dynamic>.from(body) : {'data': body};
  }

  Future<List<String>> getProvinces() async {
    final response = await _httpClient.get(
      _uri('/coverage/locations.php', {'action': 'provinces', 'country': 'DO'}),
      headers: _headers(),
    );
    return _extractNames(_decode(response));
  }

  Future<List<String>> getCities(String province) async {
    final response = await _httpClient.get(
      _uri('/coverage/locations.php', {'action': 'cities', 'country': 'DO', 'province': province}),
      headers: _headers(),
    );
    return _extractNames(_decode(response));
  }

  Future<List<String>> getZones({required String province, required String city}) async {
    final response = await _httpClient.get(
      _uri('/coverage/locations.php', {'action': 'zones', 'country': 'DO', 'province': province, 'city': city}),
      headers: _headers(),
    );
    return _extractNames(_decode(response));
  }

  Future<Map<String, dynamic>> quoteCentral({
    required String destProvince,
    required String destCity,
    int destZoneId = 0,
    String serviceType = 'standard',
    double weightLb = 2.5,
    double codAmount = 0,
  }) async {
    final response = await _httpClient.post(
      _uri('/nacional/quote.php'),
      headers: _headers(json: true),
      body: jsonEncode({
        'delivery_mode': 'central',
        'service_type': serviceType,
        'weight_lb': weightLb,
        'dest_province': destProvince,
        'dest_city': destCity,
        'dest_zone_id': destZoneId,
        'cod_amount': codAmount,
      }),
    );
    final body = _decode(response);
    return body is Map ? Map<String, dynamic>.from(body) : {'data': body};
  }
}
extension _FirstOrNull<E> on Iterable<E> {
  E? get firstOrNull => isEmpty ? null : first;
}
