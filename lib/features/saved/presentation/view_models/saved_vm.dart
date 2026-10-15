import 'dart:developer';

import 'package:art_gallary/features/home/data/models/artwork_model.dart';
import 'package:art_gallary/features/saved/data/repository/saved_artwork_repo.dart';
import 'package:art_gallary/http/app_failure.dart';
import 'package:dio/dio.dart';
import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'saved_vm.freezed.dart';
part 'saved_vm.g.dart';

@freezed
abstract class SavedState with _$SavedState {
  const factory SavedState({
    @Default(<ArtworkModel>[]) List<ArtworkModel> savedArtworks,
    @Default(false) bool isLoading,
  }) = _SavedState;
}

@riverpod
class SavedViewModel extends _$SavedViewModel {
  @override
  SavedState build() {
    Future.microtask(loadSavedArtworks);
    return const SavedState();
  }

  SavedArtworkRepository get _repository =>
      ref.read(savedArtworkRepositoryProvider);

  /// ─── ACTIONS ─────────────────────────────────────────────────────────────

  /// Load all saved artworks from storage
  Future<void> loadSavedArtworks() async {
    state = state.copyWith(isLoading: true);
    try {
      final saved = _repository.getSavedArtworks();
      state = state.copyWith(savedArtworks: saved, isLoading: false);
    } catch (e) {
      log('Error loading saved artworks', error: e);
      state = state.copyWith(isLoading: false);
    }
  }

  /// Download an artwork image to app storage
  /// Accepts an optional [onProgress] callback for direct UI toast updates
  Future<String?> downloadArtwork(
    ArtworkModel artwork, {
    void Function(double progress)? onProgress,
  }) async {
    final artworkId = artwork.id?.toString() ?? '';
    if (artworkId.isEmpty) return null;

    try {

      final localPath = await _repository.downloadImage(
        imageUrl: artwork.downloadUrl ?? artwork.url ?? '',
        artworkId: artworkId,
        onProgress: (count, total) {
          if (total > 0) {
            final progress = count / total;
            onProgress?.call(progress);
          }
        },
      );

      _updateArtworkLocalPath(artworkId, localPath);
      return localPath;
    } catch (e) {
      log('Failed to download artwork: $artworkId', error: e);
      throw(AppFailure.fromAny(e));
    } 
  }

  /// Deletes the local artwork file from device storage and resets `localUrl`
Future<String> deleteArtwork(ArtworkModel artwork) async {
  final artworkId = artwork.id?.toString() ?? '';
  final localUrl = artwork.localUrl;

  if (artworkId.isEmpty || localUrl == null || localUrl.isEmpty) {
    return 'No local file found to delete.';
  }

  try {
    // 1. Delete physical file from device storage via repository
    await _repository.deleteImage(localUrl);

    return 'Downloaded image deleted successfully';
  } catch (e) {
    log('Failed to delete artwork file: $artworkId', error: e);
    throw AppFailure.fromAny(e);
  }
}

  /// Toggle save/unsave state for an artwork and return a descriptive message string
  Future<String> toggleSave(ArtworkModel artwork) async {
    try {
      final isSaved = isArtworkSaved(artwork.id);
      final List<ArtworkModel> updatedList = List.from(state.savedArtworks);

      if (isSaved) {
        await deleteArtwork(state.savedArtworks.firstWhere((saved) => saved.id == artwork.id,));
        updatedList.removeWhere((item) => item.id == artwork.id);
        
        } else {
        // Mark as saved and attempt local storage download
        final localUrl = await downloadArtwork(artwork);
        final savedItem = artwork.copyWith(isSaved: true);
        updatedList.insert(0, savedItem.copyWith(localUrl: localUrl));
      }

      await _repository.saveArtworks(updatedList);
      state = state.copyWith(savedArtworks: updatedList);

      return isSaved ? 'Removed from saved' : 'Saved to collection';
    } catch (e) {
      log('Error toggling artwork save', error: e);
      return 'Could not update saved status. ${AppFailure.fromDioException(e as DioException)}';
    }
  }

  bool isArtworkSaved(dynamic id) {
    if (id == null) return false;
    return state.savedArtworks.any((item) => item.id == id);
  }

  /// ─── PRIVATE HELPERS ─────────────────────────────────────────────────────

  void _updateArtworkLocalPath(String artworkId, String localPath) {
    final updatedList = state.savedArtworks.map((art) {
      if (art.id?.toString() == artworkId) {
        return art.copyWith(localUrl: localPath);
      }
      return art;
    }).toList();

    _repository.saveArtworks(updatedList);
    state = state.copyWith(savedArtworks: updatedList);
  }

  // void _updateDownloadProgress(String id, double progress) {
  //   final newMap = Map<String, double>.from(state.downloadProgress);
  //   newMap[id] = progress;
  //   state = state.copyWith(downloadProgress: newMap);
  // }

  // void _removeDownloadProgress(String id) {
  //   final newMap = Map<String, double>.from(state.downloadProgress);
  //   newMap.remove(id);
  //   state = state.copyWith(downloadProgress: newMap);
  // }
}