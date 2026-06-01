class AddOnOption {
  const AddOnOption({
    required this.name,
    required this.price,
  });

  final String name;
  final double price;

  factory AddOnOption.fromJson(Map<String, dynamic> json) {
    return AddOnOption(
      name: json['name'] as String? ?? '',
      price: (json['price'] as num?)?.toDouble() ?? 0,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'name': name,
      'price': price,
    };
  }
}

class MenuItemModel {
  const MenuItemModel({
    required this.id,
    required this.name,
    required this.description,
    required this.price,
    required this.category,
    required this.imagePath,
    this.isAvailable = true,
    this.prepMinutes = 25,
    this.spiceLevels = const ['Mild', 'Medium', 'Hot', 'Extra Hot'],
    this.addOns = const [],
  });

  final String id;
  final String name;
  final String description;
  final double price;
  final String category;
  final String imagePath;
  final bool isAvailable;
  final int prepMinutes;
  final List<String> spiceLevels;
  final List<AddOnOption> addOns;

  MenuItemModel copyWith({
    String? id,
    String? name,
    String? description,
    double? price,
    String? category,
    String? imagePath,
    bool? isAvailable,
    int? prepMinutes,
    List<String>? spiceLevels,
    List<AddOnOption>? addOns,
  }) {
    return MenuItemModel(
      id: id ?? this.id,
      name: name ?? this.name,
      description: description ?? this.description,
      price: price ?? this.price,
      category: category ?? this.category,
      imagePath: imagePath ?? this.imagePath,
      isAvailable: isAvailable ?? this.isAvailable,
      prepMinutes: prepMinutes ?? this.prepMinutes,
      spiceLevels: spiceLevels ?? this.spiceLevels,
      addOns: addOns ?? this.addOns,
    );
  }

  factory MenuItemModel.fromJson(Map<String, dynamic> json) {
    return MenuItemModel(
      id: json['id'] as String? ?? '',
      name: json['name'] as String? ?? '',
      description: json['description'] as String? ?? '',
      price: (json['price'] as num?)?.toDouble() ?? 0,
      category: json['category'] as String? ?? '',
      imagePath: json['imagePath'] as String? ?? '',
      isAvailable: json['isAvailable'] as bool? ?? true,
      prepMinutes: json['prepMinutes'] as int? ?? 25,
      spiceLevels: (json['spiceLevels'] as List<dynamic>?)
              ?.map((level) => level as String)
              .toList() ??
          const ['Mild', 'Medium', 'Hot', 'Extra Hot'],
      addOns: (json['addOns'] as List<dynamic>?)
              ?.map((addOn) => AddOnOption.fromJson(addOn as Map<String, dynamic>))
              .toList() ??
          const [],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'description': description,
      'price': price,
      'category': category,
      'imagePath': imagePath,
      'isAvailable': isAvailable,
      'prepMinutes': prepMinutes,
      'spiceLevels': spiceLevels,
      'addOns': addOns.map((addOn) => addOn.toJson()).toList(),
    };
  }
}

class CartItemModel {
  CartItemModel({
    required this.id,
    required this.item,
    required this.quantity,
    this.spiceLevel,
    this.notes = '',
    this.selectedAddOns = const [],
  });

  final String id;
  final MenuItemModel item;
  int quantity;
  String? spiceLevel;
  String notes;
  List<AddOnOption> selectedAddOns;

  double get total {
    final addOnTotal = selectedAddOns.fold<double>(
      0,
      (sum, addOn) => sum + addOn.price,
    );
    return (item.price + addOnTotal) * quantity;
  }

  CartItemModel copyWith({
    String? id,
    MenuItemModel? item,
    int? quantity,
    String? spiceLevel,
    String? notes,
    List<AddOnOption>? selectedAddOns,
  }) {
    return CartItemModel(
      id: id ?? this.id,
      item: item ?? this.item,
      quantity: quantity ?? this.quantity,
      spiceLevel: spiceLevel ?? this.spiceLevel,
      notes: notes ?? this.notes,
      selectedAddOns: selectedAddOns ?? List<AddOnOption>.from(this.selectedAddOns),
    );
  }

  factory CartItemModel.fromJson(Map<String, dynamic> json) {
    return CartItemModel(
      id: json['id'] as String? ?? '',
      item: MenuItemModel.fromJson(json['item'] as Map<String, dynamic>),
      quantity: json['quantity'] as int? ?? 1,
      spiceLevel: json['spiceLevel'] as String?,
      notes: json['notes'] as String? ?? '',
      selectedAddOns: (json['selectedAddOns'] as List<dynamic>?)
              ?.map((addOn) => AddOnOption.fromJson(addOn as Map<String, dynamic>))
              .toList() ??
          const [],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'item': item.toJson(),
      'quantity': quantity,
      'spiceLevel': spiceLevel,
      'notes': notes,
      'selectedAddOns': selectedAddOns.map((addOn) => addOn.toJson()).toList(),
    };
  }
}
