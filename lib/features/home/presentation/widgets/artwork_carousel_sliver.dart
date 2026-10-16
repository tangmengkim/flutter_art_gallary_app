import 'package:art_gallary/features/home/data/models/artwork_model.dart';
import 'package:art_gallary/features/home/presentation/view_models/home_vm.dart';
import 'package:art_gallary/features/home/presentation/widgets/fullscreen_image_viewer.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';


class ArtworkCarouselSliver extends ConsumerWidget {
  const ArtworkCarouselSliver({
    super.key,
    required this.pageController,
    required this.onPageChanged,
  });

  final PageController pageController;
  final void Function(int index, int total) onPageChanged;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final artworks = ref.watch(
      homeViewModelProvider.select((s) => s.artworks),
    );

    if (artworks.isEmpty) {
      return const SizedBox.shrink();
    }

    return PageView.builder(
      controller: pageController,
      allowImplicitScrolling: true,
      itemCount: artworks.length,
      onPageChanged: (index) {
        onPageChanged(index, artworks.length);
      },
      itemBuilder: (context, index) {
        final artwork = artworks[index];
          debugPrint('Building artwork page: $index');


        return _ArtworkCarouselItem(
          key: ValueKey(artwork.id),
          controller: pageController,
          artwork: artwork,
          index: index,
          onFullscreen: () => showFullscreenImageViewer(
            context,
            artwork,
            'artwork-${artwork.id}-$index',
          ),
        );
      },
    );
  }

  
}


class _ArtworkCarouselItem extends ConsumerWidget {
  const _ArtworkCarouselItem({
    super.key,
    required this.controller,
    required this.artwork,
    required this.index,
    required this.onFullscreen,
  });

  final PageController controller;
  final ArtworkModel artwork;
  final int index;
  final VoidCallback onFullscreen;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final selectedIndex = ref.watch(
      homeViewModelProvider.select(
        (state) => state.selectedArtworkIndex,
      ),
    );

    return AnimatedBuilder(
      animation: controller,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(2, 12, 2, 20),
        child: ArtworkImageCard(
          artwork: artwork,
          index: index,
          onFullscreen: onFullscreen,
          isSelected: selectedIndex == index
        ),
      ),
      builder: (context, child) {
        var currentPage = selectedIndex.toDouble();

        if (controller.hasClients &&
            controller.position.hasContentDimensions) {
          currentPage =
              controller.page ?? selectedIndex.toDouble();
        }

        final distance = (currentPage - index).abs();

        final scale =
            (1.0 - distance * 0.055).clamp(0.88, 1.0);

        final rotation = (currentPage - index) * 0.018;

        return Transform(
          alignment: Alignment.center,
          transform: Matrix4.identity()
            ..setEntry(3, 2, 0.001)
            ..rotateY(rotation)
            ..scale(scale),
          child: child,
        );
      },
    );
  }
}



class ArtworkImageCard extends StatelessWidget {
  const ArtworkImageCard({
    super.key,
    required this.artwork,
    required this.index,
    required this.onFullscreen,
    required this.isSelected,
  });

  final ArtworkModel artwork;
  final int index;
  final VoidCallback onFullscreen;
  final bool isSelected;

  @override
  Widget build(BuildContext context) {
    final url = artwork.downloadUrl ?? artwork.url ?? '';
    final screenHeight = (MediaQuery.sizeOf(context,).height * 0.7);

    return Stack(
      fit: StackFit.expand,
      children: [
        if (url.isNotEmpty)
          Hero(
            tag: 'artwork-${artwork.id}-$index${isSelected ? '' : '-not-selected'}',
            child: GestureDetector(
              onTap: onFullscreen,
              child: Container(
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(34),
                  boxShadow: const [
                    BoxShadow(
                      color: Colors.black26,
                      offset: Offset(0, 4),
                      spreadRadius: 0,
                      blurRadius: 4,
                    ),
                  ],
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(34),
                  child: CachedNetworkImage(
                    imageUrl: url,
                    fit: BoxFit.cover,
                    memCacheHeight: screenHeight.toInt(),
                    placeholder: (context, _) => Image(
                      image: CachedNetworkImageProvider(
                        url,
                        maxHeight: screenHeight.toInt(),
                      ),
                      fit: BoxFit.cover,
                      errorBuilder: (_, __, ___) => const Center(
                        child: CircularProgressIndicator(
                          color: Color(0xFFC5A36B),
                        ),
                      ),
                    ),
                    errorWidget: (_, __, ___) => const Center(
                      child: Icon(
                        Icons.broken_image_outlined,
                        color: Colors.white38,
                        size: 52,
                      ),
                    ),
                  ),
                ),
              ),
            ),
          )
        else
          const Center(
            child: Icon(Icons.image_outlined, color: Colors.white38, size: 52),
          ),
        Positioned(
          right: 18,
          bottom: 18,
          child: GestureDetector(
            onTap: onFullscreen,
            child: Container(
              padding: EdgeInsets.all(5),
              decoration: BoxDecoration(
                color: Colors.white24,
                borderRadius: BorderRadius.circular(50)
              ),
              child: const Icon(
              Icons.fullscreen, color: Colors.white, size: 30),
            ),
          ),
        ),
      ],
    );
  }
}