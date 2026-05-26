import 'package:shop/constants.dart';

class ProductModel {
  final int? id;
  final String image, brandName, title;
  final double price;
  final double? priceAfetDiscount;
  final int? dicountpercent;
  final String? description;
  final int? stock;
  final List<String> images;

  ProductModel({
    this.id,
    required this.image,
    required this.brandName,
    required this.title,
    required this.price,
    this.priceAfetDiscount,
    this.dicountpercent,
    this.description,
    this.stock,
    List<String>? images,
  }) : images = images ?? const [];

  bool get hasStock => stock == null || stock! > 0;
  double get finalPrice => priceAfetDiscount ?? price;

  factory ProductModel.fromEcoMarketJson(Map<String, dynamic> json) {
    final price = _asDouble(json['price'] ?? json['unit_price'] ?? json['selling_price']);
    final discount = _asDouble(json['discount']);
    final discountType = (json['discount_type'] ?? '').toString().toLowerCase();
    final allImages = <String>[];
    for (final item in [json['thumbnail'], json['image']]) {
      final text = item?.toString().trim() ?? '';
      if (text.isNotEmpty && text != 'null') allImages.add(text);
    }
    if (json['images'] is List) {
      for (final item in json['images'] as List) {
        final text = item?.toString().trim() ?? '';
        if (text.isNotEmpty && text != 'null') allImages.add(text);
      }
    }
    final image = allImages.isNotEmpty ? allImages.first : '';
    final brand = _firstNonEmpty([
      json['brand_name'],
      json['brand'] is Map ? json['brand']['name'] : json['brand'],
      json['shop_name'],
      json['shop'] is Map ? json['shop']['name'] : json['shop'],
      'EcoMarket',
    ]);

    double? priceAfterDiscount;
    int? percent;
    if (discount > 0 && price > 0) {
      if (discountType == 'percent' || discountType == 'percentage') {
        percent = discount.round();
        priceAfterDiscount = price - (price * discount / 100);
      } else {
        priceAfterDiscount = (price - discount).clamp(0, price).toDouble();
        percent = ((discount / price) * 100).round();
      }
    }

    return ProductModel(
      id: _asInt(json['id']),
      image: image.isEmpty ? 'https://placehold.co/600x600/png?text=EcoMarket' : image,
      images: allImages.isEmpty ? const ['https://placehold.co/600x600/png?text=EcoMarket'] : allImages.toSet().toList(),
      brandName: brand,
      title: _firstNonEmpty([json['name'], json['title'], json['product_name']]),
      price: price,
      priceAfetDiscount: priceAfterDiscount,
      dicountpercent: percent != null && percent > 0 ? percent : null,
      description: _firstNonEmpty([json['short_description'], json['description'], json['meta_description']]),
      stock: _asInt(json['current_stock'] ?? json['stock']),
    );
  }

  static String _firstNonEmpty(List<dynamic> values) {
    for (final value in values) {
      if (value == null) continue;
      final text = value.toString().trim();
      if (text.isNotEmpty && text != 'null') return text;
    }
    return '';
  }

  static double _asDouble(dynamic value) {
    if (value is num) return value.toDouble();
    return double.tryParse(value?.toString() ?? '') ?? 0;
  }

  static int? _asInt(dynamic value) {
    if (value is int) return value;
    if (value is num) return value.toInt();
    return int.tryParse(value?.toString() ?? '');
  }
}

List<ProductModel> demoPopularProducts = [
  ProductModel(
    image: productDemoImg1,
    title: 'Producto EcoMarket',
    brandName: 'EcoMarket',
    price: 540,
    priceAfetDiscount: 420,
    dicountpercent: 20,
  ),
];
List<ProductModel> demoFlashSaleProducts = demoPopularProducts;
List<ProductModel> demoBestSellersProducts = demoPopularProducts;
List<ProductModel> kidsProducts = demoPopularProducts;
