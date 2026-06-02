class AppPreferences {
  const AppPreferences({
    this.hasReturningSession = false,
    this.isGuest = true,
    this.customerName = '',
    this.customerPhone = '',
    this.storeOpen = true,
    this.selectedMenuCategory = 'All',
  });

  final bool hasReturningSession;
  final bool isGuest;
  final String customerName;
  final String customerPhone;
  final bool storeOpen;
  final String selectedMenuCategory;

  AppPreferences copyWith({
    bool? hasReturningSession,
    bool? isGuest,
    String? customerName,
    String? customerPhone,
    bool? storeOpen,
    String? selectedMenuCategory,
  }) {
    return AppPreferences(
      hasReturningSession: hasReturningSession ?? this.hasReturningSession,
      isGuest: isGuest ?? this.isGuest,
      customerName: customerName ?? this.customerName,
      customerPhone: customerPhone ?? this.customerPhone,
      storeOpen: storeOpen ?? this.storeOpen,
      selectedMenuCategory: selectedMenuCategory ?? this.selectedMenuCategory,
    );
  }

  factory AppPreferences.fromJson(Map<String, dynamic> json) {
    return AppPreferences(
      hasReturningSession: json['hasReturningSession'] as bool? ?? false,
      isGuest: json['isGuest'] as bool? ?? true,
      customerName: json['customerName'] as String? ?? '',
      customerPhone: json['customerPhone'] as String? ?? '',
      storeOpen: json['storeOpen'] as bool? ?? true,
      selectedMenuCategory: json['selectedMenuCategory'] as String? ?? 'All',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'hasReturningSession': hasReturningSession,
      'isGuest': isGuest,
      'customerName': customerName,
      'customerPhone': customerPhone,
      'storeOpen': storeOpen,
      'selectedMenuCategory': selectedMenuCategory,
    };
  }
}
