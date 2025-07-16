import 'package:flutter/material.dart';

enum AppTheme {
  dark,
  light,
  vintage,
}

class ThemeManager {
  static final Map<AppTheme, ThemeData> _themes = {
    AppTheme.dark: _darkTheme,
    AppTheme.light: _lightTheme,
    AppTheme.vintage: _vintageTheme,
  };

  static ThemeData getTheme(AppTheme theme) {
    return _themes[theme] ?? _darkTheme;
  }

  static final ThemeData _darkTheme = ThemeData(
    useMaterial3: true,
    brightness: Brightness.dark,
    colorScheme: ColorScheme.dark(
      primary: Color(0xFF00FFFF), // Cyan accent
      secondary: Color(0xFF2196F3), // Blue accent
      surface: Color(0xFF1A1A1A), // Dark surface
      background: Color(0xFF0D0D0D), // Darker background
      onSurface: Color(0xFFFFFFFF), // White text
      onBackground: Color(0xFFFFFFFF), // White text
      error: Color(0xFFFF5252), // Red error
    ),
    scaffoldBackgroundColor: Color(0xFF0D0D0D),
    appBarTheme: AppBarTheme(
      backgroundColor: Color(0xFF1A1A1A),
      foregroundColor: Color(0xFFFFFFFF),
      elevation: 0,
    ),
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        foregroundColor: Color(0xFFFFFFFF),
        backgroundColor: Color(0xFF333333),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
        ),
      ),
    ),
    textTheme: TextTheme(
      headlineLarge: TextStyle(
        color: Color(0xFFFFFFFF),
        fontSize: 32,
        fontWeight: FontWeight.bold,
        fontFamily: 'CourierNew',
      ),
      headlineMedium: TextStyle(
        color: Color(0xFFFFFFFF),
        fontSize: 24,
        fontWeight: FontWeight.w600,
        fontFamily: 'CourierNew',
      ),
      bodyLarge: TextStyle(
        color: Color(0xFFFFFFFF),
        fontSize: 16,
        fontFamily: 'Roboto',
      ),
      bodyMedium: TextStyle(
        color: Color(0xFFCCCCCC),
        fontSize: 14,
        fontFamily: 'Roboto',
      ),
      bodySmall: TextStyle(
        color: Color(0xFF888888),
        fontSize: 12,
        fontFamily: 'Roboto',
      ),
    ),
    extensions: [
      HardwareControllerThemeExtension(
        knobGradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFF2A2A2A), Color(0xFF1A1A1A)],
        ),
        knobBorderColor: Color(0xFF444444),
        knobIndicatorColor: Color(0xFF00FFFF),
        knobHoverBorderColor: Color(0xFF00FFFF),
        ledRingColor: Color(0xFF00FFFF),
        parameterOverlayBackground: Color(0xFF1A1A1A),
        parameterOverlayText: Color(0xFFFFFFFF),
        parameterNameText: Color(0xFF00FF88),
        vuMeterBackground: Color(0xFF1A1A1A),
        vuMeterNeedleColor: Color(0xFFFF6B6B),
        vuMeterScaleColor: Color(0xFF888888),
        vuMeterRedZoneColor: Color(0xFFFF5252),
        websocketStatusConnected: Color(0xFF4CAF50),
        websocketStatusDisconnected: Color(0xFFFF5252),
        websocketStatusConnecting: Color(0xFFFF9800),
      ),
    ],
  );

  static final ThemeData _lightTheme = ThemeData(
    useMaterial3: true,
    brightness: Brightness.light,
    colorScheme: ColorScheme.light(
      primary: Color(0xFF2196F3), // Blue accent
      secondary: Color(0xFF03DAC6), // Teal accent
      surface: Color(0xFFFFFFFF), // White surface
      background: Color(0xFFF5F5F5), // Light gray background
      onSurface: Color(0xFF000000), // Black text
      onBackground: Color(0xFF000000), // Black text
      error: Color(0xFFD32F2F), // Red error
    ),
    scaffoldBackgroundColor: Color(0xFFF5F5F5),
    appBarTheme: AppBarTheme(
      backgroundColor: Color(0xFFFFFFFF),
      foregroundColor: Color(0xFF000000),
      elevation: 1,
    ),
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        foregroundColor: Color(0xFFFFFFFF),
        backgroundColor: Color(0xFF2196F3),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
        ),
      ),
    ),
    textTheme: TextTheme(
      headlineLarge: TextStyle(
        color: Color(0xFF000000),
        fontSize: 32,
        fontWeight: FontWeight.bold,
        fontFamily: 'CourierNew',
      ),
      headlineMedium: TextStyle(
        color: Color(0xFF000000),
        fontSize: 24,
        fontWeight: FontWeight.w600,
        fontFamily: 'CourierNew',
      ),
      bodyLarge: TextStyle(
        color: Color(0xFF000000),
        fontSize: 16,
        fontFamily: 'Roboto',
      ),
      bodyMedium: TextStyle(
        color: Color(0xFF333333),
        fontSize: 14,
        fontFamily: 'Roboto',
      ),
      bodySmall: TextStyle(
        color: Color(0xFF666666),
        fontSize: 12,
        fontFamily: 'Roboto',
      ),
    ),
    extensions: [
      HardwareControllerThemeExtension(
        knobGradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFFE6E6E6), Color(0xFFFFFFFF)],
        ),
        knobBorderColor: Color(0xFFD0D0D0),
        knobIndicatorColor: Color(0xFF2196F3),
        knobHoverBorderColor: Color(0xFF2196F3),
        ledRingColor: Color(0xFF2196F3),
        parameterOverlayBackground: Color(0xFFFFFFFF),
        parameterOverlayText: Color(0xFF000000),
        parameterNameText: Color(0xFF2196F3),
        vuMeterBackground: Color(0xFFFFFFFF),
        vuMeterNeedleColor: Color(0xFFD32F2F),
        vuMeterScaleColor: Color(0xFF666666),
        vuMeterRedZoneColor: Color(0xFFD32F2F),
        websocketStatusConnected: Color(0xFF4CAF50),
        websocketStatusDisconnected: Color(0xFFD32F2F),
        websocketStatusConnecting: Color(0xFFFF9800),
      ),
    ],
  );

  static final ThemeData _vintageTheme = ThemeData(
    useMaterial3: true,
    brightness: Brightness.dark,
    colorScheme: ColorScheme.dark(
      primary: Color(0xFFFFD700), // Gold accent
      secondary: Color(0xFFFF8C00), // Orange accent
      surface: Color(0xFF2E2E2E), // Vintage surface
      background: Color(0xFF1E1E1E), // Dark vintage background
      onSurface: Color(0xFFE0E0E0), // Warm white text
      onBackground: Color(0xFFE0E0E0), // Warm white text
      error: Color(0xFFFF6B6B), // Vintage red error
    ),
    scaffoldBackgroundColor: Color(0xFF1E1E1E),
    appBarTheme: AppBarTheme(
      backgroundColor: Color(0xFF2E2E2E),
      foregroundColor: Color(0xFFE0E0E0),
      elevation: 0,
    ),
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        foregroundColor: Color(0xFF1E1E1E),
        backgroundColor: Color(0xFFFFD700),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
        ),
      ),
    ),
    textTheme: TextTheme(
      headlineLarge: TextStyle(
        color: Color(0xFFE0E0E0),
        fontSize: 32,
        fontWeight: FontWeight.bold,
        fontFamily: 'CourierNew',
      ),
      headlineMedium: TextStyle(
        color: Color(0xFFE0E0E0),
        fontSize: 24,
        fontWeight: FontWeight.w600,
        fontFamily: 'CourierNew',
      ),
      bodyLarge: TextStyle(
        color: Color(0xFFE0E0E0),
        fontSize: 16,
        fontFamily: 'Roboto',
      ),
      bodyMedium: TextStyle(
        color: Color(0xFFBBBBBB),
        fontSize: 14,
        fontFamily: 'Roboto',
      ),
      bodySmall: TextStyle(
        color: Color(0xFF999999),
        fontSize: 12,
        fontFamily: 'Roboto',
      ),
    ),
    extensions: [
      HardwareControllerThemeExtension(
        knobGradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFF4A4A4A), Color(0xFF2E2E2E)],
        ),
        knobBorderColor: Color(0xFF666666),
        knobIndicatorColor: Color(0xFFFFD700),
        knobHoverBorderColor: Color(0xFFFFD700),
        ledRingColor: Color(0xFFFFD700),
        parameterOverlayBackground: Color(0xFF2E2E2E),
        parameterOverlayText: Color(0xFFE0E0E0),
        parameterNameText: Color(0xFFFFD700),
        vuMeterBackground: Color(0xFF2E2E2E),
        vuMeterNeedleColor: Color(0xFFFF6B6B),
        vuMeterScaleColor: Color(0xFF999999),
        vuMeterRedZoneColor: Color(0xFFFF6B6B),
        websocketStatusConnected: Color(0xFF4CAF50),
        websocketStatusDisconnected: Color(0xFFFF6B6B),
        websocketStatusConnecting: Color(0xFFFF8C00),
      ),
    ],
  );
}

