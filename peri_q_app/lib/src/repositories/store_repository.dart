abstract class StoreRepository {
  Future<bool> fetchStoreOpenStatus();

  Future<bool> updateStoreOpenStatus(bool isOpen);
}
