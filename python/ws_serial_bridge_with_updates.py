import asyncio
import websockets
import serial
import serial.tools.list_ports
import json
import sys
import threading
import time
from datetime import datetime
from update_manager import UpdateManager

connected_clients = set()
serial_connection = None
running = False
esp32_to_ws_queue = None
main_loop = None
update_manager = None

stats = {
    'esp32_messages_received': 0,
    'esp32_messages_sent': 0,
    'ws_messages_received': 0,
    'ws_messages_sent': 0,
    'esp32_connected': False,
    'esp32_mac_address': None,
    'esp32_device_id': None,
    'start_time': datetime.now()
}

def find_esp32_port():
    ports = list(serial.tools.list_ports.comports())
    
    print("\n" + "="*60)
    print("ESP32 PORT DETECTION")
    print("="*60)
    print(f"Scanning {len(ports)} available serial ports...\n")
    
    for i, port in enumerate(ports):
        print(f"  [{i}] {port.device}")
        print(f"      Description: {port.description}")
        if port.hwid:
            print(f"      Hardware ID: {port.hwid}")
        print()
    
    esp32_keywords = ['esp32', 'cp210', 'ch340', 'usb-serial', 'usb serial', 'silicon labs']
    
    for port in ports:
        desc_lower = port.description.lower()
        if any(keyword in desc_lower for keyword in esp32_keywords):
            print(f"Found ESP32 device: {port.device}")
            print(f"Description: {port.description}")
            return port.device
    
    if not ports:
        print("No serial ports found!")
        print("Please connect your ESP32-S3 and try again.")
        sys.exit(1)
    
    print("Could not auto-detect ESP32. Available ports:")
    for i, port in enumerate(ports):
        print(f"  [{i}] {port.device} - {port.description}")
    
    try:
        choice = int(input(f"\nSelect port [0-{len(ports)-1}]: "))
        if 0 <= choice < len(ports):
            return ports[choice].device
        else:
            print("Invalid selection")
            sys.exit(1)
    except (ValueError, KeyboardInterrupt):
        print("\nExiting...")
        sys.exit(1)

def connect_to_esp32(port, baud=115200):
    global serial_connection, stats
    
    try:
        print(f"\nConnecting to ESP32 on {port} at {baud} baud...")
        serial_connection = serial.Serial(
            port=port,
            baudrate=baud,
            timeout=1,
            write_timeout=1
        )
        
        time.sleep(2)
        
        print(f"✅ Connected to ESP32 on {port}")
        stats['esp32_connected'] = True
        return True
        
    except serial.SerialException as e:
        print(f"\n❌ Failed to connect to ESP32: {e}")
        print("\nTroubleshooting steps:")
        print("  1. Close Arduino IDE Serial Monitor")
        print("  2. Close any other programs using the serial port")
        print("  3. Unplug and replug the ESP32")
        print("  4. Try a different USB cable")
        print("  5. Check if the ESP32 is properly powered")
        print("\nPress Enter to retry, or Ctrl+C to exit...")
        try:
            input()
            return connect_to_esp32(port, baud)
        except KeyboardInterrupt:
            print("\nExiting...")
            sys.exit(0)
        return False
    except Exception as e:
        print(f"❌ Unexpected error connecting to ESP32: {e}")
        return False

