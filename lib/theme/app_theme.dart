import 'package:art_gallary/theme/app_colors.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

class AppTheme {
  AppTheme._();

  // Change from a getter to a method that accepts BuildContext
  static ThemeData getTheme() {

    return ThemeData(
      colorScheme: ColorScheme.fromSeed(seedColor: AppColors.backgroundColor),
      useMaterial3: true,

      // Use the local variable to safely switch fonts
      // fontFamily: 'Msjh',

      actionIconTheme: ActionIconThemeData(
        
        backButtonIconBuilder: (BuildContext context) {
          
          return Container(
            margin: const EdgeInsets.all(0),
            alignment: Alignment.centerLeft,
            padding: EdgeInsets.only(left: 8.spMax),
            child: Icon(
              Icons.chevron_left_rounded,
              size: 42.spMax,
              color: AppColors.primary,
            )
          );
        },

      ), 
      // canvasColor: AppColors.backgroundColor, 
      // scaffoldBackgroundColor: AppColors.backgroundColor,
      appBarTheme: const AppBarTheme(
        systemOverlayStyle: SystemUiOverlayStyle(
          statusBarColor: Colors.white,             // Android background
          // statusBarColor: Colors.transparent,
          statusBarIconBrightness: Brightness.dark,
          statusBarBrightness: Brightness.light,      
        ),
        actionsPadding: EdgeInsets.only(right: 24.0),
        centerTitle: false,
        // backgroundColor: Colors.transparent,
        scrolledUnderElevation: 0,
        elevation: 0,

        titleSpacing: 0, 

        // toolbarHeight: 76.0,
        leadingWidth: 60.0,
        titleTextStyle: TextStyle(
          color: AppColors.primary,
          fontSize: 20,
          letterSpacing: -0.22,
          height: 1, 
          fontWeight: FontWeight.w600
        ),
      ),

      textTheme: const TextTheme(
        bodyMedium: TextStyle(fontSize: 10.0), // Standard body text
        bodyLarge: TextStyle(fontSize: 12.0),  // Slightly larger fallback
        labelMedium: TextStyle(fontSize: 10.0), // Form / Button labels
      ),

      bottomNavigationBarTheme: const BottomNavigationBarThemeData(
        backgroundColor: Colors.transparent, 
        elevation: 0,                 
        type: BottomNavigationBarType.fixed, 
        selectedItemColor: Colors.white,
        unselectedItemColor: Colors.white60,
        selectedIconTheme: IconThemeData(size: 26),
        unselectedIconTheme: IconThemeData(size: 24),
      ),
    );
  }
}
