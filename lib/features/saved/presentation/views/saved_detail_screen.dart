import 'dart:io';

import 'package:art_gallary/features/home/data/models/artwork_model.dart';
import 'package:art_gallary/features/home/presentation/widgets/artwork_info_container.dart';
import 'package:art_gallary/features/home/presentation/widgets/fullscreen_image_viewer.dart';
import 'package:art_gallary/theme/app_colors.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

class SavedDetailScreen extends ConsumerWidget {
  const SavedDetailScreen({super.key, required this.artwork, this.index = 0});

  final ArtworkModel? artwork;
  final int index;

  static const _cardBackground = Color(0xFF252525);
  static const _accent = Color(0xFFC5A36B);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    if (artwork == null) {
      return Scaffold(
        appBar: AppBar(
        ),
        body: const Center(
          child: Text('Artwork details not found', style: TextStyle()),
        ),
      );
    }

    final item = artwork!;

    final imageUrl = item.downloadUrl ?? item.url ?? '';
    final localUrl = item.localUrl;
    final hasLocalFile =
        localUrl != null && localUrl.isNotEmpty && File(localUrl).existsSync();

    final author = item.author?.trim();
    final artist = (author == null || author.isEmpty)
        ? 'Unknown artist'
        : author;

    final width = artwork?.width;
    final height = artwork?.height;

    final hasDimensions = width != null && height != null && height > 0;

    final aspectRatio = hasDimensions ? width / height : null;

    final screenHeight = MediaQuery.sizeOf(context,).height.toInt();

    return Scaffold(
      body: CustomScrollView(
        slivers: [
          SliverAppBar(
            pinned: true,
            centerTitle: true,
            elevation: 0.5,
            title: Text(
              'Saved Artwork',
              style: TextStyle(fontSize: 21.spMax, fontWeight: FontWeight.w600),
            ),
          ),
          SliverAppBar(
            pinned: true,
            collapsedHeight: 200,
            expandedHeight: 500,
            leading: const SizedBox.shrink(),
            flexibleSpace: Padding(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 16),
              child: Hero(
                tag: 'saved-artwork-${item.id}-$index',
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(20),
                  child: Container(
                    color: _cardBackground,
                    child: Stack(
                      fit: StackFit.expand,
                      children: [
                        GestureDetector(
                          onTap: () => showFullscreenImageViewer(context, item, 'saved-artwork-${artwork?.id}-$index',localUrl: localUrl),
                          child: hasLocalFile
                              ? Image.file(
                                  File(localUrl),
                                  fit: BoxFit.cover,
                                  errorBuilder: (_, __, ___) =>
                                      _buildErrorPlaceholder(),
                                )
                              : CachedNetworkImage(
                                  imageUrl: imageUrl,
                                  fit: BoxFit.cover,
                                  memCacheHeight: screenHeight,
                                  placeholder: (_, __) => const Center(
                                    child: CircularProgressIndicator(
                                      color: _accent,
                                    ),
                                  ),
                                  errorWidget: (_, __, ___) =>
                                      _buildErrorPlaceholder(),
                                ),
                        ),
                        // Fullscreen Action Button
                        Positioned(
                          right: 16.w,
                          bottom: 16.h,
                          child: Material(
                            color: Colors.black45,
                            shape: const CircleBorder(),
                            child: IconButton(
                              tooltip: 'View fullscreen',
                              onPressed: () =>
                                  showFullscreenImageViewer(context, item,  'saved-artwork-${artwork?.id}-$index',localUrl: localUrl),
                              icon: const Icon(
                                Icons.fullscreen,
                                color: Colors.white,
                                size: 28,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 56),
              child: Column(
                spacing: 14,
                children: [
                  ArtworkDetailHeaderSection(
                    artist: artist,
                    index: index,
                    artwork: artwork!,
                  ),
                  ArtworkDetailDescriptionSection(artist: artist),
                  ArtworkDetailImageInfoSection(
                    artwork: artwork!,
                    artist: artist,
                    width: width,
                    height: height,
                    aspectRatio: aspectRatio,
                  ),
                  
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildErrorPlaceholder() {
    return const Center(
      child: Icon(Icons.broken_image_outlined, color: Colors.white38, size: 52),
    );
  }

  
}
