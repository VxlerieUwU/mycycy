import 'package:mycycy/storage/entry.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class StorageService {
  final _secureStorage = const FlutterSecureStorage();

  AndroidOptions _getAndroidOptions() => const AndroidOptions(
    encryptedSharedPreferences: true,
  );

  Future<void> put(Entry newItem) async {
    await _secureStorage.write(
        key: newItem.key, value: newItem.value, aOptions: _getAndroidOptions());
  }

  Future<String?> get(String key) async {
    var readData =
    await _secureStorage.read(key: key, aOptions: _getAndroidOptions());
    return readData;
  }

  Future<void> delete(Entry item) async {
    await _secureStorage.delete(key: item.key, aOptions: _getAndroidOptions());
  }

  Future<void> deleteAll() async {
    await _secureStorage.deleteAll(aOptions: _getAndroidOptions());
  }

  Future<bool> exists(String key) async {
    var containsKey = await _secureStorage.containsKey(
        key: key, aOptions: _getAndroidOptions());
    return containsKey;
  }
}