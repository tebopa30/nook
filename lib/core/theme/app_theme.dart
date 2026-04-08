import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class AppTheme {
  // アンティーク・プレミアムな色彩定義
  static const Color primaryDark = Color(0xFF1A120B); // 深い夜の書斎
  static const Color surfaceDark = Color(0xFF2C1E12); // 表紙やカードの色
  static const Color accentGold = Color(0xFFC5A059);  // 輝くゴールド
  static const Color textWhite = Color(0xFFFAF6F0);   // 紙の白に近いテキスト色
  static const Color backgroundCream = Color(0xFFF9F6F0); // 補助的な羊皮紙色

  static ThemeData get darkTheme {
    final baseTextTheme = GoogleFonts.shipporiMinchoTextTheme(ThemeData.dark().textTheme);

    return ThemeData.dark().copyWith(
      colorScheme: ColorScheme.fromSeed(
        seedColor: accentGold,
        primary: accentGold,
        onPrimary: primaryDark,
        secondary: accentGold,
        onSecondary: primaryDark,
        surface: surfaceDark,
        onSurface: textWhite,
        brightness: Brightness.dark,
      ),
      scaffoldBackgroundColor: primaryDark,
      textTheme: baseTextTheme.apply(
        bodyColor: textWhite,
        displayColor: accentGold,
      ),
      appBarTheme: const AppBarTheme(
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: true,
        foregroundColor: accentGold,
        titleTextStyle: TextStyle(
          fontSize: 20,
          fontWeight: FontWeight.bold,
          fontFamily: 'serif',
          color: accentGold,
        ),
      ),
      cardTheme: CardThemeData(
        color: surfaceDark,
        elevation: 4,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: BorderSide(color: accentGold.withOpacity(0.3), width: 0.5),
        ),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: accentGold,
          foregroundColor: primaryDark,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 24),
          textStyle: const TextStyle(fontWeight: FontWeight.bold, letterSpacing: 1.5, fontFamily: 'serif'),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: accentGold,
          side: const BorderSide(color: accentGold),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 24),
          textStyle: const TextStyle(fontWeight: FontWeight.bold, letterSpacing: 1, fontFamily: 'serif'),
        ),
      ),
    );
  }

  // 下位互換性やプレビュー用のライトテーマ
  static ThemeData get lightTheme => darkTheme; 
}
