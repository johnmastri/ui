import asyncio
import websockets
import json

async def handler(websocket):
    print("Client connected!")
    async for message in websocket:
        print("Received:", message)
        try:
            msg = json.loads(message)
            if msg.get('type') == 'parameter_update':
                # Echo back a mock LED update
                await websocket.send(json.dumps({
                    "type": "led_update",
                    "knob_id": msg.get("knob_id", 1),
                    "parameter": {
                        "id": msg.get("parameter_id"),
                        "name": msg.get("parameter_id"),
                        "value": msg.get("value"),
                        "text": f"{int(msg.get('value', 0)*100)}%",
                        "color": {"r": 76, "g": 175, "b": 80}
                    },
                    "leds": {
                        "start_index": 0,
                        "count": 28,
                        "active_count": int(msg.get("value", 0)*28),
                        "pattern": "ring_fill"
                    }
                }))
        except Exception as e:
            print("Error handling message:", e)

async def main():
    start_server = websockets.serve(handler, "localhost", 8765)
    print("WebSocket server running on ws://localhost:8765")
    await start_server
    await asyncio.Future()  # Run forever

if __name__ == "__main__":
    asyncio.run(main()) 