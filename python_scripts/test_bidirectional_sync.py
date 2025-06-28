#!/usr/bin/env python3
"""
Test Script: Bidirectional WebSocket Sync Test
Tests the enhanced Kivy app's Vue.js-compatible WebSocket functionality
"""

import asyncio
import websockets
import json
from datetime import datetime
import time

class WebSocketTester:
    def __init__(self, pi_url="ws://192.168.1.195:8765"):
        self.pi_url = pi_url
        self.websocket = None
        
    async def test_bidirectional_sync(self):
        """Test full bidirectional sync like Vue.js"""
        try:
            print("🔗 Connecting to Pi bridge...")
            self.websocket = await websockets.connect(self.pi_url)
            print("✅ Connected to Pi bridge!")
            
            # Test 1: Send parameter state request (like Vue.js does on startup)
            print("\n📋 TEST 1: Parameter State Request")
            await self.send_state_request()
            await asyncio.sleep(1)
            
            # Test 2: Send parameter structure sync
            print("\n📋 TEST 2: Parameter Structure Sync")
            await self.send_structure_sync()
            await asyncio.sleep(1)
            
            # Test 3: Send parameter value updates (like knob movements)
            print("\n📋 TEST 3: Parameter Value Updates")
            await self.send_parameter_updates()
            await asyncio.sleep(1)
            
            # Test 4: Send color updates
            print("\n📋 TEST 4: Parameter Color Updates")
            await self.send_color_updates()
            await asyncio.sleep(1)
            
            # Test 5: Listen for incoming messages
            print("\n📋 TEST 5: Listen for Messages (5 seconds)")
            await self.listen_for_messages(duration=5)
            
            print("\n✅ All tests completed!")
            
        except Exception as e:
            print(f"❌ Test failed: {e}")
        finally:
            if self.websocket:
                await self.websocket.close()
                
    async def send_state_request(self):
        """Send parameter state request (Vue.js format)"""
        if not self.websocket:
            return
            
        message = {
            "type": "request_parameter_state",
            "timestamp": int(datetime.now().timestamp() * 1000)
        }
        await self.websocket.send(json.dumps(message))
        print("❓ Sent parameter state request")
        
    async def send_structure_sync(self):
        """Send parameter structure sync (Vue.js format)"""
        if not self.websocket:
            return
            
        mock_parameters = [
            {
                "id": "input-gain",
                "name": "Input Gain",
                "value": 0.75,
                "min": 0,
                "max": 1,
                "step": 0.01,
                "format": "percentage",
                "defaultValue": 0.5,
                "color": "#4CAF50",
                "rgbColor": {"r": 76, "g": 175, "b": 80},
                "ledCount": 28
            },
            {
                "id": "drive",
                "name": "Drive",
                "value": 0.3,
                "min": 0,
                "max": 1,
                "step": 0.01,
                "format": "percentage",
                "defaultValue": 0.0,
                "color": "#FF5722",
                "rgbColor": {"r": 255, "g": 87, "b": 34},
                "ledCount": 28
            }
        ]
        
        message = {
            "type": "parameter_structure_sync",
            "structure_hash": "test_hash_123",
            "parameters": mock_parameters,
            "timestamp": int(datetime.now().timestamp() * 1000)
        }
        await self.websocket.send(json.dumps(message))
        print(f"📡 Sent structure sync: {len(mock_parameters)} parameters")
        
    async def send_parameter_updates(self):
        """Send parameter value updates (Vue.js format)"""
        if not self.websocket:
            return
            
        updates = [
            {
                "id": "input-gain",
                "value": 0.8,
                "text": "80%",
                "rgbColor": {"r": 76, "g": 175, "b": 80}
            },
            {
                "id": "drive",
                "value": 0.5,
                "text": "50%",
                "rgbColor": {"r": 255, "g": 87, "b": 34}
            }
        ]
        
        message = {
            "type": "parameter_value_sync",
            "updates": updates,
            "timestamp": int(datetime.now().timestamp() * 1000)
        }
        await self.websocket.send(json.dumps(message))
        print(f"📤 Sent parameter updates: {len(updates)} parameters")
        
    async def send_color_updates(self):
        """Send parameter color updates (Vue.js format)"""
        if not self.websocket:
            return
            
        updates = [
            {
                "id": "input-gain",
                "color": "#00BCD4",
                "rgbColor": {"r": 0, "g": 188, "b": 212}
            },
            {
                "id": "drive",
                "rgbColor": {"r": 233, "g": 30, "b": 99}
            }
        ]
        
        message = {
            "type": "parameter_color_sync",
            "updates": updates,
            "timestamp": int(datetime.now().timestamp() * 1000)
        }
        await self.websocket.send(json.dumps(message))
        print(f"🎨 Sent color updates: {len(updates)} parameters")
        
    async def listen_for_messages(self, duration=5):
        """Listen for incoming messages"""
        print(f"👂 Listening for {duration} seconds...")
        
        try:
            # Set a timeout for listening
            await asyncio.wait_for(self._listen_loop(), timeout=duration)
        except asyncio.TimeoutError:
            print(f"⏰ Listening timeout ({duration}s) - this is normal")
            
    async def _listen_loop(self):
        """Listen loop for incoming messages"""
        if not self.websocket:
            return
            
        async for message in self.websocket:
            try:
                data = json.loads(message)
                message_type = data.get('type', 'unknown')
                print(f"📥 Received: {message_type}")
                
                if message_type == 'parameter_value_sync':
                    updates = data.get('updates', [])
                    print(f"   📊 Value updates: {len(updates)}")
                    for update in updates[:2]:  # Show first 2
                        print(f"      {update.get('id')}: {update.get('value')} ({update.get('text')})")
                        
                elif message_type == 'parameter_structure_sync':
                    params = data.get('parameters', [])
                    print(f"   🏗️ Structure sync: {len(params)} parameters")
                    
                elif message_type == 'parameter_color_sync':
                    updates = data.get('updates', [])
                    print(f"   🎨 Color updates: {len(updates)}")
                    
                elif message_type == 'request_parameter_state':
                    print(f"   ❓ State request received")
                    
                else:
                    print(f"   ⚠️ Unknown type: {message_type}")
                    
            except json.JSONDecodeError:
                print(f"❌ Invalid JSON: {message}")

async def main():
    """Main test function"""
    print("🧪 BIDIRECTIONAL WEBSOCKET SYNC TEST")
    print("=" * 50)
    print("Testing enhanced Kivy app Vue.js compatibility")
    print("This will test all WebSocket message types used by Vue.js")
    print("=" * 50)
    
    tester = WebSocketTester()
    await tester.test_bidirectional_sync()
    
    print("\n" + "=" * 50)
    print("🏁 Test completed!")
    print("If you see parameter updates from the Kivy app,")
    print("bidirectional sync is working correctly!")

if __name__ == '__main__':
    asyncio.run(main()) 