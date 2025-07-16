import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:web_socket_channel/web_socket_channel.dart';
import '../models/display_state.dart';
import '../models/websocket_message.dart';
import '../models/parameter.dart';
import 'parameter_store.dart';

class WebSocketStore extends ChangeNotifier {
  final ParameterStore _parameterStore;
  
  WebSocketChannel? _channel;
  WebSocketConnectionState _connectionState = const WebSocketConnectionState();
  Timer? _reconnectTimer;
  Timer? _pingTimer;
  StreamSubscription? _messageSubscription;
  
  // Server configuration
  static const List<ServerInfo> _availableServers = [
    ServerInfo(
      id: 'localhost',
      name: 'Local',
      url: 'ws://localhost:8765',
      isDefault: true,
    ),
    ServerInfo(
      id: 'pi',
      name: 'Pi Bridge',
      url: 'ws://192.168.1.5:8765',
    ),
  ];
  
  String _selectedServerId = 'localhost';
  int _currentServerIndex = 0;
  
  // Activity tracking
  DateTime? _lastSendTime;
  DateTime? _lastReceiveTime;

  WebSocketStore(this._parameterStore) {
    // Set up parameter store WebSocket callback (like Vue.js broadcastValueUpdate)
    _parameterStore.setSendWebSocketMessage(sendMessage);
  }

  // Getters
  WebSocketConnectionState get connectionState => _connectionState;
  bool get isConnected => _connectionState.isConnected;
  bool get isConnecting => _connectionState.isConnecting;
  bool get isDisconnected => _connectionState.isDisconnected;
  bool get isReconnecting => _connectionState.isReconnecting;
  String get serverUrl => _connectionState.url;
  String get connectionStatus => _connectionState.statusText;
  List<ServerInfo> get availableServers => _availableServers;
  String get selectedServerId => _selectedServerId;
  bool get hasRecentSend => _connectionState.hasRecentSend;
  bool get hasRecentReceive => _connectionState.hasRecentReceive;
  
  ServerInfo get currentServer {
    return _availableServers.firstWhere(
      (s) => s.id == _selectedServerId,
      orElse: () => _availableServers.first,
    );
  }

  // Connection management
  Future<void> connect([String? serverId]) async {
    if (_connectionState.isConnected || _connectionState.isConnecting) return;
    
    if (serverId != null) {
      _selectedServerId = serverId;
    }
    
    final server = currentServer;
    
    _updateConnectionState(
      _connectionState.copyWith(
        status: ConnectionStatus.connecting,
        url: server.url,
        reconnectAttempts: 0,
      ),
    );
    
    try {
      _channel = WebSocketChannel.connect(
        Uri.parse(server.url),
      );
      
      _messageSubscription = _channel!.stream.listen(
        _onMessage,
        onError: _onError,
        onDone: _onDisconnected,
      );
      
      _updateConnectionState(
        _connectionState.copyWith(
          status: ConnectionStatus.connected,
          lastPing: DateTime.now(),
        ),
      );
      
      _startPingTimer();
      await _requestParameterState();
      
      debugPrint('Connected to WebSocket: ${server.url}');
      
    } catch (e) {
      debugPrint('WebSocket connection failed: $e');
      _updateConnectionState(
        _connectionState.copyWith(
          status: ConnectionStatus.disconnected,
          errorMessage: e.toString(),
        ),
      );
      
      _scheduleReconnect();
    }
  }

  Future<void> disconnect() async {
    _stopReconnectTimer();
    _stopPingTimer();
    
    await _messageSubscription?.cancel();
    _messageSubscription = null;
    
    await _channel?.sink.close();
    _channel = null;
    
    _updateConnectionState(
      _connectionState.copyWith(
        status: ConnectionStatus.disconnected,
        errorMessage: null,
      ),
    );
    
    debugPrint('Disconnected from WebSocket');
  }

  Future<void> reconnect() async {
    await disconnect();
    await connect();
  }

