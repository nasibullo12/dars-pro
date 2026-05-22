import 'package:flutter/material.dart';

class AppTheme {
  static const Color bg = Color(0xFF000000);
  static const Color surface = Color(0xFF1C1C1E);
  static const Color surface2 = Color(0xFF2C2C2E);
  static const Color border = Color(0xFF38383A);
  static const Color textColor = Color(0xFFFFFFFF);
  static const Color muted = Color(0xFF8E8E93);
  static const Color green = Color(0xFF30D158);
  static const Color orange = Color(0xFFFF9F0A);
  static const Color blue = Color(0xFF0A84FF);
  static const Color red = Color(0xFFFF453A);
  static const Color purple = Color(0xFFBF5AF2);

  static ThemeData get darkTheme => ThemeData(
        brightness: Brightness.dark,
        scaffoldBackgroundColor: bg,
        colorScheme: const ColorScheme.dark(
          primary: orange,
          secondary: blue,
          surface: surface,
          error: red,
        ),
        fontFamily: 'Nunito',
        appBarTheme: const AppBarTheme(
          backgroundColor: bg,
          elevation: 0,
          centerTitle: false,
          titleTextStyle: TextStyle(
            color: textColor,
            fontSize: 28,
            fontWeight: FontWeight.w800,
            letterSpacing: -0.5,
          ),
          iconTheme: IconThemeData(color: orange),
        ),
        tabBarTheme: const TabBarTheme(
          labelColor: orange,
          unselectedLabelColor: muted,
          indicatorColor: orange,
          labelStyle: TextStyle(fontWeight: FontWeight.w700, fontSize: 13),
          unselectedLabelStyle: TextStyle(fontWeight: FontWeight.w600, fontSize: 13),
        ),
        cardTheme: CardTheme(
          color: surface,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          elevation: 0,
        ),
        switchTheme: SwitchThemeData(
          thumbColor: WidgetStateProperty.resolveWith((states) {
            if (states.contains(WidgetState.selected)) return Colors.white;
            return muted;
          }),
          trackColor: WidgetStateProperty.resolveWith((states) {
            if (states.contains(WidgetState.selected)) return green;
            return surface2;
          }),
        ),
        textTheme: const TextTheme(
          bodyLarge: TextStyle(color: textColor),
          bodyMedium: TextStyle(color: textColor),
          bodySmall: TextStyle(color: muted),
        ),
      );
}
