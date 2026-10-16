import 'package:art_gallary/features/home/data/models/artwork_model.dart';
import 'package:art_gallary/features/home/presentation/view_models/home_vm.dart';
import 'package:art_gallary/features/saved/presentation/view_models/saved_vm.dart';
import 'package:art_gallary/shared/custom_toast.dart';
import 'package:art_gallary/theme/app_colors.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class ArtworkInfoContainer extends ConsumerWidget {
  const ArtworkInfoContainer({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final data = ref.watch(
      homeViewModelProvider.select((state) {
        final index = state.selectedArtworkIndex;

        if (index < 0 || index >= state.artworks.length) {
          return null;
        }

        final artwork = state.artworks[index];

        return (
          artwork: artwork,
          detail: artwork.id == null ? null : state.artworkDetails[artwork.id],
          index: index,
          total: state.artworks.length,
        );
      }),
    );

    if (data == null) {
      return const SizedBox.shrink();
    }

    final artwork = data.artwork;
    final detail = data.detail;
    final index = data.index;
    final total = data.total;

    // Use detail values when available, otherwise use list data.
    final artist = detail?.author ?? artwork.author ?? '';
    final width = detail?.width ?? artwork.width;
    final height = detail?.height ?? artwork.height;

    final hasDimensions = width != null && height != null && height > 0;

    final aspectRatio = hasDimensions ? width / height : null;


    return Padding(
      key: ValueKey(artwork.id),
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 56),
      child: Column(
        children: [
          ArtworkDetailHeaderSection(
            artist: artist,
            index: index,
            total: total,
            artwork: artwork,
          ),
          ArtworkDetailDescriptionSection(artist: artist),
          ArtworkDetailImageInfoSection(
            artwork: artwork,
            artist: artist,
            width: width,
            height: height,
            aspectRatio: aspectRatio,
          ),
          _FooterIndexTag(index: index, total: total),
        ],
      ),
    );
  }
}



// HEADER SECTION

class ArtworkDetailHeaderSection extends StatelessWidget {
  const ArtworkDetailHeaderSection({
    super.key, 
    required this.artist,
    required this.index,
    this.total,
    required this.artwork,
  });

  final String artist;
  final int index;
  final int? total;
  final ArtworkModel artwork;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (total != null) ...[
                Row(
                  children: [
                    Container(width: 24, height: 1, color: AppColors.secondary),
                    const SizedBox(width: 8),
                    Text(
                      'ARTWORK ${index + 1} OF $total',
                      style: const TextStyle(
                        fontSize: 11,
                        letterSpacing: 2,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 14),
              ],
              Text(
                artist,
                style: const TextStyle(
                  fontSize: 30,
                  height: 1.15,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),

        ArtworkSaveButton(artwork: artwork),
      ],
    );
  }
}

// SAVE / DOWNLOAD BUTTON
class ArtworkSaveButton extends ConsumerWidget {
  const ArtworkSaveButton({super.key, required this.artwork});

  final ArtworkModel artwork;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isSaved = ref.watch(
      savedViewModelProvider.select(
        (s) => s.savedArtworks.any((item) => item.id == artwork.id),
      ),
    );

    return GestureDetector(
      onTap: () async {
        final savedVm = ref.read(savedViewModelProvider.notifier);

        if (isSaved) {
          final message = await savedVm.toggleSave(artwork);
          if (context.mounted) {
            CustomToast.success(context, message);
          }
        } else {
          final progressToast = CustomToast.showProgress(
            context,
            initialMessage: 'Saving Artwork...',
          );

          try {
            final message = await savedVm.toggleSave(artwork);
            progressToast.dismiss();

            if (context.mounted) {
              CustomToast.success(context, message);
            }
          } catch (e) {
            progressToast.dismiss();
            if (context.mounted) {
              CustomToast.error(
                context,
                'Failed to save artwork. Please try again.',
              );
            }
          }
        }
      },
      child: Container(
        padding: EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: isSaved
              ? AppColors.secondary.withValues(alpha: 0.22)
              : AppColors.secondary.withValues(alpha: 0.10),
          borderRadius: BorderRadius.circular(50),
        ),
        child: Icon(
          isSaved ? Icons.bookmark_rounded : Icons.bookmark_border_rounded,
          color: AppColors.secondary,
        ),
      ),
    );
  }
}

class ArtworkDetailDescriptionSection extends StatelessWidget {
  const ArtworkDetailDescriptionSection({super.key, required this.artist});

  final String artist;

  @override
  Widget build(BuildContext context) {
    return Text(
      'Discover this image by $artist. Explore its composition, '
      'details, and visual character. Take a moment to appreciate '
      'the elements that make this photograph unique.',
      style: const TextStyle(
        fontSize: 15,
        height: 1.8,
        color: AppColors.secondary,
      ),
    );
  }
}

// IMAGE DETAILS GRID & TILES

class ArtworkDetailImageInfoSection extends StatelessWidget {
  const ArtworkDetailImageInfoSection({
    super.key, 
    required this.artwork,
    required this.artist,
    required this.width,
    required this.height,
    required this.aspectRatio,
  });

  final ArtworkModel artwork;
  final String artist;
  final int? width;
  final int? height;
  final double? aspectRatio;

  @override
  Widget build(BuildContext context) {
    final hasDimensions = width != null && height != null && height! > 0;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Image details',
          style: TextStyle(fontSize: 21, fontWeight: FontWeight.w600),
        ),
        const SizedBox(height: 14),
        Row(
          children: [
            Expanded(
              child: _InfoCard(
                icon: Icons.photo_size_select_large_outlined,
                label: 'Resolution',
                value: hasDimensions ? '$width × $height' : 'Unavailable',
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _InfoCard(
                icon: Icons.crop_outlined,
                label: 'Aspect ratio',
                value: aspectRatio?.toStringAsFixed(2) ?? 'Unavailable',
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        _DetailTile(
          icon: Icons.person_outline,
          label: 'Photographer',
          value: artist,
        ),
        _DetailTile(
          icon: Icons.fingerprint,
          label: 'Image ID',
          value: artwork.id ?? 'Unknown',
        ),
      ],
    );
  }
}

// HELPER COMPONENTS
class _InfoCard extends StatelessWidget {
  const _InfoCard({
    required this.icon,
    required this.label,
    required this.value,
  });

  final IconData icon;
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.secondary.withValues(alpha: 0.055),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: AppColors.secondary.withValues(alpha: 0.08)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: AppColors.secondary, size: 23),
          const SizedBox(height: 16),
          Text(
            label,
            style: const TextStyle(fontSize: 12, color: AppColors.secondary),
          ),
          const SizedBox(height: 6),
          Text(
            value,
            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
          ),
        ],
      ),
    );
  }
}

class _DetailTile extends StatelessWidget {
  const _DetailTile({
    required this.icon,
    required this.label,
    required this.value,
  });

  final IconData icon;
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 12),
      child: Row(
        children: [
          Icon(icon, color: AppColors.secondary, size: 22),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: const TextStyle(
                    fontSize: 12,
                    color: AppColors.secondary,
                  ),
                ),
                const SizedBox(height: 5),
                Text(
                  value,
                  style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _FooterIndexTag extends StatelessWidget {
  const _FooterIndexTag({required this.index, required this.total});

  final int index;
  final int total;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Text(
        'COLLECTION  •  ${index + 1} / $total',
        style: const TextStyle(
          fontSize: 11,
          letterSpacing: 2,
          color: AppColors.secondary,
        ),
      ),
    );
  }
}
