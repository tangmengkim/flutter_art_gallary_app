import 'package:art_gallary/features/home/data/models/artwork_model.dart';
import 'package:art_gallary/features/home/presentation/view_models/home_vm.dart';
import 'package:art_gallary/features/home/presentation/widgets/artwork_carousel_sliver.dart';
import 'package:art_gallary/features/home/presentation/widgets/artwork_info_container.dart';
import 'package:art_gallary/features/home/presentation/widgets/offline_banner_sliver.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

class ArtworkDetailScreen extends ConsumerStatefulWidget {
  const ArtworkDetailScreen({super.key});

  @override
  ConsumerState<ArtworkDetailScreen> createState() =>
      _ArtworkDetailScreenState();
}

class _ArtworkDetailScreenState extends ConsumerState<ArtworkDetailScreen> {
  late final PageController _pageController;
  late int _currentIndex;

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

    _pageController = PageController(
      viewportFraction: 0.88,
      initialPage: _currentIndex,
    );

    if (state.artworks.isEmpty) {
      Future.microtask(() {
        if (mounted) ref.read(homeViewModelProvider.notifier).load();
      });
    } else {
      Future.microtask(() {
        if (mounted) {
          _prefetchCurrentDetail(_currentIndex, state.artworks);
        }
      });
    }
  }

  void _onPageChanged(int index, int total) {
    _currentIndex = index;
    final vm = ref.read(homeViewModelProvider.notifier);
    final artworks = ref.read(homeViewModelProvider).artworks;

    if (index >= 0 && index < artworks.length) {
      vm.selectArtwork(artworks[index]);
      _prefetchCurrentDetail(index, artworks);
    }

    if (index >= total - 3) {
      ref.read(homeViewModelProvider.notifier).loadMore();
    }
  }

  void _prefetchCurrentDetail(int index, List<ArtworkModel> artworks) {
    if (index >= 0 && index < artworks.length) {
      final artworkId = artworks[index].id;
      if (artworkId != null) {
        ref.read(homeViewModelProvider.notifier).fetchArtworkDetail(artworkId);
      }
    }
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final hasArtworks = ref.watch(
      homeViewModelProvider.select((s) => s.artworks.isNotEmpty),
    );

    if (!hasArtworks) {
      return const _EmptyStateView(accentColor: _accent);
    }

    return Scaffold(
      body: CustomScrollView(
        physics: const BouncingScrollPhysics(),
        slivers: [
          SliverAppBar(
            pinned: true,
            expandedHeight: 72,
            toolbarHeight: 72,
            title: Text(
              'Artwork Detail',
              style: TextStyle(fontSize: 21.spMax, fontWeight: FontWeight.w600),
            ),
            centerTitle: true,
            actions: [
              IconButton(
                icon: const Icon(Icons.settings_outlined),
                onPressed: () {},
              ),
            ],
          ),

          const OfflineBannerSliver(),

          SliverAppBar(
            pinned: true,
            collapsedHeight: 200,
            expandedHeight: 500,
            leading: const SizedBox.shrink(),
            flexibleSpace: ArtworkCarouselSliver(
              pageController: _pageController,
              onPageChanged: _onPageChanged,
            ),
          ),

          const SliverToBoxAdapter(
            child: ArtworkInfoContainer(),
          ),

        ],
      ),
    );
  }
}


class _EmptyStateView extends ConsumerWidget {
  const _EmptyStateView({required this.accentColor});

  final Color accentColor;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isLoading = ref.watch(
      homeViewModelProvider.select((s) => s.isLoading),
    );
    final error = ref.watch(homeViewModelProvider.select((s) => s.error));

    return Scaffold(
      body: Center(
        child: isLoading
            ? CircularProgressIndicator(color: accentColor)
            : Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.image_not_supported_outlined, size: 48),
                  const SizedBox(height: 16),
                  Text(error ?? 'No artworks available'),
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
}