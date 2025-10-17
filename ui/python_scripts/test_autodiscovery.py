#!/usr/bin/env python3
"""
Test script to verify WebSocket auto-discovery functionality.
Run this to test the new WebSocketManager with auto-discovery.
"""

import os
import sys
import time

# Add the parent directory to the path
sys.path.append(os.path.dirname(__file__))

from stores.parameter_store import ParameterStore
from stores.websocket_manager import WebSocketManager

def test_auto_discovery():
    """Test auto-discovery functionality"""
    print("🧪 Testing WebSocket Auto-Discovery")
    print("=" * 50)
    
    # Create parameter store
    parameter_store = ParameterStore()
    parameter_store.load_mock_data()
    
    # Test 1: Auto-discovery (no URLs specified)
    print("\n📡 Test 1: Auto-discovery (default behavior)")
    ws_manager = WebSocketManager(parameter_store)
    
    # Print discovered URLs
    print(f"🔍 Discovered {len(ws_manager.urls)} URLs to try:")
    for i, url in enumerate(ws_manager.urls[:10], 1):  # Show first 10
        print(f"  {i}. {url}")
    if len(ws_manager.urls) > 10:
        print(f"  ... and {len(ws_manager.urls) - 10} more")
    
    # Test 2: Environment variable
    print("\n🌍 Test 2: Environment variable override")
    os.environ['WEBSOCKET_URL'] = 'ws://test.example.com:8765'
    ws_manager_env = WebSocketManager(parameter_store)
    print(f"🔍 Environment URL: {ws_manager_env.urls}")
    
    # Test 3: Manual URLs
    print("\n🎯 Test 3: Manual URL specification")
    manual_urls = ['ws://192.168.1.100:8765', 'ws://localhost:8765']
    ws_manager_manual = WebSocketManager(parameter_store, urls=manual_urls)
    print(f"🔍 Manual URLs: {ws_manager_manual.urls}")
    
    # Test 4: Try actual connection (if server is running)
    print("\n🔗 Test 4: Attempting actual connection")
    print("Starting connection attempt...")
    
    # Reset environment variable for real test
    if 'WEBSOCKET_URL' in os.environ:
        del os.environ['WEBSOCKET_URL']
        
    ws_manager_test = WebSocketManager(parameter_store)
    ws_manager_test.start()
    
    # Wait a bit for connection attempt
    print("⏳ Waiting 10 seconds for connection attempts...")
    time.sleep(10)
    
    # Check connection status
    info = ws_manager_test.get_connection_info()
    print("\n📊 Connection Results:")
    print(f"  Connected: {info['connected']}")
    print(f"  Current URL: {info['current_url']}")
    print(f"  URLs tried: {info['tried_urls']}")
    
    if info['connected']:
        print("✅ SUCCESS: Connected to WebSocket server!")
        print(f"🎯 Connected to: {info['current_url']}")
    else:
        print("❌ No connection established")
        print("💡 Make sure mock_ws_server.py is running somewhere on your network")
        print("💡 Or set WEBSOCKET_URL environment variable to specific server")
    
    print("\n" + "=" * 50)
    print("🧪 Auto-discovery test complete!")
    
    return ws_manager_test

def test_environment_variable_usage():
    """Show how to use environment variable"""
    print("\n💡 Usage Examples:")
    print("=" * 30)
    
    print("1. Auto-discovery (default):")
    print("   python kivy_ui_modular.py")
    
    print("\n2. Specify exact URL:")
    print("   export WEBSOCKET_URL=ws://192.168.1.50:8765")
    print("   python kivy_ui_modular.py")
    
    print("\n3. Windows PowerShell:")
    print("   $env:WEBSOCKET_URL='ws://192.168.1.50:8765'")
    print("   python kivy_ui_modular.py")
    
    print("\n4. Windows Command Prompt:")
    print("   set WEBSOCKET_URL=ws://192.168.1.50:8765")
    print("   python kivy_ui_modular.py")

if __name__ == '__main__':
    try:
        test_auto_discovery()
        test_environment_variable_usage()
    except KeyboardInterrupt:
        print("\n👋 Test interrupted by user")
    except Exception as e:
        print(f"\n💥 Test failed: {e}")
        import traceback
        traceback.print_exc() 