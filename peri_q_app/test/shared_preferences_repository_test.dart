import 'package:flutter_test/flutter_test.dart';
import 'package:peri_q_app/src/data/local/shared_preferences_repository.dart';
import 'package:peri_q_app/src/models/app_preferences.dart';
import 'package:peri_q_app/src/models/order.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test(
    'checkout cart and retry ID survive restart and stay scoped to the customer',
    () async {
      final secure = _MemorySecurePreferencesStorage();
      final first = SharedPreferencesRepository(secureStorage: secure);
      await first.saveCheckoutCart('customer-a', {
        'items': [
          {'notes': 'Gate 2'},
        ],
        'requestId': 'retry-123',
      });
      final restored = SharedPreferencesRepository(secureStorage: secure);
      expect(
        (await restored.loadCheckoutCart('customer-a'))?['requestId'],
        'retry-123',
      );
      expect(await restored.loadCheckoutCart('customer-b'), isNull);
    },
  );
  group('SharedPreferencesRepository secure personal data', () {
    test('migrates legacy plaintext personal data once', () async {
      SharedPreferences.setMockInitialValues({
        'customer_name': 'Naledi',
        'customer_phone': '+27 71 111 2222',
        'saved_addresses':
            '[{"id":"home","label":"Home","address":"1 Main Street","notes":"Gate 2"}]',
        'default_address_id': 'home',
      });
      final secureStorage = _MemorySecurePreferencesStorage();
      final repository = SharedPreferencesRepository(
        secureStorage: secureStorage,
      );

      final preferences = await repository.loadPreferences();

      expect(preferences.customerName, 'Naledi');
      expect(preferences.customerPhone, '+27 71 111 2222');
      expect(preferences.savedAddresses.single.address, '1 Main Street');
      expect(preferences.defaultAddressId, 'home');
      expect(
        secureStorage.values['peri_q_saved_addresses_v1'],
        contains('1 Main Street'),
      );

      final legacy = await SharedPreferences.getInstance();
      expect(legacy.getString('customer_name'), isNull);
      expect(legacy.getString('customer_phone'), isNull);
      expect(legacy.getString('saved_addresses'), isNull);
      expect(legacy.getString('default_address_id'), isNull);
    });

    test('writes personal data only to secure storage', () async {
      SharedPreferences.setMockInitialValues({});
      final secureStorage = _MemorySecurePreferencesStorage();
      final repository = SharedPreferencesRepository(
        secureStorage: secureStorage,
      );
      const preferences = AppPreferences(
        hasReturningSession: true,
        isGuest: false,
        customerName: 'Anele',
        customerPhone: '+27 82 000 0000',
        savedAddresses: [
          SavedAddress(
            id: 'work',
            label: 'Work',
            address: '2 Office Park',
            notes: 'Reception',
          ),
        ],
        defaultAddressId: 'work',
        preferredPaymentMethod: PaymentMethod.eft,
      );

      await repository.savePreferences(preferences);

      expect(secureStorage.values['peri_q_customer_name_v1'], 'Anele');
      expect(
        secureStorage.values['peri_q_customer_phone_v1'],
        '+27 82 000 0000',
      );
      expect(
        secureStorage.values['peri_q_saved_addresses_v1'],
        contains('2 Office Park'),
      );
      expect(secureStorage.values['peri_q_default_address_id_v1'], 'work');

      final stored = await SharedPreferences.getInstance();
      expect(stored.getString('customer_name'), isNull);
      expect(stored.getString('customer_phone'), isNull);
      expect(stored.getString('saved_addresses'), isNull);
      expect(stored.getString('default_address_id'), isNull);
      expect(stored.getString('preferred_payment_method'), 'eft');
    });

    test('secure values win over stale interrupted-migration values', () async {
      SharedPreferences.setMockInitialValues({
        'customer_name': 'Old name',
        'customer_phone': 'Old phone',
      });
      final secureStorage = _MemorySecurePreferencesStorage({
        'peri_q_customer_name_v1': 'Current name',
        'peri_q_customer_phone_v1': 'Current phone',
        'peri_q_saved_addresses_v1': '[]',
        'peri_q_default_address_id_v1': '',
      });
      final repository = SharedPreferencesRepository(
        secureStorage: secureStorage,
      );

      final preferences = await repository.loadPreferences();

      expect(preferences.customerName, 'Current name');
      expect(preferences.customerPhone, 'Current phone');
      final stored = await SharedPreferences.getInstance();
      expect(stored.getString('customer_name'), isNull);
      expect(stored.getString('customer_phone'), isNull);
    });
  });
}

class _MemorySecurePreferencesStorage implements SecurePreferencesStorage {
  _MemorySecurePreferencesStorage([Map<String, String>? values])
    : values = {...?values};

  final Map<String, String> values;

  @override
  Future<String?> read(String key) async => values[key];

  @override
  Future<void> write(String key, String value) async {
    values[key] = value;
  }
}
