import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'package:lunasea/core.dart';
import 'package:lunasea/widgets/ui/homelabarr_themes.dart';

class LunaTheme {
  /// Initialize the theme by setting the system navigation and system colours.
  void initialize() {
    //Set system UI overlay style (navbar, statusbar)
    SystemChrome.setSystemUIOverlayStyle(overlayStyle);
  }

  /// Returns the active [ThemeData] by checking the theme database value.
  ThemeData activeTheme() {
    return isAMOLEDTheme ? _pureBlackTheme() : _midnightTheme();
  }

  static bool get isAMOLEDTheme => LunaSeaDatabase.THEME_AMOLED.read();
  static bool get useBorders => LunaSeaDatabase.THEME_AMOLED_BORDER.read();

  /// Midnight theme (Default — dynamic Homelabarr palette)
  ThemeData _midnightTheme() {
    final t = HomelabarrTheme.current;
    return ThemeData(
      useMaterial3: false,
      brightness: Brightness.dark,
      canvasColor: t.primary,
      primaryColor: t.secondary,
      highlightColor: t.accent.withOpacity(LunaUI.OPACITY_SPLASH / 2),
      cardColor: t.secondary,
      hoverColor: t.accent.withOpacity(LunaUI.OPACITY_SPLASH / 2),
      splashColor: t.accent.withOpacity(LunaUI.OPACITY_SPLASH),
      dialogTheme: DialogThemeData(
        backgroundColor: t.secondary,
      ),
      iconTheme: IconThemeData(
        color: t.white,
      ),
      tooltipTheme: TooltipThemeData(
        decoration: BoxDecoration(
          color: t.secondary,
          borderRadius: const BorderRadius.all(Radius.circular(LunaUI.BORDER_RADIUS)),
        ),
        textStyle: TextStyle(
          color: t.grey,
          fontSize: LunaUI.FONT_SIZE_SUBHEADER,
        ),
        preferBelow: true,
      ),
      unselectedWidgetColor: t.white,
      textTheme: _sharedTextTheme,
      textButtonTheme: _sharedTextButtonThemeData,
      visualDensity: VisualDensity.adaptivePlatformDensity,
    );
  }

  /// AMOLED/Pure black theme
  ThemeData _pureBlackTheme() {
    return ThemeData(
      useMaterial3: false,
      brightness: Brightness.dark,
      canvasColor: Colors.black,
      primaryColor: Colors.black,
      highlightColor: LunaColours.accent.withOpacity(LunaUI.OPACITY_SPLASH / 2),
      cardColor: Colors.black,
      hoverColor: LunaColours.accent.withOpacity(LunaUI.OPACITY_SPLASH / 2),
      splashColor: LunaColours.accent.withOpacity(LunaUI.OPACITY_SPLASH),
      dialogTheme: DialogThemeData(
        backgroundColor: Colors.black,
      ),
      iconTheme: const IconThemeData(
        color: LunaColours.white,
      ),
      tooltipTheme: TooltipThemeData(
        decoration: BoxDecoration(
          color: Colors.black,
          borderRadius: const BorderRadius.all(
            Radius.circular(LunaUI.BORDER_RADIUS),
          ),
          border: useBorders ? Border.all(color: LunaColours.white10) : null,
        ),
        textStyle: const TextStyle(
          color: LunaColours.grey,
          fontSize: LunaUI.FONT_SIZE_SUBHEADER,
        ),
        preferBelow: true,
      ),
      unselectedWidgetColor: Colors.white,
      textTheme: _sharedTextTheme,
      textButtonTheme: _sharedTextButtonThemeData,
      visualDensity: VisualDensity.adaptivePlatformDensity,
    );
  }

  SystemUiOverlayStyle get overlayStyle {
    return SystemUiOverlayStyle(
      systemNavigationBarColor: LunaSeaDatabase.THEME_AMOLED.read()
          ? Colors.black
          : LunaColours.secondary,
      systemNavigationBarDividerColor: LunaSeaDatabase.THEME_AMOLED.read()
          ? Colors.black
          : LunaColours.secondary,
      statusBarColor: Colors.transparent,
      systemNavigationBarIconBrightness: Brightness.light,
      statusBarIconBrightness: Brightness.light,
      statusBarBrightness: Brightness.dark,
    );
  }

  TextTheme get _sharedTextTheme {
    const textStyle = TextStyle(color: LunaColours.white);
    return const TextTheme(
      displaySmall: textStyle,
      displayMedium: textStyle,
      displayLarge: textStyle,
      headlineSmall: textStyle,
      headlineMedium: textStyle,
      headlineLarge: textStyle,
      bodySmall: textStyle,
      bodyMedium: textStyle,
      bodyLarge: textStyle,
      titleSmall: textStyle,
      titleMedium: textStyle,
      titleLarge: textStyle,
      labelSmall: textStyle,
      labelMedium: textStyle,
      labelLarge: textStyle,
    );
  }

  TextButtonThemeData get _sharedTextButtonThemeData {
    return TextButtonThemeData(
      style: ButtonStyle(
        overlayColor: MaterialStateProperty.all<Color>(
          LunaColours.accent.withOpacity(LunaUI.OPACITY_SPLASH),
        ),
      ),
    );
  }
}
