import 'dart:async';
import 'package:flutter/material.dart';
import '../models/display_state.dart';
import '../models/parameter.dart';
import 'settings_store.dart';

class DisplayStore extends ChangeNotifier {
  final SettingsStore _settingsStore;
  
  DisplayState _state = const DisplayState();
  Timer? _overlayTimer;
  Timer? _debounceTimer;
  
  static const int _debounceDelayMs = 150;

  DisplayStore(this._settingsStore);

  // Getters
  DisplayState get state => _state;
  DisplayMode get currentMode => _state.currentMode;
  bool get isVuMeterMode => _state.isVuMeterMode;
  bool get isKnobsMode => _state.isKnobsMode;
  bool get showParameterOverlay => _state.showParameterOverlay;
  Parameter? get overlayParameter => _state.overlayParameter;
  int get currentKnobPage => _state.currentKnobPage;
  int get totalKnobPages => _state.totalKnobPages;
  bool get canSwipeLeft => _state.canSwipeLeft;
  bool get canSwipeRight => _state.canSwipeRight;
  bool get hasOverlay => _state.hasOverlay;

  // View management
  void switchToVuMeter() {
    if (_state.currentMode == DisplayMode.vuMeter) return;
    
    _hideParameterOverlay();
    _state = _state.copyWith(currentMode: DisplayMode.vuMeter);
    notifyListeners();
  }

  void switchToKnobs() {
    if (_state.currentMode == DisplayMode.knobs) return;
    
    _hideParameterOverlay();
    _state = _state.copyWith(currentMode: DisplayMode.knobs);
    notifyListeners();
  }

  void toggleView() {
    if (_state.currentMode == DisplayMode.vuMeter) {
      switchToKnobs();
    } else {
      switchToVuMeter();
    }
  }

  // Knob page management
  void setKnobPage(int page) {
    if (page < 0 || page >= _state.totalKnobPages) return;
    
    _state = _state.copyWith(currentKnobPage: page);
    notifyListeners();
  }

  void nextKnobPage() {
    if (_state.canSwipeRight) {
      setKnobPage(_state.currentKnobPage + 1);
    }
  }

  void previousKnobPage() {
    if (_state.canSwipeLeft) {
      setKnobPage(_state.currentKnobPage - 1);
    }
  }

  void setTotalKnobPages(int total) {
    if (total < 1) return;
    
    _state = _state.copyWith(totalKnobPages: total);
    
    // Adjust current page if it's now out of bounds
    if (_state.currentKnobPage >= total) {
      _state = _state.copyWith(currentKnobPage: total - 1);
    }
    
    notifyListeners();
  }

  // Parameter overlay management
  void _showParameterOverlay(Parameter parameter) {
    // Only show overlay in VU meter mode
    if (_state.currentMode != DisplayMode.vuMeter) return;
    
    // Only show if large display is enabled
    if (!_settingsStore.isLargeDisplayEnabled) return;
    
    _clearTimers();
    
    _state = _state.copyWith(
      showParameterOverlay: true,
      overlayParameter: parameter,
      overlayStartTime: DateTime.now(),
    );
    
    notifyListeners();
  }

  void _hideParameterOverlay() {
    if (!_state.showParameterOverlay) return;
    
    _clearTimers();
    
    _state = _state.copyWith(
      showParameterOverlay: false,
      overlayParameter: null,
      overlayStartTime: null,
    );
    
    notifyListeners();
  }

  void hideParameterOverlay() {
    _hideParameterOverlay();
  }

  // Parameter change handling with debounce
  void onParameterChanged(Parameter parameter) {
    // Clear existing timers
    _clearTimers();
    
    // Show overlay immediately
    _showParameterOverlay(parameter);
    
    // Start debounce timer
    _debounceTimer = Timer(
      Duration(milliseconds: _debounceDelayMs),
      _startFadeTimer,
    );
  }

  void _startFadeTimer() {
    if (!_state.showParameterOverlay) return;
    
    _clearOverlayTimer();
    
    _overlayTimer = Timer(
      Duration(milliseconds: _settingsStore.fadeDelayMs),
      _hideParameterOverlay,
    );
  }

  void _clearTimers() {
    _clearOverlayTimer();
    _clearDebounceTimer();
  }

  void _clearOverlayTimer() {
    _overlayTimer?.cancel();
    _overlayTimer = null;
  }

  void _clearDebounceTimer() {
    _debounceTimer?.cancel();
    _debounceTimer = null;
  }

  // Manual overlay control
  void extendOverlayTime() {
    if (!_state.showParameterOverlay) return;
    
    _startFadeTimer();
  }

  void resetOverlayTime() {
    if (!_state.showParameterOverlay) return;
    
    _state = _state.copyWith(overlayStartTime: DateTime.now());
    _startFadeTimer();
    notifyListeners();
  }

  // State management
  void resetState() {
    _clearTimers();
    _state = const DisplayState();
    notifyListeners();
  }

  // Overlay duration helpers
  Duration? get overlayDuration {
    if (_state.overlayStartTime == null) return null;
    return DateTime.now().difference(_state.overlayStartTime!);
  }

  double get overlayProgress {
    if (_state.overlayStartTime == null) return 0.0;
    
    final elapsed = DateTime.now().difference(_state.overlayStartTime!);
    final total = Duration(milliseconds: _settingsStore.fadeDelayMs);
    
    return (elapsed.inMilliseconds / total.inMilliseconds).clamp(0.0, 1.0);
  }

  int get overlayRemainingMs {
    if (_state.overlayStartTime == null) return 0;
    
    final elapsed = DateTime.now().difference(_state.overlayStartTime!);
    final total = Duration(milliseconds: _settingsStore.fadeDelayMs);
    final remaining = total - elapsed;
    
    return remaining.inMilliseconds.clamp(0, _settingsStore.fadeDelayMs);
  }

  // Debug helpers
  String get debugInfo {
    return '''
DisplayStore Debug Info:
- Current Mode: ${_state.currentMode}
- Show Overlay: ${_state.showParameterOverlay}
- Overlay Parameter: ${_state.overlayParameter?.name ?? 'None'}
- Knob Page: ${_state.currentKnobPage}/${_state.totalKnobPages}
- Overlay Timer Active: ${_overlayTimer != null}
- Debounce Timer Active: ${_debounceTimer != null}
- Overlay Duration: ${overlayDuration?.inMilliseconds ?? 0}ms
- Overlay Progress: ${(overlayProgress * 100).toInt()}%
- Remaining Time: ${overlayRemainingMs}ms
''';
  }

  @override
  void dispose() {
    _clearTimers();
    super.dispose();
  }
} 