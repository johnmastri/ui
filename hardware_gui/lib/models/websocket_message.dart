import 'dart:convert';
import 'parameter.dart';

abstract class WebSocketMessage {
  final String type;
  final Map<String, dynamic> data;
  final DateTime? timestamp;

  WebSocketMessage({
    required this.type,
    required this.data,
    this.timestamp,
  });

  Map<String, dynamic> toJson() {
    return {
      'type': type,
      'data': data,
      if (timestamp != null) 'timestamp': timestamp!.toIso8601String(),
    };
  }

  String toJsonString() => jsonEncode(toJson());

  factory WebSocketMessage.fromJson(Map<String, dynamic> json) {
    final type = json['type'] as String? ?? 'unknown';
    final data = json['data'] as Map<String, dynamic>? ?? {};
    final timestamp = json['timestamp'] != null 
        ? (json['timestamp'] is int 
            ? DateTime.fromMillisecondsSinceEpoch(json['timestamp'] as int)
            : DateTime.parse(json['timestamp'] as String))
        : null;

    switch (type) {
      case 'parameter_structure_sync':
        return ParameterStructureSync.fromJson(json);
      case 'parameter_value_sync':
        return ParameterValueSync.fromJson(json);
      case 'parameter_color_sync':
        return ParameterColorSync.fromJson(json);
      case 'request_parameter_state':
        return RequestParameterState.fromJson(json);
      case 'led_update':
        return LedUpdate.fromJson(json);
      case 'system':
        return SystemMessage.fromJson(json);
      case 'batch_parameter_update':
        return BatchParameterUpdate.fromJson(json);
      default:
        return UnknownMessage(type: type, data: data, timestamp: timestamp);
    }
  }
}

// Vue.js compatible ParameterValueSync with updates array
class ParameterValueSync extends WebSocketMessage {
  final List<ParameterValueUpdate> updates;

  ParameterValueSync({
    required this.updates,
    DateTime? timestamp,
  }) : super(
          type: 'parameter_value_sync',
          data: {
            'updates': updates.map((u) => u.toJson()).toList(),
          },
          timestamp: timestamp,
        );

  // Override toJson to match Vue format exactly (no data wrapper)
  @override
  Map<String, dynamic> toJson() {
    return {
      'type': type,
      'updates': updates.map((u) => u.toJson()).toList(),
      'timestamp': timestamp?.millisecondsSinceEpoch ?? DateTime.now().millisecondsSinceEpoch,
    };
  }

  factory ParameterValueSync.fromJson(Map<String, dynamic> json) {
    // Handle Vue.js format (updates at top level)
    final updatesData = json['updates'] as List? ?? [];
    final timestamp = json['timestamp'] != null 
        ? (json['timestamp'] is int 
            ? DateTime.fromMillisecondsSinceEpoch(json['timestamp'] as int)
            : DateTime.parse(json['timestamp'] as String))
        : null;
    
    return ParameterValueSync(
      updates: updatesData
          .map((u) => ParameterValueUpdate.fromJson(u as Map<String, dynamic>))
          .toList(),
      timestamp: timestamp,
    );
  }
}

// Individual parameter update matching Vue format
class ParameterValueUpdate {
  final String id;
  final double value;
  final String text;
  final Map<String, int> rgbColor; // Vue uses 'rgbColor' not 'color'

  ParameterValueUpdate({
    required this.id,
    required this.value,
    required this.text,
    required this.rgbColor,
  });

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'value': value,
      'text': text,
      'rgbColor': rgbColor,
    };
  }

  factory ParameterValueUpdate.fromJson(Map<String, dynamic> json) {
    return ParameterValueUpdate(
      id: json['id'] as String? ?? '',
      value: (json['value'] as num?)?.toDouble() ?? 0.0,
      text: json['text'] as String? ?? '',
      rgbColor: (json['rgbColor'] as Map<String, dynamic>?)?.cast<String, int>() ?? 
                {'r': 128, 'g': 128, 'b': 128},
    );
  }
}

class ParameterStructureSync extends WebSocketMessage {
  final String structureHash;
  final List<Parameter> parameters;

