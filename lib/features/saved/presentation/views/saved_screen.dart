import 'dart:io';

import 'package:art_gallary/core/router/router.dart';
import 'package:art_gallary/features/home/data/models/artwork_model.dart';
import 'package:art_gallary/features/saved/presentation/view_models/saved_vm.dart';
import 'package:art_gallary/shared/custom_toast.dart';
import 'package:art_gallary/theme/app_colors.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:go_router/go_router.dart';

class SavedScreen extends ConsumerWidget {
  const SavedScreen({super.key});

  static const _ink = Color(0xFF292824);
  static const _muted = Color(0xFF82796F);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final savedArtworks = ref.watch(
      savedViewModelProvider.select((s) => s.savedArtworks),
    );
    final isLoading = ref.watch(
      savedViewModelProvider.select((s) => s.isLoading),
    );

    final viewModel = ref.read(savedViewModelProvider.notifier);
    final gridCrossAxisCount = MediaQuery.sizeOf(context).width >= 600 ? 3 : 2;

    return Scaffold(
      body: CustomScrollView(
        slivers: [
          SliverAppBar(
            pinned: false,
            title: _buildHeader(savedArtworks.length),
          ),
          SliverFillRemaining(
            child: Column(
              children: [
                Expanded(
                  child: isLoading
                      ? const Center(
                          child: CircularProgressIndicator(
                            color: AppColors.secondary,
                          ),
                        )
                      : savedArtworks.isEmpty
                      ? _buildEmptyState()
                      : GridView.builder(
                          padding: EdgeInsets.fromLTRB(16.w, 8.h, 16.w, 100.h),
                          itemCount: savedArtworks.length,
                          cacheExtent: 500,
                          addAutomaticKeepAlives: true,
                          addRepaintBoundaries: true,
                          gridDelegate:
                              SliverGridDelegateWithFixedCrossAxisCount(
                                crossAxisCount: gridCrossAxisCount,
                                crossAxisSpacing: 14.w,
                                mainAxisSpacing: 18.h,
                                childAspectRatio: 10 / 16,
                              ),
                          itemBuilder: (context, index) {
                            final artwork = savedArtworks[index];

                            return _SavedArtworkCard(
                              key: ValueKey(artwork.id ?? index),
                              artwork: artwork,
                              index: index,
                              onTap: () =>
                                  _onArtworkTap(context, artwork, index),
                              onRemove: () =>
                                  _onArtworkRemove(context, viewModel, artwork),
                            );
                          },
                        ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  void _onArtworkTap(BuildContext context, ArtworkModel artwork, int index) {
    context.push(
      '$pageSaved/$pageArtDetail',
      extra: {'artwork': artwork, 'index': index},
    );
  }

  Future<void> _onArtworkRemove(
    BuildContext context,
    SavedViewModel viewModel,
    ArtworkModel artwork,
  ) async {
    final message = await viewModel.toggleSave(artwork);
    if (context.mounted) {
      CustomToast.success(context, message);
    }
  }

  Widget _buildHeader(int count) {
    return Padding(
      padding: EdgeInsets.fromLTRB(20.w, 20.h, 20.w, 12.h),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'COLLECTION',
                style: TextStyle(
                  color: AppColors.secondary,
                  fontSize: 12.spMax,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 2.5,
                ),
              ),
              SizedBox(height: 4.h),
              Text(
                'Saved Artworks',
                style: TextStyle(
                  color: _ink,
                  fontSize: 24.spMax,
                  fontWeight: FontWeight.w700,
                  letterSpacing: -0.5,
                ),
              ),
            ],
          ),
          const Spacer(),
          if (count > 0)
            Container(
              padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 6.h),
              decoration: BoxDecoration(
                color: const Color(0xFFE8DFD1),
                borderRadius: BorderRadius.circular(20.r),
              ),
              child: Text(
                '$count works',
                style: TextStyle(
                  color: AppColors.primary,
                  fontSize: 12.spMax,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Padding(
        padding: EdgeInsets.symmetric(horizontal: 32.w),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 72.w,
              height: 72.w,
              decoration: const BoxDecoration(
                color: Color(0xFFE8DFD1),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.bookmark_outline_rounded,
                color: AppColors.primary,
                size: 32,
              ),
            ),
            SizedBox(height: 20.h),
            Text(
              'No saved artworks yet',
              style: TextStyle(
                color: _ink,
                fontSize: 18.spMax,
                fontWeight: FontWeight.w700,
              ),
            ),
            SizedBox(height: 8.h),
            Text(
              'Bookmark artworks in the journal to curate your personal collection.',
              textAlign: TextAlign.center,
              style: TextStyle(color: _muted, fontSize: 13.spMax, height: 1.5),
            ),
          ],
        ),
      ),
    );
  }
}

class _SavedArtworkCard extends StatefulWidget {
  const _SavedArtworkCard({
    super.key,
    required this.artwork,
    required this.index,
    required this.onTap,
    required this.onRemove,
  });

  final ArtworkModel artwork;
  final int index;
  final VoidCallback onTap;
  final VoidCallback onRemove;

  @override
  State<_SavedArtworkCard> createState() => _SavedArtworkCardState();
}

class _SavedArtworkCardState extends State<_SavedArtworkCard> {
  final LayerLink _layerLink = LayerLink();

  static const _ink = Color(0xFF292824);
  static const _muted = Color(0xFF82796F);

  @override
  Widget build(BuildContext context) {
    final imageUrl = widget.artwork.downloadUrl ?? widget.artwork.url ?? '';
    final localUrl = widget.artwork.localUrl;
    final hasLocalFile = localUrl != null && localUrl.isNotEmpty;
    final author = widget.artwork.author?.trim();
    final artist = (author == null || author.isEmpty) ? 'Unknown' : author;
    final screenHeight = MediaQuery.sizeOf(context).height.toInt();

    return RepaintBoundary(
      child: GestureDetector(
        onTap: widget.onTap,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: Hero(
                tag: 'saved-artwork-${widget.artwork.id}-${widget.index}',
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(20),
                  child: CachedNetworkImage(
                    imageUrl: imageUrl,
                    fit: BoxFit.cover,
                    memCacheHeight: screenHeight,
                    placeholder: (_, __) =>
                        Container(color: const Color(0xFFE7DED1)),
                    errorWidget: (_, __, ___) => Image.file(
                      File(localUrl ?? ''),
                      fit: BoxFit.cover,
                      cacheHeight: screenHeight,
                      frameBuilder:
                          (context, child, frame, wasSynchronouslyLoaded) {
                            if (wasSynchronouslyLoaded) return child;
                            return AnimatedOpacity(
                              opacity: frame == null ? 0.0 : 1.0,
                              duration: const Duration(milliseconds: 280),
                              curve: Curves.easeOut,
                              child: child,
                            );
                          },
                      errorBuilder: (_, __, ___) => _buildErrorPlaceholder(),
                    ),
                  ),
                ),
              ),
            ),
            SizedBox(height: 9.h),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Artwork #${widget.artwork.id}',
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
                      artist,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(color: _muted, fontSize: 11.spMax),
                    ),
                  ],
                ),
                GestureDetector(
                  onTap: widget.onRemove,
                  child: Container(
                    padding: EdgeInsets.all(4),
                    decoration: BoxDecoration(
                      color: AppColors.surface.withValues(alpha: 0.5),
                      borderRadius: BorderRadius.circular(50),
                    ),
                    child: const Icon(
                      Icons.bookmark_rounded,
                      color: AppColors.secondary,
                      size: 28,
                    ),
                    // child: IconButton(
                    //   padding: EdgeInsets.zero,
                    //   iconSize: 30,
                    //   tooltip: 'Remove from saved',
                    // icon: const Icon(
                    //   Icons.bookmark_rounded,
                    //   color: AppColors.secondary,
                    // ),
                    //   onPressed: widget.onRemove,
                    // ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildErrorPlaceholder() {
    return Container(
      color: const Color(0xFFE7DED1),
      child: const Center(
        child: Icon(Icons.broken_image_outlined, color: _muted),
      ),
    );
  }
}
