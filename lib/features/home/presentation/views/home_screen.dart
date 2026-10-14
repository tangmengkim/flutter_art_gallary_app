import 'package:art_gallary/features/home/data/models/artwork_model.dart';
import 'package:art_gallary/features/home/presentation/view_models/home_vm.dart';
import 'package:art_gallary/theme/app_colors.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

class HomeScreen extends ConsumerStatefulWidget {
  const HomeScreen({super.key, this.onArtworkTap});

  final ValueChanged<ArtworkModel>? onArtworkTap;

  @override
  ConsumerState<HomeScreen> createState() => _ArtFeedScreenState();
}

class _ArtFeedScreenState extends ConsumerState<HomeScreen> {
  final ScrollController _scrollController = ScrollController();

  static const _ink = Color(0xFF292824);
  static const _muted = Color(0xFF82796F);
  static const _accent = Color(0xFF9A7653);

  bool shouldLoadMore = false;

  @override
  void initState() {
    super.initState();

    _scrollController.addListener(_onScroll);

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        ref.read(homeViewModelProvider.notifier).load();
      }
    });
  }

  void _onScroll() {
    // 1. Fast-fail if not attached or already processing a load
    if (!_scrollController.hasClients || shouldLoadMore) return;

    final position = _scrollController.position;

    // 2. Trigger ONLY when user is within 500px of the bottom
    if (position.extentAfter <= 500) {
      final state = ref.read(homeViewModelProvider);

      // 3. Do not trigger if loading, offline, error present, or no more data
      if (state.isLoading ||
          state.isRefreshing ||
          state.isLoadMore ||
          !state.hasMore ||
          state.error != null ||
          state.isOffline) {
        return;
      }

      shouldLoadMore = true;

      // 4. Use whenComplete to safely reset the flag regardless of success/error
      ref.read(homeViewModelProvider.notifier).loadMore().whenComplete(() {
        if (mounted) {
          shouldLoadMore = false;
        }
      });
    }
  }

  @override
  void dispose() {
    _scrollController
      ..removeListener(_onScroll)
      ..dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(homeViewModelProvider);

    final gridCrossAxisCount = MediaQuery.sizeOf(context).width >= 600 ? 3 : 2;

    return Scaffold(
      backgroundColor: AppColors.backgroundColor,
      body: SafeArea(
        bottom: false,
        child: Expanded(
          child: RefreshIndicator(
            color: _accent,
            onRefresh: () => ref
                .read(homeViewModelProvider.notifier)
                .load(refresh: true),
            child: CustomScrollView(
              controller: _scrollController,
              scrollCacheExtent: const ScrollCacheExtent.viewport(
                2,
              ), // lazy load 5 viewport to reduce memory usage
              physics: const AlwaysScrollableScrollPhysics(),
              slivers: [
                SliverToBoxAdapter(child: _buildHeader()),
                if (state.isLoading && state.artworks.isEmpty)
                  const SliverFillRemaining(
                    hasScrollBody: false,
                    child: Center(
                      child: CircularProgressIndicator(color: _accent),
                    ),
                  )
                else if (state.error != null && state.artworks.isEmpty)
                  SliverFillRemaining(
                    hasScrollBody: false,
                    child: _buildError(state.error!),
                  )
                else if (state.artworks.isEmpty)
                  const SliverFillRemaining(
                    hasScrollBody: false,
                    child: Center(child: Text('No artwork available')),
                  )
                else ...[
                  if (state.artworks.isNotEmpty)
                    SliverToBoxAdapter(
                      child: _buildFeatured(state.artworks.first),
                    ),
                  SliverToBoxAdapter(
                    child: Padding(
                      padding: EdgeInsets.fromLTRB(20.w, 24.h, 20.w, 14.h),
                      child: Row(
                        children: [
                          Text(
                            'Explore artworks',
                            style: TextStyle(
                              fontSize: 21.spMax,
                              fontWeight: FontWeight.w700,
                              color: _ink,
                            ),
                          ),
                          const Spacer(),
                          Text(
                            '${state.artworks.length} works',
                            style: TextStyle(
                              color: _muted,
                              fontSize: 12.spMax,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  SliverPadding(
                    padding: EdgeInsets.symmetric(horizontal: 16.w),
                    sliver: SliverGrid(
                      delegate: SliverChildBuilderDelegate((
                        context,
                        index,
                      ) {
                        final artwork = state.artworks[index];
        
                        return _ArtworkCard(
                          artwork: artwork,
                          index: index,
                          onTap: () {
                            ref.read(homeViewModelProvider.notifier).selectArtwork(artwork);
                            widget.onArtworkTap?.call(artwork);
                          },
                        );
                      }, childCount: state.artworks.length),
                      gridDelegate:
                          SliverGridDelegateWithFixedCrossAxisCount(
                            crossAxisCount: gridCrossAxisCount,
                            crossAxisSpacing: 14.w,
                            mainAxisSpacing: 18.h,
                            childAspectRatio: 10 / 16,
                          ),
                    ),
                  ),
                  SliverPadding(
                    padding: const EdgeInsets.only(bottom: 100),
                    sliver: SliverToBoxAdapter(
                      child: _buildPaginationFooter(state),
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Padding(
      padding: EdgeInsets.fromLTRB(20.w, 20.h, 20.w, 12.h),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'ART JOURNAL',
                  style: TextStyle(
                    color: _accent,
                    fontSize: 24.spMax,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 2.5,
                  ),
                ),
                SizedBox(height: 7.h),
                Text(
                  'Find your inspiration.',
                  style: TextStyle(
                    color: _ink,
                    fontSize: 16.spMax,
                    fontWeight: FontWeight.w700,
                    letterSpacing: -0.7,
                  ),
                ),
                SizedBox(height: 5.h),
                Text(
                  'Discover beautiful photography from around the world.',
                  style: TextStyle(color: _muted, fontSize: 12.spMax),
                ),
              ],
            ),
          ),
          Container(
            width: 44.w,
            height: 44.w,
            decoration: const BoxDecoration(
              color: Color(0xFFE8DFD1),
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.palette_outlined, color: _ink),
          ),
        ],
      ),
    );
  }

  Widget _buildFeatured(ArtworkModel artwork) {
    return Padding(
      padding: EdgeInsets.fromLTRB(16.w, 12.h, 16.w, 0),
      child: GestureDetector(
        onTap: () => widget.onArtworkTap?.call(artwork),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(20.r),
          child: Stack(
            children: [
              CachedNetworkImage(
                imageUrl: artwork.downloadUrl ?? '',
                width: double.infinity,
                height: 240.h,
                fit: BoxFit.cover,
                placeholder: (_, __) =>
                    Container(height: 240.h, color: const Color(0xFFE7DED1)),
                errorWidget: (_, __, ___) => Container(
                  height: 240.h,
                  color: const Color(0xFFE7DED1),
                  child: const Icon(Icons.broken_image_outlined),
                ),
              ),
              Positioned.fill(
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [
                        Colors.transparent,
                        Colors.black.withValues(alpha: 0.72),
                      ],
                      stops: const [0.35, 1],
                    ),
                  ),
                ),
              ),
              Positioned(
                left: 18.w,
                right: 18.w,
                bottom: 18.h,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      "TODAY'S DISCOVERY",
                      style: TextStyle(
                        color: Colors.white70,
                        fontSize: 10,
                        letterSpacing: 2,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    SizedBox(height: 6.h),
                    Text(
                      'Artwork #${artwork.id}',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 23.spMax,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    SizedBox(height: 4.h),
                    Text(
                      'Photograph by ${artwork.author}',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: Colors.white70,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildError(String message) {
    return Center(
      child: Padding(
        padding: EdgeInsets.all(24.w),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.cloud_off_outlined, size: 48, color: _muted),
            SizedBox(height: 12.h),
            Text(
              message,
              textAlign: TextAlign.center,
              style: const TextStyle(color: _ink),
            ),
            SizedBox(height: 16.h),
            FilledButton(
              onPressed: () => ref.read(homeViewModelProvider.notifier).load(),
              style: FilledButton.styleFrom(backgroundColor: _ink),
              child: const Text('Try again'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPaginationFooter(HomeState state) {
    if (state.isLoadMore) {
      return Padding(
        padding: EdgeInsets.all(20.h),
        child: const Center(child: CircularProgressIndicator(color: _accent)),
      );
    }

    if (state.error != null && state.artworks.isNotEmpty) {
      return Center(
        child: Container(
          height: 80.h,
          child: TextButton(
            onPressed: () =>
                ref.read(homeViewModelProvider.notifier).loadMore(),
            child: const Text('Could not load more · Retry'),
          ),
        ),
      );
    }

    if (!state.hasMore) {
      return Padding(
        padding: EdgeInsets.all(24.h),
        child: const Center(
          child: Text(
            "You've reached the end for now.",
            style: TextStyle(color: _muted),
          ),
        ),
      );
    }

    return SizedBox(height: 24.h);
  }
}

class _ArtworkCard extends ConsumerWidget {
  const _ArtworkCard({required this.artwork, required this.onTap, required this.index});

  final ArtworkModel artwork;
  final VoidCallback onTap;
  final int index;

  static const _ink = Color(0xFF292824);
  static const _muted = Color(0xFF82796F);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final screenHeight = MediaQuery.sizeOf(context).height;
    final vm = ref.read(homeViewModelProvider.notifier);
    final isSelected = vm.getSelectedArtworkIndex == index;
    return RepaintBoundary(
      child: GestureDetector(
        onTap: onTap,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: Hero(
                tag: 'artwork-${artwork.id}-$index' + (!isSelected ? 'not-selected' : ''),
                child: CachedNetworkImage(
                  imageUrl: artwork.downloadUrl ?? '',
                  // width: double.infinity,
                  memCacheHeight: screenHeight.toInt(),
                  // memCacheWidth: screenWidth.toInt(),
                  fit: BoxFit.cover,
                  placeholder: (_, __) =>
                      Container(color: const Color(0xFFE7DED1)),
                  errorWidget: (_, __, ___) => Container(
                    color: const Color(0xFFE7DED1),
                    child: const Center(
                      child: Icon(Icons.broken_image_outlined),
                    ),
                  ),
                ),
              ),
            ),
            SizedBox(height: 9.h),
            Text(
              'Artwork #${artwork.id}',
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                color: _ink,
                fontWeight: FontWeight.w700,
                fontSize: 13.spMax,
              ),
            ),
            SizedBox(height: 3.h),
            Text(
              artwork.author ?? 'Unknown',
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(color: _muted, fontSize: 11.spMax),
            ),
          ],
        ),
      ),
    );
  }
}