  // Server selection
  Future<void> selectServer(String serverId) async {
    if (_selectedServerId == serverId) return;
    
    _selectedServerId = serverId;
    
    if (_connectionState.isConnected) {
      await reconnect();
    }
  }

  // Message handling
  void _onMessage(dynamic message) {
    _lastReceiveTime = DateTime.now();
    _updateConnectionState(
      _connectionState.copyWith(lastReceive: _lastReceiveTime),
    );
    
    try {
      final Map<String, dynamic> data = jsonDecode(message as String);
      debugPrint('Received WebSocket message: ${data['type']}');
      
      final wsMessage = WebSocketMessage.fromJson(data);
      _handleWebSocketMessage(wsMessage);
      
    } catch (e) {
      debugPrint('Error parsing WebSocket message: $e');
      debugPrint('Raw message: $message');
      
      // Try to extract message type for debugging
      try {
        final Map<String, dynamic> data = jsonDecode(message as String);
        debugPrint('Message type: ${data['type']}');
        debugPrint('Message data: ${data['data']}');
      } catch (e2) {
        debugPrint('Could not parse message for debugging: $e2');
      }
    }
  }

  void _handleWebSocketMessage(WebSocketMessage message) {
    switch (message.type) {
      case 'parameter_structure_sync':
        _parameterStore.updateParameterStructure(message as ParameterStructureSync);
        break;
        
      case 'parameter_value_sync':
        // Use new method that handles updates array (with shouldBroadcast = false to prevent loops)
        _parameterStore.updateParametersFromMessage(message as ParameterValueSync);
        break;
        
      case 'parameter_color_sync':
        final colorSync = message as ParameterColorSync;
        // Handle color updates array like Vue.js
        for (final update in colorSync.updates) {
          if (update.rgbColor != null) {
            final color = ParameterColor(
              r: update.rgbColor!['r'] ?? 128,
              g: update.rgbColor!['g'] ?? 128,
              b: update.rgbColor!['b'] ?? 128,
            );
            _parameterStore.updateParameterColor(update.id, color);
          }
        }
        break;
        
      case 'batch_parameter_update':
        _parameterStore.updateParametersFromBatch(message as BatchParameterUpdate);
        break;
        
      case 'led_update':
        // Handle LED update (if needed)
        break;
        
      case 'system':
        _handleSystemMessage(message as SystemMessage);
        break;
        
      default:
        debugPrint('Unknown WebSocket message type: ${message.type}');
    }
  }

  void _handleSystemMessage(SystemMessage message) {
    switch (message.command) {
      case 'pong':
        _updateConnectionState(
          _connectionState.copyWith(lastPing: DateTime.now()),
        );
        break;
        
      case 'error':
        debugPrint('Server error: ${message.message}');
        _updateConnectionState(
          _connectionState.copyWith(errorMessage: message.message),
        );
        break;
        
      default:
        debugPrint('System message: ${message.command} - ${message.message}');
    }
  }

  void _onError(error) {
    debugPrint('WebSocket error: $error');
    _updateConnectionState(
      _connectionState.copyWith(
        status: ConnectionStatus.disconnected,
        errorMessage: error.toString(),
      ),
    );
    
    _scheduleReconnect();
  }

  void _onDisconnected() {
    debugPrint('WebSocket disconnected');
    _updateConnectionState(
      _connectionState.copyWith(
        status: ConnectionStatus.disconnected,
      ),
    );
    
    _scheduleReconnect();
  }

  // Message sending
  Future<void> sendMessage(WebSocketMessage message) async {
    if (!_connectionState.isConnected) return;
    
    try {
      final jsonString = message.toJsonString();
      _channel?.sink.add(jsonString);
      
      _lastSendTime = DateTime.now();
      _updateConnectionState(
        _connectionState.copyWith(lastSend: _lastSendTime),
      );
      
    } catch (e) {
      debugPrint('Error sending WebSocket message: $e');
    }
  }

