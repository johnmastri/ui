import 'package:flutter/material.dart';
import '../models/parameter.dart';
import '../models/websocket_message.dart';
import 'display_store.dart';

class ParameterStore extends ChangeNotifier {
  final DisplayStore _displayStore;
  
  List<Parameter> _parameters = [];
  String _structureHash = '';
  Map<String, Parameter> _parameterMap = {};
  
  // For tracking parameter changes
  String? _lastChangedParameterId;
  DateTime? _lastChangeTimestamp;

  ParameterStore(this._displayStore);

  // Getters
  List<Parameter> get parameters => List.unmodifiable(_parameters);
  String get structureHash => _structureHash;
  int get parameterCount => _parameters.length;
  bool get hasParameters => _parameters.isNotEmpty;
  String? get lastChangedParameterId => _lastChangedParameterId;
  DateTime? get lastChangeTimestamp => _lastChangeTimestamp;

  // Get parameter by ID
  Parameter? getParameterById(String id) {
    return _parameterMap[id];
  }

  // Get parameter by index
  Parameter? getParameterByIndex(int index) {
    if (index < 0 || index >= _parameters.length) return null;
    return _parameters[index];
  }

  // Get parameters by category
  List<Parameter> getParametersByCategory(String category) {
    return _parameters.where((p) => p.category == category).toList();
  }

  // Get parameters for knob page (8 parameters per page)
  List<Parameter> getParametersForPage(int page) {
    const parametersPerPage = 8;
    final startIndex = page * parametersPerPage;
    final endIndex = (startIndex + parametersPerPage).clamp(0, _parameters.length);
    
    if (startIndex >= _parameters.length) return [];
    
    return _parameters.sublist(startIndex, endIndex);
  }

  // Get total number of knob pages
  int get totalKnobPages {
    const parametersPerPage = 8;
    return (_parameters.length / parametersPerPage).ceil().clamp(1, 100);
  }

  // Update parameter structure from WebSocket
  void updateParameterStructure(ParameterStructureSync message) {
    if (message.structureHash == _structureHash) return;
    
    _structureHash = message.structureHash;
    _parameters = List.from(message.parameters);
    _rebuildParameterMap();
    
    // Update display store with new page count
    _displayStore.setTotalKnobPages(totalKnobPages);
    
    debugPrint('Parameter structure updated: ${_parameters.length} parameters');
    notifyListeners();
  }

  // Update single parameter value
  void updateParameter(String id, double value, {String? text, ParameterColor? color, bool shouldBroadcast = true}) {
    final parameter = _parameterMap[id];
    if (parameter == null) return;
    
    final updatedParameter = parameter.copyWith(
      value: value,
      normalizedValue: value,
      text: text ?? parameter.text,
      color: color ?? parameter.color,
      lastUpdated: DateTime.now(),
    );
    
    _replaceParameter(updatedParameter);
    _trackParameterChange(id);
    
    // Notify display store about the change
    _displayStore.onParameterChanged(updatedParameter);
    
    // Broadcast to WebSocket if this is from UI (like Vue.js)
    if (shouldBroadcast) {
      _broadcastValueUpdate(id, value);
    }
    
    notifyListeners();
  }

  // Update parameters from WebSocket message (handles updates array)
  void updateParametersFromMessage(ParameterValueSync message) {
    for (final update in message.updates) {
      // Update using shouldBroadcast: false to prevent feedback loops (like Vue.js)
      updateParameter(
        update.id, 
        update.value, 
        text: update.text,
        color: ParameterColor(
          r: update.rgbColor['r'] ?? 128,
          g: update.rgbColor['g'] ?? 128,
          b: update.rgbColor['b'] ?? 128,
        ),
        shouldBroadcast: false, // Critical: prevent WebSocket feedback loop
      );
    }
  }

  // Update parameter color
  void updateParameterColor(String id, ParameterColor color) {
    final parameter = _parameterMap[id];
    if (parameter == null) return;
    
    final updatedParameter = parameter.copyWith(
      color: color,
      lastUpdated: DateTime.now(),
    );
    
    _replaceParameter(updatedParameter);
    notifyListeners();
  }

