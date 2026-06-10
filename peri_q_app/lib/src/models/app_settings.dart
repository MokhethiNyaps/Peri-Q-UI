import 'todays_special_settings.dart';

class AppSettings {
  const AppSettings({
    this.storeOpen = true,
    this.openingTime = '10:00',
    this.closingTime = '21:00',
    this.todaysSpecial = const TodaysSpecialSettings(),
  });

  final bool storeOpen;
  final String openingTime;
  final String closingTime;
  final TodaysSpecialSettings todaysSpecial;

  AppSettings copyWith({
    bool? storeOpen,
    String? openingTime,
    String? closingTime,
    TodaysSpecialSettings? todaysSpecial,
  }) {
    return AppSettings(
      storeOpen: storeOpen ?? this.storeOpen,
      openingTime: openingTime ?? this.openingTime,
      closingTime: closingTime ?? this.closingTime,
      todaysSpecial: todaysSpecial ?? this.todaysSpecial,
    );
  }

  factory AppSettings.fromJson(Map<String, dynamic>? json) {
    if (json == null) {
      return const AppSettings();
    }

    return AppSettings(
      storeOpen: json['store_open'] as bool? ?? true,
      openingTime: _validTimeOrDefault(json['opening_time'], '10:00'),
      closingTime: _validTimeOrDefault(json['closing_time'], '21:00'),
      todaysSpecial: TodaysSpecialSettings.fromJson(json),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'store_open': storeOpen,
      'opening_time': openingTime.trim(),
      'closing_time': closingTime.trim(),
      ...todaysSpecial.toJson(),
    };
  }

  bool isOpenAt(DateTime dateTime) {
    if (!storeOpen) {
      return false;
    }

    final openingMinutes = _minutesFromTime(openingTime);
    final closingMinutes = _minutesFromTime(closingTime);
    final nowMinutes = (dateTime.hour * 60) + dateTime.minute;

    if (openingMinutes == closingMinutes) {
      return true;
    }

    if (openingMinutes < closingMinutes) {
      return nowMinutes >= openingMinutes && nowMinutes < closingMinutes;
    }

    return nowMinutes >= openingMinutes || nowMinutes < closingMinutes;
  }

  static int _minutesFromTime(String value) {
    final parts = value.split(':');
    if (parts.length != 2) {
      return 0;
    }

    final hour = int.tryParse(parts[0]) ?? 0;
    final minute = int.tryParse(parts[1]) ?? 0;
    return (hour.clamp(0, 23) * 60) + minute.clamp(0, 59);
  }

  static String _validTimeOrDefault(Object? value, String fallback) {
    final text = value?.toString().trim() ?? '';
    if (RegExp(r'^\d{2}:\d{2}$').hasMatch(text)) {
      return text;
    }
    return fallback;
  }
}
