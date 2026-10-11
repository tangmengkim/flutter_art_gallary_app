import 'package:art_gallary/core/constants/app_constants.dart';
import 'package:art_gallary/shared/custom_navbar.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:go_router/go_router.dart';



class MainScaffold extends StatefulWidget {
  final StatefulNavigationShell navigationShell;

  const MainScaffold({super.key, required this.navigationShell});

  @override
  State<MainScaffold> createState() => _MainScaffoldState();
}

class _MainScaffoldState extends State<MainScaffold> {
  // Stores the history of visited tab indexes
  final List<int> _tabHistory = [];
  bool _isPoppingHistory = false;

  @override
  void didUpdateWidget(MainScaffold oldWidget) {
    super.didUpdateWidget(oldWidget);
    
    final oldIndex = oldWidget.navigationShell.currentIndex;
    final newIndex = widget.navigationShell.currentIndex;

    // Automatically tracks history whether user taps the menu or uses code (.go)
    if (oldIndex != newIndex) {
      if (_isPoppingHistory) {
        _isPoppingHistory = false; // Reset flag if we are going backward
      } else {
        _tabHistory.remove(oldIndex); // Avoid duplicate entries
        _tabHistory.add(oldIndex);    // Save the tab we just left
      }
    }
  }

  DateTime? _lastPressedAt;

  void _handleBackNavigation(bool didPop) {
    if (didPop) return;

    print("remain tab history: $_tabHistory");

    if (_tabHistory.isNotEmpty) {
      final previousIndex = _tabHistory.removeLast();
      setState(() {
        _isPoppingHistory = true;
      });
      widget.navigationShell.goBranch(previousIndex);
      ///
      if(_tabHistory.firstOrNull != 0 && previousIndex != 0) {
        _tabHistory.insert(0, 0);
      }
    } 
    else if (widget.navigationShell.currentIndex != 0) {
      widget.navigationShell.goBranch(0);
    } 
    // Custom double-tap logic for Index 0:
    else {
      final now = DateTime.now();
      if (_lastPressedAt == null || now.difference(_lastPressedAt!) > const Duration(seconds: 2)) {
        _lastPressedAt = now;
        
        // Show a quick native alert toast or snackbar
        Fluttertoast.showToast(msg:"Press back again to exit", toastLength: Toast.LENGTH_SHORT);
      } else {
        // Second tap happened within 2 seconds -> close app
        SystemNavigator.pop();
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    // Check if GoRouter can pop internally (i.e., we are viewing a child/detail page)
    final bool canPopInternally = GoRouter.of(context).canPop();

    return PopScope(
      // True: Allows standard pop (Detail page -> Parent page)
      // False: Blocks OS back gesture so our custom tab navigation logic can run
      canPop: canPopInternally,
      onPopInvokedWithResult: (didPop, result) {
        _handleBackNavigation(didPop);
      },
      child: Scaffold(
        body: KeyedSubtree(
        child: widget.navigationShell,
        ),
        bottomNavigationBar: CustomBottomNavBar(selectedIndex: widget.navigationShell.currentIndex, onItemTapped: (index) async {
          widget.navigationShell.goBranch(
            index,
            // initialLocation: index == widget.navigationShell.currentIndex,
          );
        })
      )
    );
  }
}