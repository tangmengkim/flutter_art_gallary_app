import 'dart:math' as math;

import 'package:art_gallary/features/home/data/models/artwork_model.dart';
import 'package:art_gallary/features/home/presentation/view_models/home_vm.dart';
import 'package:art_gallary/features/home/presentation/widgets/fullscreen_image_viewer.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class ArtworkDetailScreen extends ConsumerStatefulWidget {
  const ArtworkDetailScreen({super.key});

  @override
  ConsumerState<ArtworkDetailScreen> createState() =>
      _ArtworkDetailScreenState();
}

class _ArtworkDetailScreenState extends ConsumerState<ArtworkDetailScreen> {
  late final PageController _pageController;
  late int _currentIndex;
  late double _page;

  static const _background = Color(0xFF414141);
  static const _cardBackground = Color(0xFF252525);
  static const _accent = Color(0xFFC5A36B);

  @override
  void initState() {
    super.initState();

    final state = ref.read(homeViewModelProvider);
    final selectedIndex = state.selectedArtworkIndex;

    _currentIndex =
        (selectedIndex >= 0 && selectedIndex < state.artworks.length)
        ? selectedIndex
        : 0;
    _page = _currentIndex.toDouble();

    _pageController = PageController(
      viewportFraction: 0.82,
      initialPage: _currentIndex,
    )..addListener(_handlePageScroll);

    if (state.artworks.isEmpty) {
      Future.microtask(() {
        if (mounted) ref.read(homeViewModelProvider.notifier).load();
      });
    }
  }

  void _handlePageScroll() {
    if (!_pageController.hasClients) return;
    final page = _pageController.page ?? 0;
    if ((_page - page).abs() > 0.001 && mounted) {
      setState(() => _page = page);
    }
  }

  void _onPageChanged(int index, int total) {
    setState(() => _currentIndex = index);
    if (index >= total - 3) {
      ref.read(homeViewModelProvider.notifier).loadMore();
    }
  }

