
import 'package:art_gallary/theme/app_colors.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';


class SavedScreen extends ConsumerWidget {
  const SavedScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {

    return const Scaffold(
      body: Center(
        child: Text(
          "Saved Screen",
          style: TextStyle(fontSize: 24, color: AppColors.primary),
        ),
      ),
    );
  }
}
