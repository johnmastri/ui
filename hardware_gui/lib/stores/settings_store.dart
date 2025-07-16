import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../theme/theme_manager.dart';

class SettingsStore extends ChangeNotifier {
  static const String _themeKey = 'app_theme';
  static const String _fadeDelayKey = 'fade_delay_seconds';
  static const String _isLargeDisplayEnabledKey = 'large_display_enabled';
  static const String _deviceNameKey = 'device_name';
  static const String _channelNameKey = 'channel_name';

  SharedPreferences? _prefs;

  // Theme settings
  AppTheme _currentTheme = AppTheme.dark;
  
  // Display settings
  int _fadeDelaySeconds = 3;
  bool _isLargeDisplayEnabled = true;
  bool _isSettingsPanelOpen = false;
  
  // Device settings
  String _deviceName = 'Hardware Controller';
  String _channelName = 'Channel 1';

  // Getters
  AppTheme get currentTheme => _currentTheme;
  int get fadeDelaySeconds => _fadeDelaySeconds;
  int get fadeDelayMs => _fadeDelaySeconds * 1000;
  bool get isLargeDisplayEnabled => _isLargeDisplayEnabled;
  bool get isSettingsPanelOpen => _isSettingsPanelOpen;
  String get deviceName => _deviceName;
  String get channelName => _channelName;

  ThemeData get themeData => ThemeManager.getTheme(_currentTheme);

  // Initialize settings from shared preferences
  Future<void> initialize() async {
    _prefs = await SharedPreferences.getInstance();
    
    // Load theme
    final themeIndex = _prefs!.getInt(_themeKey) ?? AppTheme.dark.index;
    _currentTheme = AppTheme.values[themeIndex];
    
    // Load display settings
    _fadeDelaySeconds = _prefs!.getInt(_fadeDelayKey) ?? 3;
    _isLargeDisplayEnabled = _prefs!.getBool(_isLargeDisplayEnabledKey) ?? true;
    
    // Load device settings
    _deviceName = _prefs!.getString(_deviceNameKey) ?? 'Hardware Controller';
    _channelName = _prefs!.getString(_channelNameKey) ?? 'Channel 1';
    
    notifyListeners();
  }

  // Theme management
  Future<void> setTheme(AppTheme theme) async {
    if (_currentTheme == theme) return;
    
    _currentTheme = theme;
    await _prefs?.setInt(_themeKey, theme.index);
    notifyListeners();
  }

  Future<void> nextTheme() async {
    final themes = AppTheme.values;
    final currentIndex = themes.indexOf(_currentTheme);
    final nextIndex = (currentIndex + 1) % themes.length;
    await setTheme(themes[nextIndex]);
  }

  // Display settings
  Future<void> setFadeDelay(int seconds) async {
    if (seconds < 1 || seconds > 10) return;
    
    _fadeDelaySeconds = seconds;
    await _prefs?.setInt(_fadeDelayKey, seconds);
    notifyListeners();
  }

  Future<void> toggleLargeDisplay() async {
    _isLargeDisplayEnabled = !_isLargeDisplayEnabled;
    await _prefs?.setBool(_isLargeDisplayEnabledKey, _isLargeDisplayEnabled);
    notifyListeners();
  }

  // Settings panel management
  void openSettingsPanel() {
    _isSettingsPanelOpen = true;
    notifyListeners();
  }

  void closeSettingsPanel() {
    _isSettingsPanelOpen = false;
    notifyListeners();
  }

  // Device settings
  Future<void> setDeviceName(String name) async {
    _deviceName = name;
    await _prefs?.setString(_deviceNameKey, name);
    notifyListeners();
  }

  Future<void> setChannelName(String name) async {
    _channelName = name;
    await _prefs?.setString(_channelNameKey, name);
    notifyListeners();
  }

  // Reset to defaults
  Future<void> resetToDefaults() async {
    _currentTheme = AppTheme.dark;
    _fadeDelaySeconds = 3;
    _isLargeDisplayEnabled = true;
    _deviceName = 'Hardware Controller';
    _channelName = 'Channel 1';
    
    await _prefs?.clear();
    await _prefs?.setInt(_themeKey, _currentTheme.index);
    await _prefs?.setInt(_fadeDelayKey, _fadeDelaySeconds);
    await _prefs?.setBool(_isLargeDisplayEnabledKey, _isLargeDisplayEnabled);
    await _prefs?.setString(_deviceNameKey, _deviceName);
    await _prefs?.setString(_channelNameKey, _channelName);
    
    notifyListeners();
  }

  // Get theme colors for UI components
  Color getThemeColor(String colorName) {
    final extension = themeData.extension<HardwareControllerThemeExtension>();
    if (extension == null) return Colors.grey;

    switch (colorName) {
      case 'knobIndicator':
        return extension.knobIndicatorColor;
      case 'knobBorder':
        return extension.knobBorderColor;
      case 'knobHoverBorder':
        return extension.knobHoverBorderColor;
      case 'ledRing':
        return extension.ledRingColor;
      case 'parameterOverlayBackground':
        return extension.parameterOverlayBackground;
      case 'parameterOverlayText':
        return extension.parameterOverlayText;
      case 'parameterNameText':
        return extension.parameterNameText;
      case 'vuMeterBackground':
        return extension.vuMeterBackground;
      case 'vuMeterNeedle':
        return extension.vuMeterNeedleColor;
      case 'vuMeterScale':
        return extension.vuMeterScaleColor;
      case 'vuMeterRedZone':
        return extension.vuMeterRedZoneColor;
      case 'websocketConnected':
        return extension.websocketStatusConnected;
      case 'websocketDisconnected':
        return extension.websocketStatusDisconnected;
      case 'websocketConnecting':
        return extension.websocketStatusConnecting;
      default:
        return Colors.grey;
    }
  }

  Gradient get knobGradient {
    final extension = themeData.extension<HardwareControllerThemeExtension>();
    return extension?.knobGradient ?? const LinearGradient(
      colors: [Colors.grey, Colors.black],
    );
  }

  @override
  void dispose() {
    super.dispose();
  }
} 