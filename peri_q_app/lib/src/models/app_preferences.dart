import 'package:flutter/material.dart';
import 'order.dart';

class SavedAddress {
  const SavedAddress({
    required this.id,
    required this.label,
    required this.address,
    this.notes = '',
  });

  final String id;
  final String label;
  final String address;
  final String notes;

  String get displayAddress {
    final cleanNotes = notes.trim();
    if (cleanNotes.isEmpty) {
      return address.trim();
    }
    return '${address.trim()}\n$cleanNotes';
  }

  SavedAddress copyWith({
    String? id,
    String? label,
    String? address,
    String? notes,
  }) {
    return SavedAddress(
      id: id ?? this.id,
      label: label ?? this.label,
      address: address ?? this.address,
      notes: notes ?? this.notes,
    );
  }

  factory SavedAddress.fromJson(Map<String, dynamic> json) {
    return SavedAddress(
      id: json['id'] as String? ?? '',
      label: json['label'] as String? ?? 'Address',
      address: json['address'] as String? ?? '',
      notes: json['notes'] as String? ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return {'id': id, 'label': label, 'address': address, 'notes': notes};
  }
}

class AppPreferences {
  const AppPreferences({
    this.hasReturningSession = false,
    this.isGuest = true,
    this.customerName = '',
    this.customerPhone = '',
    this.storeOpen = true,
    this.selectedMenuCategory = 'All',
    this.savedAddresses = const [],
    this.defaultAddressId,
    this.preferredPaymentMethod = PaymentMethod.yoco,
    // New installs open in the dark "Night Grill" brand theme; a saved choice
    // (light, dark or system) is always respected.
    this.themeMode = ThemeMode.dark,
  });

  final bool hasReturningSession;
  final bool isGuest;
  final String customerName;
  final String customerPhone;
  final bool storeOpen;
  final String selectedMenuCategory;
  final List<SavedAddress> savedAddresses;
  final String? defaultAddressId;
  final PaymentMethod preferredPaymentMethod;
  final ThemeMode themeMode;

  AppPreferences copyWith({
    bool? hasReturningSession,
    bool? isGuest,
    String? customerName,
    String? customerPhone,
    bool? storeOpen,
    String? selectedMenuCategory,
    List<SavedAddress>? savedAddresses,
    String? defaultAddressId,
    bool clearDefaultAddressId = false,
    PaymentMethod? preferredPaymentMethod,
    ThemeMode? themeMode,
  }) {
    return AppPreferences(
      hasReturningSession: hasReturningSession ?? this.hasReturningSession,
      isGuest: isGuest ?? this.isGuest,
      customerName: customerName ?? this.customerName,
      customerPhone: customerPhone ?? this.customerPhone,
      storeOpen: storeOpen ?? this.storeOpen,
      selectedMenuCategory: selectedMenuCategory ?? this.selectedMenuCategory,
      savedAddresses: savedAddresses ?? this.savedAddresses,
      defaultAddressId: clearDefaultAddressId
          ? null
          : (defaultAddressId ?? this.defaultAddressId),
      preferredPaymentMethod:
          preferredPaymentMethod ?? this.preferredPaymentMethod,
      themeMode: themeMode ?? this.themeMode,
    );
  }

  factory AppPreferences.fromJson(Map<String, dynamic> json) {
    final savedAddressValues = json['savedAddresses'] as List<dynamic>? ?? [];

    final themeStr = json['themeMode'] as String?;
    final mode = switch (themeStr) {
      'light' => ThemeMode.light,
      'system' => ThemeMode.system,
      _ => ThemeMode.dark,
    };

    return AppPreferences(
      hasReturningSession: json['hasReturningSession'] as bool? ?? false,
      isGuest: json['isGuest'] as bool? ?? true,
      customerName: json['customerName'] as String? ?? '',
      customerPhone: json['customerPhone'] as String? ?? '',
      storeOpen: json['storeOpen'] as bool? ?? true,
      selectedMenuCategory: json['selectedMenuCategory'] as String? ?? 'All',
      savedAddresses: savedAddressValues
          .whereType<Map<String, dynamic>>()
          .map(SavedAddress.fromJson)
          .where((address) => address.id.isNotEmpty)
          .toList(),
      defaultAddressId: json['defaultAddressId'] as String?,
      preferredPaymentMethod: paymentMethodFromCode(
        json['preferredPaymentMethod'] as String? ?? 'yoco',
      ),
      themeMode: mode,
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
      'savedAddresses': savedAddresses
          .map((address) => address.toJson())
          .toList(),
      'defaultAddressId': defaultAddressId,
      'preferredPaymentMethod': preferredPaymentMethod.code,
      'themeMode': themeMode.name,
    };
  }
}
