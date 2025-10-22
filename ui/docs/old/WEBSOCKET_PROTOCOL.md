# WebSocket Protocol Documentation

## Overview

This document describes the WebSocket protocol used by the MIDI controller system for communication between the Flutter client, Vue.js client, and the ESP32 bridge/VST plugin.

## Connection Details

### Server Discovery
- **Primary**: `ws://localhost:8765` (development/VST mode)
- **Secondary**: `ws://192.168.1.195:8765` (Pi bridge mode)
- **Auto-reconnect**: Exponential backoff (1s, 2s, 4s, 8s, max 30s)
- **Health monitoring**: Periodic ping/pong for connection validation

### Connection States
- `CONNECTING` - Initial connection attempt
- `CONNECTED` - Active WebSocket connection
- `DISCONNECTED` - Connection lost or failed
- `RECONNECTING` - Attempting to reconnect

## Message Format

All messages follow this JSON structure:
```json
{
  "type": "message_type",
  "data": {
    // Message-specific payload
  },
  "timestamp": "2024-01-01T00:00:00.000Z" // Optional
}
```

## Message Types

### 1. Parameter Structure Sync
**Type**: `parameter_structure_sync`
**Direction**: Server → Client
**Purpose**: Initial parameter structure definition with validation hash

```json
{
  "type": "parameter_structure_sync",
  "data": {
    "structure_hash": "abc123def456",
    "parameters": [
      {
        "id": "param_001",
        "name": "Filter Cutoff",
        "min": 0.0,
        "max": 1.0,
        "default": 0.5,
        "step": 0.01,
        "unit": "Hz",
        "category": "filter"
      }
    ]
  }
}
```

### 2. Parameter Value Sync
**Type**: `parameter_value_sync`
**Direction**: Bidirectional
**Purpose**: Real-time parameter value updates with display information

```json
{
  "type": "parameter_value_sync",
  "data": {
    "id": "param_001",
    "value": 0.75,
    "normalized_value": 0.75,
    "text": "750 Hz",
    "color": {
      "r": 255,
      "g": 100,
      "b": 50
    }
  }
}
```

### 3. Parameter Color Sync
**Type**: `parameter_color_sync`
**Direction**: Server → Client
**Purpose**: Update LED ring colors without changing values

```json
{
  "type": "parameter_color_sync",
  "data": {
    "id": "param_001",
    "color": {
      "r": 255,
      "g": 100,
      "b": 50
    }
  }
}
```

### 4. Request Parameter State
**Type**: `request_parameter_state`
**Direction**: Client → Server
**Purpose**: Request current state of specific parameters or all parameters

```json
{
  "type": "request_parameter_state",
  "data": {
    "parameter_ids": ["param_001", "param_002"], // or "all"
    "include_structure": true // Optional: include parameter definitions
  }
}
```

### 5. LED Update
**Type**: `led_update`
**Direction**: Server → Client
**Purpose**: Update LED ring display data for hardware visualization

```json
{
  "type": "led_update",
  "data": {
    "parameter_id": "param_001",
    "led_data": [
      {"r": 255, "g": 0, "b": 0},
      {"r": 255, "g": 50, "b": 0},
      {"r": 255, "g": 100, "b": 0}
      // ... array of RGB values for LED ring
    ],
    "brightness": 0.8
  }
}
```

### 6. System Commands
**Type**: `system`
**Direction**: Bidirectional
**Purpose**: System control and status messages

```json
{
  "type": "system",
  "data": {
    "command": "ping|pong|reset|status|error",
    "message": "Optional message",
    "error_code": 500 // Only for errors
  }
}
```

### 7. Batch Parameter Update
**Type**: `batch_parameter_update`
**Direction**: Bidirectional
**Purpose**: Update multiple parameters in a single message

```json
{
  "type": "batch_parameter_update",
  "data": {
    "updates": [
      {
        "id": "param_001",
        "value": 0.75,
        "text": "750 Hz",
        "color": {"r": 255, "g": 100, "b": 50}
      },
      {
        "id": "param_002",
        "value": 0.5,
        "text": "50%",
        "color": {"r": 0, "g": 255, "b": 0}
      }
    ]
  }
}
```

## State Management

### Parameter State Structure
```json
{
  "id": "param_001",
  "name": "Filter Cutoff",
  "value": 0.75,
  "normalized_value": 0.75,
  "text": "750 Hz",
  "color": {
    "r": 255,
    "g": 100,
    "b": 50
  },
  "min": 0.0,
  "max": 1.0,
  "step": 0.01,
  "unit": "Hz",
  "category": "filter",
  "is_active": true,
  "last_updated": "2024-01-01T00:00:00.000Z"
}
```

### Connection State Management
```json
{
  "status": "CONNECTED|DISCONNECTED|CONNECTING|RECONNECTING",
  "url": "ws://192.168.1.195:8765",
  "last_ping": "2024-01-01T00:00:00.000Z",
  "reconnect_attempts": 0,
  "max_reconnect_attempts": 10,
  "reconnect_delay": 1000
}
```

## Error Handling

### Error Message Format
```json
{
  "type": "system",
  "data": {
    "command": "error",
    "error_code": 500,
    "message": "Parameter validation failed",
    "details": {
      "parameter_id": "param_001",
      "invalid_value": 1.5,
      "valid_range": [0.0, 1.0]
    }
  }
}
```

### Common Error Codes
- `400` - Bad Request (invalid message format)
- `404` - Parameter Not Found
- `422` - Validation Error (value out of range)
- `500` - Internal Server Error
- `503` - Service Unavailable (bridge disconnected)

## Implementation Notes

### Message Ordering
- Parameter structure sync should be processed before value syncs
- Batch updates should be processed atomically
- LED updates can be processed asynchronously

### Performance Considerations
- Throttle parameter updates to 60Hz maximum
- Batch multiple parameter changes when possible
- Use delta updates for LED ring data when supported

### Compatibility
- All message types are backward compatible with Vue.js client
- New message types should include version information
- Clients should ignore unknown message types gracefully

### Security
- No authentication required for local connections
- Message validation on both client and server sides
- Rate limiting for parameter updates (max 100 updates/second)

## Flutter Implementation Guidelines

### Message Handling
```dart
// Example message handler structure
abstract class WebSocketMessage {
  final String type;
  final Map<String, dynamic> data;
  final DateTime? timestamp;
}

class ParameterValueSync extends WebSocketMessage {
  final String id;
  final double value;
  final String text;
  final Color color;
}
```

### State Updates
- Use Provider/Riverpod for state management
- Implement optimistic updates for UI responsiveness
- Handle rollback on server rejection
- Queue updates during reconnection

### Connection Management
- Implement exponential backoff for reconnection
- Handle WebSocket lifecycle events
- Provide connection status to UI
- Implement heartbeat mechanism

---

*This protocol ensures seamless communication between the Flutter client and existing system components while maintaining compatibility with the Vue.js implementation.* 