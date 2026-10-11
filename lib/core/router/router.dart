import 'dart:developer';

import 'package:art_gallary/features/home/presentation/views/art_detail_screen.dart';
import 'package:art_gallary/features/home/presentation/views/home_screen.dart';
import 'package:art_gallary/features/profile/presentation/views/profile_screen.dart';
import 'package:art_gallary/features/saved/presentation/views/saved_screen.dart';
import 'package:art_gallary/shared/main_scaffold.dart';

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';


const pageSuccess = "/success";

//HOME
const pageHome = "/home_page";

//ART_DETAIL (Used as a relative sub-route path string, must NOT start or end with '/')
const pageArtDetail = "art_detail_page";

//SAVED
const pageSaved = "/saved_page";

//PROFILE
const pageProfile = "/profile_page";

class RouteUpdateListener {
  void Function(String currentPageUri) listener;
  
  RouteUpdateListener({
    required this.listener
  });
}

class AppRouter {

  static final AppRouter instance = AppRouter._internal();
  AppRouter._internal();

  factory AppRouter() {
    return instance;
  }

  GoRouter? _router;
  List<AppPageConfig>? _listPages;
  GoRouter get router =>  _router ?? getConfigRouter();
  List<AppPageConfig> get listPages =>  _listPages ?? _getPageConfigList();
  final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();
  final GlobalKey<NavigatorState> _shellNavigatorKey = GlobalKey<NavigatorState>();
  GlobalKey<NavigatorState> get shellNavigatorKey => _shellNavigatorKey;
  
  final List<RouteUpdateListener> _listeners = [];
  bool _isRouteListenerInitialized = false;
  String? _initialRoute;

  GoRouter getConfigRouter(){
    final cleanLayoutPageList = listPages.where((page) => page.isCleanLayout).toList();

    log("_initialRoute : $_initialRoute");
    _router = GoRouter(
      navigatorKey: navigatorKey,
      routes: [
        StatefulShellRoute.indexedStack(
          builder: (context, state, navigationShell) => MainScaffold(navigationShell: navigationShell),
          branches: [
            buildHomeBranch(),
            buildSavedBranch(),
            buildProfileBranch(),
          ]
        ),
        ..._mapBuilderToPageBuilder(cleanLayoutPageList),
      ],
      initialLocation: _initialRoute,
    );
    return _router!;
  }

  List<AppPageConfig> _getPageConfigList(){
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
              child: page.builder!(context, state)
            )
            : null,
      );
    }).toList();
  }

  void setInitialRoute(String path){
    _initialRoute = path;
  }

  String get currentPageUri => router.routeInformationProvider.value.uri.toString();
  AppPageConfig get currentPage => listPages.singleWhere((page)=> page.path == currentPageUri);

  void _onUpdateRoute(){
    for(final data in _listeners){
      data.listener.call(currentPageUri);
    }
  }
  
  void _initRouteUpdateListener(){
    _isRouteListenerInitialized = true;
    router.routerDelegate.addListener(_onUpdateRoute);
  }

  void dispose(){
    router.routerDelegate.removeListener(_onUpdateRoute);
    _isRouteListenerInitialized = false;
  }

  void addRouteUpdateListener(void Function(String currentPageUri) listener){
    if(!_isRouteListenerInitialized) _initRouteUpdateListener();
    _listeners.add(
      RouteUpdateListener(
        listener: listener
      )
    );
  }

  void removeRouteUpdateListener(void Function(String currentPageUri) listener){
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
          builder: (context, state) => const HomeScreen(),
          routes: [
            GoRoute(
              path: pageArtDetail, // Relative path matching "art_detail_page"
              name: "$pageHome/$pageArtDetail", // Unique lookup name identifier string
              builder: (context, state) => const ArtDetailScreen(),
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
              path: pageArtDetail, // Relative path matching "art_detail_page"
              name: "$pageSaved/$pageArtDetail", // Unique lookup name identifier string
              builder: (context, state) => const ArtDetailScreen(),
            ),
          ],
        ),
      ],
    );
  }

  // ---- BRANCH 3: Profile ----
  StatefulShellBranch buildProfileBranch() {
    return StatefulShellBranch(
      routes: [
        GoRoute(
          path: pageProfile,
          name: pageProfile,
          builder: (context, state) => const ProfileScreen(),
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
    this.title = ''
  });

  final bool isCleanLayout;
  final String title;
}