  ParameterStructureSync({
    required this.structureHash,
    required this.parameters,
    DateTime? timestamp,
  }) : super(
          type: 'parameter_structure_sync',
          data: {
            'structure_hash': structureHash,
            'parameters': parameters.map((p) => p.toJson()).toList(),
          },
          timestamp: timestamp,
        );

  // Override toJson to match Vue format exactly (no data wrapper)
  @override
  Map<String, dynamic> toJson() {
    return {
      'type': type,
      'structure_hash': structureHash,
      'parameters': parameters.map((p) => p.toJson()).toList(),
      'timestamp': timestamp?.millisecondsSinceEpoch ?? DateTime.now().millisecondsSinceEpoch,
    };
  }

  factory ParameterStructureSync.fromJson(Map<String, dynamic> json) {
    // Handle Vue.js format (fields at top level)
    final parametersData = json['parameters'] as List? ?? [];
    final timestamp = json['timestamp'] != null 
        ? (json['timestamp'] is int 
            ? DateTime.fromMillisecondsSinceEpoch(json['timestamp'] as int)
            : DateTime.parse(json['timestamp'] as String))
        : null;
    
    return ParameterStructureSync(
      structureHash: json['structure_hash'] as String? ?? '',
      parameters: parametersData
          .map((p) => Parameter.fromJson(p as Map<String, dynamic>))
          .toList(),
      timestamp: timestamp,
    );
  }
}

// Vue.js compatible ParameterColorSync with updates array
class ParameterColorSync extends WebSocketMessage {
  final List<ParameterColorUpdate> updates;

  ParameterColorSync({
    required this.updates,
    DateTime? timestamp,
  }) : super(
          type: 'parameter_color_sync',
          data: {
            'updates': updates.map((u) => u.toJson()).toList(),
          },
          timestamp: timestamp,
        );

  // Override toJson to match Vue format exactly (no data wrapper)
  @override
  Map<String, dynamic> toJson() {
    return {
      'type': type,
      'updates': updates.map((u) => u.toJson()).toList(),
      'timestamp': timestamp?.millisecondsSinceEpoch ?? DateTime.now().millisecondsSinceEpoch,
    };
  }

  factory ParameterColorSync.fromJson(Map<String, dynamic> json) {
    final updatesData = json['updates'] as List? ?? [];
    final timestamp = json['timestamp'] != null 
        ? (json['timestamp'] is int 
            ? DateTime.fromMillisecondsSinceEpoch(json['timestamp'] as int)
            : DateTime.parse(json['timestamp'] as String))
        : null;
    
    return ParameterColorSync(
      updates: updatesData
          .map((u) => ParameterColorUpdate.fromJson(u as Map<String, dynamic>))
          .toList(),
      timestamp: timestamp,
    );
  }
}

class ParameterColorUpdate {
  final String id;
  final String? color;
  final Map<String, int>? rgbColor;

  ParameterColorUpdate({
    required this.id,
    this.color,
    this.rgbColor,
  });

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      if (color != null) 'color': color,
      if (rgbColor != null) 'rgbColor': rgbColor,
    };
  }

  factory ParameterColorUpdate.fromJson(Map<String, dynamic> json) {
    return ParameterColorUpdate(
      id: json['id'] as String? ?? '',
      color: json['color'] as String?,
      rgbColor: (json['rgbColor'] as Map<String, dynamic>?)?.cast<String, int>(),
    );
  }
}

class RequestParameterState extends WebSocketMessage {
  final List<String> parameterIds;
  final bool includeStructure;

  RequestParameterState({
    required this.parameterIds,
    this.includeStructure = false,
    DateTime? timestamp,
  }) : super(
          type: 'request_parameter_state',
          data: {
            'parameter_ids': parameterIds,
            'include_structure': includeStructure,
          },
          timestamp: timestamp,
        );