def serial_reader_thread():
    global serial_connection, running, stats, esp32_to_ws_queue, main_loop
    
    print("Starting ESP32 serial reader thread...")
    
    while running:
        if not serial_connection or not serial_connection.is_open:
            time.sleep(1)
            continue
        
        try:
            if serial_connection.in_waiting:
                line = serial_connection.readline().decode('utf-8').strip()
            else:
                time.sleep(0.01)
                continue
            
            if line:
                stats['esp32_messages_received'] += 1
                timestamp = datetime.now().strftime("%H:%M:%S.%f")[:-3]
                print(f"[{timestamp}] ESP32: {line}")
                
                try:
                    message = json.loads(line)
                    
                    if message.get('type') == 'startup':
                        stats['esp32_device_id'] = message.get('device_id')
                        stats['esp32_mac_address'] = message.get('mac_address')
                        print(f"\nESP32 Startup Detected!")
                        print(f"  Device ID: {stats['esp32_device_id']}")
                        print(f"  MAC Address: {stats['esp32_mac_address']}")
                        print(f"  Firmware: {message.get('firmware_version')}")
                        print()
                    
                    if message.get('type') == 'encoder':
                        print(f"ENCODER MESSAGE: {message}")
                    
                    if esp32_to_ws_queue and main_loop:
                        try:
                            asyncio.run_coroutine_threadsafe(
                                esp32_to_ws_queue.put(message),
                                main_loop
                            )
                        except Exception as e:
                            print(f"Error putting message in queue: {e}")
                    
                except json.JSONDecodeError:
                    debug_message = {
                        'type': 'esp32_debug',
                        'message': line,
                        'timestamp': int(time.time() * 1000)
                    }
                    
                    if esp32_to_ws_queue and main_loop:
                        try:
                            asyncio.run_coroutine_threadsafe(
                                esp32_to_ws_queue.put(debug_message),
                                main_loop
                            )
                        except:
                            pass
                    
        except serial.SerialException as e:
            print(f"Serial connection lost: {e}")
            serial_connection = None
            stats['esp32_connected'] = False
            time.sleep(1)
            
        except Exception as e:
            print(f"Error in serial reader: {e}")
            time.sleep(0.1)

async def websocket_handler(websocket):
    client_addr = websocket.remote_address
    timestamp = datetime.now().strftime("%H:%M:%S.%f")[:-3]
    print(f"[{timestamp}] WebSocket client connected: {client_addr}")
    
    connected_clients.add(websocket)
    
    await send_to_client(websocket, {
        'type': 'bridge_status',
        'esp32_connected': stats['esp32_connected'],
        'device_id': stats['esp32_device_id'],
        'mac_address': stats['esp32_mac_address'],
        'stats': {
            'esp32_messages_received': stats['esp32_messages_received'],
            'esp32_messages_sent': stats['esp32_messages_sent'],
            'ws_messages_received': stats['ws_messages_received'],
            'ws_messages_sent': stats['ws_messages_sent']
        },
        'timestamp': int(time.time() * 1000)
    })
    
    try:
        async for message in websocket:
            await handle_websocket_message(websocket, message)
            
    except websockets.exceptions.ConnectionClosed:
        print(f"WebSocket client disconnected: {client_addr}")
    except Exception as e:
        print(f"WebSocket error for {client_addr}: {e}")
    finally:
        connected_clients.discard(websocket)

async def handle_websocket_message(websocket, message_str):
    global stats
    
    try:
        stats['ws_messages_received'] += 1
        timestamp = datetime.now().strftime("%H:%M:%S.%f")[:-3]
        print(f"[{timestamp}] WebSocket: {message_str}")
        
        message = json.loads(message_str)
        message_type = message.get('type', '')
        
        if message_type == 'bridge_command':
            await handle_bridge_command(websocket, message)
            return
        
        if message_type == 'parameter_structure_sync':
            print(f"PARAMETER STRUCTURE RECEIVED! Broadcasting to {len(connected_clients)} clients")
            print(f"Structure contains {len(message.get('parameters', []))} parameters")
            for client in connected_clients.copy():
                if client != websocket:
                    try:
                        await client.send(message_str)
                    except:
                        connected_clients.discard(client)
            await forward_to_esp32(message)
            return
                        
        elif message_type == 'parameter_value_sync':
            print(f"Broadcasting parameter values to {len(connected_clients)} clients")
            for client in connected_clients.copy():
                if client != websocket:
                    try:
                        await client.send(message_str)
                    except:
                        connected_clients.discard(client)
            await forward_to_esp32(message)
            return
                        
        elif message_type == 'parameter_color_sync':
            print(f"COLOR UPDATE! Broadcasting color changes to {len(connected_clients)} clients")
            color_updates = message.get('updates', [])
            for update in color_updates:
                param_id = update.get('id', 'unknown')
                color = update.get('color', 'unknown')
                print(f"Parameter {param_id} color changed to {color}")
            for client in connected_clients.copy():
                if client != websocket:
                    try:
                        await client.send(message_str)
                    except:
                        connected_clients.discard(client)
            await forward_to_esp32(message)
            return
        
        elif message_type == 'check_updates':
            await handle_check_updates(websocket)
            return
            
        elif message_type == 'download_updates':
            components = message.get('components', [])
            await handle_download_updates(websocket, components)
            return
            
        elif message_type == 'install_updates':
            components = message.get('components', [])
            await handle_install_updates(websocket, components)
            return
            
        elif message_type == 'get_update_status':
            await handle_get_update_status(websocket)
            return
        
        await forward_to_esp32(message)
        
    except json.JSONDecodeError:
        print(f"Invalid JSON from WebSocket: {message_str}")
    except Exception as e:
        print(f"Error handling WebSocket message: {e}")

