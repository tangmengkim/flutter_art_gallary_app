import 'dart:developer';
import 'dart:io';

import 'package:art_gallary/core/storage/storage_initializer.dart';
import 'package:art_gallary/core/storage/storage_registry.dart';
import 'package:art_gallary/features/home/data/models/artwork_model.dart';
import 'package:dio/dio.dart';
import 'package:path_provider/path_provider.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'saved_artwork_repo.g.dart';

@riverpod
SavedArtworkRepository savedArtworkRepository(Ref ref) {
  return SavedArtworkRepository(Dio());
}

class SavedArtworkRepository {
  SavedArtworkRepository(this._dio);

  final Dio _dio;

  /// ─── HIVE PERSISTENCE ───────────────────────────────────────────────────

  List<ArtworkModel> getSavedArtworks() {
    return LocalData().getList<ArtworkModel>(
          StorageRegistry.savedArtworkBox,
          StorageKey.savedArtworkList,
          defaultValue: [],
        ) ??
        [];
  }

  Future<void> saveArtworks(List<ArtworkModel> artworks) async {
    await LocalData().put<List<ArtworkModel>>(
      StorageRegistry.savedArtworkBox,
      StorageKey.savedArtworkList,
      artworks,
    );
  }

  /// ─── LOCAL FILE DOWNLOAD ────────────────────────────────────────────────

  Future<String> downloadImage({
    required String imageUrl,
    required String artworkId,
    required void Function(int count, int total) onProgress,
  }) async {
    final appDir = await getApplicationDocumentsDirectory();
    final targetDir = Directory('${appDir.path}/downloaded_artworks');

    if (!await targetDir.exists()) {
      await targetDir.create(recursive: true);
    }

    final uri = Uri.parse(imageUrl);
    final String ext =
        uri.pathSegments.isNotEmpty && uri.pathSegments.last.contains('.')
        ? uri.pathSegments.last.split('.').last
        : 'jpg';

    final fileName = 'artwork_$artworkId.$ext';
    final fullPath = '${targetDir.path}/$fileName';
    final file = File(fullPath);

    if (await file.exists()) {
      print('===============fhdshafhdsahfashd');

      return fullPath;
    }

    try {
      await _dio.download(
        imageUrl,
        fullPath,
        options: Options(responseType: ResponseType.bytes),
        onReceiveProgress: onProgress,
      );
      return fullPath;
    } catch (e) {
      if (await file.exists()) {
        await file.delete();
      }
      rethrow;
    }
  }

  /// Deletes the physical file at [filePath] if it exists on disk
  Future<void> deleteImage(String filePath) async {
    print('==================$filePath');
    try {
      final file = File(filePath);
      if (await file.exists()) {
        await file.delete();
      }
    } catch (e) {
      log('Failed to delete physical file at $filePath', error: e);
      rethrow;
    }
  }
}
