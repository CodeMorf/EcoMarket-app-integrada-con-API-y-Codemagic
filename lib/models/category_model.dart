class CategoryModel {
  final int? id;
  final String title;
  final String? image, svgSrc;
  final List<CategoryModel>? subCategories;

  CategoryModel({
    this.id,
    required this.title,
    this.image,
    this.svgSrc,
    this.subCategories,
  });

  factory CategoryModel.fromEcoMarketJson(Map<String, dynamic> json) {
    final children = json['children'];
    return CategoryModel(
      id: _asInt(json['id']),
      title: _firstNonEmpty([json['name'], json['title'], json['label']]),
      image: _firstNonEmpty([json['image'], json['icon']]),
      subCategories: children is List
          ? children
              .whereType<Map>()
              .map((item) => CategoryModel.fromEcoMarketJson(Map<String, dynamic>.from(item)))
              .toList()
          : null,
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

  static int? _asInt(dynamic value) {
    if (value is int) return value;
    if (value is num) return value.toInt();
    return int.tryParse(value?.toString() ?? '');
  }
}

final List<CategoryModel> demoCategoriesWithImage = [
  CategoryModel(title: 'Supermercado'),
  CategoryModel(title: 'Farmacia'),
  CategoryModel(title: 'Hogar'),
];

final List<CategoryModel> demoCategories = demoCategoriesWithImage;