class HardwareControllerThemeExtension extends ThemeExtension<HardwareControllerThemeExtension> {
  final Gradient knobGradient;
  final Color knobBorderColor;
  final Color knobIndicatorColor;
  final Color knobHoverBorderColor;
  final Color ledRingColor;
  final Color parameterOverlayBackground;
  final Color parameterOverlayText;
  final Color parameterNameText;
  final Color vuMeterBackground;
  final Color vuMeterNeedleColor;
  final Color vuMeterScaleColor;
  final Color vuMeterRedZoneColor;
  final Color websocketStatusConnected;
  final Color websocketStatusDisconnected;
  final Color websocketStatusConnecting;

  const HardwareControllerThemeExtension({
    required this.knobGradient,
    required this.knobBorderColor,
    required this.knobIndicatorColor,
    required this.knobHoverBorderColor,
    required this.ledRingColor,
    required this.parameterOverlayBackground,
    required this.parameterOverlayText,
    required this.parameterNameText,
    required this.vuMeterBackground,
    required this.vuMeterNeedleColor,
    required this.vuMeterScaleColor,
    required this.vuMeterRedZoneColor,
    required this.websocketStatusConnected,
    required this.websocketStatusDisconnected,
    required this.websocketStatusConnecting,
  });

  @override
  ThemeExtension<HardwareControllerThemeExtension> copyWith({
    Gradient? knobGradient,
    Color? knobBorderColor,
    Color? knobIndicatorColor,
    Color? knobHoverBorderColor,
    Color? ledRingColor,
    Color? parameterOverlayBackground,
    Color? parameterOverlayText,
    Color? parameterNameText,
    Color? vuMeterBackground,
    Color? vuMeterNeedleColor,
    Color? vuMeterScaleColor,
    Color? vuMeterRedZoneColor,
    Color? websocketStatusConnected,
    Color? websocketStatusDisconnected,
    Color? websocketStatusConnecting,
  }) {
    return HardwareControllerThemeExtension(
      knobGradient: knobGradient ?? this.knobGradient,
      knobBorderColor: knobBorderColor ?? this.knobBorderColor,
      knobIndicatorColor: knobIndicatorColor ?? this.knobIndicatorColor,
      knobHoverBorderColor: knobHoverBorderColor ?? this.knobHoverBorderColor,
      ledRingColor: ledRingColor ?? this.ledRingColor,
      parameterOverlayBackground: parameterOverlayBackground ?? this.parameterOverlayBackground,
      parameterOverlayText: parameterOverlayText ?? this.parameterOverlayText,
      parameterNameText: parameterNameText ?? this.parameterNameText,
      vuMeterBackground: vuMeterBackground ?? this.vuMeterBackground,
      vuMeterNeedleColor: vuMeterNeedleColor ?? this.vuMeterNeedleColor,
      vuMeterScaleColor: vuMeterScaleColor ?? this.vuMeterScaleColor,
      vuMeterRedZoneColor: vuMeterRedZoneColor ?? this.vuMeterRedZoneColor,
      websocketStatusConnected: websocketStatusConnected ?? this.websocketStatusConnected,
      websocketStatusDisconnected: websocketStatusDisconnected ?? this.websocketStatusDisconnected,
      websocketStatusConnecting: websocketStatusConnecting ?? this.websocketStatusConnecting,
    );
  }

