// import 'dart:convert';


// import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:art_gallary/features/home/data/models/artwork_model.dart';
import 'package:hive_ce_flutter/hive_ce_flutter.dart';
import 'storage_registry.dart';

class StorageInitializer {

  static Future<void> init() async {
    await Hive.initFlutter();

    //MARK: Register Adapter 

    Hive.registerAdapter(ArtworkModelAdapter());


    //MARK: Open Boxes
    await Hive.openBox(StorageRegistry.artworkBox);
    await Hive.openBox(StorageRegistry.savedArtworkBox);

  }


}


class LocalData {
  // Singleton pattern
  static final LocalData _instance = LocalData._internal();
  factory LocalData() => _instance;
  LocalData._internal();

  /// Reads a single value safely (primitives, single models, or objects)
  T? get<T>(String boxName, String key, {T? defaultValue}) {
    try {
      final box = Hive.box(boxName);
      final dynamic value = box.get(key, defaultValue: defaultValue);

      if (value == null) return defaultValue;
      if (value is T) return value;

      return value as T;
    } catch (e) {
      print("Hive box reading error [$boxName - $key]: $e");
      return defaultValue;
    }
  }

  /// Reads a list safely and converts List<dynamic> -> List<E>
  List<E>? getList<E>(String boxName, String key, {List<E>? defaultValue}) {
    try {
      final box = Hive.box(boxName);
      final dynamic value = box.get(key);

      if (value == null) return defaultValue;

      if (value is List) {
        // Creates a strongly typed List<E> from Hive's List<dynamic>
        return List<E>.from(value);
      }

      return defaultValue;
    } catch (e) {
      print("Hive box list reading error [$boxName - $key]: $e");
      return defaultValue;
    }
  }

  Future<void> put<T>(String boxName, String key, T value) async {
    final box = Hive.box(boxName);
    await box.put(key, value);
  }

  Future<void> delete(String boxName, String key) async {
    final box = Hive.box(boxName);
    await box.delete(key);
  }

  Future<void> clearBox(String boxName) async {
    final box = Hive.box(boxName);
    await box.clear();
  }
}