async def handle_bridge_command(websocket, message):
    command = message.get('command', '')
    
    if command == 'get_status':
        await send_to_client(websocket, {
            'type': 'bridge_status',
            'esp32_connected': stats['esp32_connected'],
            'device_id': stats['esp32_device_id'],
            'mac_address': stats['esp32_mac_address'],
            'stats': stats.copy(),
            'timestamp': int(time.time() * 1000)
        })
        
    elif command == 'restart_esp32_connection':
        print("Restarting ESP32 connection...")
        if serial_connection:
            serial_connection.close()

async def forward_to_esp32(message):
    global stats
    
    if not serial_connection or not serial_connection.is_open:
        print("Cannot send to ESP32: Serial connection not available")
        return
        
    try:
        message_str = json.dumps(message)
        serial_connection.write((message_str + '\n').encode('utf-8'))
        serial_connection.flush()
        
        stats['esp32_messages_sent'] += 1
        timestamp = datetime.now().strftime("%H:%M:%S.%f")[:-3]
        print(f"[{timestamp}] -> ESP32: {message_str}")
        
    except Exception as e:
        print(f"Error sending to ESP32: {e}")

async def send_to_client(websocket, message):
    global stats
    
    try:
        message_str = json.dumps(message)
        await websocket.send(message_str)
        stats['ws_messages_sent'] += 1
        
    except Exception as e:
        print(f"Error sending to WebSocket client: {e}")

async def broadcast_to_websockets(message):
    if not connected_clients:
        return
        
    clients_copy = connected_clients.copy()
    
    for client in clients_copy:
        try:
            await send_to_client(client, message)
        except:
            connected_clients.discard(client)

async def handle_check_updates(websocket):
    global update_manager
    
    print("[UPDATE] Checking for updates...")
    
    try:
        result = await update_manager.check_for_updates()
        
        if result:
            await send_to_client(websocket, {
                'type': 'update_check_result',
                **result
            })
        else:
            await send_to_client(websocket, {
                'type': 'update_error',
                'error': update_manager.update_status.get('error', 'Unknown error')
            })
    except Exception as e:
        print(f"[UPDATE] Error checking for updates: {e}")
        await send_to_client(websocket, {
            'type': 'update_error',
            'error': str(e)
        })

async def handle_download_updates(websocket, components):
    global update_manager
    
    print(f"[UPDATE] Downloading updates for: {components}")
    
    try:
        result = await update_manager.check_for_updates()
        
        if not result or not result.get('available'):
            await send_to_client(websocket, {
                'type': 'update_error',
                'error': 'No updates available'
            })
            return
        
        available_components = result['components']
        
        for component in components:
            if component in available_components:
                comp_data = available_components[component]
                
                success = await update_manager.download_update(
                    component,
                    comp_data['url'],
                    comp_data['sha256'],
                    comp_data['size_bytes']
                )
                
                if not success:
                    await send_to_client(websocket, {
                        'type': 'update_error',
                        'error': f'Failed to download {component}'
                    })
                    return
                
                progress = update_manager.download_progress.get(component, {})
                await send_to_client(websocket, {
                    'type': 'update_progress',
                    'component': component,
                    **progress
                })
        
        await send_to_client(websocket, {
            'type': 'update_download_complete'
        })
        
    except Exception as e:
        print(f"[UPDATE] Error downloading updates: {e}")
        await send_to_client(websocket, {
            'type': 'update_error',
            'error': str(e)
        })

