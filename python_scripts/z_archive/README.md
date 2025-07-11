## Copy script to pi
# From your Windows machine (in PowerShell/CMD)
scp VSTMastrCtrl/mastrctrl/plugin/ui/python_scripts/kivy_ui.py mastrctrl@192.168.1.195:~/

# WebSocket Server for Testing

This directory contains Python scripts for testing the WebSocket communication between the MastrCtrl frontend and hardware emulator.

## Setup

1. **Install Python dependencies:**
   ```bash
   pip install websockets
   ```

2. **Start the WebSocket server:**
   ```bash
   python mock_ws_server.py
   ```
   The server will start on `ws://localhost:8765`

3. **Test the server (optional):**
   ```bash
   python test_websocket.py
   ```

## Usage

### Mock WebSocket Server (`mock_ws_server.py`)

- **Port:** 8765
- **Protocol:** WebSocket
- **Purpose:** Echoes back mock LED update payloads for testing

**Supported Messages:**
- `parameter_update` - Returns a mock `led_update` response

**Example:**
```json
// Send
{
  "type": "parameter_update",
  "parameter_id": "input-gain",
  "value": 0.75,
  "knob_id": 1
}

// Receive
{
  "type": "led_update",
  "knob_id": 1,
  "parameter": {
    "id": "input-gain",
    "name": "input-gain",
    "value": 0.75,
    "text": "75%",
    "color": {"r": 76, "g": 175, "b": 80}
  },
  "leds": {
    "start_index": 0,
    "count": 28,
    "active_count": 21,
    "pattern": "ring_fill"
  }
}
```

### Frontend Integration

The MastrCtrl frontend will automatically connect to `ws://localhost:8765` when the app loads. You can see the connection status in the header bar:

- **WebSocket:** Shows connection status
- **Send/Receive:** Status lights that flash when messages are sent/received
- **Server:** Shows the WebSocket server URL

## Development

To extend the server for more testing scenarios:

1. Add new message types to the `handler` function in `mock_ws_server.py`
2. Create corresponding response payloads
3. Test with the frontend or use `test_websocket.py`

## Troubleshooting

- **Connection refused:** Make sure the server is running on port 8765
- **No response:** Check the server console for error messages
- **Frontend not connecting:** Verify the WebSocket URL in the frontend matches the server 