  @override
  void dispose() {
    _pageController
      ..removeListener(_handlePageScroll)
      ..dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(homeViewModelProvider);
    final artworks = state.artworks;

    if (artworks.isEmpty) {
      return Scaffold(
        backgroundColor: _background,
        body: Center(
          child: state.isLoading
              ? const CircularProgressIndicator(color: _accent)
              : Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(
                      Icons.image_not_supported_outlined,
                      color: Colors.white70,
                      size: 48,
                    ),
                    const SizedBox(height: 16),
                    Text(
                      state.error ?? 'No artworks available',
                      style: const TextStyle(color: Colors.white70),
                    ),
                    const SizedBox(height: 12),
                    OutlinedButton(
                      onPressed: () => ref
                          .read(homeViewModelProvider.notifier)
                          .load(refresh: true),
                      child: const Text('Try again'),
                    ),
                  ],
                ),
        ),
      );
    }

    final selectedIndex = _currentIndex.clamp(0, artworks.length - 1);
    final artwork = artworks[selectedIndex];

    return Scaffold(
      backgroundColor: _background,
      body: SafeArea(
        bottom: false,
        child: Column(
          children: [
            _buildHeader(),
            Expanded(
              flex: 6,
              child: PageView.builder(
                controller: _pageController,
                itemCount: artworks.length,
                onPageChanged: (index) =>
                    _onPageChanged(index, artworks.length),
                itemBuilder: (context, index) {
                  final item = artworks[index];
                  final distance = (_page - index).abs();
                  final scale = (1 - distance * 0.055).clamp(0.88, 1.0);
                  final rotation = (_page - index) * 0.018;

                  return Transform(
                    alignment: Alignment.center,
                    transform: Matrix4.identity()
                      ..setEntry(3, 2, 0.001)
                      ..rotateY(rotation)
                      ..scale(scale),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 5,
                        vertical: 12,
                      ),
                      child: _ArtworkImageCard(
                        artwork: item,
                        index: index,

                        selectedIndex: selectedIndex,
                        background: _cardBackground,
                        onFullscreen: () =>
                            _showFullscreen(context, item, index),
                      ),
                    ),
                  );
                },
              ),
            ),
            Expanded(
              flex: 4,
              child: AnimatedSwitcher(
                duration: const Duration(milliseconds: 300),
                switchInCurve: Curves.easeOutCubic,
                switchOutCurve: Curves.easeInCubic,
                child: SingleChildScrollView(
                  key: ValueKey(artwork.id ?? selectedIndex),
                  padding: const EdgeInsets.fromLTRB(28, 16, 28, 36),
                  child: _buildArtworkInfo(
                    artwork,
                    selectedIndex,
                    artworks.length,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 12, 20, 8),
      child: Row(
        children: [
          IconButton(
            icon: const Icon(Icons.arrow_back, color: Colors.white),
            onPressed: () => Navigator.of(context).pop(),
          ),
          const Spacer(),
          const Text(
            'Art of the Day',
            style: TextStyle(
              color: Colors.white,
              fontSize: 20,
              fontWeight: FontWeight.w600,
            ),
          ),
          const Spacer(),
          const SizedBox(width: 48),
        ],
      ),
    );
  }

  Widget _buildArtworkInfo(ArtworkModel artwork, int index, int total) {
    final author = artwork.author?.trim();
    final artist = (author == null || author.isEmpty)
        ? 'Unknown artist'
        : author;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'ARTWORK ${index + 1} OF$total',
          style: const TextStyle(
            color: Colors.white60,
            fontSize: 12,
            letterSpacing: 1.6,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          artist,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 28,
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }

  void _showFullscreen(BuildContext context, ArtworkModel artwork, int index) {
    final url = artwork.downloadUrl ?? artwork.url ?? '';
    if (url.isEmpty) return;

    Navigator.of(context).push(
      PageRouteBuilder<void>(
        opaque:
            false, // 💡 Crucial: lets previous screen show through as background fades
        barrierColor: Colors.transparent,
        pageBuilder: (_, __, ___) => FullscreenImageViewer(
          imageUrl: url,
          heroTag: 'artwork-${artwork.id}-$index',
        ),
      ),
    );
  }
}

class _ArtworkImageCard extends StatelessWidget {
  const _ArtworkImageCard({
    required this.artwork,
    required this.index,
    required this.selectedIndex,
    required this.background,
    required this.onFullscreen,
  });

  final ArtworkModel artwork;
  final int index;
  final int selectedIndex;
  final Color background;
  final VoidCallback onFullscreen;

  @override
  Widget build(BuildContext context) {
    final url = artwork.downloadUrl ?? artwork.url ?? '';
    final screenHeight = MediaQuery.of(context).size.height;

    return Stack(
      fit: StackFit.expand,
      children: [
        if (url.isNotEmpty)
          Hero(
            tag: 'artwork-${artwork.id}-$index',
            child: GestureDetector(
              onTap: () {
                if (index != selectedIndex) return;
                onFullscreen();
              },
              child: ClipRRect(
                borderRadius: BorderRadius.circular(34),
                child: CachedNetworkImage(
                  imageUrl: url,
                  fit: BoxFit.cover,
                  // 💡 1. High-res target height (900px) instead of screenHeight (2400px+)
                  memCacheHeight: screenHeight.toInt(),

                  // 💡 2. Reads the 350px thumbnail directly from RAM (0ms delay)
                  placeholder: (context, _) => Image(
                    image: CachedNetworkImageProvider(
                      url,
                      maxHeight: screenHeight
                          .toInt(), // Must match memCacheHeight used on HomeScreen
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
          )
        else
          const Center(
            child: Icon(Icons.image_outlined, color: Colors.white38, size: 52),
          ),
        Positioned(
          right: 18,
          bottom: 18,
          child: Material(
            color: Colors.white24,
            shape: const CircleBorder(),
            child: IconButton(
              onPressed: onFullscreen,
              icon: const Icon(Icons.fullscreen, color: Colors.white, size: 30),
            ),
          ),
        ),
      ],
    );
  }
}
