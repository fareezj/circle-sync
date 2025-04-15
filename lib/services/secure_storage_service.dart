import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'dart:async';

class SecureStorageService {
  SecureStorageService._privateConstructor();

  static final SecureStorageService _instance =
      SecureStorageService._privateConstructor();

  static SecureStorageService get instance => _instance;

  final FlutterSecureStorage _secureStorage = const FlutterSecureStorage();

  // A generic stream controller to notify changes on any key.
  final StreamController<String> _dataChangedController =
      StreamController<String>.broadcast();

  /// Expose the stream for any data change.
  Stream<String> get onDataChanged => _dataChangedController.stream;

  /// Returns a stream that emits an event when the specified key (or 'all') is updated.
  Stream<void> onKeyChanged(String key) {
    return _dataChangedController.stream
        .where((changedKey) => changedKey == key || changedKey == 'all')
        .map((_) {});
  }

  Future<void> writeData(String key, String value) async {
    await _secureStorage.write(
      key: key,
      value: value,
      iOptions: _getIOSOptions(),
      aOptions: _getAndroidOptions(),
    );
    _dataChangedController.add(key);
  }

  Future<String?> readData(String key) async {
    return await _secureStorage.read(
      key: key,
      iOptions: _getIOSOptions(),
      aOptions: _getAndroidOptions(),
    );
  }

  Future<void> deleteData(String key) async {
    await _secureStorage.delete(
      key: key,
      iOptions: _getIOSOptions(),
      aOptions: _getAndroidOptions(),
    );
    _dataChangedController.add(key);
  }

  Future<void> deleteAllData() async {
    await _secureStorage.deleteAll(
      iOptions: _getIOSOptions(),
      aOptions: _getAndroidOptions(),
    );
    // Emit a global update so that every key refreshes.
    _dataChangedController.add('all');
  }

  IOSOptions _getIOSOptions() => const IOSOptions();

  AndroidOptions _getAndroidOptions() => AndroidOptions();

  void dispose() {
    _dataChangedController.close();
  }
}