  factory RequestParameterState.fromJson(Map<String, dynamic> json) {
    // Handle Vue.js format (fields at top level, no data wrapper)
    final timestamp = json['timestamp'] != null 
        ? (json['timestamp'] is int 
            ? DateTime.fromMillisecondsSinceEpoch(json['timestamp'] as int)
            : DateTime.parse(json['timestamp'] as String))
        : null;
    
    return RequestParameterState(
      parameterIds: (json['parameter_ids'] as List? ?? []).cast<String>(),
      includeStructure: json['include_structure'] as bool? ?? false,
      timestamp: timestamp,
    );
  }
}

class LedUpdate extends WebSocketMessage {
  final String parameterId;
  final List<ParameterColor> ledData;
  final double brightness;

  LedUpdate({
    required this.parameterId,
    required this.ledData,
    this.brightness = 0.8,
    DateTime? timestamp,
  }) : super(
          type: 'led_update',
          data: {
            'parameter_id': parameterId,
            'led_data': ledData.map((color) => color.toJson()).toList(),
            'brightness': brightness,
          },
          timestamp: timestamp,
        );

  factory LedUpdate.fromJson(Map<String, dynamic> json) {
    final data = json['data'] as Map<String, dynamic>;
    return LedUpdate(
      parameterId: data['parameter_id'] as String,
      ledData: (data['led_data'] as List)
          .map((colorData) => ParameterColor.fromJson(colorData as Map<String, dynamic>))
          .toList(),
      brightness: (data['brightness'] as num?)?.toDouble() ?? 0.8,
      timestamp: json['timestamp'] != null 
          ? (json['timestamp'] is int 
              ? DateTime.fromMillisecondsSinceEpoch(json['timestamp'] as int)
              : DateTime.parse(json['timestamp'] as String))
          : null,
    );
  }
}

class SystemMessage extends WebSocketMessage {
  final String command;
  final String? message;
  final int? errorCode;

  SystemMessage({
    required this.command,
    this.message,
    this.errorCode,
    DateTime? timestamp,
  }) : super(
          type: 'system',
          data: {
            'command': command,
            if (message != null) 'message': message,
            if (errorCode != null) 'error_code': errorCode,
          },
          timestamp: timestamp,
        );

  factory SystemMessage.fromJson(Map<String, dynamic> json) {
    final data = json['data'] as Map<String, dynamic>;
    return SystemMessage(
      command: data['command'] as String,
      message: data['message'] as String?,
      errorCode: data['error_code'] as int?,
      timestamp: json['timestamp'] != null 
          ? (json['timestamp'] is int 
              ? DateTime.fromMillisecondsSinceEpoch(json['timestamp'] as int)
              : DateTime.parse(json['timestamp'] as String))
          : null,
    );
  }
}

class BatchParameterUpdate extends WebSocketMessage {
  final List<ParameterValueUpdate> updates;

  BatchParameterUpdate({
    required this.updates,
    DateTime? timestamp,
  }) : super(
          type: 'batch_parameter_update',
          data: {
            'updates': updates.map((update) => update.toJson()).toList(),
          },
          timestamp: timestamp,
        );

  factory BatchParameterUpdate.fromJson(Map<String, dynamic> json) {
    final data = json['data'] as Map<String, dynamic>;
    final updates = (data['updates'] as List).map((updateData) {
      final update = updateData as Map<String, dynamic>;
      return ParameterValueUpdate(
        id: update['id'] as String? ?? '',
        value: (update['value'] as num?)?.toDouble() ?? 0.0,
        text: update['text'] as String? ?? '',
        rgbColor: (update['rgbColor'] as Map<String, dynamic>?)?.cast<String, int>() ?? 
                  {'r': 128, 'g': 128, 'b': 128},
      );
    }).toList();

    return BatchParameterUpdate(
      updates: updates,
      timestamp: json['timestamp'] != null 
          ? (json['timestamp'] is int 
              ? DateTime.fromMillisecondsSinceEpoch(json['timestamp'] as int)
              : DateTime.parse(json['timestamp'] as String))
          : null,
    );
  }
}

class UnknownMessage extends WebSocketMessage {
  UnknownMessage({
    required String type,
    required Map<String, dynamic> data,
    DateTime? timestamp,
  }) : super(type: type, data: data, timestamp: timestamp);
} 