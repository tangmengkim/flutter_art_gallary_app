import 'dart:io';

import 'package:art_gallary/features/home/data/models/artwork_model.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

class FullscreenImageViewer extends StatefulWidget {
  const FullscreenImageViewer({
    super.key,
    required this.imageUrl,
    required this.heroTag,
    this.localUrl,
  });

  final String imageUrl;
  final String heroTag;
  final String? localUrl;

  @override
  State<FullscreenImageViewer> createState() => _FullscreenImageViewerState();
}

class _FullscreenImageViewerState extends State<FullscreenImageViewer>
    with TickerProviderStateMixin {
  final TransformationController _transformationController =
      TransformationController();

  late AnimationController _resetAnimationController;
  late AnimationController _zoomAnimationController;
  Animation<Offset>? _resetOffsetAnimation;
  Animation<Matrix4>? _zoomAnimation;

  Offset _dragOffset = Offset.zero;
  bool _isDragging = false;
  bool _showControls = true;
  bool _isZoomedIn = false;

  @override
  void initState() {
    super.initState();

    // Controller for drag snap-back animation
    _resetAnimationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 200),
    )..addListener(() {
        if (_resetOffsetAnimation != null) {
          setState(() {
            _dragOffset = _resetOffsetAnimation!.value;
          });
        }
      });

    // Controller for double-tap smooth zoom
    _zoomAnimationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 250),
    )..addListener(() {
        if (_zoomAnimation != null) {
          _transformationController.value = _zoomAnimation!.value;
        }
      });

    _transformationController.addListener(_onTransformationChanged);
  }

  void _onTransformationChanged() {
    final scale = _transformationController.value.getMaxScaleOnAxis();
    final isZoomed = scale > 1.05;
    if (isZoomed != _isZoomedIn) {
      setState(() => _isZoomedIn = isZoomed);
    }
  }

  @override
  void dispose() {
    _transformationController.removeListener(_onTransformationChanged);
    _transformationController.dispose();
    _resetAnimationController.dispose();
    _zoomAnimationController.dispose();
    super.dispose();
  }

  // Smooth Double Tap Zoom
  void _handleDoubleTap(TapDownDetails details) {
    final Matrix4 endMatrix;

    if (_isZoomedIn) {
      // Reset back to original 1.0x scale
      endMatrix = Matrix4.identity();
    } else {
      const scale = 2.5;

      final renderBox = context.findRenderObject() as RenderBox?;
      if (renderBox == null) return;

      final viewportSize = renderBox.size;
      final tapPosition = renderBox.globalToLocal(details.globalPosition);

      final width = viewportSize.width;
      final height = viewportSize.height / 2.2;

      final targetTx = (width / 2) - (tapPosition.dx * scale);
      final targetTy = (height / 2) - (tapPosition.dy * scale);

      final clampedTx = targetTx.clamp(width * (1 - scale), 0.0);
      final clampedTy = targetTy.clamp(height * (1 - scale), 0.0);

      endMatrix = Matrix4.identity()
        ..translate(clampedTx, clampedTy)
        ..scale(scale);
    }

    _zoomAnimation = Matrix4Tween(
      begin: _transformationController.value,
      end: endMatrix,
    ).animate(
      CurvedAnimation(
        parent: _zoomAnimationController,
        curve: Curves.easeOutCubic,
      ),
    );

    _zoomAnimationController.forward(from: 0);
  }

  double get _backgroundOpacity {
    final dragDistance = _dragOffset.dy.abs();
    final opacity = 1.0 - (dragDistance / 220.0);
    return opacity.clamp(0.0, 1.0);
  }

  double get _imageScale {
    final dragDistance = _dragOffset.dy.abs();
    final scale = 1.0 - (dragDistance / 1000.0);
    return scale.clamp(0.75, 1.0);
  }

  @override
  Widget build(BuildContext context) {
    final localUrl = widget.localUrl;
    final hasLocalFile =
        localUrl != null && localUrl.isNotEmpty && File(localUrl).existsSync();

    return Scaffold(
      backgroundColor: Colors.black.withValues(alpha: _backgroundOpacity),
      body: SafeArea(
        child: Stack(
          children: [
            // 1. Tap anywhere outside image / on background to dismiss
            Positioned.fill(
              child: GestureDetector(
                behavior: HitTestBehavior.opaque,
                onTap: () => context.pop(),
                child: const SizedBox.expand(),
              ),
            ),

            // 2. Interactive Image Layer
            InteractiveViewer(
              transformationController: _transformationController,
              minScale: 1.0,
              maxScale: 4.0,
              panEnabled: _isZoomedIn,
              child: Center(
                child: GestureDetector(
                  onTap: () => setState(() => _showControls = !_showControls),
                  onDoubleTapDown: _handleDoubleTap,
                  onDoubleTap: () {},
                  onVerticalDragStart: _isZoomedIn
                      ? null
                      : (_) => setState(() => _isDragging = true),
                  onVerticalDragUpdate: _isZoomedIn
                      ? null
                      : (details) {
                          setState(() {
                            _dragOffset += details.delta;
                          });
                        },
                  onVerticalDragEnd: _isZoomedIn
                      ? null
                      : (details) {
                          final velocity = details.primaryVelocity ?? 0;
                          if (_dragOffset.dy.abs() > 120 ||
                              velocity.abs() > 800) {
                            context.pop();
                          } else {
                            _resetOffsetAnimation = Tween<Offset>(
                              begin: _dragOffset,
                              end: Offset.zero,
                            ).animate(
                              CurvedAnimation(
                                parent: _resetAnimationController,
                                curve: Curves.easeOutCubic,
                              ),
                            );
                            _resetAnimationController.forward(from: 0);
                            setState(() => _isDragging = false);
                          }
                        },
                  child: Transform.translate(
                    offset: _dragOffset,
                    child: Transform.scale(
                      scale: _imageScale,
                      child: Hero(
                        tag: widget.heroTag,
                        child: hasLocalFile
                            ? Image.file(
                                File(localUrl!),
                                fit: BoxFit.contain,
                                errorBuilder: (_, __, ___) => _buildErrorWidget(),
                              )
                            : CachedNetworkImage(
                                imageUrl: widget.imageUrl,
                                fit: BoxFit.contain,
                                placeholder: (_, __) => const Center(
                                  child: CircularProgressIndicator(
                                    color: Color(0xFFC5A36B),
                                  ),
                                ),
                                errorWidget: (_, __, ___) => _buildErrorWidget(),
                              ),
                      ),
                    ),
                  ),
                ),
              ),
            ),

            // 3. Top Close Button Overlay
            AnimatedOpacity(
              duration: const Duration(milliseconds: 180),
              opacity: (_showControls && !_isDragging) ? 1.0 : 0.0,
              child: Align(
                alignment: Alignment.topRight,
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Material(
                    color: Colors.black45,
                    shape: const CircleBorder(),
                    child: IconButton(
                      icon: const Icon(
                        Icons.close,
                        color: Colors.white,
                        size: 26,
                      ),
                      onPressed: () => context.pop(),
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildErrorWidget() {
    return const Icon(
      Icons.broken_image_outlined,
      color: Colors.white70,
      size: 48,
    );
  }
}

void showFullscreenImageViewer(
    BuildContext context,
    ArtworkModel artwork,
    String heroTag,
    {String? localUrl}
  ) {
    final url = artwork.downloadUrl ?? artwork.url ?? '';
    if (url.isEmpty) return;

    Navigator.of(context).push(
      PageRouteBuilder<void>(
        opaque: false,
        barrierColor: Colors.transparent,
        transitionDuration: const Duration(milliseconds: 250),
        reverseTransitionDuration: const Duration(milliseconds: 200),
        pageBuilder: (_, animation, __) {
          return FadeTransition(
            opacity: animation,
            child: FullscreenImageViewer(
              imageUrl: url,
              heroTag: heroTag,
              localUrl: localUrl,
            ),
          );
        },
      ),
    );
  }