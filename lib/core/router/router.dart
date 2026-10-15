import 'dart:developer';

import 'package:art_gallary/features/home/data/models/artwork_model.dart';
import 'package:art_gallary/features/home/presentation/views/artwork_detail_screen.dart';
import 'package:art_gallary/features/home/presentation/views/home_screen.dart';
import 'package:art_gallary/features/saved/presentation/views/saved_detail_screen.dart';
import 'package:art_gallary/features/saved/presentation/views/saved_screen.dart';
import 'package:art_gallary/shared/main_scaffold.dart';

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';


const pageSuccess = "/success";

//HOME
const pageHome = "/";

//ART_DETAIL (Used as a relative sub-route path string, must NOT start or end with '/')
const pageArtDetail = "art_detail_page";

//SAVED
const pageSaved = "/saved_page";


class RouteUpdateListener {
  void Function(String currentPageUri) listener;

  RouteUpdateListener({required this.listener});
}

class AppRouter {

  static final AppRouter instance = AppRouter._internal();
  AppRouter._internal();

  factory AppRouter() {
    return instance;
  }

  GoRouter? _router;
  List<AppPageConfig>? _listPages;
  GoRouter get router => _router ?? getConfigRouter();
  List<AppPageConfig> get listPages => _listPages ?? _getPageConfigList();
  final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();
  final GlobalKey<NavigatorState> _shellNavigatorKey =
      GlobalKey<NavigatorState>();
  GlobalKey<NavigatorState> get shellNavigatorKey => _shellNavigatorKey;
  
  final List<RouteUpdateListener> _listeners = [];
  bool _isRouteListenerInitialized = false;
  String? _initialRoute;

  GoRouter getConfigRouter() {
    final cleanLayoutPageList = listPages
        .where((page) => page.isCleanLayout)
        .toList();

    log("_initialRoute : $_initialRoute");
    _router = GoRouter(
      navigatorKey: navigatorKey,
      routes: [
        StatefulShellRoute.indexedStack(
          builder: (context, state, navigationShell) =>
              MainScaffold(navigationShell: navigationShell),
          branches: [
            buildHomeBranch(),
            buildSavedBranch(),
          ],
        ),
        ..._mapBuilderToPageBuilder(cleanLayoutPageList),
      ],
      initialLocation: _initialRoute,
    );
    return _router!;
  }

  List<AppPageConfig> _getPageConfigList() {
    _listPages = [
      // AppPageConfig(
      //   path: pageHome,
      //   name: pageHome,
      //   builder: (context, state) => const HomeScreen(),
      // ),
    ];
    return listPages;
  }

  List<GoRoute> _mapBuilderToPageBuilder(List<AppPageConfig> pages) {
    return pages.map((page) {
      return GoRoute(
        path: page.path,
        name: page.name,
        pageBuilder: page.builder != null
            ? (context, state) => MaterialPage(
                key: state.pageKey,
                child: page.builder!(context, state),
              )
            : null,
      );
    }).toList();
  }

  void setInitialRoute(String path) {
    _initialRoute = path;
  }

  String get currentPageUri =>
      router.routeInformationProvider.value.uri.toString();
  AppPageConfig get currentPage =>
      listPages.singleWhere((page) => page.path == currentPageUri);

  void _onUpdateRoute() {
    for (final data in _listeners) {
      data.listener.call(currentPageUri);
    }
  }

  void _initRouteUpdateListener() {
    _isRouteListenerInitialized = true;
    router.routerDelegate.addListener(_onUpdateRoute);
  }

  void dispose() {
    router.routerDelegate.removeListener(_onUpdateRoute);
    _isRouteListenerInitialized = false;
  }

  void addRouteUpdateListener(void Function(String currentPageUri) listener) {
    if (!_isRouteListenerInitialized) _initRouteUpdateListener();
    _listeners.add(RouteUpdateListener(listener: listener));
  }

  void removeRouteUpdateListener(
    void Function(String currentPageUri) listener,
  ) {
    _listeners.removeWhere((element) => element.listener == listener);
  }

  /// Pops screens until the condition is met, then pushes the new page.
  void pushAndRemoveUntil({
    required BuildContext context,
    required String newPath,
    required bool Function(String currentPath) predicate,
    Object? extra,
  }) {
    while (context.canPop()) {
      final currentUri = GoRouterState.of(context).uri.toString();
      if (predicate(currentUri)) {
        break;
      }
      context.pop();
    }
    context.push(newPath, extra: extra);
  }

  /// Pops screens until the condition
  void popUntilPath(BuildContext context, String targetPath) {
    while (GoRouter.of(context).canPop() &&
        GoRouterState.of(context).uri.toString() != targetPath) {
      context.pop();
    }
  }

  // ---- BRANCH 1: HOME ----
  StatefulShellBranch buildHomeBranch() {
    return StatefulShellBranch(
    routes: [
      GoRoute(
        path: pageHome,
        name: pageHome,
        builder: (context, state) => HomeScreen(
          onArtworkTap: (artwork) {
            // Push full path: /art_detail_page
            context.push("/$pageArtDetail", extra: artwork);
          },
        ),
        routes: [
          GoRoute(
            parentNavigatorKey: navigatorKey, // Hides bottom navbar by pushing to Root Navigator
            path: pageArtDetail,
            name: pageArtDetail,
            builder: (context, state) => const ArtworkDetailScreen(),
          ),
        ],
      ),
    ],
  );
  }

  // ---- BRANCH 2: Saved ----
  StatefulShellBranch buildSavedBranch() {
    return StatefulShellBranch(
    routes: [
      GoRoute(
        path: pageSaved,
        name: pageSaved,
        builder: (context, state) => const SavedScreen(),
        routes: [
          GoRoute(
              parentNavigatorKey: navigatorKey, // Hides bottom navbar
              path: pageArtDetail,
              name: "$pageSaved/$pageArtDetail",
              builder: (context, state) {
                if (state.extra is Map<String, dynamic>) {
                  final data = state.extra as Map<String, dynamic>;
                  return SavedDetailScreen(
                    artwork: data['artwork'] as ArtworkModel?,
                    index: (data['index'] as int?) ?? 0,
                  );
                }
                return SavedDetailScreen(
                  artwork: state.extra as ArtworkModel?,
                );
              },
            ),
        ],
      ),
    ],
  );
  }

}

class AppPageConfig extends GoRoute {
  AppPageConfig({
    required super.path,
    super.name,
    super.builder,
    super.pageBuilder,
    this.isCleanLayout = true,
    this.title = '',
  });

  final bool isCleanLayout;
  final String title;
}
