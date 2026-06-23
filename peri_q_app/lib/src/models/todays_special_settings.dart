class TodaysSpecialSettings {
  const TodaysSpecialSettings({
    this.enabled = true,
    this.label = "TODAY'S SPECIAL",
    this.title = 'Chicken, Pork & Wors Plate',
    this.subtitle = 'R70 - Flame-grilled meats served with pap',
    this.imagePath = 'assets/images/brand_mark.png',
    this.menuItemId = 'combo-chicken-pork-wors',
  });

  final bool enabled;
  final String label;
  final String title;
  final String subtitle;
  final String imagePath;
  final String? menuItemId;

  TodaysSpecialSettings copyWith({
    bool? enabled,
    String? label,
    String? title,
    String? subtitle,
    String? imagePath,
    String? menuItemId,
  }) {
    return TodaysSpecialSettings(
      enabled: enabled ?? this.enabled,
      label: label ?? this.label,
      title: title ?? this.title,
      subtitle: subtitle ?? this.subtitle,
      imagePath: imagePath ?? this.imagePath,
      menuItemId: menuItemId ?? this.menuItemId,
    );
  }

  factory TodaysSpecialSettings.fromJson(Map<String, dynamic>? json) {
    if (json == null) {
      return const TodaysSpecialSettings();
    }

    return TodaysSpecialSettings(
      enabled: json['todays_special_enabled'] as bool? ?? true,
      label: _stringOrDefault(json['todays_special_label'], "TODAY'S SPECIAL"),
      title: _stringOrDefault(
        json['todays_special_title'],
        'Chicken, Pork & Wors Plate',
      ),
      subtitle: _stringOrDefault(
        json['todays_special_subtitle'],
        'R70 - Flame-grilled meats served with pap',
      ),
      imagePath: _stringOrDefault(
        json['todays_special_image_path'],
        'assets/images/brand_mark.png',
      ),
      menuItemId: _nullableString(json['todays_special_menu_item_id']),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'todays_special_enabled': enabled,
      'todays_special_label': label.trim(),
      'todays_special_title': title.trim(),
      'todays_special_subtitle': subtitle.trim(),
      'todays_special_image_path': imagePath.trim(),
      'todays_special_menu_item_id': menuItemId?.trim().isEmpty ?? true
          ? null
          : menuItemId!.trim(),
    };
  }

  static String _stringOrDefault(Object? value, String fallback) {
    final text = value?.toString().trim() ?? '';
    return text.isEmpty ? fallback : text;
  }

  static String? _nullableString(Object? value) {
    final text = value?.toString().trim() ?? '';
    return text.isEmpty ? null : text;
  }
}
