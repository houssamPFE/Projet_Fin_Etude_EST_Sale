class CategoryModel {
  final int id;
  final String name;
  final String slug;
  final String icon;
  final String description;
  final bool isActive;

  const CategoryModel({
    required this.id,
    required this.name,
    required this.slug,
    required this.icon,
    required this.description,
    required this.isActive,
  });

  factory CategoryModel.fromJson(Map<String, dynamic> json) => CategoryModel(
        id: json['id'] as int,
        name: json['name'] as String,
        slug: json['slug'] as String,
        icon: json['icon'] as String? ?? '',
        description: json['description'] as String? ?? '',
        isActive: json['is_active'] as bool? ?? true,
      );
}