async def handle_install_updates(websocket, components):
    global update_manager
    
    print(f"[UPDATE] Installing updates for: {components}")
    
    try:
        steps = []
        if 'firmware' in components:
            steps.extend(['Backing up firmware', 'Flashing ESP32', 'Verifying firmware'])
        if 'server' in components:
            steps.extend(['Backing up server', 'Installing server', 'Restarting server'])
        if 'ui' in components:
            steps.extend(['Backing up UI', 'Installing UI', 'Restarting UI'])
        
        await send_to_client(websocket, {
            'type': 'update_install_progress',
            'phase': 'starting',
            'steps': steps,
            'current_step': 0
        })
        
        current_step = 0
        updated_versions = {}
        
        for component in ['firmware', 'server', 'ui']:
            if component not in components:
                continue
            
            result = await update_manager.check_for_updates()
            if not result or not result.get('available'):
                raise Exception('No updates available')
            
            version = result['components'][component]['version']
            
            if component == 'firmware':
                success = update_manager.apply_firmware_update(version)
                current_step += 3
            elif component == 'server':
                success = update_manager.apply_server_update(version)
                current_step += 3
            elif component == 'ui':
                success = update_manager.apply_ui_update(version)
                current_step += 3
            
            if success:
                updated_versions[component] = version
                await send_to_client(websocket, {
                    'type': 'update_install_progress',
                    'phase': f'{component} complete',
                    'steps': steps,
                    'current_step': current_step
                })
            else:
                raise Exception(f'Failed to install {component}')
        
        await send_to_client(websocket, {
            'type': 'update_complete',
            'components': list(updated_versions.keys()),
            'versions': updated_versions
        })
        
    except Exception as e:
        print(f"[UPDATE] Error installing updates: {e}")
        await send_to_client(websocket, {
            'type': 'update_error',
            'error': str(e)
        })

async def handle_get_update_status(websocket):
    global update_manager
    
    try:
        status = update_manager.get_status()
        await send_to_client(websocket, {
            'type': 'current_versions',
            'versions': status['current_versions']
        })
    except Exception as e:
        print(f"[UPDATE] Error getting status: {e}")

async def message_forwarder():
    global esp32_to_ws_queue
    
    print("Starting message forwarder...")
    
    while running:
        try:
            message = await asyncio.wait_for(
                esp32_to_ws_queue.get(), 
                timeout=1.0
            )
            
            await broadcast_to_websockets(message)
            
        except asyncio.TimeoutError:
            continue
        except Exception as e:
            print(f"Error in message forwarder: {e}")

async def start_server(port, baud=115200, ws_port=8766):
    global running, serial_connection, esp32_to_ws_queue, main_loop, update_manager
    
    main_loop = asyncio.get_running_loop()
    
    print("\n" + "="*60)
    print("ESP32-S3 WebSocket-to-Serial Bridge Server with OTA Updates")
    print("="*60)
    
    update_manager = UpdateManager()
    print("[UPDATE] Update manager initialized")
    
    esp32_port = find_esp32_port()
    
    if not connect_to_esp32(esp32_port, baud):
        print("Failed to connect to ESP32. Exiting.")
        return
    
    print(f"\nESP32 Serial: {esp32_port} @ {baud} baud")
    print(f"WebSocket Server: ws://0.0.0.0:{ws_port}")
    print("="*60)
    
    running = True
    esp32_to_ws_queue = asyncio.Queue()
    
    serial_thread = threading.Thread(target=serial_reader_thread, daemon=True)
    serial_thread.start()
    
    forwarder_task = asyncio.create_task(message_forwarder())
    
    server = await websockets.serve(
        websocket_handler,
        "0.0.0.0",
        ws_port
    )
    
    print("\nBridge is running!")
    print(f"Connect WebSocket clients to: ws://localhost:{ws_port}")
    print("ESP32 messages will be forwarded to WebSocket clients")
    print("WebSocket commands will be sent to ESP32")
    print("\nPress Ctrl+C to stop...\n")
    
    try:
        await asyncio.gather(server.wait_closed(), forwarder_task)
    except KeyboardInterrupt:
        print("\nShutting down bridge...")
        running = False
        if serial_connection:
            serial_connection.close()

def main():
    import argparse
    
    parser = argparse.ArgumentParser(description='ESP32 WebSocket-to-Serial Bridge')
    parser.add_argument('--port', default=None, 
                       help='Serial port for ESP32 (default: auto-detect)')
    parser.add_argument('--baud', type=int, default=115200,
                       help='Baud rate for serial communication (default: 115200)')
    parser.add_argument('--ws-port', type=int, default=8766,
                       help='WebSocket server port (default: 8766)')
    
    args = parser.parse_args()
    
    try:
        asyncio.run(start_server(args.port, args.baud, args.ws_port))
    except KeyboardInterrupt:
        print("\nBridge stopped by user")
    except Exception as e:
        print(f"Bridge crashed: {e}")

if __name__ == '__main__':
    main()

