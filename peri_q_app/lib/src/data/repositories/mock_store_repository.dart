import '../../repositories/store_repository.dart';

class MockStoreRepository implements StoreRepository {
  MockStoreRepository({
    bool initialStoreOpen = true,
  }) : _storeOpen = initialStoreOpen;

  bool _storeOpen;

  @override
  Future<bool> fetchStoreOpenStatus() async {
    return _storeOpen;
  }

  @override
  Future<bool> updateStoreOpenStatus(bool isOpen) async {
    _storeOpen = isOpen;
    return _storeOpen;
  }
}
