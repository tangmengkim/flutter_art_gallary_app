import 'dart:math';

import 'package:art_gallary/core/constants/scroll_provider.dart';
import 'package:art_gallary/features/home/data/models/artwork_model.dart';
import 'package:art_gallary/features/home/presentation/view_models/home_vm.dart';
import 'package:art_gallary/features/home/presentation/widgets/offline_banner_sliver.dart';
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
  late ScrollController _scrollController;
  bool shouldLoadMore = false;

  @override
  void initState() {
    super.initState();
    _scrollController = ref.read(homeScrollControllerProvider);
    _scrollController.addListener(_onScroll);

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        ref.read(homeViewModelProvider.notifier).load();
      }
    });
  }

  void _onScroll() {
    if (!_scrollController.hasClients || shouldLoadMore) return;

    if (_scrollController.position.extentAfter <= 500) {
      final state = ref.read(homeViewModelProvider);

      if (state.isLoading ||
          state.isRefreshing ||
          state.isLoadMore ||
          !state.hasMore ||
          state.error != null ||
          state.isOffline) {
        return;
      }

      shouldLoadMore = true;
      ref.read(homeViewModelProvider.notifier).loadMore().whenComplete(() {
        if (mounted) shouldLoadMore = false;
      });
    }
  }

  @override
  void dispose() {
    _scrollController.removeListener(_onScroll);
    super.dispose();
  }

  void _handleArtworkTap(ArtworkModel artwork) {
    ref.read(homeViewModelProvider.notifier).selectArtwork(artwork);
    widget.onArtworkTap?.call(artwork);
  }

  // Keep as a const or static variable outside the build method

  @override
  Widget build(BuildContext context) {
    final gridCrossAxisCount = MediaQuery.sizeOf(context).width >= 600 ? 3 : 2;
  final gridDelegate = SliverGridDelegateWithFixedCrossAxisCount(
      crossAxisCount: gridCrossAxisCount,
      crossAxisSpacing: 14,
      mainAxisSpacing: 18,
      childAspectRatio: 10 / 16,
    );

    final activeScrollController = ref.watch(homeScrollControllerProvider);

    final artworks = ref.watch(homeViewModelProvider.select((s) => s.artworks));

    final isLoading = ref.watch(
      homeViewModelProvider.select((s) => s.isLoading),
    );

    final error = ref.watch(homeViewModelProvider.select((s) => s.error));

    return Scaffold(
      backgroundColor: AppColors.backgroundColor,
      body: Column(
        children: [
          Expanded(
            child: RefreshIndicator(
              edgeOffset: 195,
              displacement: 10,
              color: const Color(0xFF9A7653),
              onRefresh: () =>
                  ref.read(homeViewModelProvider.notifier).load(refresh: true),
              child: CustomScrollView(
                controller: activeScrollController,
                scrollCacheExtent: const ScrollCacheExtent.viewport(2),
                physics: const AlwaysScrollableScrollPhysics(),
                slivers: [
                  _HeaderSliverAppBar(scrollController: _scrollController),

                  // Offline banner watches state internally
                  const OfflineBannerSliver(),

                  if (isLoading && artworks.isEmpty)
                    const SliverFillRemaining(
                      hasScrollBody: false,
                      child: Center(
                        child: CircularProgressIndicator(
                          color: Color(0xFF9A7653),
                        ),
                      ),
                    )
                  else if (error != null && artworks.isEmpty)
                    SliverFillRemaining(
                      hasScrollBody: false,
                      child: _buildError(error),
                    )
                  else if (artworks.isEmpty)
                    const SliverFillRemaining(
                      hasScrollBody: false,
                      child: Center(child: Text('No artwork available')),
                    )
                  else ...[
                    SliverToBoxAdapter(
                      child: _buildFeatured(
                        artworks[Random().nextInt(artworks.length)],
                      ),
                    ),

                    // Count Header
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
                                color: const Color(0xFF292824),
                              ),
                            ),
                            const Spacer(),
                            Text(
                              '${artworks.length} works',
                              style: TextStyle(
                                color: const Color(0xFF82796F),
                                fontSize: 12.spMax,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),

                    // GRID BUILDER (Isolated from pagination state changes)
                    SliverPadding(
                      padding: EdgeInsets.symmetric(horizontal: 16.w),
                      sliver: SliverGrid.builder(
                        itemCount: artworks.length,
                        gridDelegate: gridDelegate,
                        addAutomaticKeepAlives: false,
                        addRepaintBoundaries: true,
                        addSemanticIndexes: false,
                        itemBuilder: (context, index) {
                          final artwork = artworks[index];
                          return _ArtworkCard(
                            key: ValueKey(artwork.id ?? index),
                            artwork: artwork,
                            index: index,
                            onTap: () => _handleArtworkTap(artwork),
                          );
                        },
                      ),
                    ),

                    // Pagination footer watches state internally
                    const SliverPadding(
                      padding: EdgeInsets.only(bottom: 100),
                      sliver: SliverToBoxAdapter(
                        child: _PaginationFooterWidget(),
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ),
        ],
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
            const Icon(
              Icons.cloud_off_outlined,
              size: 48,
              color: Color(0xFF82796F),
            ),
            SizedBox(height: 12.h),
            Text(
              message,
              textAlign: TextAlign.center,
              style: const TextStyle(color: Color(0xFF292824)),
            ),
            SizedBox(height: 16.h),
            FilledButton(
              onPressed: () => ref.read(homeViewModelProvider.notifier).load(),
              style: FilledButton.styleFrom(
                backgroundColor: const Color(0xFF292824),
              ),
              child: const Text('Try again'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFeatured(ArtworkModel artwork) {
    final cachedHeight = (MediaQuery.sizeOf(context,).height * 0.7).toInt();
    return Padding(
      padding: EdgeInsets.fromLTRB(16.w, 12.h, 16.w, 0),
      child: GestureDetector(
        onTap: () => _handleArtworkTap(artwork),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(20),
          child: Stack(
            children: [
              CachedNetworkImage(
                imageUrl: artwork.downloadUrl ?? '',
                width: double.infinity,
                height: 240.h,
                memCacheHeight: cachedHeight,
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
}

// Prevents parent & grid rebuilds
class _PaginationFooterWidget extends ConsumerWidget {
  const _PaginationFooterWidget();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isLoadMore = ref.watch(
      homeViewModelProvider.select((s) => s.isLoadMore),
    );
    final hasMore = ref.watch(homeViewModelProvider.select((s) => s.hasMore));
    final error = ref.watch(homeViewModelProvider.select((s) => s.error));
    final hasArtworks = ref.watch(
      homeViewModelProvider.select((s) => s.artworks.isNotEmpty),
    );

    if (isLoadMore) {
      return Padding(
        padding: EdgeInsets.all(20.h),
        child: const Center(
          child: CircularProgressIndicator(color: AppColors.secondary),
        ),
      );
    }

    if (error != null && hasArtworks) {
      return Center(
        child: SizedBox(
          height: 80.h,
          child: TextButton(
            onPressed: () =>
                ref.read(homeViewModelProvider.notifier).loadMore(),
            child: const Text('Could not load more · Retry'),
          ),
        ),
      );
    }

    if (!hasMore) {
      return Padding(
        padding: EdgeInsets.all(24.h),
        child: const Center(
          child: Text(
            "You've reached the end for now.",
            style: TextStyle(color: Color(0xFF82796F)),
          ),
        ),
      );
    }

    return SizedBox(height: 24.h);
  }
}

class _HeaderSliverAppBar extends StatelessWidget {
  final ScrollController scrollController;
  const _HeaderSliverAppBar({required this.scrollController});

  @override
  Widget build(BuildContext context) {
    return SliverAppBar(
      backgroundColor: AppColors.backgroundColor,
      surfaceTintColor: Colors.transparent,
      elevation: 11,
      scrolledUnderElevation: 0.5,
      pinned: true,
      expandedHeight: 150.spMax,
      automaticallyImplyLeading: false,
      titleSpacing: 20.w,
      title: GestureDetector(
        onTap: () {
          if (scrollController.hasClients) {
            scrollController.animateTo(
              0.0,
              duration: const Duration(milliseconds: 500),
              curve: Curves.easeInOut,
            );
          }
        },
        child: Text(
          'ART GALLERY',
          style: TextStyle(
            fontSize: 22.spMax,
            fontWeight: FontWeight.w800,
            letterSpacing: 2.2,
          ),
        ),
      ),
      flexibleSpace: LayoutBuilder(
        builder: (context, constraints) {
          final collapsed = constraints.maxHeight <= kToolbarHeight + 85.spMax;

          return FlexibleSpaceBar(
            collapseMode: CollapseMode.pin,
            background: Container(
              padding: EdgeInsets.fromLTRB(
                40.w,
                MediaQuery.paddingOf(context).top,
                20.w,
                12.h,
              ),
              decoration: BoxDecoration(
                color: AppColors.surface.withValues(alpha: 0.8),
                borderRadius: const BorderRadius.only(
                  bottomLeft: Radius.circular(20),
                  bottomRight: Radius.circular(20),
                ),
              ),
              child: AnimatedOpacity(
                duration: const Duration(milliseconds: 150),
                opacity: collapsed ? 0 : 1,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    Text(
                      'WELCOME TO ART GALLERY',
                      style: TextStyle(
                        color: const Color(0xFF82796F),
                        fontSize: 10.spMax,
                        fontWeight: FontWeight.w700,
                        letterSpacing: 2,
                      ),
                    ),
                    SizedBox(height: 6.h),
                    Text.rich(
                      TextSpan(
                        children: [
                          const TextSpan(text: 'Discover art.'),
                          TextSpan(
                            text: ' Find inspiration.',
                            style: TextStyle(
                              color: const Color(0xFF9A7653),
                              fontStyle: FontStyle.italic,
                              fontWeight: FontWeight.w500,
                              fontSize: 20.spMax,
                            ),
                          ),
                        ],
                      ),
                      style: TextStyle(
                        color: const Color(0xFF292824),
                        fontSize: 28.spMax,
                        height: 1.12,
                        fontWeight: FontWeight.w800,
                        letterSpacing: -0.8,
                      ),
                    ),
                    SizedBox(height: 5.h),
                    Text(
                      'Explore beautiful images and discover your next favorite.',
                      maxLines: 2,
                      style: TextStyle(
                        color: const Color(0xFF82796F),
                        fontSize: 13.spMax,
                        height: 1.5,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}

class _ArtworkCard extends ConsumerWidget {
  const _ArtworkCard({
    super.key,
    required this.artwork,
    required this.onTap,
    required this.index,
  });

  final ArtworkModel artwork;
  final VoidCallback onTap;
  final int index;

  static const _ink = Color(0xFF292824);
  static const _muted = Color(0xFF82796F);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final screenHeight = (MediaQuery.sizeOf(context,).height * 0.7);
    return GestureDetector(
      onTap: onTap,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: Hero(
              transitionOnUserGestures: true,
              tag: 'artwork-${artwork.id}-$index',
              child: Container(
                clipBehavior: Clip.antiAlias,
                decoration: const BoxDecoration(
                  borderRadius: BorderRadius.all(Radius.circular(20)),
                ),
                child: CachedNetworkImage(
                  imageUrl: artwork.downloadUrl ?? '',
                  memCacheHeight: screenHeight.toInt(),
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
          ),
          SizedBox(height: 9.h),
          Text(
            'Artwork By ${artwork.author ?? 'Unknown'}',
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
    );
  }
}
