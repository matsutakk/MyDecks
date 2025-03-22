import 'package:flutter/material.dart';
import 'app_colors.dart';

class AppThemes {
  // 共通の設定値
  static const double _defaultBorderRadius = 12.0;
  static const double _buttonBorderRadius = 8.0;
  static const double _bottomSheetRadius = 16.0;
  
  static const EdgeInsets _buttonPadding = EdgeInsets.symmetric(horizontal: 16, vertical: 12);
  
  // ライトテーマ
  static ThemeData get lightTheme {
    return _createTheme(
      brightness: Brightness.light,
      primaryColor: AppColors.primary,
      secondaryColor: AppColors.accent,
      backgroundColor: AppColors.background,
      surfaceColor: AppColors.surface,
      errorColor: AppColors.error,
      
      appBarBackgroundColor: AppColors.primary,
      appBarForegroundColor: Colors.white,
      
      cardBackgroundColor: AppColors.cardBackground,
      cardBorderColor: AppColors.cardBorder,
      
      tabBarSelectedColor: Colors.white,
      tabBarUnselectedColor: Colors.white70,
      tabBarIndicatorColor: Colors.white,
      
      bottomAppBarColor: AppColors.primary,
      bottomSheetBackgroundColor: Colors.white,
    );
  }
  
  // ダークテーマ
  static ThemeData get darkTheme {
    return _createTheme(
      brightness: Brightness.dark,
      primaryColor: AppColors.primaryDark,
      secondaryColor: AppColors.accentDark,
      backgroundColor: Colors.black,
      surfaceColor: Colors.grey[900]!,
      errorColor: AppColors.error,
      
      appBarBackgroundColor: Colors.grey[900]!,
      appBarForegroundColor: Colors.white,
      
      cardBackgroundColor: Colors.grey[850]!,
      cardBorderColor: Colors.grey[800]!,
      
      tabBarSelectedColor: Colors.white,
      tabBarUnselectedColor: Colors.grey[500]!,
      tabBarIndicatorColor: AppColors.accentDark,
      
      bottomAppBarColor: Colors.grey[900]!,
      bottomSheetBackgroundColor: Colors.grey[900]!,
    );
  }
  
  // テーマ作成の共通メソッド
  static ThemeData _createTheme({
    required Brightness brightness,
    required Color primaryColor,
    required Color secondaryColor,
    required Color backgroundColor,
    required Color surfaceColor,
    required Color errorColor,
    required Color appBarBackgroundColor,
    required Color appBarForegroundColor,
    required Color cardBackgroundColor,
    required Color cardBorderColor,
    required Color tabBarSelectedColor,
    required Color tabBarUnselectedColor,
    required Color tabBarIndicatorColor,
    required Color bottomAppBarColor,
    required Color bottomSheetBackgroundColor,
  }) {
    // primaryとaccentのライト/ダークバリエーション
    final primaryLight = brightness == Brightness.light 
      ? AppColors.primaryLight 
      : AppColors.primary;
      
    final secondaryLight = brightness == Brightness.light 
      ? AppColors.accentLight 
      : AppColors.accent;
      
    // ColorScheme の構築
    final colorScheme = brightness == Brightness.light
      ? ColorScheme.light(
          primary: primaryColor,
          primaryContainer: primaryLight,
          secondary: secondaryColor,
          secondaryContainer: secondaryLight,
          surface: surfaceColor,
          background: backgroundColor,
          error: errorColor,
        )
      : ColorScheme.dark(
          primary: primaryColor,
          primaryContainer: primaryLight,
          secondary: secondaryColor,
          secondaryContainer: secondaryLight,
          surface: surfaceColor,
          background: backgroundColor,
          error: errorColor,
        );
      
    // テーマデータの構築
    return ThemeData(
      brightness: brightness,
      primaryColor: primaryColor,
      colorScheme: colorScheme,
      scaffoldBackgroundColor: backgroundColor,
      
      // AppBar テーマ
      appBarTheme: AppBarTheme(
        backgroundColor: appBarBackgroundColor,
        foregroundColor: appBarForegroundColor,
        elevation: 0,
        centerTitle: true,
        titleTextStyle: TextStyle(
          fontSize: 18,
          fontWeight: FontWeight.bold,
          color: appBarForegroundColor,
        ),
      ),
      
      // Card テーマ
      cardTheme: CardTheme(
        color: cardBackgroundColor,
        elevation: 1.0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(_defaultBorderRadius),
          side: BorderSide(color: cardBorderColor),
        ),
        clipBehavior: Clip.antiAlias,
      ),
      
      // ボタンテーマ
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: primaryColor,
          foregroundColor: appBarForegroundColor,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(_buttonBorderRadius),
          ),
          padding: _buttonPadding,
          elevation: 2,
        ),
      ),
      
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: primaryColor,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(_buttonBorderRadius),
          ),
          padding: _buttonPadding,
        ),
      ),
      
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: primaryColor,
          side: BorderSide(color: primaryColor),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(_buttonBorderRadius),
          ),
          padding: _buttonPadding,
        ),
      ),
      
      // TabBar テーマ
      tabBarTheme: TabBarTheme(
        labelColor: tabBarSelectedColor,
        unselectedLabelColor: tabBarUnselectedColor,
        indicatorColor: tabBarIndicatorColor,
        indicatorSize: TabBarIndicatorSize.tab,
        labelStyle: const TextStyle(fontWeight: FontWeight.bold),
        unselectedLabelStyle: const TextStyle(fontWeight: FontWeight.normal),
      ),
      
      // FAB テーマ
      floatingActionButtonTheme: FloatingActionButtonThemeData(
        backgroundColor: secondaryColor,
        foregroundColor: Colors.white,
        shape: const CircleBorder(), // 完全な円形
        elevation: 4,
        highlightElevation: 8,
        extendedPadding: const EdgeInsets.all(16), // パディングを追加
        sizeConstraints: const BoxConstraints.tightFor(width: 56, height: 56), // サイズを標準に
      ),
      
      // BottomAppBar テーマ
      bottomAppBarTheme: BottomAppBarTheme(
        color: bottomAppBarColor,
        elevation: 4, // 影を控えめに
        height: 52.0, // 高さを標準に設定
        padding: EdgeInsets.zero, // パディングなし
        shape: const CircularNotchedRectangle(),
      ),
      
      // BottomSheet テーマ
      bottomSheetTheme: BottomSheetThemeData(
        backgroundColor: bottomSheetBackgroundColor,
        elevation: 8,
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(
            top: Radius.circular(_bottomSheetRadius),
          ),
        ),
      ),
      
      // Input テーマ
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: brightness == Brightness.light 
            ? Colors.grey[100] 
            : Colors.grey[800],
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(_buttonBorderRadius),
          borderSide: BorderSide.none,
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(_buttonBorderRadius),
          borderSide: BorderSide(color: primaryColor, width: 1.5),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(_buttonBorderRadius),
          borderSide: BorderSide(color: errorColor, width: 1.5),
        ),
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
      ),
      
      // Divider テーマ
      dividerTheme: DividerThemeData(
        color: brightness == Brightness.light 
            ? Colors.grey[300] 
            : Colors.grey[700],
        thickness: 1,
        space: 1,
      ),
      
      // チェックボックス、スイッチなどのアクセント色
      checkboxTheme: CheckboxThemeData(
        fillColor: MaterialStateProperty.resolveWith<Color>((states) {
          if (states.contains(MaterialState.disabled)) {
            return Colors.grey;
          }
          return primaryColor;
        }),
      ),
      
      // Material 3 を有効化（オプション）
      useMaterial3: true,
    );
  }
}