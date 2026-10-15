import 'dart:async';
import 'dart:developer';

import 'package:art_gallary/core/storage/storage_initializer.dart';
import 'package:art_gallary/core/storage/storage_registry.dart';
import 'package:art_gallary/features/home/data/models/artwork_model.dart';
import 'package:art_gallary/features/home/data/repository/artwork_repo.dart';
import 'package:art_gallary/http/app_failure.dart';
import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'home_vm.freezed.dart';
part 'home_vm.g.dart';

@freezed
abstract class HomeState with _$HomeState {
  const factory HomeState({
    @Default(false) bool isOffline,
    @Default(false) bool isLoading,
    @Default(false) bool isRefreshing,
    @Default(false) bool isLoadMore,
    @Default(true) bool hasMore,
    @Default(1) int page,
    @Default(<ArtworkModel>[]) List<ArtworkModel> artworks,
    @Default({}) Map<String, ArtworkModel> artworkDetails, // Detail Cache
    @Default(-1) int selectedArtworkIndex,
    String? error,
  }) = _HomeState;
}

@riverpod
class HomeViewModel extends _$HomeViewModel {
  static const int _pageSize = 20;
  static const Duration _retryInterval = Duration(seconds: 4);
  bool _cacheLoaded = false;

  Timer? _retryTimer;

  @override
  HomeState build() {
    // Future.microtask(_loadCachedArtworks);
    ref.onDispose(_stopAutoRetry);
    return const HomeState();
  }

  ArtworkRepository get _repository => ref.read(artworkRepositoryProvider);

  // Helper flag to check active loading operations
  bool get _isBusy => state.isLoading || state.isRefreshing || state.isLoadMore;

  // ─── PUBLIC ACTIONS ────────────────────────────────────────────────────────

  /// Initial fetch or pull-to-refresh
  Future<void> load({bool refresh = false, bool silent = false}) async {
    if (_isBusy) return;

    final isInitial = state.artworks.isEmpty;

    if (!silent) {
      _cacheLoaded = false; // Reset cache loaded flag for fresh load
      state = state.copyWith(
        isLoading: isInitial && !refresh,
        isRefreshing: refresh && !isInitial,
        error: null,
      );
    }

    await _fetchArtworks(page: 2); // skip duplicate image page 1
  }

  void selectArtwork(ArtworkModel artwork) {
    final index = state.artworks.indexOf(artwork);
    print('Selected artwork index: $index');
    if (index == -1) {
      log('Artwork not found in the current list: ${artwork.id}');
      return;
    }
    state = state.copyWith(selectedArtworkIndex: index);
  }

  int get getSelectedArtworkIndex => state.selectedArtworkIndex;

  /// Paginate next set of items
  Future<void> loadMore({bool silent = false}) async {
    if (_isBusy || !state.hasMore || state.artworks.isEmpty) return;

    if (!silent) {
      state = state.copyWith(isLoadMore: true, error: null);
    }

    await _fetchArtworks(page: state.page + 1, isPagination: true);
  }

  void clearError() => state = state.copyWith(error: null);

  // ─── PRIVATE FETCH LOGIC ───────────────────────────────────────────────────

  Future<void> _fetchArtworks({
  required int page,
  bool isPagination = false,
}) async {
  try {
    final response = await _repository.getArtList(
      queries: {'page': page, 'limit': _pageSize},
    );

    if (!ref.mounted) return;

    _stopAutoRetry();

    final List<ArtworkModel> updatedList;
    if (isPagination) {
      if (response.isEmpty) {
        // If empty response, update pagination flags without re-allocating artwork list
        state = state.copyWith(
          hasMore: false,
          isLoadMore: false,
          error: null,
        );
        return;
      }

      final existingIds = state.artworks.map((art) => art.id).toSet();
      final uniqueNewItems = response.where((art) => !existingIds.contains(art.id));

      // No actual new items returned
      if (uniqueNewItems.isEmpty) {
  state = state.copyWith(
    hasMore: false,
    isLoadMore: false,
    isLoading: false,
    isRefreshing: false,
    error: null,
  );
  return;
}

      updatedList = List.of(state.artworks)..addAll(uniqueNewItems);
    } else {
      updatedList = response;
    }

    // Single State Update for successful fetch
    state = state.copyWith(
      artworks: updatedList,
      page: page,
      hasMore: response.length >= _pageSize,
      isLoading: false,
      isRefreshing: false,
      isLoadMore: false,
      isOffline: false,
      error: null,
    );

    // Safe local caching (isolated from catch block so it doesn't trigger retry state)
    _cacheArtworksLocally(updatedList);

  } catch (e, st) {
    if (!ref.mounted) return;
    
    _handleError(e, st);

    // Only fallback to disk cache if we don't already have in-memory items
    if (state.artworks.isEmpty) {
      await _loadCachedArtworks();
    }
  }
}

void _cacheArtworksLocally(List<ArtworkModel> list) {
  unawaited(
    LocalData()
        .put<List<ArtworkModel>>(
          StorageRegistry.artworkBox,
          StorageKey.artworkList,
          list,
        )
        .catchError((e) {
      log('Failed to cache artworks locally: $e');
    }),
  );
}

  Future<void> fetchArtworkDetail(String artworkId) async {

  try {
    final response = await _repository.getArtDetail(id: artworkId);
    if (!ref.mounted) return;


      state = state.copyWith(
        artworkDetails: {
          ...state.artworkDetails,
          artworkId: response,
        },
      );
    
  } catch (e) {
    log('Failed to fetch detail for $artworkId: $e');
  } finally {

  }
}

  // -- Cached Artworks Management
  Future<void> _loadCachedArtworks() async {
    if (_cacheLoaded || !ref.mounted) return;

    _cacheLoaded = true;

    final cachedArtworks = LocalData().getList<ArtworkModel>(
      StorageRegistry.artworkBox,
      StorageKey.artworkList,
      defaultValue: [],
    );
    if (cachedArtworks == null || cachedArtworks.isEmpty) return;

    state = state.copyWith(
      artworks: cachedArtworks,
      isLoading: false,
      // isOffline: true,
      error: null,
    );
  }
  // ─── ERROR & AUTO-RETRY LOGIC ──────────────────────────────────────────────

  void _handleError(Object e, StackTrace st) {
    log('API Request Error', error: e, stackTrace: st);
    if (!ref.mounted) return;

    final failure = AppFailure.fromAny(e);
    final isNoInternet = failure.maybeWhen(
      noInternet: (_) => true,
      orElse: () => false,
    );

    state = state.copyWith(
      isLoading: false,
      isRefreshing: false,
      isLoadMore: false,
      isOffline: isNoInternet ? true : state.isOffline,
      error: failure.errorMessage,
    );

    if (isNoInternet) {
      _startAutoRetry();
    }
  }

  void _startAutoRetry() {
    if (_retryTimer?.isActive ?? false) return;

    _retryTimer = Timer.periodic(_retryInterval, (_) {
      if (!ref.mounted) {
        _stopAutoRetry();
        return;
      }

      if (state.artworks.isEmpty) {
        load(silent: true);
      } else if (state.hasMore) {
        loadMore(silent: true);
      }
    });
  }

  void _stopAutoRetry() {
    _retryTimer?.cancel();
    _retryTimer = null;
  }
}
