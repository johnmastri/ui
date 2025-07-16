import 'parameter.dart';

enum DisplayMode {
  vuMeter,
  knobs,
}

enum ConnectionStatus {
  connecting,
  connected,
  disconnected,
  reconnecting,
}

class DisplayState {
  final DisplayMode currentMode;
  final bool showParameterOverlay;
  final Parameter? overlayParameter;
  final DateTime? overlayStartTime;
  final int currentKnobPage;
  final int totalKnobPages;

  const DisplayState({
    this.currentMode = DisplayMode.vuMeter,
    this.showParameterOverlay = false,
    this.overlayParameter,
    this.overlayStartTime,
    this.currentKnobPage = 0,
    this.totalKnobPages = 1,
  });

  DisplayState copyWith({
    DisplayMode? currentMode,
    bool? showParameterOverlay,
    Parameter? overlayParameter,
    DateTime? overlayStartTime,
    int? currentKnobPage,
    int? totalKnobPages,
  }) {
    return DisplayState(
      currentMode: currentMode ?? this.currentMode,
      showParameterOverlay: showParameterOverlay ?? this.showParameterOverlay,
      overlayParameter: overlayParameter ?? this.overlayParameter,
      overlayStartTime: overlayStartTime ?? this.overlayStartTime,
      currentKnobPage: currentKnobPage ?? this.currentKnobPage,
      totalKnobPages: totalKnobPages ?? this.totalKnobPages,
    );
  }

  bool get isVuMeterMode => currentMode == DisplayMode.vuMeter;
  bool get isKnobsMode => currentMode == DisplayMode.knobs;
  bool get hasOverlay => showParameterOverlay && overlayParameter != null;
  bool get canSwipeLeft => currentKnobPage > 0;
  bool get canSwipeRight => currentKnobPage < totalKnobPages - 1;

  @override
  String toString() {
    return 'DisplayState(currentMode: $currentMode, showParameterOverlay: $showParameterOverlay, overlayParameter: ${overlayParameter?.name}, currentKnobPage: $currentKnobPage/$totalKnobPages)';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is DisplayState &&
        other.currentMode == currentMode &&
        other.showParameterOverlay == showParameterOverlay &&
        other.overlayParameter == overlayParameter &&
        other.overlayStartTime == overlayStartTime &&
        other.currentKnobPage == currentKnobPage &&
        other.totalKnobPages == totalKnobPages;
  }

  @override
  int get hashCode {
    return Object.hash(
      currentMode,
      showParameterOverlay,
      overlayParameter,
      overlayStartTime,
      currentKnobPage,
      totalKnobPages,
    );
  }
}

class WebSocketConnectionState {
  final ConnectionStatus status;
  final String url;
  final DateTime? lastPing;
  final DateTime? lastSend;
  final DateTime? lastReceive;
  final int reconnectAttempts;
  final int maxReconnectAttempts;
  final int reconnectDelay;
  final String? errorMessage;

  const WebSocketConnectionState({
    this.status = ConnectionStatus.disconnected,
    this.url = '',
    this.lastPing,
    this.lastSend,
    this.lastReceive,
    this.reconnectAttempts = 0,
    this.maxReconnectAttempts = 10,
    this.reconnectDelay = 1000,
    this.errorMessage,
  });

  WebSocketConnectionState copyWith({
    ConnectionStatus? status,
    String? url,
    DateTime? lastPing,
    DateTime? lastSend,
    DateTime? lastReceive,
    int? reconnectAttempts,
    int? maxReconnectAttempts,
    int? reconnectDelay,
    String? errorMessage,
  }) {
    return WebSocketConnectionState(
      status: status ?? this.status,
      url: url ?? this.url,
      lastPing: lastPing ?? this.lastPing,
      lastSend: lastSend ?? this.lastSend,
      lastReceive: lastReceive ?? this.lastReceive,
      reconnectAttempts: reconnectAttempts ?? this.reconnectAttempts,
      maxReconnectAttempts: maxReconnectAttempts ?? this.maxReconnectAttempts,
      reconnectDelay: reconnectDelay ?? this.reconnectDelay,
      errorMessage: errorMessage ?? this.errorMessage,
    );
  }

  bool get isConnected => status == ConnectionStatus.connected;
  bool get isConnecting => status == ConnectionStatus.connecting;
  bool get isDisconnected => status == ConnectionStatus.disconnected;
  bool get isReconnecting => status == ConnectionStatus.reconnecting;

  bool get hasRecentSend {
    if (lastSend == null) return false;
    return DateTime.now().difference(lastSend!).inSeconds < 2;
  }

  bool get hasRecentReceive {
    if (lastReceive == null) return false;
    return DateTime.now().difference(lastReceive!).inSeconds < 2;
  }

  String get statusText {
    switch (status) {
      case ConnectionStatus.connecting:
        return 'Connecting...';
      case ConnectionStatus.connected:
        return 'Connected';
      case ConnectionStatus.disconnected:
        return 'Disconnected';
      case ConnectionStatus.reconnecting:
        return 'Reconnecting...';
    }
  }

  @override
  String toString() {
    return 'WebSocketConnectionState(status: $status, url: $url, reconnectAttempts: $reconnectAttempts)';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is WebSocketConnectionState &&
        other.status == status &&
        other.url == url &&
        other.lastPing == lastPing &&
        other.lastSend == lastSend &&
        other.lastReceive == lastReceive &&
        other.reconnectAttempts == reconnectAttempts &&
        other.maxReconnectAttempts == maxReconnectAttempts &&
        other.reconnectDelay == reconnectDelay &&
        other.errorMessage == errorMessage;
  }

  @override
  int get hashCode {
    return Object.hash(
      status,
      url,
      lastPing,
      lastSend,
      lastReceive,
      reconnectAttempts,
      maxReconnectAttempts,
      reconnectDelay,
      errorMessage,
    );
  }
}

class ServerInfo {
  final String id;
  final String name;
  final String url;
  final bool isDefault;

  const ServerInfo({
    required this.id,
    required this.name,
    required this.url,
    this.isDefault = false,
  });

  @override
  String toString() => 'ServerInfo(id: $id, name: $name, url: $url, isDefault: $isDefault)';

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is ServerInfo &&
        other.id == id &&
        other.name == name &&
        other.url == url &&
        other.isDefault == isDefault;
  }

  @override
  int get hashCode => Object.hash(id, name, url, isDefault);
} 