  // Convenience methods for common messages  
  Future<void> sendParameterUpdate(String id, double value) async {
    final parameter = _parameterStore.getParameterById(id);
    if (parameter == null) return;
    
    final message = ParameterValueSync(
      updates: [
        ParameterValueUpdate(
          id: id,
          value: value,
          text: parameter.text,
          rgbColor: {
            'r': parameter.color.r,
            'g': parameter.color.g,
            'b': parameter.color.b,
          },
        ),
      ],
    );
    
    await sendMessage(message);
  }

  Future<void> sendParameterColorUpdate(String id, ParameterColor color) async {
    final message = ParameterColorSync(
      updates: [
        ParameterColorUpdate(
          id: id,
          rgbColor: {
            'r': color.r,
            'g': color.g,
            'b': color.b,
          },
        ),
      ],
    );
    await sendMessage(message);
  }

  Future<void> _requestParameterState() async {
    final message = RequestParameterState(
      parameterIds: ['all'],
      includeStructure: true,
    );
    await sendMessage(message);
  }

  Future<void> sendPing() async {
    final message = SystemMessage(command: 'ping');
    await sendMessage(message);
  }

  // Reconnection logic
  void _scheduleReconnect() {
    if (_connectionState.reconnectAttempts >= _connectionState.maxReconnectAttempts) {
      debugPrint('Max reconnection attempts reached');
      return;
    }
    
    _stopReconnectTimer();
    
    final delay = _calculateReconnectDelay();
    
    _updateConnectionState(
      _connectionState.copyWith(
        status: ConnectionStatus.reconnecting,
        reconnectAttempts: _connectionState.reconnectAttempts + 1,
        reconnectDelay: delay,
      ),
    );
    
    _reconnectTimer = Timer(Duration(milliseconds: delay), () {
      _tryNextServer();
    });
  }

  void _tryNextServer() {
    _currentServerIndex = (_currentServerIndex + 1) % _availableServers.length;
    final nextServer = _availableServers[_currentServerIndex];
    
    debugPrint('Trying next server: ${nextServer.name}');
    connect(nextServer.id);
  }

  int _calculateReconnectDelay() {
    final baseDelay = 1000; // 1 second
    final maxDelay = 30000; // 30 seconds
    final attempts = _connectionState.reconnectAttempts;
    
    // Exponential backoff: 1s, 2s, 4s, 8s, 16s, 30s (max)
    final delay = (baseDelay * (1 << attempts)).clamp(baseDelay, maxDelay);
    return delay;
  }

  void _stopReconnectTimer() {
    _reconnectTimer?.cancel();
    _reconnectTimer = null;
  }

  // Ping timer
  void _startPingTimer() {
    _stopPingTimer();
    _pingTimer = Timer.periodic(
      const Duration(seconds: 10),
      (_) => sendPing(),
    );
  }

  void _stopPingTimer() {
    _pingTimer?.cancel();
    _pingTimer = null;
  }

  // State management
  void _updateConnectionState(WebSocketConnectionState newState) {
    _connectionState = newState;
    notifyListeners();
  }

  // Initialize with automatic connection
  Future<void> initialize() async {
    // Try to connect to the default server
    await connect();
  }

  // Debug helpers
  String get debugInfo {
    return '''
WebSocketStore Debug Info:
- Status: ${_connectionState.status}
- URL: ${_connectionState.url}
- Reconnect Attempts: ${_connectionState.reconnectAttempts}/${_connectionState.maxReconnectAttempts}
- Last Ping: ${_connectionState.lastPing}
- Last Send: ${_connectionState.lastSend}
- Last Receive: ${_connectionState.lastReceive}
- Selected Server: $_selectedServerId
- Current Server Index: $_currentServerIndex
- Error: ${_connectionState.errorMessage ?? 'None'}
''';
  }

  @override
  void dispose() {
    _stopReconnectTimer();
    _stopPingTimer();
    disconnect();
    super.dispose();
  }
} 