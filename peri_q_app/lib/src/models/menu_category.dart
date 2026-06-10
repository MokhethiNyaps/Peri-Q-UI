class MenuCategoryModel {
  const MenuCategoryModel({
    required this.id,
    required this.name,
    this.sortOrder = 0,
    this.isActive = true,
  });

  final String id;
  final String name;
  final int sortOrder;
  final bool isActive;

  MenuCategoryModel copyWith({
    String? id,
    String? name,
    int? sortOrder,
    bool? isActive,
  }) {
    return MenuCategoryModel(
      id: id ?? this.id,
      name: name ?? this.name,
      sortOrder: sortOrder ?? this.sortOrder,
      isActive: isActive ?? this.isActive,
    );
  }
}
