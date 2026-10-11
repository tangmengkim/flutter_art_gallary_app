import 'package:flutter/material.dart';

import '../../theme/app_colors.dart';

class CustomBottomNavBar extends StatefulWidget {
  final int selectedIndex;
  final ValueChanged<int> onItemTapped;

  const CustomBottomNavBar({
    super.key,
    required this.selectedIndex,
    required this.onItemTapped,
  });

  @override
  State<CustomBottomNavBar> createState() => _CustomBottomNavBarState();
}

class _CustomBottomNavBarState extends State<CustomBottomNavBar>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _animation;

  double _startLeft = 0.0;
  double _endLeft = 0.0;

  final double _capsuleWidth = 60.0;
  bool _isFirstRender = true;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 350), // Liquid transit speed
    );

    // Smooth elastic-like curve mimicking organic fluid tension
    _animation = CurvedAnimation(
      parent: _animationController,
      curve: Curves.fastOutSlowIn,
    );
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  @override
  void didUpdateWidget(covariant CustomBottomNavBar oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.selectedIndex != widget.selectedIndex) {
      _triggerLiquidAnimation(oldWidget.selectedIndex, widget.selectedIndex);
    }
  }

  void _triggerLiquidAnimation(int fromIndex, int toIndex) {
    final double totalWidth = MediaQuery.of(context).size.width;
    final double zoneWidth = totalWidth / 3;
    final double centerOffset = (zoneWidth - _capsuleWidth) / 2;

    // Calculate layout pixel positions dynamically
    _startLeft = (fromIndex * zoneWidth) + centerOffset;
    _endLeft = (toIndex * zoneWidth) + centerOffset;

    _animationController.forward(from: 0.0);
  }

  @override
  Widget build(BuildContext context) {
    // Standard initialization safe-check for initial layout positions
    if (_isFirstRender) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        final double totalWidth = MediaQuery.of(context).size.width;
        final double zoneWidth = totalWidth / 3;
        final double centerOffset = (zoneWidth - _capsuleWidth) / 2;
        setState(() {
          _startLeft = (widget.selectedIndex * zoneWidth) + centerOffset;
          _endLeft = _startLeft;
          _isFirstRender = false;
        });
      });
    }

    return Container(
      height: 91.5,
      decoration: const BoxDecoration(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        boxShadow: [
          BoxShadow(
            color: Colors.black12,
            blurRadius: 16,
            offset: Offset(0, -4),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
        child: Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [AppColors.backgroundColor, Color(0xffEFEBE2)],
            ),
          ),
          padding: const EdgeInsets.only(top: 12, bottom: 16),
          child: Column(
            children: [
              // Visual handle top line
              // Container(
              //   width: 36,
              //   height: 4,
              //   decoration: BoxDecoration(
              //     color: AppColors.divider,
              //     borderRadius: BorderRadius.circular(2),
              //   ),
              // ),
              // const Spacer(),
              SizedBox(
                height: 60,
                child: Stack(
                  children: [
                    // LIQUID GLASS HERO PILL EFFECT
                    AnimatedBuilder(
                      animation: _animation,
                      builder: (context, child) {
                        final t = _animation.value;

                        // 1. Compute smooth translation across the horizontal track line
                        final currentLeft =
                            _startLeft + (_endLeft - _startLeft) * t;

                        // 2. Liquid Stretch Formula: Math curve creates a bulge peak in the middle of the run (t = 0.5)
                        final stretchMultiplier =
                            (t * (1 - t) * 4); // Peak value is 1.0 at center
                        final travelDistance = (_endLeft - _startLeft).abs();

                        // Capsule stretches wider depending on how far it has to travel
                        final dynamicStretch =
                            (travelDistance * 0.35) * stretchMultiplier;
                        final computedWidth = _capsuleWidth + dynamicStretch;

                        // Adjust left margin slightly to offset backward/forward stretch changes organically
                        final correctedLeft = _endLeft > _startLeft
                            ? currentLeft
                            : currentLeft - dynamicStretch;

                        return Positioned(
                          left: correctedLeft,
                          // top: 0,
                          child: Container(
                            width: computedWidth,
                            height: 42,
                            decoration: BoxDecoration(
                              color: AppColors.surface.withOpacity(0.45),
                              borderRadius: BorderRadius.circular(20),
                            ),
                          ),
                        );
                      },
                    ),

                    // INTERACTION BUTTON LAYER
                    Row(
                      children: [
                        Expanded(
                          child: _NavItem(
                            index: 0,
                            selectedIndex: widget.selectedIndex,
                            activeIcon: Icons.home_rounded,
                            inactiveIcon: Icons.home_outlined,
                            label: "Home",
                            onTap: widget.onItemTapped,
                          ),
                        ),
                        Expanded(
                          child: _NavItem(
                            index: 1,
                            selectedIndex: widget.selectedIndex,
                            activeIcon: Icons.bookmark_rounded,
                            inactiveIcon: Icons.bookmark_border_rounded,
                            label: "Saved",
                            onTap: widget.onItemTapped,
                          ),
                        ),
                        Expanded(
                          child: _NavItem(
                            index: 2,
                            selectedIndex: widget.selectedIndex,
                            isProfile: true,
                            // profileImageUrl: 'https://unsplash.com',
                            label: "Profile",
                            onTap: widget.onItemTapped,
                          ),
                        ),
                      ],
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

class _NavItem extends StatelessWidget {
  final int index;
  final int selectedIndex;
  final IconData? activeIcon;
  final IconData? inactiveIcon;
  final String label;
  final ValueChanged<int> onTap;
  final bool isProfile;
  final String? profileImageUrl;

  const _NavItem({
    required this.index,
    required this.selectedIndex,
    this.activeIcon,
    this.inactiveIcon,
    required this.label,
    required this.onTap,
    this.isProfile = false,
    this.profileImageUrl,
  });

  @override
  Widget build(BuildContext context) {
    final bool isSelected = index == selectedIndex;

    return GestureDetector(
      onTap: () => onTap(index),
      behavior: HitTestBehavior.opaque,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          AnimatedScale(
            scale: isSelected ? 1.08 : 1.0,
            duration: const Duration(milliseconds: 250),
            curve: Curves.easeOutBack,
            child: Container(
              height: 42,
              alignment: Alignment.center,
              child: isProfile
                  ? _buildProfileIcon(isSelected)
                  : AnimatedSwitcher(
                      duration: const Duration(milliseconds: 180),
                      transitionBuilder: (child, animation) =>
                          FadeTransition(opacity: animation, child: child),
                      child: Icon(
                        isSelected ? activeIcon : inactiveIcon,
                        key: ValueKey<bool>(isSelected),
                        color: AppColors.primary,
                        size: 24,
                      ),
                    ),
            ),
          ),
          const SizedBox(height: 2),
          AnimatedDefaultTextStyle(
            duration: const Duration(milliseconds: 200),
            style: TextStyle(
              color: AppColors.primary,
              fontSize: 11,
              fontWeight: isSelected ? FontWeight.w600 : FontWeight.w400,
            ),
            child: Text(label, textAlign: TextAlign.center),
          ),
        ],
      ),
    );
  }

  Widget _buildProfileIcon(bool isSelected) {
    const double size = 24.0;

    return AnimatedContainer(
      duration: const Duration(milliseconds: 250),
      curve: Curves.easeInOut,
      width: size,
      height: size,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        border: isSelected
            ? Border.all(color: AppColors.primary, width: 1.5)
            : Border.all(color: AppColors.surface, width: 1.5),
      ),
      child: CircleAvatar(
        radius: 11,
        backgroundColor: AppColors.surface,
        backgroundImage: profileImageUrl != null && profileImageUrl!.isNotEmpty
            ? NetworkImage(profileImageUrl!)
            : null,
        child: (profileImageUrl == null || profileImageUrl!.isEmpty)
            ? Icon(Icons.person_rounded, size: 16, color: AppColors.primary)
            : null,
      ),
    );
  }
}
