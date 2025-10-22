#!/usr/bin/env python3

import asyncio
import websockets
import json
import argparse

async def echo_server(websocket):
    print(f"Client connected: {websocket.remote_address}")
    
    await websocket.send(json.dumps({
        'type': 'startup',
        'device_id': 'test_server',
        'version': '1.0.0',
        'status': 'ready'
    }))
    
    try:
        async for message in websocket:
            print(f"Received: {message}")
            
            msg = json.loads(message)
            msg_type = msg.get('type')
            
            if msg_type == 'led_update':
                print(f"  LED Update: encoder={msg.get('encoder_id')}, "
                      f"color=RGB({msg.get('color', {}).get('r')}, {msg.get('color', {}).get('g')}, {msg.get('color', {}).get('b')}), "
                      f"pattern={msg.get('pattern')}, value={msg.get('value')}")
            
            echo_response = {
                'type': 'echo',
                'original': msg
            }
            await websocket.send(json.dumps(echo_response))
            
    except websockets.exceptions.ConnectionClosed:
        print("Client disconnected")

async def start_server(ip, port):
    print("=" * 60)
    print("WebSocket Test Server")
    print("=" * 60)
    print(f"Starting server on ws://{ip}:{port}")
    print("Waiting for connections...")
    print()
    
    async with websockets.serve(echo_server, ip, port):
        await asyncio.Future()

def main():
    parser = argparse.ArgumentParser(description='Test WebSocket Server')
    parser.add_argument('--ip', default='0.0.0.0', help='IP address to bind to')
    parser.add_argument('--port', type=int, default=8765, help='Port to listen on')
    
    args = parser.parse_args()
    
    try:
        asyncio.run(start_server(args.ip, args.port))
    except KeyboardInterrupt:
        print("\nServer stopped")

if __name__ == '__main__':
    main()