  @override
  ThemeExtension<HardwareControllerThemeExtension> lerp(
    ThemeExtension<HardwareControllerThemeExtension>? other,
    double t,
  ) {
    if (other is! HardwareControllerThemeExtension) {
      return this;
    }
    return HardwareControllerThemeExtension(
      knobGradient: Gradient.lerp(knobGradient, other.knobGradient, t) ?? knobGradient,
      knobBorderColor: Color.lerp(knobBorderColor, other.knobBorderColor, t) ?? knobBorderColor,
      knobIndicatorColor: Color.lerp(knobIndicatorColor, other.knobIndicatorColor, t) ?? knobIndicatorColor,
      knobHoverBorderColor: Color.lerp(knobHoverBorderColor, other.knobHoverBorderColor, t) ?? knobHoverBorderColor,
      ledRingColor: Color.lerp(ledRingColor, other.ledRingColor, t) ?? ledRingColor,
      parameterOverlayBackground: Color.lerp(parameterOverlayBackground, other.parameterOverlayBackground, t) ?? parameterOverlayBackground,
      parameterOverlayText: Color.lerp(parameterOverlayText, other.parameterOverlayText, t) ?? parameterOverlayText,
      parameterNameText: Color.lerp(parameterNameText, other.parameterNameText, t) ?? parameterNameText,
      vuMeterBackground: Color.lerp(vuMeterBackground, other.vuMeterBackground, t) ?? vuMeterBackground,
      vuMeterNeedleColor: Color.lerp(vuMeterNeedleColor, other.vuMeterNeedleColor, t) ?? vuMeterNeedleColor,
      vuMeterScaleColor: Color.lerp(vuMeterScaleColor, other.vuMeterScaleColor, t) ?? vuMeterScaleColor,
      vuMeterRedZoneColor: Color.lerp(vuMeterRedZoneColor, other.vuMeterRedZoneColor, t) ?? vuMeterRedZoneColor,
      websocketStatusConnected: Color.lerp(websocketStatusConnected, other.websocketStatusConnected, t) ?? websocketStatusConnected,
      websocketStatusDisconnected: Color.lerp(websocketStatusDisconnected, other.websocketStatusDisconnected, t) ?? websocketStatusDisconnected,
      websocketStatusConnecting: Color.lerp(websocketStatusConnecting, other.websocketStatusConnecting, t) ?? websocketStatusConnecting,
    );
  }
} 