  // Batch update parameters
  void updateParametersFromBatch(BatchParameterUpdate message) {
    bool hasChanges = false;
    
    for (final update in message.updates) {
      final parameter = _parameterMap[update.id];
      if (parameter == null) continue;
      
      final updatedParameter = parameter.copyWith(
        value: update.value,
        normalizedValue: update.value, // Use value for both
        text: update.text,
        color: ParameterColor(
          r: update.rgbColor['r'] ?? 128,
          g: update.rgbColor['g'] ?? 128,
          b: update.rgbColor['b'] ?? 128,
        ),
        lastUpdated: DateTime.now(),
      );
      
      _replaceParameter(updatedParameter);
      _trackParameterChange(update.id);
      hasChanges = true;
    }
    
    if (hasChanges) {
      // For batch updates, show overlay for the last changed parameter
      if (_lastChangedParameterId != null) {
        final lastParameter = _parameterMap[_lastChangedParameterId!];
        if (lastParameter != null) {
          _displayStore.onParameterChanged(lastParameter);
        }
      }
      
      notifyListeners();
    }
  }

  // Add new parameter
  void addParameter(Parameter parameter) {
    if (_parameterMap.containsKey(parameter.id)) {
      updateParametersFromMessage(ParameterValueSync(
        updates: [
          ParameterValueUpdate(
            id: parameter.id,
            value: parameter.value,
            text: parameter.text,
            rgbColor: {
              'r': parameter.color.r,
              'g': parameter.color.g,
              'b': parameter.color.b,
            },
          ),
        ],
      ));
      return;
    }
    
    _parameters.add(parameter);
    _parameterMap[parameter.id] = parameter;
    
    // Update display store with new page count
    _displayStore.setTotalKnobPages(totalKnobPages);
    
    notifyListeners();
  }

  // Remove parameter
  void removeParameter(String id) {
    final parameter = _parameterMap[id];
    if (parameter == null) return;
    
    _parameters.remove(parameter);
    _parameterMap.remove(id);
    
    // Update display store with new page count
    _displayStore.setTotalKnobPages(totalKnobPages);
    
    notifyListeners();
  }

  // Clear all parameters
  void clearParameters() {
    _parameters.clear();
    _parameterMap.clear();
    _structureHash = '';
    _lastChangedParameterId = null;
    _lastChangeTimestamp = null;
    
    // Update display store
    _displayStore.setTotalKnobPages(1);
    
    notifyListeners();
  }

  // Broadcast parameter value update to WebSocket (like Vue.js broadcastValueUpdate)
  void _broadcastValueUpdate(String paramId, double value) {
    final parameter = _parameterMap[paramId];
    if (parameter == null) return;
    
    // Create Vue.js compatible message format
    final message = ParameterValueSync(
      updates: [
        ParameterValueUpdate(
          id: paramId,
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
    
    // Send to WebSocket - we'll inject this through a callback
    _sendWebSocketMessage?.call(message);
  }

  // WebSocket message sender (injected from WebSocketStore)
  void Function(WebSocketMessage)? _sendWebSocketMessage;
  
  void setSendWebSocketMessage(void Function(WebSocketMessage) sender) {
    _sendWebSocketMessage = sender;
  }

  // Private helper methods
  void _replaceParameter(Parameter parameter) {
    final index = _parameters.indexWhere((p) => p.id == parameter.id);
    if (index >= 0) {
      _parameters[index] = parameter;
      _parameterMap[parameter.id] = parameter;
    }
  }

  void _rebuildParameterMap() {
    _parameterMap.clear();
    for (final parameter in _parameters) {
      _parameterMap[parameter.id] = parameter;
    }
  }

  void _trackParameterChange(String id) {
    _lastChangedParameterId = id;
    _lastChangeTimestamp = DateTime.now();
  }

  // Debug helpers
  String get debugInfo {
    return '''
ParameterStore Debug Info:
- Parameter Count: ${_parameters.length}
- Structure Hash: $_structureHash
- Total Pages: $totalKnobPages
- Last Changed: $_lastChangedParameterId
- Last Change Time: $_lastChangeTimestamp
''';
  }

  @override
  void dispose() {
    super.dispose();
  }
} 