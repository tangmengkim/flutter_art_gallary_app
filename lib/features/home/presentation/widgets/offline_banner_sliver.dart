import 'package:art_gallary/features/home/presentation/view_models/home_vm.dart';
import 'package:art_gallary/theme/app_colors.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

class OfflineBannerSliver extends ConsumerStatefulWidget {
  const OfflineBannerSliver({super.key});

  @override
  ConsumerState<OfflineBannerSliver> createState() =>
      _OfflineBannerSliverState();
}

class _OfflineBannerSliverState
    extends ConsumerState<OfflineBannerSliver>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double> _heightFactor;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 300),
    );
    _heightFactor = CurvedAnimation(
      parent: _controller,
      curve: Curves.easeInOutCubic,
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isOffline = ref.watch(
      homeViewModelProvider.select((s) => s.isOffline),
    );

    if (isOffline) {
      _controller.forward();
    } else {
      _controller.reverse();
    }

    return AnimatedBuilder(
      animation: _heightFactor,
      builder: (context, child) {
        final currentHeight = 42.h * _heightFactor.value;

        if (currentHeight <= 0.0) {
          return const SliverToBoxAdapter(child: SizedBox.shrink());
        }

        return SliverPersistentHeader(
          pinned: true,
          delegate: _DynamicOfflineBannerDelegate(
            height: currentHeight,
            opacity: _heightFactor.value,
          ),
        );
      },
    );
  }
}

class _DynamicOfflineBannerDelegate extends SliverPersistentHeaderDelegate {
  _DynamicOfflineBannerDelegate({
    required this.height,
    required this.opacity,
  });

  final double height;
  final double opacity;

  @override
  Widget build(
    BuildContext context,
    double shrinkOffset,
    bool overlapsContent,
  ) {
    return Opacity(
      opacity: opacity.clamp(0.0, 1.0),
      child: SizedBox.expand(
        child: Container(
          decoration: const BoxDecoration(
            color: Color(0xFFE5D8C6),
            border: Border(
              bottom: BorderSide(color: Color(0xFFD4C3AE), width: 0.8),
            ),
          ),
          padding: EdgeInsets.symmetric(horizontal: 16.w),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(5),
                decoration: BoxDecoration(
                  color: AppColors.secondary.withValues(alpha: 0.15),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.wifi_off_rounded,
                  size: 14,
                  color: AppColors.primary,
                ),
              ),
              SizedBox(width: 10.w),
              Expanded(
                child: Text(
                  'Offline Mode · Showing locally saved artwork',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: 12.spMax,
                    fontWeight: FontWeight.w600,
                    color: AppColors.primary,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  double get maxExtent => height;

  @override
  double get minExtent => height;

  @override
  bool shouldRebuild(covariant _DynamicOfflineBannerDelegate oldDelegate) {
    return oldDelegate.height != height || oldDelegate.opacity != opacity;
  }
}