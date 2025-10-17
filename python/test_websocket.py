#!/usr/bin/env python3
"""
Simple test script to verify the WebSocket server is working.
Run this after starting the mock_ws_server.py
"""

import asyncio
import websockets
import json

async def test_websocket():
    uri = "ws://localhost:8765"
    
    try:
        async with websockets.connect(uri) as websocket:
            print("Connected to WebSocket server!")
            
            # Send a test parameter update
            test_message = {
                "type": "parameter_update",
                "parameter_id": "test-param",
                "value": 0.75,
                "knob_id": 1
            }
            
            print(f"Sending: {test_message}")
            await websocket.send(json.dumps(test_message))
            
            # Wait for response
            response = await websocket.recv()
            print(f"Received: {response}")
            
            # Parse and verify response
            response_data = json.loads(response)
            if response_data.get("type") == "led_update":
                print("✅ Test passed! Server responded with LED update")
            else:
                print("❌ Test failed! Unexpected response type")
                
    except Exception as e:
        print(f"❌ Test failed! Error: {e}")

if __name__ == "__main__":
    print("Testing WebSocket server...")
    asyncio.run(test_websocket()) 