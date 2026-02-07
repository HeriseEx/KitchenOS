import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

/// 应用主题配置
/// iOS 17 Inspired Theme
class AppTheme {
  // Premium Luxury Colors
  static const Color primaryColor = Color(0xFF2C2C2E); // Deep Matte Black for luxury base
  static const Color accentColor = Color(0xFFD4AF37); // Champagne Gold
  static const Color secondaryColor = Color(0xFF8E8E93); // Metallic Gray
  
  static const Color surfaceColor = Colors.white;
  static const Color backgroundColor = Color(0xFFF5F5F7); // High-end paper white/gray
  
  // Semantic Colors (Refined)
  static const Color errorColor = Color(0xFFFF453A); // Vibrant Red
  static const Color warningColor = Color(0xFFFFD60A); // Vibrant Yellow
  static const Color successColor = Color(0xFF32D74B); // Vibrant Green

  // Resource Colors (Sophisticated Palette)
  static const Color criticalPathColor = Color(0xFFFF375F); // Neo Pink
  static const Color checkpointColor = Color(0xFF64D2FF); // Ice Blue
  static const Color freeResourceColor = Color(0xFF30D158); // Mint Green
  static const Color occupiedResourceColor = Color(0xFF0A84FF); // Azure Blue
  static const Color dirtyResourceColor = Color(0xFFFF9F0A); // Bronze Orange

  // Premium Gradients
  static const LinearGradient primaryGradient = LinearGradient(
    colors: [Color(0xFF2C2C2E), Color(0xFF1C1C1E)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const LinearGradient luxuryGradient = LinearGradient(
    colors: [Color(0xFFD4AF37), Color(0xFFC5A028)], // Gold Gradient
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );
  
  static const LinearGradient glassGradient = LinearGradient(
    colors: [Colors.white54, Colors.white24],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  // Layered Shadows for Depth
  static List<BoxShadow> get softShadow => [
    BoxShadow(
      color: Colors.black.withOpacity(0.03),
      blurRadius: 10,
      offset: const Offset(0, 4),
    ),
    BoxShadow(
      color: Colors.black.withOpacity(0.02),
      blurRadius: 20,
      offset: const Offset(0, 8),
    ),
  ];

  static List<BoxShadow> get glowShadow => [
    BoxShadow(
      color: accentColor.withOpacity(0.3),
      blurRadius: 24,
      offset: const Offset(0, 8),
      spreadRadius: -4,
    ),
  ];

  static List<BoxShadow> get floatingShadow => [
    BoxShadow(
      color: Colors.black.withOpacity(0.08),
      blurRadius: 30,
      offset: const Offset(0, 15),
      spreadRadius: 0,
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
        secondary: accentColor,
        surface: surfaceColor,
        error: errorColor,
        brightness: Brightness.light,
      ),
      
      fontFamily: 'San Francisco',
      textTheme: const TextTheme(
        displayLarge: TextStyle(
          fontSize: 34, 
          fontWeight: FontWeight.w800, 
          letterSpacing: -1.0, 
          color: Color(0xFF1C1C1E),
          height: 1.1,
        ),
        displayMedium: TextStyle(
          fontSize: 28, 
          fontWeight: FontWeight.w700, 
          letterSpacing: -0.8, 
          color: Color(0xFF1C1C1E),
        ),
        titleLarge: TextStyle(
          fontSize: 22, 
          fontWeight: FontWeight.w700, 
          letterSpacing: -0.6, 
          color: Color(0xFF1C1C1E),
        ),
        bodyLarge: TextStyle(
          fontSize: 17, 
          color: Color(0xFF3A3A3C), 
          letterSpacing: -0.3,
          height: 1.5,
        ),
        bodyMedium: TextStyle(
          fontSize: 15, 
          color: Color(0xFF3A3A3C),
          height: 1.4,
        ),
      ),

      appBarTheme: const AppBarTheme(
        centerTitle: true,
        elevation: 0,
        backgroundColor: Colors.transparent,
        foregroundColor: Color(0xFF1C1C1E),
        scrolledUnderElevation: 0,
        systemOverlayStyle: SystemUiOverlayStyle.dark,
        titleTextStyle: TextStyle(
          color: Color(0xFF1C1C1E),
          fontSize: 17,
          fontWeight: FontWeight.w600,
          letterSpacing: -0.4,
        ),
      ),

      cardTheme: CardThemeData(
        elevation: 0,
        color: surfaceColor,
        margin: EdgeInsets.zero,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(24),
          side: BorderSide(color: Colors.black.withOpacity(0.03), width: 1),
        ),
      ),

      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: primaryColor,
          foregroundColor: Colors.white,
          elevation: 0,
          shadowColor: Colors.transparent,
          padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 18),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(40),
          ),
          textStyle: const TextStyle(
            fontSize: 17,
            fontWeight: FontWeight.w600,
            letterSpacing: -0.4,
          ),
        ),
      ),

      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: Colors.white,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide.none,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide(color: Colors.black.withOpacity(0.05)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: const BorderSide(color: primaryColor, width: 1.5),
        ),
        contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 18),
        hintStyle: TextStyle(color: Colors.grey[400]),
      ),
      
      chipTheme: ChipThemeData(
        backgroundColor: Colors.grey[100],
        shape: const StadiumBorder(side: BorderSide.none),
        labelStyle: const TextStyle(fontSize: 13, fontWeight: FontWeight.w500),
      ),
      
      bottomSheetTheme: const BottomSheetThemeData(
        backgroundColor: Colors.transparent,
        modalBackgroundColor: Colors.transparent,
        elevation: 0,
      ),
      
      dividerTheme: DividerThemeData(
        color: Colors.black.withOpacity(0.06),
        thickness: 1,
        space: 1,
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
      ),
      appBarTheme: const AppBarTheme(
        centerTitle: true,
        elevation: 0,
        backgroundColor: Colors.transparent,
        foregroundColor: Colors.white,
        systemOverlayStyle: SystemUiOverlayStyle.light,
      ),
      cardTheme: CardThemeData(
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
