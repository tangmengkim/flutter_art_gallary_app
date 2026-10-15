import 'package:art_gallary/theme/app_colors.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

enum ToastType { success, error, info }

class ToastHandle {
  ToastHandle(this._entry, this._updateOverlay);

  final OverlayEntry _entry;
  final void Function(double? progress, String? message) _updateOverlay;

  void update({double? progress, String? message}) {
    _updateOverlay(progress, message);
  }

  void dismiss() {
    _entry.remove();
  }
}

class CustomToast {
  static void show(
    BuildContext context, {
    required String message,
    ToastType type = ToastType.success,
    Duration duration = const Duration(seconds: 2),
  }) {
    final scaffoldMessenger = ScaffoldMessenger.of(context);
    scaffoldMessenger.hideCurrentSnackBar();

    final Color backgroundColor;
    final IconData icon;

    switch (type) {
      case ToastType.success:
        backgroundColor = AppColors.primary;
        icon = Icons.check_circle_outline_rounded;
        break;
      case ToastType.error:
        backgroundColor = AppColors.danger;
        icon = Icons.error_outline_rounded;
        break;
      case ToastType.info:
        backgroundColor = AppColors.secondary;
        icon = Icons.info_outline_rounded;
        break;
    }

    scaffoldMessenger.showSnackBar(
      SnackBar(
        duration: duration,
        elevation: 0,
        behavior: SnackBarBehavior.floating,
        backgroundColor: Colors.transparent,
        padding: EdgeInsets.zero,
        margin: EdgeInsets.only(bottom: 24.h),
        content: _ToastContainer(
          backgroundColor: backgroundColor,
          leading: Icon(icon, color: Colors.white, size: 20.spMax),
          message: message,
        ),
      ),
    );
  }

  /// Helper method for showing live progress toast
  static ToastHandle showProgress(
    BuildContext context, {
    required String initialMessage,
  }) {
    late OverlayEntry overlayEntry;
    double? currentProgress = 0.01;
    String currentMessage = initialMessage;

    late void Function(double? progress, String? message) updateOverlay;

    final bottomPadding = MediaQuery.of(context).padding.bottom + 24.h;

    overlayEntry = OverlayEntry(
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setState) {
            updateOverlay = (progress, message) {
              if (overlayEntry.mounted) {
                setState(() {
                  if (progress != null) currentProgress = progress;
                  if (message != null) currentMessage = message;
                });
              }
            };

            return Positioned(
              bottom: bottomPadding,
              left: 0,
              right: 0,
              child: Material(
                color: Colors.transparent,
                child: _ToastContainer(
                  backgroundColor: AppColors.primary,
                  leading: Container(
                    margin: EdgeInsets.symmetric(horizontal: 10.w),
                    width: 40.w,
                    height: 40.w,
                    child: CircularProgressIndicator(
                      value: (currentProgress != null && currentProgress! > 0.05)
                          ? currentProgress
                          : null,
                      strokeWidth: 2.5,
                      color: Colors.white,
                    ),
                  ),
                  message: currentMessage,
                ),
              ),
            );
          },
        );
      },
    );

    Overlay.of(context).insert(overlayEntry);

    return ToastHandle(overlayEntry, (progress, message) {
      updateOverlay(progress, message);
    });
  }

  static void success(BuildContext context, String message) =>
      show(context, message: message, type: ToastType.success);

  static void error(BuildContext context, String message) =>
      show(context, message: message, type: ToastType.error);
}

class _ToastContainer extends StatelessWidget {
  const _ToastContainer({
    required this.backgroundColor,
    required this.leading,
    required this.message,
  });

  final Color backgroundColor;
  final Widget leading;
  final String message;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 46.w, vertical: 12.h),
      margin: EdgeInsets.symmetric(horizontal: 56.w),
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.18),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          leading,
          SizedBox(width: 12.w),
          Expanded(
            child: Text(
              message,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                color: Colors.white,
                fontSize: 13.spMax,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }
}