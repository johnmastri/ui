import asyncio
import websockets
import json

# Store connected clients for broadcasting
connected_clients = set()

async def handler(websocket):
    print("Client connected!")
    connected_clients.add(websocket)
    try:
        async for message in websocket:
            print("Received:", message)
            try:
                msg = json.loads(message)
                message_type = msg.get('type')
                
                # Handle different message types
                if message_type == 'parameter_structure_sync':
                    print(f"📡 PARAMETER STRUCTURE RECEIVED! Broadcasting to {len(connected_clients)} clients")
                    print(f"Structure contains {len(msg.get('parameters', []))} parameters")
                    # Broadcast structure to all other connected clients
                    broadcasted_count = 0
                    for client in connected_clients.copy():
                        if client != websocket:
                            try:
                                await client.send(message)  # Echo the exact message
                                broadcasted_count += 1
                                print(f"✅ Sent to client {broadcasted_count}")
                            except (websockets.exceptions.ConnectionClosed, websockets.exceptions.ConnectionClosedError, Exception) as e:
                                connected_clients.remove(client)
                                print(f"❌ Client disconnected during broadcast: {e}")
                    print(f"📤 Successfully broadcasted to {broadcasted_count} clients")
                                
                elif message_type == 'parameter_value_sync':
                    print(f"Broadcasting parameter values to {len(connected_clients)} clients")
                    # Broadcast values to all other connected clients
                    for client in connected_clients.copy():
                        if client != websocket:
                            try:
                                await client.send(message)  # Echo the exact message
                            except (websockets.exceptions.ConnectionClosed, websockets.exceptions.ConnectionClosedError, Exception) as e:
                                connected_clients.remove(client)
                                print(f"❌ Client disconnected during value broadcast: {e}")
                                
                elif message_type == 'parameter_color_sync':
                    print(f"🎨 COLOR UPDATE! Broadcasting color changes to {len(connected_clients)} clients")
                    color_updates = msg.get('updates', [])
                    for update in color_updates:
                        param_id = update.get('id', 'unknown')
                        color = update.get('color', 'unknown')
                        print(f"🎨 Parameter {param_id} color changed to {color}")
                    # Broadcast colors to all other connected clients
                    for client in connected_clients.copy():
                        if client != websocket:
                            try:
                                await client.send(message)  # Echo the exact message
                            except (websockets.exceptions.ConnectionClosed, websockets.exceptions.ConnectionClosedError, Exception) as e:
                                connected_clients.remove(client)
                                print(f"❌ Client disconnected during color broadcast: {e}")
                                
                elif message_type == 'request_parameter_state':
                    print(f"Parameter state request from client - broadcasting to {len(connected_clients)} clients")
                    # Broadcast request to all other connected clients
                    for client in connected_clients.copy():
                        if client != websocket:
                            try:
                                await client.send(message)  # Echo the exact message
                            except (websockets.exceptions.ConnectionClosed, websockets.exceptions.ConnectionClosedError, Exception) as e:
                                connected_clients.remove(client)
                                print(f"❌ Client disconnected during state request broadcast: {e}")
                                
                elif message_type == 'parameter_update':
                    # Legacy support - echo back a mock LED update
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
                else:
                    print(f"Unknown message type: {message_type}")
                    
            except Exception as e:
                print("Error handling message:", e)
    finally:
        connected_clients.remove(websocket)
        print("Client disconnected!")

async def main():
    start_server = websockets.serve(handler, "0.0.0.0", 8765)
    print("WebSocket server running on ws://0.0.0.0:8765")
    print("Access from network: ws://192.168.1.5:8765")
    await start_server
    await asyncio.Future()  # Run forever

if __name__ == "__main__":
    asyncio.run(main()) 