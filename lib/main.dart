import 'package:art_gallary/core/constants/app_constants.dart';
import 'package:art_gallary/core/router/router.dart';
import 'package:art_gallary/theme/app_theme.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:flutter_screenutil/flutter_screenutil.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  SystemChrome.setSystemUIOverlayStyle(
    const SystemUiOverlayStyle(
      statusBarColor: Colors.black, // Android: Status bar background color
      statusBarIconBrightness: Brightness
          .light, // Android: White icons (so they are visible on black)
      statusBarBrightness:
          Brightness.dark, // iOS: Sets top status bar text/icons to light color
    ),
  );

  // Portrait Only
  await SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
    DeviceOrientation.portraitDown,
  ]);

  await StorageInitializer.init();

  runApp(
    UncontrolledProviderScope(
      container: appContainer,
      child: const ArtGallaryApp(),
    ),
  );
} //=> runApp(const MyApp());

class ArtGallaryApp extends ConsumerStatefulWidget {
  const ArtGallaryApp({super.key});

  @override
  ConsumerState<ConsumerStatefulWidget> createState() => _ArtGallaryAppState();
}

class _ArtGallaryAppState extends ConsumerState<ArtGallaryApp> {
  @override
  void initState() {
    // TODO: implement initState
    super.initState();
    AppRouter.instance.setInitialRoute(pageHome);
  }

  @override
  Widget build(BuildContext context) {
    return ScreenUtilInit(
      designSize: const Size(1280, 800),
      minTextAdapt: true,
      splitScreenMode: true,
      builder: (_, child) {
        return MaterialApp.router(
          title: 'Art Gallary App',
          theme: AppTheme.getTheme(),
          builder: (context, child) {
            return child!;
          },
          debugShowCheckedModeBanner: false,
          routerConfig: AppRouter.instance.router,
        );
      },
    );
  }

  @override
  void dispose() {
    // TODO: implement dispose
    super.dispose();

    AppRouter.instance.dispose();
  }
}
