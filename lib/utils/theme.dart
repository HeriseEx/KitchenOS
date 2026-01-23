import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

/// 应用主题配置
/// iOS 17 Inspired Theme
class AppTheme {
  // iOS System Colors
  static const Color primaryColor = Color(0xFF34C759); // iOS Green
  static const Color secondaryColor = Color(0xFFFF9500); // iOS Orange
  static const Color errorColor = Color(0xFFFF3B30); // iOS Red
  static const Color warningColor = Color(0xFFFFCC00); // iOS Yellow
  
  static const Color surfaceColor = Colors.white;
  static const Color backgroundColor = Color(0xFFF2F2F7); // iOS Grouped Background

  // Resource Colors (Softened)
  static const Color criticalPathColor = Color(0xFFFF2D55); // iOS Pink
  static const Color checkpointColor = Color(0xFF8E8E93); // iOS System Gray
  static const Color freeResourceColor = Color(0xFF34C759);
  static const Color occupiedResourceColor = Color(0xFF007AFF); // iOS Blue
  static const Color dirtyResourceColor = Color(0xFFFF9500);

  // Pro Max UI Extensions
  static const LinearGradient primaryGradient = LinearGradient(
    colors: [Color(0xFF34C759), Color(0xFF30D158)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const LinearGradient warmGradient = LinearGradient(
    colors: [Color(0xFFFF9500), Color(0xFFFFCC00)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static List<BoxShadow> get softShadow => [
    BoxShadow(
      color: Colors.black.withOpacity(0.06),
      blurRadius: 24,
      offset: const Offset(0, 8),
      spreadRadius: -4,
    ),
  ];

  static List<BoxShadow> get glowShadow => [
    BoxShadow(
      color: primaryColor.withOpacity(0.3),
      blurRadius: 20,
      offset: const Offset(0, 8),
    ),
  ];

  static ThemeData get lightTheme {
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.light,
      primaryColor: primaryColor,
      scaffoldBackgroundColor: backgroundColor,
      colorScheme: ColorScheme.fromSeed(
        seedColor: primaryColor,
        primary: primaryColor,
        secondary: secondaryColor,
        error: errorColor,
        surface: surfaceColor,
        background: backgroundColor,
        brightness: Brightness.light,
      ),
      
      // Typography - mimicking SF Pro
      fontFamily: 'San Francisco', // Fallback will happen naturally
      textTheme: const TextTheme(
        displayLarge: TextStyle(fontSize: 34, fontWeight: FontWeight.bold, letterSpacing: -0.5, color: Colors.black),
        displayMedium: TextStyle(fontSize: 28, fontWeight: FontWeight.bold, letterSpacing: -0.5, color: Colors.black),
        titleLarge: TextStyle(fontSize: 22, fontWeight: FontWeight.w700, letterSpacing: -0.5, color: Colors.black),
        bodyLarge: TextStyle(fontSize: 17, color: Colors.black87),
        bodyMedium: TextStyle(fontSize: 15, color: Colors.black87),
      ),

      appBarTheme: const AppBarTheme(
        centerTitle: true,
        elevation: 0,
        backgroundColor: Colors.transparent,
        foregroundColor: Colors.black,
        systemOverlayStyle: SystemUiOverlayStyle.dark,
        titleTextStyle: TextStyle(
          color: Colors.black,
          fontSize: 17,
          fontWeight: FontWeight.w600,
        ),
      ),

      cardTheme: CardTheme(
        elevation: 0, // We will handle shadow manually for that precise Apple feel
        color: surfaceColor,
        margin: EdgeInsets.zero,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
        ),
      ),

      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: primaryColor,
          foregroundColor: Colors.white,
          elevation: 0,
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(40), // Pill shape
          ),
          textStyle: const TextStyle(
            fontSize: 17,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),

      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: Colors.white,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide.none,
        ),
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        hintStyle: TextStyle(color: Colors.grey[400]),
      ),
      
      bottomSheetTheme: const BottomSheetThemeData(
        backgroundColor: Colors.transparent,
        modalBackgroundColor: Colors.transparent,
      ),
    );
  }

  static ThemeData get darkTheme {
    const darkBg = Color(0xFF000000);
    const darkSurface = Color(0xFF1C1C1E); // iOS Dark Gray 6
    
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      primaryColor: primaryColor,
      scaffoldBackgroundColor: darkBg,
      colorScheme: ColorScheme.fromSeed(
        seedColor: primaryColor,
        brightness: Brightness.dark,
        surface: darkSurface,
        background: darkBg,
      ),
      appBarTheme: const AppBarTheme(
        centerTitle: true,
        elevation: 0,
        backgroundColor: Colors.transparent,
        foregroundColor: Colors.white,
        systemOverlayStyle: SystemUiOverlayStyle.light,
      ),
      cardTheme: CardTheme(
        elevation: 0,
        color: darkSurface,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
        ),
      ),
    );
  }
}

/// 工具方法
class AppUtils {
  /// 格式化秒数为 mm:ss
  static String formatDuration(int seconds) {
    final minutes = seconds ~/ 60;
    final secs = seconds % 60;
    return '${minutes.toString().padLeft(2, '0')}:${secs.toString().padLeft(2, '0')}';
  }

  /// 格式化秒数为中文描述
  static String formatDurationChinese(int seconds) {
    if (seconds < 60) {
      return '$seconds秒';
    }
    final minutes = seconds ~/ 60;
    final secs = seconds % 60;
    if (secs == 0) {
      return '$minutes分钟';
    }
    return '$minutes分$secs秒';
  }
}
